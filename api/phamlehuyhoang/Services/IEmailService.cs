namespace phamlehuyhoang.Services;

public interface IEmailService
{
    Task<bool> SendOtpEmailAsync(string toEmail, string fullName, string otpCode, string purpose);
}
