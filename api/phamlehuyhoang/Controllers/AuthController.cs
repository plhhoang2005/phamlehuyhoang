using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using phamlehuyhoang.Data;
using phamlehuyhoang.DTOs;
using phamlehuyhoang.Services;

namespace phamlehuyhoang.Controllers;

[ApiController]
[Route("api/[controller]")]
[TypeFilter(typeof(AuthExceptionFilter))]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly AppDbContext _context;
    public AuthController(IAuthService authService, AppDbContext context)
    {
        _authService = authService;
        _context = context;
    }

    [HttpPost("register")]
    public async Task<ActionResult<PreAuthResponse>> Register([FromBody] RegisterRequest request) =>
        Ok(await _authService.RegisterStudentAsync(request));

    [HttpPost("verify-email")]
    public async Task<IActionResult> VerifyEmail([FromBody] VerifyOtpRequest request)
    {
        await _authService.VerifyEmailAsync(request);
        return Ok(new { message = "Tài khoản đã được kích hoạt. Vui lòng đăng nhập để tiếp tục." });
    }

    [HttpPost("login")]
    public async Task<ActionResult<PreAuthResponse>> Login([FromBody] LoginRequest request) =>
        Ok(await _authService.LoginAsync(request));

    [HttpPost("face-login")]
    public async Task<ActionResult<PreAuthResponse>> FaceLogin([FromBody] FaceLoginRequest request) =>
        Ok(await _authService.FaceLoginAsync(request));

    [HttpPost("verify-otp")]
    public async Task<ActionResult<AuthResponse>> VerifyOtp([FromBody] VerifyOtpRequest request) =>
        Ok(await _authService.VerifyOtpAndGenerateTokenAsync(request));

    [HttpPost("resend-otp")]
    public async Task<ActionResult<PreAuthResponse>> ResendOtp([FromBody] ResendOtpRequest request) =>
        Ok(await _authService.ResendOtpAsync(request));

    [Authorize]
    [HttpPost("register-face")]
    public async Task<IActionResult> RegisterFace([FromBody] RegisterFaceRequest request)
    {
        if (!Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id)) return Unauthorized();
        await _authService.RegisterFaceAsync(id, request);
        return Ok(new { message = "Đăng ký khuôn mặt thành công." });
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<ActionResult<UserDto>> GetCurrentUser()
    {
        if (!Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var id)) return Unauthorized();
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound(new { message = "Người dùng không tồn tại." });
        return Ok(new UserDto(user.Id, user.Username, user.Email, user.FullName,
            user.StudentCode, user.Role, user.FaceEmbedding is { Length: > 0 }));
    }
}
