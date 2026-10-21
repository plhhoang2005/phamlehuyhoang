using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using phamlehuyhoang.Data;
using phamlehuyhoang.Enums;

namespace phamlehuyhoang.Services;

internal static class ResourceAuthorization
{
    public static async Task<bool> CanManageClassAsync(AppDbContext context, Guid userId, Guid classId)
    {
        var user = await context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == userId && u.IsActive);
        if (user == null) return false;
        if (user.Role == UserRole.Admin) return true;
        return user.Role == UserRole.Lecturer && await context.CourseClasses
            .AnyAsync(c => c.Id == classId && c.LecturerId == userId);
    }

    public static async Task<bool> CanReadClassAsync(AppDbContext context, ClaimsPrincipal principal, Guid classId)
    {
        if (!Guid.TryParse(principal.FindFirstValue(ClaimTypes.NameIdentifier), out var userId)) return false;
        if (await CanManageClassAsync(context, userId, classId)) return true;
        return await context.Users.AnyAsync(u => u.Id == userId && u.IsActive && u.Role == UserRole.Student)
            && await context.ClassEnrollments.AnyAsync(e => e.CourseClassId == classId && e.StudentId == userId);
    }

    public static Task<bool> CanManageClassAsync(AppDbContext context, ClaimsPrincipal principal, Guid classId) =>
        Guid.TryParse(principal.FindFirstValue(ClaimTypes.NameIdentifier), out var userId)
            ? CanManageClassAsync(context, userId, classId) : Task.FromResult(false);

    public static async Task DemandManageClassAsync(AppDbContext context, Guid userId, Guid classId)
    {
        if (!await CanManageClassAsync(context, userId, classId))
            throw new UnauthorizedAccessException("Bạn không được phân công giảng dạy lớp học phần này");
    }

    public static bool ValidLocation(double latitude, double longitude, double radius) =>
        double.IsFinite(latitude) && latitude >= -90 && latitude <= 90 &&
        double.IsFinite(longitude) && longitude >= -180 && longitude <= 180 &&
        double.IsFinite(radius) && radius > 0;
}
