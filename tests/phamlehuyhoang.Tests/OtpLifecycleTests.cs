using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using phamlehuyhoang.Data;
using phamlehuyhoang.Entities;
using phamlehuyhoang.Services;
using Xunit;

namespace phamlehuyhoang.Tests;

public class MockEmailService : IEmailService
{
    public string? LastCodeSent { get; private set; }
    public string? LastEmailSent { get; private set; }

    public Task<bool> SendOtpEmailAsync(string toEmail, string fullName, string otpCode, string purpose)
    {
        LastCodeSent = otpCode;
        LastEmailSent = toEmail;
        return Task.FromResult(true);
    }
}

public class OtpLifecycleTests
{
    private AppDbContext CreateInMemoryDbContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }

    [Fact]
    public async Task Otp_HappyPath_SucceedsAndCannotBeReused()
    {
        using var context = CreateInMemoryDbContext();
        var mockEmail = new MockEmailService();
        var otpService = new OtpService(context, mockEmail, NullLogger<OtpService>.Instance);

        var user = new User
        {
            Id = Guid.NewGuid(),
            Username = "teststudent",
            Email = "student@test.com",
            FullName = "Nguyen Van Test"
        };
        context.Users.Add(user);
        await context.SaveChangesAsync();

        var (challenge, rawCode) = await otpService.CreateChallengeAsync(user.Id, "Login");

        Assert.Equal(6, rawCode.Length);
        Assert.Equal(rawCode, mockEmail.LastCodeSent);

        // Lần đầu xác thực đúng mã -> Thành công
        var (success1, msg1, verifiedUser) = await otpService.VerifyOtpAsync(challenge.Ticket, rawCode);
        Assert.True(success1);
        Assert.NotNull(verifiedUser);
        Assert.Equal(user.Id, verifiedUser.Id);

        // Dùng lại mã vừa xác thực -> Bị từ chối
        var (success2, msg2, _) = await otpService.VerifyOtpAsync(challenge.Ticket, rawCode);
        Assert.False(success2);
        Assert.Contains("đã được sử dụng", msg2);
    }

    [Fact]
    public async Task Otp_WrongCode_BlocksAfter5Attempts()
    {
        using var context = CreateInMemoryDbContext();
        var mockEmail = new MockEmailService();
        var otpService = new OtpService(context, mockEmail, NullLogger<OtpService>.Instance);

        var user = new User
        {
            Id = Guid.NewGuid(),
            Username = "teststudent2",
            Email = "student2@test.com",
            FullName = "Test Student"
        };
        context.Users.Add(user);
        await context.SaveChangesAsync();

        var (challenge, rawCode) = await otpService.CreateChallengeAsync(user.Id, "Login");

        // Nhập sai 5 lần
        for (int i = 1; i <= 5; i++)
        {
            var (success, msg, _) = await otpService.VerifyOtpAsync(challenge.Ticket, "000000");
            Assert.False(success);
        }

        // Lần thứ 6 kể cả nhập đúng mã thật -> Vẫn bị khóa
        var (finalSuccess, finalMsg, _) = await otpService.VerifyOtpAsync(challenge.Ticket, rawCode);
        Assert.False(finalSuccess);
        Assert.Contains("quá số lần cho phép", finalMsg);
    }

    [Fact]
    public async Task Otp_Expired_Fails()
    {
        using var context = CreateInMemoryDbContext();
        var mockEmail = new MockEmailService();
        var otpService = new OtpService(context, mockEmail, NullLogger<OtpService>.Instance);

        var user = new User
        {
            Id = Guid.NewGuid(),
            Username = "teststudent3",
            Email = "student3@test.com",
            FullName = "Test Student 3"
        };
        context.Users.Add(user);
        await context.SaveChangesAsync();

        var (challenge, rawCode) = await otpService.CreateChallengeAsync(user.Id, "Login");

        // Giả lập thời gian hết hạn (lùi lại 10 phút trước)
        var dbChallenge = await context.OtpChallenges.FindAsync(challenge.Id);
        dbChallenge!.ExpiresAtUtc = DateTime.UtcNow.AddMinutes(-5);
        await context.SaveChangesAsync();

        var (success, msg, _) = await otpService.VerifyOtpAsync(challenge.Ticket, rawCode);
        Assert.False(success);
        Assert.Contains("hết thời hạn", msg);
    }

    [Fact]
    public async Task Otp_Resend_Enforces60SecondsCooldown()
    {
        using var context = CreateInMemoryDbContext();
        var mockEmail = new MockEmailService();
        var otpService = new OtpService(context, mockEmail, NullLogger<OtpService>.Instance);

        var user = new User
        {
            Id = Guid.NewGuid(),
            Username = "teststudent4",
            Email = "student4@test.com",
            FullName = "Test Student 4"
        };
        context.Users.Add(user);
        await context.SaveChangesAsync();

        var (challenge, _) = await otpService.CreateChallengeAsync(user.Id, "Login");

        // Thử gửi lại ngay lập tức -> Bị từ chối do cooldown 60s
        var (successImmediate, msgImmediate, _, _) = await otpService.ResendOtpAsync(challenge.Ticket);
        Assert.False(successImmediate);
        Assert.Contains("Vui lòng đợi thêm", msgImmediate);

        // Giả lập đã qua 65 giây
        var dbChallenge = await context.OtpChallenges.FindAsync(challenge.Id);
        dbChallenge!.LastSentAtUtc = DateTime.UtcNow.AddSeconds(-65);
        await context.SaveChangesAsync();

        // Gửi lại sau cooldown -> Thành công
        var (successAfter, msgAfter, newTicket, newRaw) = await otpService.ResendOtpAsync(challenge.Ticket);
        Assert.True(successAfter);
        Assert.NotNull(newTicket);
        Assert.NotNull(newRaw);
    }
}
