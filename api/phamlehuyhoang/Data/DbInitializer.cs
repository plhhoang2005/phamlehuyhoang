using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using phamlehuyhoang.Entities;
using phamlehuyhoang.Enums;

namespace phamlehuyhoang.Data;

public static class DbInitializer
{
    public static async Task SeedAsync(AppDbContext context)
    {
        await context.Database.MigrateAsync();

        var hasher = new PasswordHasher<User>();

        // 1. Tạo tài khoản Admin
        var admin = await context.Users.FirstOrDefaultAsync(u => u.Username == "admin");
        if (admin == null)
        {
            admin = new User
            {
                Id = Guid.NewGuid(),
                Username = "admin",
                Email = "admin@phamlehuyhoang.edu.vn",
                FullName = "Quản trị viên Hệ thống",
                Role = UserRole.Admin,
                CreatedAtUtc = DateTime.UtcNow,
                IsActive = true
            };
            admin.PasswordHash = hasher.HashPassword(admin, "Admin@123456");
            context.Users.Add(admin);
        }

        // 2. Tạo tài khoản Giảng viên
        var lecturer = await context.Users.FirstOrDefaultAsync(u => u.Username == "giangvien1");
        if (lecturer == null)
        {
            lecturer = new User
            {
                Id = Guid.NewGuid(),
                Username = "giangvien1",
                Email = "giangvien1@phamlehuyhoang.edu.vn",
                FullName = "TS. Nguyễn Văn Hướng",
                Role = UserRole.Lecturer,
                CreatedAtUtc = DateTime.UtcNow,
                IsActive = true
            };
            lecturer.PasswordHash = hasher.HashPassword(lecturer, "GiangVien@123");
            context.Users.Add(lecturer);
        }

        // 3. Tạo tài khoản Sinh viên 1
        var student1 = await context.Users.FirstOrDefaultAsync(u => u.Username == "sinhvien1");
        if (student1 == null)
        {
            student1 = new User
            {
                Id = Guid.NewGuid(),
                Username = "sinhvien1",
                Email = "sinhvien1@phamlehuyhoang.edu.vn",
                FullName = "Phạm Lê Huy Hoàng",
                StudentCode = "23010001",
                Role = UserRole.Student,
                CreatedAtUtc = DateTime.UtcNow,
                IsActive = true
            };
            student1.PasswordHash = hasher.HashPassword(student1, "SinhVien@123");
            context.Users.Add(student1);
        }

        // 4. Tạo tài khoản Sinh viên 2
        var student2 = await context.Users.FirstOrDefaultAsync(u => u.Username == "sinhvien2");
        if (student2 == null)
        {
            student2 = new User
            {
                Id = Guid.NewGuid(),
                Username = "sinhvien2",
                Email = "sinhvien2@phamlehuyhoang.edu.vn",
                FullName = "Trần Thị Mai",
                StudentCode = "23010002",
                Role = UserRole.Student,
                CreatedAtUtc = DateTime.UtcNow,
                IsActive = true
            };
            student2.PasswordHash = hasher.HashPassword(student2, "SinhVien@123");
            context.Users.Add(student2);
        }

        await context.SaveChangesAsync();

        // 5. Môn học
        var subject = await context.Subjects.FirstOrDefaultAsync(s => s.Code == "INT3101");
        if (subject == null)
        {
            subject = new Subject
            {
                Id = Guid.NewGuid(),
                Code = "INT3101",
                Name = "Lập trình thiết bị di động",
                Credits = 3,
                CreatedAtUtc = DateTime.UtcNow
            };
            context.Subjects.Add(subject);
            await context.SaveChangesAsync();
        }

        // 6. Lớp học phần
        var courseClass = await context.CourseClasses.FirstOrDefaultAsync(c => c.Code == "261_INT3101_01");
        if (courseClass == null)
        {
            courseClass = new CourseClass
            {
                Id = Guid.NewGuid(),
                Code = "261_INT3101_01",
                SubjectId = subject.Id,
                LecturerId = lecturer.Id,
                TotalSessions = 15,          // N = 15
                MaxAbsencesAllowed = 3,      // L = 3
                DefaultLatitude = 10.762622,
                DefaultLongitude = 106.682333,
                DefaultRadiusMeters = 100.0,
                CreatedAtUtc = DateTime.UtcNow
            };
            context.CourseClasses.Add(courseClass);
            await context.SaveChangesAsync();
        }

        // 7. Ghi danh sinh viên vào lớp
        if (!await context.ClassEnrollments.AnyAsync(e => e.CourseClassId == courseClass.Id && e.StudentId == student1.Id))
        {
            context.ClassEnrollments.Add(new ClassEnrollment
            {
                Id = Guid.NewGuid(),
                CourseClassId = courseClass.Id,
                StudentId = student1.Id,
                EnrolledAtUtc = DateTime.UtcNow
            });
        }

        if (!await context.ClassEnrollments.AnyAsync(e => e.CourseClassId == courseClass.Id && e.StudentId == student2.Id))
        {
            context.ClassEnrollments.Add(new ClassEnrollment
            {
                Id = Guid.NewGuid(),
                CourseClassId = courseClass.Id,
                StudentId = student2.Id,
                EnrolledAtUtc = DateTime.UtcNow
            });
        }
        await context.SaveChangesAsync();

        // 8. Tạo 15 buổi học mẫu
        var existingSessions = await context.ClassSessions
            .Where(s => s.CourseClassId == courseClass.Id)
            .OrderBy(s => s.SessionNumber)
            .ToListAsync();

        if (!existingSessions.Any())
        {
            var sessions = new List<ClassSession>();
            var baseDate = DateTime.UtcNow.Date.AddDays(-28); // 4 tuần trước

            for (int i = 1; i <= 15; i++)
            {
                var sessionDate = baseDate.AddDays((i - 1) * 3);
                bool isPastFinalized = i <= 8; // Buổi 1 đến 8 đã diễn ra và chốt (M = 8)

                var session = new ClassSession
                {
                    Id = Guid.NewGuid(),
                    CourseClassId = courseClass.Id,
                    SessionNumber = i,
                    Title = $"Buổi {i}: {(i == 1 ? "Giới thiệu & Kiến trúc Mobile" : i == 2 ? "Dart căn bản & Widget Flutter" : i == 3 ? "State Management & Provider" : i == 4 ? "Giao tiếp REST API & JWT" : i == 5 ? "Lưu trữ dữ liệu SQLite & Cache" : i == 6 ? "Định vị Geolocation & Map" : i == 7 ? "Quét mã QR Code & Camera" : i == 8 ? "Xác thực sinh trắc học & Khuôn mặt" : $"Chuyên đề nâng cao phần {i - 8}")}",
                    StartTimeUtc = sessionDate.AddHours(7),
                    EndTimeUtc = sessionDate.AddHours(11),
                    RoomName = "Phòng Lab A.205",
                    Latitude = courseClass.DefaultLatitude,
                    Longitude = courseClass.DefaultLongitude,
                    RadiusMeters = courseClass.DefaultRadiusMeters,
                    IsCancelled = false,
                    IsFinalized = isPastFinalized,
                    FinalizedAtUtc = isPastFinalized ? sessionDate.AddHours(12) : null,
                    FinalizedByUserId = isPastFinalized ? lecturer.Id : null
                };

                sessions.Add(session);
                context.ClassSessions.Add(session);
            }

            await context.SaveChangesAsync();

            // 9. Tạo kết quả điểm danh cho 8 buổi đầu của student1 đúng theo ví dụ chuẩn trong plan:
            // N = 15, M = 8, A = 2, L = 3 (Vắng 2 buổi: buổi 3 và buổi 6)
            for (int i = 0; i < 8; i++)
            {
                var s = sessions[i];
                bool isAbsent = (i + 1 == 3) || (i + 1 == 6); // Vắng ở buổi 3 và buổi 6

                var status = isAbsent ? AttendanceStatus.Absent : AttendanceStatus.Present;

                context.AttendanceRecords.Add(new AttendanceRecord
                {
                    Id = Guid.NewGuid(),
                    ClassSessionId = s.Id,
                    StudentId = student1.Id,
                    Status = status,
                    CheckedInAtUtc = isAbsent ? null : s.StartTimeUtc.AddMinutes(5),
                    CheckInMethod = isAbsent ? "AutoFinalize" : "QrLocation",
                    StudentLatitude = isAbsent ? null : s.Latitude + 0.0001,
                    StudentLongitude = isAbsent ? null : s.Longitude + 0.0001,
                    DistanceMeters = isAbsent ? null : 15.2,
                    AccuracyMeters = isAbsent ? null : 8.0,
                    CreatedAtUtc = s.StartTimeUtc,
                    Note = isAbsent ? "Vắng không phép khi chốt kết quả" : "Điểm danh thành công qua QR + Vị trí"
                });
            }

            // Buổi 9 là buổi hiện tại: mở sẵn 1 phiên QR để sẵn sàng demo ngay!
            var session9 = sessions[8];
            var qrToken = "DEMO-QR-" + Guid.NewGuid().ToString("N")[..8].ToUpperInvariant();
            context.AttendanceQrSessions.Add(new AttendanceQrSession
            {
                Id = Guid.NewGuid(),
                ClassSessionId = session9.Id,
                QrToken = qrToken,
                CreatedAtUtc = DateTime.UtcNow,
                ExpiresAtUtc = DateTime.UtcNow.AddHours(24), // Để lâu phục vụ kiểm thử
                IsOpen = true
            });

            await context.SaveChangesAsync();
        }
    }
}
