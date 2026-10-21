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
                u.FaceEmbedding != null && u.FaceEmbedding.Length > 0,
                u.IsActive
            ))
            .ToListAsync();

        return Ok(users);
    }

    [HttpPost]
    public async Task<ActionResult<UserDto>> CreateUser([FromBody] CreateUserRequest request)
    {
        if (!SupportedRole(request.Role) || string.IsNullOrWhiteSpace(request.Username) || request.Username.Trim().Length > 50 ||
            !ValidProfile(request.Email, request.FullName, request.StudentCode) || string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 6)
            return BadRequest(new { message = "Vai trò hoặc thông tin người dùng không hợp lệ" });
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
            EmailConfirmed = false,
            IsActive = true
        };

        user.PasswordHash = _passwordHasher.HashPassword(user, request.Password);
        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        return Ok(new UserDto(user.Id, user.Username, user.Email, user.FullName, user.StudentCode, user.Role, false, user.IsActive));
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateUser(Guid id, [FromBody] UpdateUserRequest request)
    {
        await using var transaction = _context.Database.IsRelational()
            ? await _context.Database.BeginTransactionAsync(System.Data.IsolationLevel.Serializable) : null;
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound(new { message = "Người dùng không tồn tại" });

        if (!SupportedRole(request.Role) || !ValidProfile(request.Email, request.FullName, request.StudentCode))
            return BadRequest(new { message = "Vai trò hoặc thông tin người dùng không hợp lệ" });
        if (user.Role == UserRole.Admin && user.IsActive && (request.Role != UserRole.Admin || !request.IsActive) &&
            !await _context.Users.AnyAsync(u => u.Id != id && u.Role == UserRole.Admin && u.IsActive))
            return BadRequest(new { message = "Phải giữ ít nhất một quản trị viên đang hoạt động" });
        if (request.Role != user.Role &&
            ((user.Role == UserRole.Lecturer && await _context.CourseClasses.AnyAsync(c => c.LecturerId == id)) ||
             (user.Role == UserRole.Student && await _context.ClassEnrollments.AnyAsync(e => e.StudentId == id))))
            return BadRequest(new { message = "Không thể đổi vai trò khi người dùng còn được phân công hoặc ghi danh trong lớp" });

        var cleanEmail = request.Email.Trim().ToLowerInvariant();
        if (await _context.Users.AnyAsync(u => u.Id != id && u.Email.ToLower() == cleanEmail))
        {
            return BadRequest(new { message = "Email đã được người khác sử dụng" });
        }

        var emailChanged = !string.Equals(user.Email, cleanEmail, StringComparison.OrdinalIgnoreCase);
        var securityChanged = emailChanged || user.Role != request.Role || user.IsActive != request.IsActive;
        if (securityChanged)
        {
            user.AuthVersion++;
            var tickets = await _context.OtpChallenges.Where(c => c.UserId == id && !c.IsUsed).ToListAsync();
            foreach (var ticket in tickets) ticket.IsUsed = true;
        }
        if (emailChanged) user.EmailConfirmed = false;
        user.Email = cleanEmail;
        user.FullName = request.FullName.Trim();
        user.Role = request.Role;
        user.StudentCode = request.StudentCode?.Trim();
        user.IsActive = request.IsActive;

        await _context.SaveChangesAsync();
        if (transaction != null) await transaction.CommitAsync();
        return Ok(new { message = "Cập nhật thành công" });
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeactivateUser(Guid id)
    {
        await using var transaction = _context.Database.IsRelational()
            ? await _context.Database.BeginTransactionAsync(System.Data.IsolationLevel.Serializable) : null;
        var user = await _context.Users.FindAsync(id);
        if (user == null) return NotFound(new { message = "Người dùng không tồn tại" });

        if (user.Role == UserRole.Admin && user.IsActive &&
            !await _context.Users.AnyAsync(u => u.Id != id && u.Role == UserRole.Admin && u.IsActive))
            return BadRequest(new { message = "Không thể khóa quản trị viên hoạt động cuối cùng" });

        // Bảo toàn dữ liệu: không xóa cứng cascade để giữ lịch sử điểm danh
        user.IsActive = !user.IsActive;
        user.AuthVersion++;
        var tickets = await _context.OtpChallenges.Where(c => c.UserId == id && !c.IsUsed).ToListAsync();
        foreach (var ticket in tickets) ticket.IsUsed = true;
        await _context.SaveChangesAsync();
        if (transaction != null) await transaction.CommitAsync();

        return Ok(new { message = user.IsActive ? "Đã kích hoạt lại tài khoản" : "Đã tạm khóa tài khoản", isActive = user.IsActive });
    }

    private static bool SupportedRole(string role) => role is UserRole.Admin or UserRole.Lecturer or UserRole.Student;

    private static bool ValidProfile(string email, string fullName, string? studentCode) =>
        !string.IsNullOrWhiteSpace(email) && email.Trim().Length <= 100 &&
        new System.ComponentModel.DataAnnotations.EmailAddressAttribute().IsValid(email.Trim()) &&
        !string.IsNullOrWhiteSpace(fullName) && fullName.Trim().Length <= 100 && (studentCode == null || studentCode.Trim().Length <= 50);
}
