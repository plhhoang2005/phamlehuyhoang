using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using phamlehuyhoang.Data;
using phamlehuyhoang.DTOs;
using phamlehuyhoang.Entities;
using phamlehuyhoang.Enums;

namespace phamlehuyhoang.Services;

public class AuthService : IAuthService
{
    private readonly AppDbContext _context;
    private readonly IOtpService _otpService;
    private readonly IFaceService _faceService;
    private readonly IConfiguration _configuration;
    private readonly IWebHostEnvironment _environment;
    private readonly PasswordHasher<User> _passwordHasher;
    private readonly ILogger<AuthService> _logger;

    public AuthService(
        AppDbContext context,
        IOtpService otpService,
        IFaceService faceService,
        IConfiguration configuration,
        IWebHostEnvironment environment,
        ILogger<AuthService> logger)
    {
        _context = context;
        _otpService = otpService;
        _faceService = faceService;
        _configuration = configuration;
        _environment = environment;
        _passwordHasher = new PasswordHasher<User>();
        _logger = logger;
    }

    public async Task<User> RegisterStudentAsync(RegisterRequest request)
    {
        var cleanUsername = request.Username.Trim().ToLowerInvariant();
        var cleanEmail = request.Email.Trim().ToLowerInvariant();

        if (await _context.Users.AnyAsync(u => u.Username.ToLower() == cleanUsername))
        {
            throw new InvalidOperationException("Tên đăng nhập này đã được sử dụng");
        }

        if (await _context.Users.AnyAsync(u => u.Email.ToLower() == cleanEmail))
        {
            throw new InvalidOperationException("Địa chỉ email này đã được sử dụng");
        }

        var user = new User
        {
            Id = Guid.NewGuid(),
            Username = cleanUsername,
            Email = cleanEmail,
            FullName = request.FullName.Trim(),
            StudentCode = request.StudentCode?.Trim(),
            Role = UserRole.Student, // Luôn mặc định là Student
            CreatedAtUtc = DateTime.UtcNow,
            IsActive = true
        };

        user.PasswordHash = _passwordHasher.HashPassword(user, request.Password);

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        return user;
    }

    public async Task<PreAuthResponse> LoginAsync(LoginRequest request)
    {
        var cleanUsername = request.Username.Trim().ToLowerInvariant();
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Username.ToLower() == cleanUsername);

        if (user == null || !user.IsActive)
        {
            throw new UnauthorizedAccessException("Tên đăng nhập hoặc mật khẩu không chính xác");
        }

        var verifyResult = _passwordHasher.VerifyHashedPassword(user, user.PasswordHash, request.Password);
        if (verifyResult == PasswordVerificationResult.Failed)
        {
            throw new UnauthorizedAccessException("Tên đăng nhập hoặc mật khẩu không chính xác");
        }

        // Tạo challenge OTP
        var (challenge, rawCode) = await _otpService.CreateChallengeAsync(user.Id, "Đăng nhập mật khẩu");

        string? devOtp = _environment.IsDevelopment() ? rawCode : null;

