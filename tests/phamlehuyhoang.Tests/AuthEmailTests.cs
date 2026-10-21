using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Logging.Abstractions;
using phamlehuyhoang.Data;
using phamlehuyhoang.DTOs;
using phamlehuyhoang.Entities;
using phamlehuyhoang.Services;

namespace phamlehuyhoang.Tests;

public class AuthEmailTests
{
    private static AppDbContext CreateContext() => new(new DbContextOptionsBuilder<AppDbContext>()
        .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static AuthService CreateAuth(AppDbContext db, IEmailService email) => new(
        db, new OtpService(db, email, NullLogger<OtpService>.Instance),
        new UnusedFaceService(), new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["Jwt:Secret"] = "test-only-signing-key-at-least-32-characters-long"
        }).Build(), new DevelopmentEnvironment(), NullLogger<AuthService>.Instance);

    [Fact]
    public async Task Email_WithoutSmtpConfiguration_DoesNotReportSuccessfulDelivery()
    {
        var service = new EmailService(new ConfigurationBuilder().Build(), NullLogger<EmailService>.Instance);
        Assert.False(await service.SendOtpEmailAsync("student@example.com", "Student", "123456", "Login"));
    }

    [Fact]
    public async Task Otp_DeliveryFailure_DoesNotCreateUsableChallenge()
    {
        using var db = CreateContext();
        var user = new User { Email = "student@example.com", Username = "student", FullName = "Student" };
        db.Users.Add(user);
        await db.SaveChangesAsync();
        var otp = new OtpService(db, new RejectingEmailService(), NullLogger<OtpService>.Instance);

        await Assert.ThrowsAnyAsync<InvalidOperationException>(() => otp.CreateChallengeAsync(user.Id, "Login"));
        Assert.Empty(await db.OtpChallenges.Where(c => !c.IsUsed).ToListAsync());
    }

    [Fact]
    public async Task Registration_SendsActivationEmailAndDoesNotReturnAccountOrToken()
    {
        using var db = CreateContext();
        var email = new MockEmailService();
        var auth = CreateAuth(db, email);
        var response = await auth.RegisterStudentAsync(new RegisterRequest(
            "newstudent", "student@example.com", "Student", "StrongPass123!", "S123"));

        Assert.NotNull(email.LastCodeSent);
        Assert.Equal("student@example.com", email.LastEmailSent);
        var json = JsonSerializer.Serialize(response);
        Assert.Contains("Ticket", json);
        Assert.DoesNotContain("PasswordHash", json);
        Assert.DoesNotContain("Token", json);
    }

    [Fact]
    public async Task DevelopmentLogin_DoesNotExposeOtpInResponse()
    {
        using var db = CreateContext();
        var email = new MockEmailService();
        var auth = CreateAuth(db, email);
        await auth.RegisterStudentAsync(new RegisterRequest(
            "newstudent", "student@example.com", "Student", "StrongPass123!", "S123"));
        // End the registration challenge to isolate the response contract from its cooldown.
        foreach (var challenge in await db.OtpChallenges.ToListAsync()) challenge.IsUsed = true;
        await db.SaveChangesAsync();
        var response = await auth.LoginAsync(new LoginRequest("newstudent", "StrongPass123!"));
        var json = JsonSerializer.Serialize(response);
        Assert.DoesNotContain("DevOtp", json);
        Assert.DoesNotContain(email.LastCodeSent!, json);
    }


    [Fact]
    public async Task ActivationOtp_CannotLogIn_AndLoginOtpCannotActivate()
    {
        using var db = CreateContext();
        var email = new MockEmailService();
        var auth = CreateAuth(db, email);
        var activation = await auth.RegisterStudentAsync(new RegisterRequest(
            "newstudent", "student@example.com", "Student", "StrongPass123!", "S123"));
        var activationCode = email.LastCodeSent!;
        Assert.Equal(OtpService.EmailActivationPurpose, activation.Purpose);
        Assert.False((await db.Users.SingleAsync()).EmailConfirmed);

        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            auth.VerifyOtpAndGenerateTokenAsync(new VerifyOtpRequest(activation.Ticket, activationCode)));
        await auth.VerifyEmailAsync(new VerifyOtpRequest(activation.Ticket, activationCode));
        Assert.True((await db.Users.SingleAsync()).EmailConfirmed);
        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            auth.VerifyEmailAsync(new VerifyOtpRequest(activation.Ticket, activationCode)));

        var login = await auth.LoginAsync(new LoginRequest("newstudent", "StrongPass123!"));
        var loginCode = email.LastCodeSent!;
        Assert.Equal(OtpService.LoginPurpose, login.Purpose);
        Assert.NotEqual(activation.Ticket, login.Ticket);
        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            auth.VerifyEmailAsync(new VerifyOtpRequest(login.Ticket, loginCode)));
        var result = await auth.VerifyOtpAndGenerateTokenAsync(new VerifyOtpRequest(login.Ticket, loginCode));
        Assert.False(string.IsNullOrWhiteSpace(result.Token));
        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            auth.VerifyOtpAndGenerateTokenAsync(new VerifyOtpRequest(login.Ticket, loginCode)));
    }

    [Fact]
    public async Task ExistingUnverifiedAccount_LoginRequestsActivationFirst()
    {
        using var db = CreateContext();
        var email = new MockEmailService();
        var auth = CreateAuth(db, email);
        var activation = await auth.RegisterStudentAsync(new RegisterRequest(
            "newstudent", "student@example.com", "Student", "StrongPass123!", null));
        (await db.OtpChallenges.SingleAsync()).LastSentAtUtc = DateTime.UtcNow.AddSeconds(-65);
        await db.SaveChangesAsync();

        var response = await auth.LoginAsync(new LoginRequest("newstudent", "StrongPass123!"));
        Assert.Equal(OtpService.EmailActivationPurpose, response.Purpose);
        Assert.NotEqual(activation.Ticket, response.Ticket);
        Assert.False((await db.Users.SingleAsync()).EmailConfirmed);
    }

    [Fact]
    public async Task Otp_IsStoredAsHash_AndConsumedTicketCannotBeResent()
    {
        using var db = CreateContext();
        var email = new MockEmailService();
        var otp = new OtpService(db, email, NullLogger<OtpService>.Instance);
        var user = new User { Username = "student", Email = "student@example.com", FullName = "Student" };
        db.Users.Add(user);
        await db.SaveChangesAsync();
        var (challenge, raw) = await otp.CreateChallengeAsync(user.Id, OtpService.LoginPurpose);
        Assert.NotEqual(raw, challenge.CodeHash);
        Assert.Equal(64, challenge.CodeHash.Length);
        Assert.True((await otp.VerifyOtpAsync(challenge.Ticket, raw, OtpService.LoginPurpose)).Success);
        challenge.LastSentAtUtc = DateTime.UtcNow.AddSeconds(-65);
        await db.SaveChangesAsync();
        Assert.False((await otp.ResendOtpAsync(challenge.Ticket)).Success);
    }

    [Fact]
    public async Task Resend_InvalidatesPreviousCode_AndPreservesPurpose()
    {
        using var db = CreateContext();
        var email = new MockEmailService();
        var otp = new OtpService(db, email, NullLogger<OtpService>.Instance);
        var user = new User { Username = "student", Email = "student@example.com", FullName = "Student" };
        db.Users.Add(user);
        await db.SaveChangesAsync();
        var (original, originalCode) = await otp.CreateChallengeAsync(user.Id, OtpService.EmailActivationPurpose);
        original.LastSentAtUtc = DateTime.UtcNow.AddSeconds(-65);
        await db.SaveChangesAsync();
        var replacement = await otp.ResendOtpAsync(original.Ticket);
        Assert.True(replacement.Success);
        Assert.False((await otp.VerifyOtpAsync(original.Ticket, originalCode, OtpService.EmailActivationPurpose)).Success);
        Assert.Equal(OtpService.EmailActivationPurpose,
            (await db.OtpChallenges.SingleAsync(c => c.Ticket == replacement.NewTicket)).Purpose);
        Assert.True((await otp.VerifyOtpAsync(replacement.NewTicket!, email.LastCodeSent!,
            OtpService.EmailActivationPurpose)).Success);
    }

    [Fact]
    public async Task Registration_CanRetryAfterEmailFailure_WithoutCreatingDuplicateAccount()
    {
        using var db = CreateContext();
        var email = new MockEmailService { ShouldSucceed = false };
        var auth = CreateAuth(db, email);
        var request = new RegisterRequest("newstudent", "student@example.com", "Student", "StrongPass123!", null);
        await Assert.ThrowsAsync<EmailDeliveryException>(() => auth.RegisterStudentAsync(request));
        Assert.Single(await db.Users.ToListAsync());
        Assert.Empty(await db.OtpChallenges.ToListAsync());
        email.ShouldSucceed = true;
        var response = await auth.RegisterStudentAsync(request);
        Assert.Equal(OtpService.EmailActivationPurpose, response.Purpose);
        Assert.Single(await db.Users.ToListAsync());
    }

    private sealed class RejectingEmailService : IEmailService
    {
        public Task<bool> SendOtpEmailAsync(string toEmail, string fullName, string otpCode, string purpose) => Task.FromResult(false);
    }

    private sealed class DevelopmentEnvironment : IWebHostEnvironment
    {
        public string ApplicationName { get; set; } = "Tests";
        public string EnvironmentName { get; set; } = "Development";
        public string WebRootPath { get; set; } = "";
        public IFileProvider WebRootFileProvider { get; set; } = new NullFileProvider();
        public string ContentRootPath { get; set; } = "";
        public IFileProvider ContentRootFileProvider { get; set; } = new NullFileProvider();
    }

    private sealed class UnusedFaceService : IFaceService
    {
        public FaceProcessResult ExtractEmbeddingFromBase64(string imageBase64) => throw new NotSupportedException();
        public FaceProcessResult CompareFaces(byte[] registeredEmbedding, string candidateBase64, double threshold = 0.60) => throw new NotSupportedException();
        public double ComputeCosineSimilarity(byte[] embeddingA, byte[] embeddingB) => throw new NotSupportedException();
    }
}
