using System.ComponentModel.DataAnnotations;

namespace phamlehuyhoang.DTOs;

public record CreateUserRequest(
    [Required] [MaxLength(50)] string Username,
    [Required] [EmailAddress] string Email,
    [Required] [MaxLength(100)] string FullName,
    [Required] [MinLength(6)] string Password,
    [Required] string Role,
    string? StudentCode
);

public record UpdateUserRequest(
    [Required] [EmailAddress] string Email,
    [Required] [MaxLength(100)] string FullName,
    [Required] string Role,
    string? StudentCode,
    bool IsActive
);
