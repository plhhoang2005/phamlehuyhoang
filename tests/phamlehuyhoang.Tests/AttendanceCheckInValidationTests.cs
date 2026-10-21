using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using phamlehuyhoang.Data;
using phamlehuyhoang.DTOs;
using phamlehuyhoang.Entities;
using phamlehuyhoang.Enums;
using phamlehuyhoang.Services;
using Xunit;

namespace phamlehuyhoang.Tests;

public class AttendanceCheckInValidationTests
{
    private AppDbContext CreateInMemoryDbContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }

    [Fact]
    public async Task CheckIn_ValidQrAndLocation_Succeeds()
    {
        using var context = CreateInMemoryDbContext();
        var service = new AttendanceService(context, NullLogger<AttendanceService>.Instance);

        var student = new User { Id = Guid.NewGuid(), Username = "sv1", Role = UserRole.Student, FullName = "SV 1" };
        var courseClass = new CourseClass { Id = Guid.NewGuid(), Code = "CLASS1" };
        var enrollment = new ClassEnrollment { Id = Guid.NewGuid(), CourseClassId = courseClass.Id, StudentId = student.Id };
        var session = new ClassSession
        {
            Id = Guid.NewGuid(),
            CourseClassId = courseClass.Id,
            Latitude = 10.762622,
            Longitude = 106.682333,
            RadiusMeters = 100.0,
            StartTimeUtc = DateTime.UtcNow.AddMinutes(-5),
            IsFinalized = false
        };
        var qrSession = new AttendanceQrSession
        {
            Id = Guid.NewGuid(),
            ClassSessionId = session.Id,
            QrToken = "TOKEN123",
            IsOpen = true,
            ExpiresAtUtc = DateTime.UtcNow.AddSeconds(60)
        };

        context.Users.Add(student);
        context.CourseClasses.Add(courseClass);
        context.ClassEnrollments.Add(enrollment);
        context.ClassSessions.Add(session);
        context.AttendanceQrSessions.Add(qrSession);
        await context.SaveChangesAsync();

        // Sinh viên đứng cách phòng học ~10m (tọa độ rất gần)
        var request = new CheckInQrRequest("TOKEN123", session.Latitude + 0.00005, session.Longitude, 10.0, DateTime.UtcNow);

        var result = await service.ProcessQrCheckInAsync(student.Id, request);

        Assert.True(result.Success);
        Assert.NotNull(result.CheckedInAtUtc);
        Assert.InRange(result.DistanceMeters ?? 999, 0, 50);

        // Bấm lại lần 2 -> Không tạo duplicate, trả về kết quả đã điểm danh
        var resultRepeat = await service.ProcessQrCheckInAsync(student.Id, request);
        Assert.True(resultRepeat.Success);
        Assert.Contains("trước đó", resultRepeat.Message);

        var recordCount = await context.AttendanceRecords.CountAsync(r => r.ClassSessionId == session.Id && r.StudentId == student.Id);
        Assert.Equal(1, recordCount);
    }

    [Fact]
    public async Task CheckIn_OutOfRangeDistance_Fails()
    {
        using var context = CreateInMemoryDbContext();
        var service = new AttendanceService(context, NullLogger<AttendanceService>.Instance);

        var student = new User { Id = Guid.NewGuid(), Username = "sv2", Role = UserRole.Student };
        var courseClass = new CourseClass { Id = Guid.NewGuid(), Code = "CLASS2" };
        var enrollment = new ClassEnrollment { Id = Guid.NewGuid(), CourseClassId = courseClass.Id, StudentId = student.Id };
        var session = new ClassSession
        {
            Id = Guid.NewGuid(),
            CourseClassId = courseClass.Id,
            Latitude = 10.762622,
            Longitude = 106.682333,
            RadiusMeters = 50.0, // Bán kính 50m
            StartTimeUtc = DateTime.UtcNow,
            IsFinalized = false
        };
        var qrSession = new AttendanceQrSession
        {
            Id = Guid.NewGuid(),
            ClassSessionId = session.Id,
            QrToken = "TOKEN456",
            IsOpen = true,
            ExpiresAtUtc = DateTime.UtcNow.AddSeconds(60)
        };

        context.Users.Add(student);
        context.CourseClasses.Add(courseClass);
        context.ClassEnrollments.Add(enrollment);
        context.ClassSessions.Add(session);
        context.AttendanceQrSessions.Add(qrSession);
        await context.SaveChangesAsync();

        // Sinh viên đứng cách 1km
        var request = new CheckInQrRequest("TOKEN456", 10.772622, 106.682333, 10.0, DateTime.UtcNow);

        var result = await service.ProcessQrCheckInAsync(student.Id, request);

        Assert.False(result.Success);
        Assert.Contains("vượt quá bán kính cho phép", result.Message);
    }

    [Fact]
    public async Task CheckIn_ExpiredOrClosedQr_Fails()
    {
        using var context = CreateInMemoryDbContext();
        var service = new AttendanceService(context, NullLogger<AttendanceService>.Instance);

        var student = new User { Id = Guid.NewGuid(), Username = "sv3", Role = UserRole.Student };
        var courseClass = new CourseClass { Id = Guid.NewGuid(), Code = "CLASS3" };
        var enrollment = new ClassEnrollment { Id = Guid.NewGuid(), CourseClassId = courseClass.Id, StudentId = student.Id };
        var session = new ClassSession { Id = Guid.NewGuid(), CourseClassId = courseClass.Id, Latitude = 10.0, Longitude = 106.0, RadiusMeters = 100 };

        // QR đã hết hạn
        var expiredQr = new AttendanceQrSession
        {
            Id = Guid.NewGuid(),
            ClassSessionId = session.Id,
            QrToken = "EXPIRED",
            IsOpen = true,
            ExpiresAtUtc = DateTime.UtcNow.AddSeconds(-10)
        };

        // QR đã đóng bởi giảng viên
        var closedQr = new AttendanceQrSession
        {
            Id = Guid.NewGuid(),
            ClassSessionId = session.Id,
            QrToken = "CLOSED",
            IsOpen = false,
            ExpiresAtUtc = DateTime.UtcNow.AddMinutes(10)
        };

        context.Users.Add(student);
        context.CourseClasses.Add(courseClass);
        context.ClassEnrollments.Add(enrollment);
        context.ClassSessions.Add(session);
        context.AttendanceQrSessions.AddRange(expiredQr, closedQr);
        await context.SaveChangesAsync();

        var req1 = new CheckInQrRequest("EXPIRED", 10.0, 106.0, 10.0, DateTime.UtcNow);
        var res1 = await service.ProcessQrCheckInAsync(student.Id, req1);
        Assert.False(res1.Success);
        Assert.Contains("hết thời gian hiệu lực", res1.Message);

        var req2 = new CheckInQrRequest("CLOSED", 10.0, 106.0, 10.0, DateTime.UtcNow);
        var res2 = await service.ProcessQrCheckInAsync(student.Id, req2);
        Assert.False(res2.Success);
        Assert.Contains("đã được giảng viên đóng", res2.Message);
    }

    [Fact]
    public async Task CheckIn_PoorGpsAccuracy_Rejected()
    {
        using var context = CreateInMemoryDbContext();
        var service = new AttendanceService(context, NullLogger<AttendanceService>.Instance);

        // Sai số GPS 75m > 50m tối đa cho phép
        var req = new CheckInQrRequest("ANY_TOKEN", 10.0, 106.0, 75.0, DateTime.UtcNow);
        var res = await service.ProcessQrCheckInAsync(Guid.NewGuid(), req);

        Assert.False(res.Success);
        Assert.Contains("Độ chính xác GPS", res.Message);
    }
}
