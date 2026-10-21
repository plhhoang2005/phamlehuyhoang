using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using phamlehuyhoang.Data;
using phamlehuyhoang.DTOs;
using phamlehuyhoang.Entities;
using phamlehuyhoang.Enums;

namespace phamlehuyhoang.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = UserRole.Admin)]
public class UsersController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly PasswordHasher<User> _passwordHasher = new();

    public UsersController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<List<UserDto>>> GetUsers([FromQuery] string? role)
    {
        var query = _context.Users.AsQueryable();
        if (!string.IsNullOrWhiteSpace(role))
        {
            query = query.Where(u => u.Role == role);
        }

        var users = await query
            .OrderBy(u => u.Role)
            .ThenBy(u => u.FullName)
            .Select(u => new UserDto(
                u.Id,
                u.Username,
                u.Email,
                u.FullName,
                u.StudentCode,
                u.Role,
                u.FaceEmbedding != null && u.FaceEmbedding.Length > 0
            ))
            .ToListAsync();

        return Ok(users);
    }

    [HttpPost]
    public async Task<ActionResult<UserDto>> CreateUser([FromBody] CreateUserRequest request)
    {
        var cleanUsername = request.Username.Trim().ToLowerInvariant();
        var cleanEmail = request.Email.Trim().ToLowerInvariant();

        if (await _context.Users.AnyAsync(u => u.Username.ToLower() == cleanUsername))
        {
            return BadRequest(new { message = "Tên đăng nhập đã tồn tại" });
        }

        if (await _context.Users.AnyAsync(u => u.Email.ToLower() == cleanEmail))
        {
            return BadRequest(new { message = "Email đã tồn tại" });
        }

        var user = new User
        {
            Id = Guid.NewGuid(),
            Username = cleanUsername,
            Email = cleanEmail,
            FullName = request.FullName.Trim(),
            StudentCode = request.StudentCode?.Trim(),
            Role = request.Role,
            CreatedAtUtc = DateTime.UtcNow,
            IsActive = true
        };

        user.PasswordHash = _passwordHasher.HashPassword(user, request.Password);
        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        return Ok(new UserDto(user.Id, user.Username, user.Email, user.FullName, user.StudentCode, user.Role, false));
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateUser(Guid id, [FromBody] UpdateUserRequest request)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound(new { message = "Người dùng không tồn tại" });

        var cleanEmail = request.Email.Trim().ToLowerInvariant();
        if (await _context.Users.AnyAsync(u => u.Id != id && u.Email.ToLower() == cleanEmail))
        {
            return BadRequest(new { message = "Email đã được người khác sử dụng" });
        }

        user.Email = cleanEmail;
        user.FullName = request.FullName.Trim();
        user.Role = request.Role;
        user.StudentCode = request.StudentCode?.Trim();
        user.IsActive = request.IsActive;

        await _context.SaveChangesAsync();
        return Ok(new { message = "Cập nhật thành công" });
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeactivateUser(Guid id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound(new { message = "Người dùng không tồn tại" });

        // Bảo toàn dữ liệu: không xóa cứng cascade để giữ lịch sử điểm danh
        user.IsActive = !user.IsActive;
        await _context.SaveChangesAsync();

        return Ok(new { message = user.IsActive ? "Đã kích hoạt lại tài khoản" : "Đã tạm khóa tài khoản", isActive = user.IsActive });
    }
}
