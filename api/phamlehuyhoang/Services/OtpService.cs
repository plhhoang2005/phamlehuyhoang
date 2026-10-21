using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using phamlehuyhoang.Data;
using phamlehuyhoang.Entities;

namespace phamlehuyhoang.Services;

public class OtpService : IOtpService
{
    private readonly AppDbContext _context;
    private readonly IEmailService _emailService;
    private readonly ILogger<OtpService> _logger;

    public const int CodeLifetimeMinutes = 5;
    public const int MaxAttempts = 5;
    public const int ResendCooldownSeconds = 60;

    public OtpService(AppDbContext context, IEmailService emailService, ILogger<OtpService> logger)
    {
        _context = context;
        _emailService = emailService;
        _logger = logger;
    }

    public async Task<(OtpChallenge Challenge, string RawCode)> CreateChallengeAsync(Guid userId, string purpose)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null) throw new InvalidOperationException("Người dùng không tồn tại");

        // Vô hiệu hóa các challenge cũ chưa dùng cùng mục đích của user này
        var oldChallenges = await _context.OtpChallenges
            .Where(c => c.UserId == userId && c.Purpose == purpose && !c.IsUsed)
            .ToListAsync();
        foreach (var old in oldChallenges)
        {
            old.IsUsed = true;
        }

        // Sinh mã OTP 6 chữ số an toàn bảo mật
        var rawCode = RandomNumberGenerator.GetInt32(100000, 1000000).ToString("D6");
        var ticket = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32))
            .Replace('+', '-').Replace('/', '_').TrimEnd('=');

        var now = DateTime.UtcNow;
        var challenge = new OtpChallenge
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Ticket = ticket,
            Code = rawCode,
            Purpose = purpose,
            CreatedAtUtc = now,
            ExpiresAtUtc = now.AddMinutes(CodeLifetimeMinutes),
            AttemptCount = 0,
            IsUsed = false,
            LastSentAtUtc = now
        };

        _context.OtpChallenges.Add(challenge);
        await _context.SaveChangesAsync();

        // Gửi email OTP
        await _emailService.SendOtpEmailAsync(user.Email, user.FullName, rawCode, purpose);

        return (challenge, rawCode);
    }

    public async Task<(bool Success, string Message, User? User)> VerifyOtpAsync(string ticket, string code)
    {
        var challenge = await _context.OtpChallenges
            .Include(c => c.User)
            .FirstOrDefaultAsync(c => c.Ticket == ticket);

        if (challenge == null)
        {
            return (false, "Phiên xác thực OTP không tồn tại hoặc không hợp lệ", null);
        }

        if (challenge.IsUsed)
        {
            return (false, "Mã OTP này đã được sử dụng trước đó", null);
        }

        var now = DateTime.UtcNow;
        if (now > challenge.ExpiresAtUtc)
        {
            challenge.IsUsed = true;
            await _context.SaveChangesAsync();
            return (false, "Mã OTP đã hết thời hạn 5 phút. Vui lòng yêu cầu gửi lại", null);
        }

        if (challenge.AttemptCount >= MaxAttempts)
        {
            challenge.IsUsed = true;
            await _context.SaveChangesAsync();
            return (false, "Bạn đã nhập sai quá số lần cho phép (tối đa 5 lần). Vui lòng yêu cầu lại", null);
        }

        if (challenge.Code != code.Trim())
        {
            challenge.AttemptCount++;
            await _context.SaveChangesAsync();
            var remaining = MaxAttempts - challenge.AttemptCount;
            return (false, $"Mã OTP không chính xác. Bạn còn {remaining} lần thử", null);
        }

        // Xác thực thành công: đánh dấu đã dùng
        challenge.IsUsed = true;
        await _context.SaveChangesAsync();

        return (true, "Xác thực OTP thành công", challenge.User);
    }

    public async Task<(bool Success, string Message, string? NewTicket, string? RawCode)> ResendOtpAsync(string ticket)
    {
        var challenge = await _context.OtpChallenges
            .Include(c => c.User)
            .FirstOrDefaultAsync(c => c.Ticket == ticket);

        if (challenge == null || challenge.User == null)
        {
            return (false, "Phiên xác thực không tồn tại", null, null);
        }

        var now = DateTime.UtcNow;
        var elapsed = (now - challenge.LastSentAtUtc).TotalSeconds;
        if (elapsed < ResendCooldownSeconds)
        {
            int wait = (int)Math.Ceiling(ResendCooldownSeconds - elapsed);
            return (false, $"Vui lòng đợi thêm {wait} giây trước khi yêu cầu gửi lại mã mới", null, null);
        }

        // Tạo challenge mới
        var (newChallenge, rawCode) = await CreateChallengeAsync(challenge.UserId, challenge.Purpose);
        return (true, "Mã OTP mới đã được gửi", newChallenge.Ticket, rawCode);
    }
}
