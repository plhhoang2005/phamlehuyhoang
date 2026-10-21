using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using phamlehuyhoang.Controllers;
using phamlehuyhoang.Data;
using phamlehuyhoang.DTOs;
using phamlehuyhoang.Entities;
using phamlehuyhoang.Enums;
using phamlehuyhoang.Services;

namespace phamlehuyhoang.Tests;

public class MajorWorkflowTests
{
    private sealed class TestDb : AppDbContext
    {
        public bool FailAttendanceSave { get; set; }
        public TestDb() : base(new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options) { }
        public override Task<int> SaveChangesAsync(CancellationToken token = default)
        {
            if (FailAttendanceSave && ChangeTracker.Entries<AttendanceRecord>().Any(e => e.State == EntityState.Added))
                throw new DbUpdateException("Simulated storage outage");
            return base.SaveChangesAsync(token);
        }
    }

    private static T As<T>(T controller, User user) where T : ControllerBase
    {
        controller.ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext() };
        controller.HttpContext.User = new ClaimsPrincipal(new ClaimsIdentity(new[] {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()), new Claim(ClaimTypes.Role, user.Role)
        }, "test"));
        return controller;
    }

    private static AttendanceService Service(AppDbContext db) => new(db, NullLogger<AttendanceService>.Instance);
    private static async Task<(User owner, User outsider, User student, CourseClass course, ClassSession session)> Seed(TestDb db)
    {
        var owner = new User { Username = "owner", Role = UserRole.Lecturer };
        var outsider = new User { Username = "other", Role = UserRole.Lecturer };
        var student = new User { Username = "student", Role = UserRole.Student };
        var subject = new Subject { Code = "CS", Name = "Computing" };
        var course = new CourseClass { Code = "CS01", LecturerId = owner.Id, SubjectId = subject.Id };
        var session = new ClassSession { CourseClassId = course.Id, Title = "Lesson", SessionNumber = 1,
            StartTimeUtc = DateTime.UtcNow.AddMinutes(-2), EndTimeUtc = DateTime.UtcNow.AddHours(1), Latitude = 10, Longitude = 106 };
        db.AddRange(owner, outsider, student, subject, course, session,
            new ClassEnrollment { CourseClassId = course.Id, StudentId = student.Id },
            new AttendanceQrSession { ClassSessionId = session.Id, QrToken = "VALID", ExpiresAtUtc = DateTime.UtcNow.AddMinutes(1) });
        await db.SaveChangesAsync();
        return (owner, outsider, student, course, session);
    }

    [Theory]
    [InlineData("close")]
    [InlineData("finalize")]
    [InlineData("open")]
    [InlineData("adjust")]
    public async Task UnassignedLecturer_CannotMutateAttendance(string operation)
    {
        using var db = new TestDb(); var f = await Seed(db); var service = Service(db);
        var record = new AttendanceRecord { ClassSessionId = f.session.Id, StudentId = f.student.Id };
        db.Add(record); await db.SaveChangesAsync();
        await Assert.ThrowsAsync<UnauthorizedAccessException>(async () => {
            if (operation == "close") await service.CloseQrSessionAsync(f.session.Id, f.outsider.Id);
            if (operation == "finalize") await service.FinalizeSessionAsync(f.session.Id, f.outsider.Id);
            if (operation == "open") await service.OpenOrRefreshQrSessionAsync(f.session.Id, f.outsider.Id);
            if (operation == "adjust") await service.AdjustAttendanceAsync(record.Id, AttendanceStatus.Absent, "Reason", f.outsider.Id);
        });
        Assert.False(f.session.IsFinalized);
        Assert.True((await db.AttendanceQrSessions.SingleAsync()).IsOpen);
    }

    [Fact]
    public async Task Admin_CanManageAnotherLecturersSession()
    {
        using var db = new TestDb(); var f = await Seed(db);
        var admin = new User { Role = UserRole.Admin }; db.Add(admin); await db.SaveChangesAsync();
        Assert.True(await Service(db).CloseQrSessionAsync(f.session.Id, admin.Id));
        Assert.False((await db.AttendanceQrSessions.SingleAsync()).IsOpen);
    }

    [Fact]
    public async Task CheckIn_SaveFailureNeverReturnsSuccessOrLeavesAddedRecord()
    {
        using var db = new TestDb(); var f = await Seed(db); db.FailAttendanceSave = true;
        var result = await Service(db).ProcessQrCheckInAsync(f.student.Id, new("VALID", 10, 106, 5, DateTime.UtcNow));
        Assert.False(result.Success);
        Assert.Empty(await db.AttendanceRecords.ToListAsync());
        Assert.DoesNotContain(db.ChangeTracker.Entries<AttendanceRecord>(), e => e.State == EntityState.Added);
    }

    [Fact]
    public async Task CheckIn_ValidQrPersistsExactlyOneRecord()
    {
        using var db = new TestDb(); var f = await Seed(db); var service = Service(db);
        Assert.True((await service.ProcessQrCheckInAsync(f.student.Id, new("VALID", 10, 106, 5, DateTime.UtcNow))).Success);
        Assert.True((await service.ProcessQrCheckInAsync(f.student.Id, new("VALID", 10, 106, 5, DateTime.UtcNow))).Success);
        Assert.Single(await db.AttendanceRecords.ToListAsync());
    }

    [Fact]
    public async Task CancelledSession_CannotOpenOrCheckIn()
    {
        using var db = new TestDb(); var f = await Seed(db); f.session.IsCancelled = true; await db.SaveChangesAsync();
        await Assert.ThrowsAsync<InvalidOperationException>(() => Service(db).OpenOrRefreshQrSessionAsync(f.session.Id, f.owner.Id));
        Assert.False((await Service(db).ProcessQrCheckInAsync(f.student.Id, new("VALID", 10, 106, 5, DateTime.UtcNow))).Success);
    }

    [Fact]
    public async Task Student_CannotFetchActiveQrToken()
    {
        using var db = new TestDb(); var f = await Seed(db);
        var controller = As(new AttendanceController(Service(db), db), f.student);
        Assert.IsType<ForbidResult>((await controller.GetActiveQrSession(f.session.Id)).Result);
    }

    [Fact]
    public async Task UnassignedLecturer_CannotReadClassOrSessionsOrAttendance()
    {
        using var db = new TestDb(); var f = await Seed(db);
        Assert.IsType<ForbidResult>((await As(new CourseClassesController(db), f.outsider).GetClassById(f.course.Id)).Result);
        Assert.IsType<ForbidResult>((await As(new ClassSessionsController(db, Service(db)), f.outsider).GetSessionById(f.session.Id)).Result);
        Assert.IsType<ForbidResult>((await As(new AttendanceController(Service(db), db), f.outsider).GetSessionAttendance(f.session.Id)).Result);
    }

    [Fact]
    public async Task UnassignedLecturer_CannotCreateOrUpdateSession()
    {
        using var db = new TestDb(); var f = await Seed(db); var c = As(new ClassSessionsController(db, Service(db)), f.outsider);
        Assert.IsType<ForbidResult>((await c.CreateSession(new(f.course.Id, 2, "Lesson 2", DateTime.UtcNow, DateTime.UtcNow.AddHours(1), "A1", 10, 106, 100))).Result);
        Assert.IsType<ForbidResult>(await c.UpdateSession(f.session.Id, new("changed", DateTime.UtcNow, DateTime.UtcNow.AddHours(1), "A1", 10, 106, 100, false)));
        Assert.Equal("Lesson", f.session.Title);
    }

    [Fact]
    public async Task InvalidClassNumbersAndLecturer_AreRejected()
    {
        using var db = new TestDb(); var f = await Seed(db); var c = new CourseClassesController(db);
        Assert.IsType<BadRequestObjectResult>(await c.UpdateClass(f.course.Id, new(f.student.Id, 0, -1, 91, 106, -1)));
        Assert.Equal(15, f.course.TotalSessions);
    }

    [Fact]
    public async Task InvalidSessionDatesAndDuplicateNumber_AreRejected()
    {
        using var db = new TestDb(); var f = await Seed(db); var c = As(new ClassSessionsController(db, Service(db)), f.owner);
        Assert.IsType<BadRequestObjectResult>((await c.CreateSession(new(f.course.Id, 2, "Bad", DateTime.UtcNow, DateTime.UtcNow.AddHours(-1), "A", 10, 106, 100))).Result);
        Assert.IsType<BadRequestObjectResult>((await c.CreateSession(new(f.course.Id, 1, "Duplicate", DateTime.UtcNow, DateTime.UtcNow.AddHours(1), "A", 10, 106, 100))).Result);
    }

    [Fact]
    public async Task SubjectUpdate_ChangesSubjectAndRejectsDuplicateCode()
    {
        using var db = new TestDb(); var f = await Seed(db); var controller = new SubjectsController(db);
        var method = typeof(SubjectsController).GetMethod("UpdateSubject"); Assert.NotNull(method);
        var result = await (Task<IActionResult>)method.Invoke(controller, new object[] { f.course.SubjectId, new CreateSubjectRequest(" NEW ", "New name", 4) })!;
        Assert.IsType<OkObjectResult>(result);
        Assert.Equal("NEW", (await db.Subjects.FindAsync(f.course.SubjectId))!.Code);
    }

    [Fact]
    public async Task ClassDelete_PreservesAttendanceHistoryButDeletesEmptyClass()
    {
        using var db = new TestDb(); var f = await Seed(db); var controller = new CourseClassesController(db);
        var method = typeof(CourseClassesController).GetMethod("DeleteClass"); Assert.NotNull(method);
        db.Add(new AttendanceRecord { ClassSessionId = f.session.Id, StudentId = f.student.Id }); await db.SaveChangesAsync();
        Assert.IsType<ConflictObjectResult>(await (Task<IActionResult>)method.Invoke(controller, new object[] { f.course.Id })!);
        var empty = new CourseClass { Code = "EMPTY", SubjectId = f.course.SubjectId }; db.Add(empty); await db.SaveChangesAsync();
        Assert.IsType<OkObjectResult>(await (Task<IActionResult>)method.Invoke(controller, new object[] { empty.Id })!);
        Assert.Null(await db.CourseClasses.FindAsync(empty.Id));
        Assert.NotNull(await db.CourseClasses.FindAsync(f.course.Id));
    }

    [Fact]
    public async Task EmailChange_RequiresVerificationAndRevokesTickets()
    {
        using var db = new TestDb(); var f = await Seed(db); f.student.EmailConfirmed = true;
        var otp = new OtpChallenge { UserId = f.student.Id, Ticket = "pending", ExpiresAtUtc = DateTime.UtcNow.AddMinutes(5) }; db.Add(otp); await db.SaveChangesAsync();
        Assert.IsType<OkObjectResult>(await new UsersController(db).UpdateUser(f.student.Id, new("new@example.com", "Student", UserRole.Student, "S1", true)));
        Assert.False(f.student.EmailConfirmed); Assert.True(otp.IsUsed);
    }

    [Fact]
    public async Task UnsupportedRoleAndLastAdminDeactivation_AreRejected()
    {
        using var db = new TestDb(); var f = await Seed(db); var controller = new UsersController(db);
        Assert.IsType<BadRequestObjectResult>((await controller.CreateUser(new("bad", "bad@example.com", "Bad", "password", "SuperUser", null))).Result);
        var admin = new User { Role = UserRole.Admin }; db.Add(admin); await db.SaveChangesAsync();
        Assert.IsType<BadRequestObjectResult>(await controller.DeactivateUser(admin.Id));
        Assert.True(admin.IsActive);
    }

    [Fact]
    public async Task ClassEdit_UpdatesCodeAndSubject()
    {
        using var db = new TestDb(); var f = await Seed(db);
        var subject = new Subject { Code = "NEXT", Name = "Next subject" }; db.Add(subject); await db.SaveChangesAsync();
        var json = $$"""{"lecturerId":"{{f.owner.Id}}","totalSessions":15,"maxAbsencesAllowed":3,"defaultLatitude":10,"defaultLongitude":106,"defaultRadiusMeters":100,"code":" EDITED ","subjectId":"{{subject.Id}}"}""";
        var request = System.Text.Json.JsonSerializer.Deserialize<UpdateCourseClassRequest>(json, new System.Text.Json.JsonSerializerOptions(System.Text.Json.JsonSerializerDefaults.Web))!;
        Assert.IsType<OkObjectResult>(await new CourseClassesController(db).UpdateClass(f.course.Id, request));
        Assert.Equal("EDITED", f.course.Code); Assert.Equal(subject.Id, f.course.SubjectId);
    }

    [Fact]
    public async Task SessionEdit_ChangesNumberAndRejectsDuplicates()
    {
        using var db = new TestDb(); var f = await Seed(db);
        var json = $$"""{"title":"Edited","startTimeUtc":"{{DateTime.UtcNow:O}}","endTimeUtc":"{{DateTime.UtcNow.AddHours(1):O}}","roomName":"A","latitude":10,"longitude":106,"radiusMeters":100,"isCancelled":false,"sessionNumber":2}""";
        var request = System.Text.Json.JsonSerializer.Deserialize<UpdateClassSessionRequest>(json, new System.Text.Json.JsonSerializerOptions(System.Text.Json.JsonSerializerDefaults.Web))!;
        var controller = As(new ClassSessionsController(db, Service(db)), f.owner);
        Assert.IsType<OkObjectResult>(await controller.UpdateSession(f.session.Id, request));
        Assert.Equal(2, f.session.SessionNumber);
        var other = new ClassSession { CourseClassId = f.course.Id, SessionNumber = 1 }; db.Add(other); await db.SaveChangesAsync();
        Assert.IsType<BadRequestObjectResult>(await controller.UpdateSession(other.Id, request));
        Assert.Equal(1, other.SessionNumber);
    }

    [Theory]
    [InlineData("missing")]
    [InlineData("stale")]
    [InlineData("future")]
    [InlineData("nan-accuracy")]
    [InlineData("infinite-accuracy")]
    [InlineData("negative-accuracy")]
    [InlineData("nan-latitude")]
    [InlineData("infinite-longitude")]
    [InlineData("finalized")]
    public async Task CheckIn_InvalidLocationEvidenceOrFinalizedSession_IsRejected(string invalid)
    {
        using var db = new TestDb(); var f = await Seed(db);
        DateTime? timestamp = invalid switch { "missing" => null, "stale" => DateTime.UtcNow.AddMinutes(-2), "future" => DateTime.UtcNow.AddMinutes(2), _ => DateTime.UtcNow };
        var accuracy = invalid switch { "nan-accuracy" => double.NaN, "infinite-accuracy" => double.PositiveInfinity, "negative-accuracy" => -1, _ => 5 };
        if (invalid == "finalized") { f.session.IsFinalized = true; await db.SaveChangesAsync(); }
        var result = await Service(db).ProcessQrCheckInAsync(f.student.Id, new("VALID", invalid == "nan-latitude" ? double.NaN : 10,
            invalid == "infinite-longitude" ? double.PositiveInfinity : 106, accuracy, timestamp));
        Assert.False(result.Success);
        Assert.Empty(await db.AttendanceRecords.ToListAsync());
    }

    [Fact]
    public async Task EnrolledStudent_CanReadOwnClassButOnlyOwnEnrollment()
    {
        using var db = new TestDb(); var f = await Seed(db);
        var other = new User { Role = UserRole.Student, Username = "otherStudent" }; db.Add(other);
        db.Add(new ClassEnrollment { CourseClassId = f.course.Id, StudentId = other.Id }); await db.SaveChangesAsync();
        var controller = As(new CourseClassesController(db), f.student);
        Assert.IsType<OkObjectResult>((await controller.GetClassById(f.course.Id)).Result);
        var result = Assert.IsType<OkObjectResult>((await controller.GetEnrolledStudents(f.course.Id)).Result);
        var enrollments = Assert.IsType<List<EnrollmentDto>>(result.Value);
        Assert.Equal(f.student.Id, Assert.Single(enrollments).StudentId);
        var stranger = new User { Role = UserRole.Student, Username = "stranger" }; db.Add(stranger); await db.SaveChangesAsync();
        Assert.IsType<ForbidResult>((await As(new CourseClassesController(db), stranger).GetClassById(f.course.Id)).Result);
        Assert.IsType<ForbidResult>((await As(new ClassSessionsController(db, Service(db)), stranger).GetSessionsForClass(f.course.Id)).Result);
    }

    [Fact]
    public async Task LastActiveAdmin_CannotBeDemotedThroughUpdate()
    {
        using var db = new TestDb();
        var admin = new User { Role = UserRole.Admin, Email = "admin@example.com" }; db.Add(admin); await db.SaveChangesAsync();
        Assert.IsType<BadRequestObjectResult>(await new UsersController(db).UpdateUser(admin.Id, new("admin@example.com", "Admin", UserRole.Student, null, true)));
        Assert.Equal(UserRole.Admin, admin.Role);
    }
}
