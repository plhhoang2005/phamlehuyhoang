using phamlehuyhoang.DTOs;
using phamlehuyhoang.Entities;

namespace phamlehuyhoang.Services;

public interface IAuthService
{
    Task<PreAuthResponse> RegisterStudentAsync(RegisterRequest request);
    Task VerifyEmailAsync(VerifyOtpRequest request);
    Task<PreAuthResponse> LoginAsync(LoginRequest request);
    Task<PreAuthResponse> FaceLoginAsync(FaceLoginRequest request);
    Task<AuthResponse> VerifyOtpAndGenerateTokenAsync(VerifyOtpRequest request);
    Task<PreAuthResponse> ResendOtpAsync(ResendOtpRequest request);
    Task<bool> RegisterFaceAsync(Guid userId, RegisterFaceRequest request);
    string GenerateJwtToken(User user);
}
