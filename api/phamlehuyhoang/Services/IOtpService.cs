using phamlehuyhoang.Entities;

namespace phamlehuyhoang.Services;

public interface IOtpService
{
    Task<(OtpChallenge Challenge, string RawCode)> CreateChallengeAsync(Guid userId, string purpose);
    Task<(bool Success, string Message, User? User)> VerifyOtpAsync(string ticket, string code, string? expectedPurpose = null);
    Task<(bool Success, string Message, string? NewTicket, string? RawCode)> ResendOtpAsync(string ticket);
}
