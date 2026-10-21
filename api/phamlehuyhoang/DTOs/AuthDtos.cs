using System.ComponentModel.DataAnnotations;

namespace phamlehuyhoang.DTOs;

public record RegisterRequest(
    [Required] [MaxLength(50)] string Username,
    [Required] [EmailAddress] string Email,
    [Required] [MaxLength(100)] string FullName,
    [Required] [MinLength(6)] string Password,
    string? StudentCode
);

public record LoginRequest(
    [Required] string Username,
    [Required] string Password
);

public record PreAuthResponse(
    string Ticket,
    string Message,
    int ExpiresInSeconds,
    string Purpose = "Login"
);

public record VerifyOtpRequest(
    [Required] string Ticket,
    [Required] [RegularExpression(@"^\d{6}$")] string Code
);

public record ResendOtpRequest(
    [Required] string Ticket
);

public record FaceLoginRequest(
    [Required] string Username,
    [Required] string ImageBase64
);

public record RegisterFaceRequest(
    [Required] string ImageBase64
);

public record AuthResponse(
    string Token,
    UserDto User
);

public record UserDto(
    Guid Id,
    string Username,
    string Email,
    string FullName,
    string? StudentCode,
    string Role,
    bool HasFaceRegistered,
    bool IsActive = true
);
