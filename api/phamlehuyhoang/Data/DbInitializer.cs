using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using phamlehuyhoang.Entities;
using phamlehuyhoang.Enums;

namespace phamlehuyhoang.Data;

public static class DbInitializer
{
    public static async Task InitializeAsync(AppDbContext context, IConfiguration configuration)
    {
        await context.Database.MigrateAsync();
        await EnsureConfiguredAdminAsync(context, configuration);
    }

    public static async Task EnsureConfiguredAdminAsync(AppDbContext context, IConfiguration configuration)
    {
        // Tùy chọn tạo quản trị viên thật từ cấu hình riêng; không có tài khoản/mật khẩu mẫu.
        var username = configuration["BootstrapAdmin:Username"]?.Trim().ToLowerInvariant();
        var email = configuration["BootstrapAdmin:Email"]?.Trim().ToLowerInvariant();
        var password = configuration["BootstrapAdmin:Password"];
        if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(email) ||
            string.IsNullOrWhiteSpace(password)) return;
        if (!new EmailAddressAttribute().IsValid(email) || password.Length < 8)
            throw new InvalidOperationException("Cấu hình BootstrapAdmin phải có email hợp lệ và mật khẩu tối thiểu 8 ký tự.");
        var existing = await context.Users.FirstOrDefaultAsync(u => u.Username == username || u.Email == email);
        if (existing != null)
        {
            if (existing.Username == username && existing.Email == email && existing.Role == UserRole.Admin && existing.IsActive)
                return;
            throw new InvalidOperationException("BootstrapAdmin trùng tài khoản hiện có. Hãy chọn username/email mới; không ghi đè tài khoản cũ.");
        }
        var user = new User
        {
            Username = username, Email = email, FullName = "Quản trị viên",
            Role = UserRole.Admin, EmailConfirmed = false
        };
        user.PasswordHash = new PasswordHasher<User>().HashPassword(user, password);
        context.Users.Add(user);
        await context.SaveChangesAsync();
    }
}