        return new PreAuthResponse(
            challenge.Ticket,
            $"Mã OTP đã được gửi tới email {MaskEmail(user.Email)}. Vui lòng kiểm tra hộp thư",
            OtpService.CodeLifetimeMinutes * 60,
            devOtp
        );
    }

    public async Task<PreAuthResponse> FaceLoginAsync(FaceLoginRequest request)
    {
        var cleanUsername = request.Username.Trim().ToLowerInvariant();
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Username.ToLower() == cleanUsername);

        if (user == null || !user.IsActive)
        {
            throw new UnauthorizedAccessException("Tài khoản không tồn tại");
        }

        if (user.FaceEmbedding == null || user.FaceEmbedding.Length == 0)
        {
            throw new InvalidOperationException("Tài khoản này chưa đăng ký dữ liệu khuôn mặt. Vui lòng đăng nhập bằng mật khẩu");
        }

        // Đối chiếu 1:1 với mẫu khuôn mặt đã lưu
        var matchResult = _faceService.CompareFaces(user.FaceEmbedding, request.ImageBase64);
        if (!matchResult.Success)
        {
            throw new UnauthorizedAccessException(matchResult.Message);
        }

        // Đối chiếu thành công -> Cấp challenge OTP theo luồng 2 lớp bắt buộc
        var (challenge, rawCode) = await _otpService.CreateChallengeAsync(user.Id, "Đăng nhập khuôn mặt");

        string? devOtp = _environment.IsDevelopment() ? rawCode : null;

        return new PreAuthResponse(
            challenge.Ticket,
            $"Nhận diện khuôn mặt thành công! Mã OTP đã được gửi tới email {MaskEmail(user.Email)} để xác thực bước 2",
            OtpService.CodeLifetimeMinutes * 60,
            devOtp
        );
    }

    public async Task<AuthResponse> VerifyOtpAndGenerateTokenAsync(VerifyOtpRequest request)
    {
        var (success, message, user) = await _otpService.VerifyOtpAsync(request.Ticket, request.Code);
        if (!success || user == null)
        {
            throw new UnauthorizedAccessException(message);
        }

        var token = GenerateJwtToken(user);

        var userDto = new UserDto(
            user.Id,
            user.Username,
            user.Email,
            user.FullName,
            user.StudentCode,
            user.Role,
            user.FaceEmbedding != null && user.FaceEmbedding.Length > 0
        );

        return new AuthResponse(token, userDto);
    }

    public async Task<PreAuthResponse> ResendOtpAsync(ResendOtpRequest request)
    {
        var (success, message, newTicket, rawCode) = await _otpService.ResendOtpAsync(request.Ticket);
        if (!success || string.IsNullOrWhiteSpace(newTicket))
        {
            throw new InvalidOperationException(message);
        }

        string? devOtp = _environment.IsDevelopment() ? rawCode : null;

        return new PreAuthResponse(
            newTicket,
            message,
            OtpService.CodeLifetimeMinutes * 60,
            devOtp
        );
    }

    public async Task<bool> RegisterFaceAsync(Guid userId, RegisterFaceRequest request)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null) throw new InvalidOperationException("Người dùng không tồn tại");

        var extractResult = _faceService.ExtractEmbeddingFromBase64(request.ImageBase64);
        if (!extractResult.Success || extractResult.Embedding == null)
        {
            throw new InvalidOperationException(extractResult.Message);
        }

        user.FaceEmbedding = extractResult.Embedding;
        user.FaceRegisteredAtUtc = DateTime.UtcNow;

        await _context.SaveChangesAsync();
        _logger.LogInformation("Người dùng {Username} ({Id}) đã cập nhật mẫu khuôn mặt thành công", user.Username, user.Id);
        return true;
    }

    public string GenerateJwtToken(User user)
    {
        var secret = _configuration["Jwt:Secret"] ?? "DefaultFallbackSecretKeyphamlehuyhoang1234567890123456";
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Name, user.Username),
            new(ClaimTypes.Email, user.Email),
            new(ClaimTypes.Role, user.Role),
            new("FullName", user.FullName)
        };

        if (!string.IsNullOrWhiteSpace(user.StudentCode))
        {
            claims.Add(new Claim("StudentCode", user.StudentCode));
        }

        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"] ?? "phamlehuyhoang",
            audience: _configuration["Jwt:Audience"] ?? "phamlehuyhoang",
            claims: claims,
            expires: DateTime.UtcNow.AddHours(24),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private static string MaskEmail(string email)
    {
        var parts = email.Split('@');
        if (parts.Length != 2) return email;
        var name = parts[0];
        if (name.Length <= 2) return $"{name}***@{parts[1]}";
        return $"{name[0]}***{name[^1]}@{parts[1]}";
    }
}
