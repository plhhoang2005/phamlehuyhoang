using System.Net;
using MailKit.Net.Smtp;
using MailKit.Security;
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
        var devBypass = _configuration.GetValue<bool>("DevMode:EnableOtpConsoleLog", false);

        var host = _configuration["Smtp:Host"];
        var username = _configuration["Smtp:User"];
        var password = _configuration["Smtp:Password"];
        var port = int.TryParse(_configuration["Smtp:Port"], out var parsedPort) ? parsedPort : 587;
        if (string.IsNullOrWhiteSpace(host) || string.IsNullOrWhiteSpace(username) ||
            string.IsNullOrWhiteSpace(password) || port is < 1 or > 65535)
        {
            if (devBypass)
            {
                LogDevOtp(toEmail, fullName, otpCode, purpose, "Chưa cấu hình SMTP");
                return true;
            }
            _logger.LogError("Chưa cấu hình SMTP đầy đủ (Host/User/Password/Port). Không gửi email và không cấp mã đăng nhập.");
            return false;
        }

        try
        {
            var message = new MimeMessage();
            message.From.Add(new MailboxAddress("Điểm danh Sinh viên", username));
            message.To.Add(new MailboxAddress(fullName, toEmail));
            // Không đưa OTP vào tiêu đề, log hoặc HTTP response.
            message.Subject = $"Mã xác thực {purpose} — Điểm danh Sinh viên";
            var safeName = WebUtility.HtmlEncode(fullName);
            var safePurpose = WebUtility.HtmlEncode(purpose);
            message.Body = new BodyBuilder
            {
                TextBody = $"Xin chào {fullName}, mã xác thực {purpose} của bạn là {otpCode}. Mã có hiệu lực 5 phút và chỉ dùng một lần. Không chia sẻ mã với người khác.",
                HtmlBody = $"<div style='font-family:Arial;padding:24px'><h2>Điểm danh Sinh viên</h2><p>Xin chào {safeName},</p><p>Mã xác thực {safePurpose}:</p><p style='font-size:30px;font-weight:bold;letter-spacing:6px'>{otpCode}</p><p>Mã có hiệu lực 5 phút và chỉ dùng một lần. Không chia sẻ mã với người khác.</p></div>"
            }.ToMessageBody();

            using var cancellation = new CancellationTokenSource(TimeSpan.FromSeconds(10));
            using var client = new SmtpClient { Timeout = 10000 };
            await client.ConnectAsync(host, port,
                port == 465 ? SecureSocketOptions.SslOnConnect : SecureSocketOptions.StartTls,
                cancellation.Token);
            await client.AuthenticateAsync(username, password, cancellation.Token);
            await client.SendAsync(message, cancellation.Token);
            // SMTP đã chấp nhận thư. Lỗi đóng kết nối không biến thư đã gửi thành thất bại.
            try { await client.DisconnectAsync(true, cancellation.Token); }
            catch { /* Dispose closes the transport. */ }

            SaveOtpToLocalFile(toEmail, otpCode, purpose, "Gửi qua Gmail SMTP thành công");
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError("Gửi email xác thực thất bại ({ErrorType}); không dùng mã dự phòng.", ex.GetType().Name);
            if (devBypass)
            {
                LogDevOtp(toEmail, fullName, otpCode, purpose, $"SMTP thất bại ({ex.GetType().Name})");
                return true;
            }
            return false;
        }
    }

    private void SaveOtpToLocalFile(string toEmail, string otpCode, string purpose, string status)
    {
        try
        {
            var localDir = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../../.local"));
            if (Directory.Exists(localDir))
            {
                var filePath = Path.Combine(localDir, "dev-latest-otp.txt");
                File.WriteAllText(filePath, $"OTP: {otpCode}\nEmail: {toEmail}\nPurpose: {purpose}\nStatus: {status}\nTimeUtc: {DateTime.UtcNow:O}");
            }
        }
        catch { /* Bỏ qua nếu không ghi được file */ }
    }

    private void LogDevOtp(string toEmail, string fullName, string otpCode, string purpose, string reason)
    {
        Console.ForegroundColor = ConsoleColor.Yellow;
        Console.WriteLine("\n========================================================");
        Console.WriteLine($"[DEV OTP LOGGER] {reason}");
        Console.WriteLine($"[DEV OTP LOGGER] Người nhận: {toEmail} ({fullName})");
        Console.WriteLine($"[DEV OTP LOGGER] Thao tác:   {purpose}");
        Console.WriteLine($"[DEV OTP LOGGER] MÃ OTP:    >>>  {otpCode}  <<<");
        Console.WriteLine("========================================================\n");
        Console.ResetColor();
        _logger.LogWarning("[DEV OTP] Mã OTP cho {Email} ({Purpose}) là: {OtpCode} (Lý do: {Reason})", toEmail, purpose, otpCode, reason);
        SaveOtpToLocalFile(toEmail, otpCode, purpose, reason);
    }
}
