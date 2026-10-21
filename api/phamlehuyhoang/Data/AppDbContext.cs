using Microsoft.EntityFrameworkCore;
using phamlehuyhoang.Entities;

namespace phamlehuyhoang.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<OtpChallenge> OtpChallenges => Set<OtpChallenge>();
    public DbSet<Subject> Subjects => Set<Subject>();
    public DbSet<CourseClass> CourseClasses => Set<CourseClass>();
    public DbSet<ClassEnrollment> ClassEnrollments => Set<ClassEnrollment>();
    public DbSet<ClassSession> ClassSessions => Set<ClassSession>();
    public DbSet<AttendanceQrSession> AttendanceQrSessions => Set<AttendanceQrSession>();
    public DbSet<AttendanceRecord> AttendanceRecords => Set<AttendanceRecord>();
    public DbSet<AttendanceHistory> AttendanceHistories => Set<AttendanceHistory>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasIndex(u => u.Username).IsUnique();
            entity.HasIndex(u => u.Email).IsUnique();
        });

        modelBuilder.Entity<OtpChallenge>(entity =>
        {
            entity.HasIndex(o => o.Ticket).IsUnique();
            entity.HasIndex(o => new { o.UserId, o.ExpiresAtUtc, o.IsUsed });
        });

        modelBuilder.Entity<Subject>(entity =>
        {
            entity.HasIndex(s => s.Code).IsUnique();
        });

        modelBuilder.Entity<CourseClass>(entity =>
        {
            entity.HasIndex(c => c.Code).IsUnique();
        });

        modelBuilder.Entity<ClassEnrollment>(entity =>
        {
            entity.HasIndex(e => new { e.CourseClassId, e.StudentId }).IsUnique();
        });

        modelBuilder.Entity<AttendanceQrSession>(entity =>
        {
            entity.HasIndex(q => q.QrToken).IsUnique();
            entity.HasIndex(q => new { q.ClassSessionId, q.IsOpen });
        });

        modelBuilder.Entity<AttendanceRecord>(entity =>
        {
            // Ràng buộc Unique ngăn chặn race conditions / bấm 2 lần
            entity.HasIndex(a => new { a.ClassSessionId, a.StudentId }).IsUnique();
        });

        modelBuilder.Entity<AttendanceHistory>(entity =>
        {
            entity.HasOne(h => h.AttendanceRecord)
                .WithMany(r => r.Histories)
                .HasForeignKey(h => h.AttendanceRecordId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(h => h.ChangedByUser)
                .WithMany()
                .HasForeignKey(h => h.ChangedByUserId)
                .OnDelete(DeleteBehavior.Restrict);
        });
    }
}
