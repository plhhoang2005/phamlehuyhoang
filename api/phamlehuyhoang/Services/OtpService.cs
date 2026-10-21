using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using phamlehuyhoang.Data;
using phamlehuyhoang.Entities;

namespace phamlehuyhoang.Services;

public class OtpService : IOtpService
{
    public const string LoginPurpose = "Login";
    public const string EmailActivationPurpose = "EmailActivation";
    public const int CodeLifetimeMinutes = 5;
    public const int MaxAttempts = 5;
    public const int ResendCooldownSeconds = 60;
    private readonly AppDbContext _context;
    private readonly IEmailService _emailService;

    public OtpService(AppDbContext context, IEmailService emailService, ILogger<OtpService> logger)
    {
        _context = context;
        _emailService = emailService;
    }

    private static string HashCode(string ticket, string code) =>
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(ticket + ":" + code)));

    public async Task<(OtpChallenge Challenge, string RawCode)> CreateChallengeAsync(Guid userId, string purpose)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null || !user.IsActive)
            throw new UnauthorizedAccessException("Tài khoản không khả dụng.");

        var oldChallenges = await _context.OtpChallenges
            .Where(c => c.UserId == userId && c.Purpose == purpose && !c.IsUsed)
            .ToListAsync();
        var latest = oldChallenges.OrderByDescending(c => c.LastSentAtUtc).FirstOrDefault();
        var now = DateTime.UtcNow;
        if (latest != null && (now - latest.LastSentAtUtc).TotalSeconds < ResendCooldownSeconds)
        {
            var wait = (int)Math.Ceiling(ResendCooldownSeconds - (now - latest.LastSentAtUtc).TotalSeconds);
            throw new InvalidOperationException($"Vui lòng đợi thêm {wait} giây trước khi yêu cầu mã mới.");
        }

        var rawCode = RandomNumberGenerator.GetInt32(100000, 1000000).ToString("D6");
        var ticket = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32))
            .Replace('+', '-').Replace('/', '_').TrimEnd('=');
        var challenge = new OtpChallenge
        {
            UserId = userId, Ticket = ticket, CodeHash = HashCode(ticket, rawCode),
            Purpose = purpose, CreatedAtUtc = now,
            ExpiresAtUtc = now.AddMinutes(CodeLifetimeMinutes), LastSentAtUtc = now
        };
        var displayPurpose = purpose == EmailActivationPurpose ? "kích hoạt tài khoản" : "đăng nhập";

        // Không tạo challenge có thể sử dụng hoặc nói đã gửi nếu SMTP thất bại.
        if (!await _emailService.SendOtpEmailAsync(user.Email, user.FullName, rawCode, displayPurpose))
            throw new EmailDeliveryException();

        foreach (var old in oldChallenges) old.IsUsed = true;
        _context.OtpChallenges.Add(challenge);
        await _context.SaveChangesAsync();
        return (challenge, rawCode);
    }

    public async Task<(bool Success, string Message, User? User)> VerifyOtpAsync(
        string ticket, string code, string? expectedPurpose = null)
    {
        var challenge = await _context.OtpChallenges.Include(c => c.User)
            .FirstOrDefaultAsync(c => c.Ticket == ticket);
        if (challenge == null || challenge.User == null || !challenge.User.IsActive)
            return (false, "Phiên xác thực không hợp lệ.", null);
        if (expectedPurpose != null && challenge.Purpose != expectedPurpose)
            return (false, "Mã xác thực không đúng mục đích của thao tác.", null);
        if (challenge.IsUsed)
            return (false, "Mã OTP này đã được sử dụng hoặc phiên đã kết thúc.", null);
        if (DateTime.UtcNow >= challenge.ExpiresAtUtc)
            return (false, "Mã OTP đã hết thời hạn 5 phút. Vui lòng yêu cầu gửi lại.", null);
        if (challenge.AttemptCount >= MaxAttempts)
            return (false, "Bạn đã nhập sai quá số lần cho phép (tối đa 5 lần). Hãy đăng nhập lại.", null);

        if (!CryptographicOperations.FixedTimeEquals(
                Encoding.UTF8.GetBytes(challenge.CodeHash),
                Encoding.UTF8.GetBytes(HashCode(ticket, code.Trim()))))
        {
            challenge.AttemptCount++;
            try { await _context.SaveChangesAsync(); }
            catch (DbUpdateConcurrencyException)
            {
                return (false, "Phiên xác thực đã thay đổi. Vui lòng thử lại.", null);
            }
            return (false, $"Mã OTP không chính xác. Bạn còn {MaxAttempts - challenge.AttemptCount} lần thử.", null);
        }

        challenge.IsUsed = true;
        try { await _context.SaveChangesAsync(); }
        catch (DbUpdateConcurrencyException)
        {
            return (false, "Mã OTP đã được sử dụng. Vui lòng đăng nhập lại.", null);
        }
        return (true, "Xác thực thành công.", challenge.User);
    }

    public async Task<(bool Success, string Message, string? NewTicket, string? RawCode)> ResendOtpAsync(string ticket)
    {
        var challenge = await _context.OtpChallenges.Include(c => c.User)
            .FirstOrDefaultAsync(c => c.Ticket == ticket);
        if (challenge == null || challenge.User == null || !challenge.User.IsActive || challenge.IsUsed)
            return (false, "Phiên xác thực đã kết thúc. Vui lòng đăng nhập lại.", null, null);
        if (challenge.CreatedAtUtc < DateTime.UtcNow.AddMinutes(-30))
            return (false, "Phiên xác thực đã quá hạn. Vui lòng đăng nhập lại.", null, null);

        var elapsed = (DateTime.UtcNow - challenge.LastSentAtUtc).TotalSeconds;
        if (elapsed < ResendCooldownSeconds)
            return (false, $"Vui lòng đợi thêm {(int)Math.Ceiling(ResendCooldownSeconds - elapsed)} giây trước khi yêu cầu gửi lại.", null, null);

        var (newChallenge, rawCode) = await CreateChallengeAsync(challenge.UserId, challenge.Purpose);
        return (true, "Mã xác thực mới đã được gửi tới email của bạn.", newChallenge.Ticket, rawCode);
    }
}
