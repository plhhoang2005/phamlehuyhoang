using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using phamlehuyhoang.Data;
using phamlehuyhoang.Entities;
using phamlehuyhoang.Enums;
using phamlehuyhoang.Services;

namespace phamlehuyhoang.Tests;

public class AttendanceConcurrencyTests
{
    private sealed class ConcurrentFinalizeContext : AppDbContext
    {
        private readonly DbContextOptions<AppDbContext> _options;
        public ConcurrentFinalizeContext(DbContextOptions<AppDbContext> options) : base(options) { _options = options; }
        public bool FinalizeOnCheckIn { get; set; }
        public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            var pending = ChangeTracker.Entries<AttendanceRecord>()
                .FirstOrDefault(e => e.State == EntityState.Added && e.Entity.CheckInMethod == "QrLocation");
            if (FinalizeOnCheckIn && pending != null)
            {
                await using var concurrent = new AppDbContext(_options);
                var session = await concurrent.ClassSessions.FindAsync(pending.Entity.ClassSessionId);
                session!.IsFinalized = true;
                concurrent.Add(new AttendanceRecord { ClassSessionId = pending.Entity.ClassSessionId,
                    StudentId = pending.Entity.StudentId, Status = AttendanceStatus.Absent, CheckInMethod = "AutoFinalize" });
                await concurrent.SaveChangesAsync(cancellationToken);
                throw new DbUpdateException("Concurrent finalization inserted absent record before check-in");
            }
            return await base.SaveChangesAsync(cancellationToken);
        }
    }
    [Fact]
    public async Task ConcurrentFinalization_CannotReportAbsentRecordAsSuccessfulCheckIn()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>().UseInMemoryDatabase(Guid.NewGuid().ToString()).Options;
        await using var db = new ConcurrentFinalizeContext(options);
        var student = new User { Username = "student" };
        var subject = new Subject { Code = "SUB" };
        var course = new CourseClass { SubjectId = subject.Id, Code = "CLS" };
        var session = new ClassSession { CourseClassId = course.Id, SessionNumber = 1, Latitude = 10, Longitude = 106,
            StartTimeUtc = DateTime.UtcNow.AddMinutes(-1), EndTimeUtc = DateTime.UtcNow.AddHours(1) };
        db.AddRange(student, subject, course, session,
            new ClassEnrollment { CourseClassId = course.Id, StudentId = student.Id },
            new AttendanceQrSession { ClassSessionId = session.Id, QrToken = "QR", ExpiresAtUtc = DateTime.UtcNow.AddMinutes(1) });
        await db.SaveChangesAsync();
        db.FinalizeOnCheckIn = true;
        var result = await new AttendanceService(db, NullLogger<AttendanceService>.Instance)
            .ProcessQrCheckInAsync(student.Id, new("QR", 10, 106, 5, DateTime.UtcNow));
        Assert.False(result.Success);
        var stored = await db.AttendanceRecords.AsNoTracking().SingleAsync();
        Assert.Equal(AttendanceStatus.Absent, stored.Status);
        Assert.Null(stored.CheckedInAtUtc);
    }
}
