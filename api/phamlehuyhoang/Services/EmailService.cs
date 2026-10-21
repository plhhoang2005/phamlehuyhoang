using MailKit.Net.Smtp;
using MimeKit;

namespace phamlehuyhoang.Services;

public class EmailService : IEmailService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<bool> SendOtpEmailAsync(string toEmail, string fullName, string otpCode, string purpose)
    {
        var smtpHost = _configuration["Smtp:Host"] ?? Environment.GetEnvironmentVariable("SMTP_HOST");
        var smtpPortStr = _configuration["Smtp:Port"] ?? Environment.GetEnvironmentVariable("SMTP_PORT");
        var smtpUser = _configuration["Smtp:User"] ?? Environment.GetEnvironmentVariable("SMTP_USER");
        var smtpPass = _configuration["Smtp:Password"] ?? Environment.GetEnvironmentVariable("SMTP_PASSWORD");

        _logger.LogInformation("[OTP NOTIFICATION] Cho {Email} ({Name}): Mã OTP là {Code} (Mục đích: {Purpose})",
            toEmail, fullName, otpCode, purpose);

        if (string.IsNullOrWhiteSpace(smtpHost) || string.IsNullOrWhiteSpace(smtpUser))
        {
            _logger.LogWarning("Chưa cấu hình SMTP thật. Mã OTP được ghi log phục vụ môi trường phát triển.");
            return true;
        }

        try
        {
            int port = int.TryParse(smtpPortStr, out var p) ? p : 587;
            var message = new MimeMessage();
            message.From.Add(new MailboxAddress("Hệ Thống Điểm Danh phamlehuyhoang", smtpUser));
            message.To.Add(new MailboxAddress(fullName, toEmail));
            message.Subject = $"[phamlehuyhoang] Mã xác thực OTP: {otpCode}";

            var bodyBuilder = new BodyBuilder
            {
                HtmlBody = $@"
                    <div style='font-family: Arial, sans-serif; padding: 20px; color: #333;'>
                        <h2>Hệ thống Điểm danh Sinh viên — phamlehuyhoang</h2>
                        <p>Xin chào <b>{fullName}</b>,</p>
                        <p>Mã xác thực OTP của bạn cho thao tác <b>{purpose}</b> là:</p>
                        <div style='font-size: 28px; font-weight: bold; letter-spacing: 6px; color: #1976D2; margin: 16px 0;'>
                            {otpCode}
                        </div>
                        <p>Mã này có hiệu lực trong vòng <b>5 phút</b> và chỉ sử dụng được 1 lần.</p>
                        <p>Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email.</p>
                    </div>"
            };

            message.Body = bodyBuilder.ToMessageBody();

            using var client = new SmtpClient();
            await client.ConnectAsync(smtpHost, port, MailKit.Security.SecureSocketOptions.StartTlsWhenAvailable);
            if (!string.IsNullOrWhiteSpace(smtpPass))
            {
                await client.AuthenticateAsync(smtpUser, smtpPass);
            }
            await client.SendAsync(message);
            await client.DisconnectAsync(true);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi gửi email thật tới {Email}. Fallback sang chế độ ghi log dev.", toEmail);
            return false;
        }
    }
}
