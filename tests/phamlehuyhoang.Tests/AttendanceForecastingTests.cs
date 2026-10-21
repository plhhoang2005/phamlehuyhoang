using Microsoft.Extensions.Logging.Abstractions;
using phamlehuyhoang.DTOs;
using phamlehuyhoang.Entities;
using phamlehuyhoang.Enums;
using phamlehuyhoang.Services;
using Xunit;

namespace phamlehuyhoang.Tests;

public class AttendanceForecastingTests
{
    private readonly AttendanceService _service;

    public AttendanceForecastingTests()
    {
        _service = new AttendanceService(null!, NullLogger<AttendanceService>.Instance);
    }

    [Fact]
    public void Forecast_MatchesMasterPlanAcceptanceExample()
    {
        // Yêu cầu bắt buộc trong mục 4 của plan:
        // N = 15, M = 8, A = 2, L = 3
        // Kỳ vọng: Còn 1 buổi có thể vắng, Tỷ lệ hiện tại = 75.0%, Tỷ lệ nếu vắng tiếp = ~66.67%
        var courseClass = new CourseClass
        {
            Id = Guid.NewGuid(),
            Code = "261_INT3101_01",
            TotalSessions = 15,
            MaxAbsencesAllowed = 3
        };

        var sessions = new List<ClassSession>();
        for (int i = 1; i <= 8; i++)
        {
            sessions.Add(new ClassSession
            {
                Id = Guid.NewGuid(),
                CourseClassId = courseClass.Id,
                SessionNumber = i,
                IsFinalized = true,
                IsCancelled = false
            });
        }

        var studentId = Guid.NewGuid();
        var records = new List<AttendanceRecord>();
        for (int i = 0; i < 8; i++)
        {
            // 2 buổi vắng: buổi 3 và 6
            bool isAbsent = (i == 2 || i == 5);
            records.Add(new AttendanceRecord
            {
                Id = Guid.NewGuid(),
                ClassSessionId = sessions[i].Id,
                StudentId = studentId,
                Status = isAbsent ? AttendanceStatus.Absent : AttendanceStatus.Present
            });
        }

        var result = _service.ComputeForecast(courseClass, sessions, records);

        Assert.Equal(15, result.N);
        Assert.Equal(3, result.L);
        Assert.Equal(8, result.M);
        Assert.Equal(2, result.A);
        Assert.NotNull(result.CurrentPercentage);
        Assert.Equal(75.0, result.CurrentPercentage.Value, 2);

        Assert.NotNull(result.NextAbsentPercentage);
        // (8 - 2) / (8 + 1) * 100 = 6 / 9 * 100 = 66.6666...%
        Assert.Equal(66.67, result.NextAbsentPercentage.Value, 2);

        Assert.Equal(1, result.RemainingAbsencesAllowed);
        Assert.False(result.IsLimitExceeded);
    }

    [Fact]
    public void Forecast_Boundary_ZeroSessions_ReturnsNoData()
    {
        // Khi M = 0: chưa có dữ liệu, không chia cho 0
        var courseClass = new CourseClass
        {
            Id = Guid.NewGuid(),
            TotalSessions = 15,
            MaxAbsencesAllowed = 3
        };

        var result = _service.ComputeForecast(courseClass, new List<ClassSession>(), new List<AttendanceRecord>());

        Assert.Equal(0, result.M);
        Assert.Null(result.CurrentPercentage);
        Assert.Equal("Chưa có dữ liệu buổi học đã chốt", result.StatusDescription);
    }

    [Fact]
    public void Forecast_Boundary_AllSessionsFinalized_NoNextSessionAssumption()
    {
        // Khi M = N: đã kết thúc toàn bộ khóa học, không hiển thị giả định vắng buổi tiếp theo
        var courseClass = new CourseClass
        {
            Id = Guid.NewGuid(),
            TotalSessions = 5,
            MaxAbsencesAllowed = 1
        };

        var sessions = new List<ClassSession>();
        var records = new List<AttendanceRecord>();
        for (int i = 1; i <= 5; i++)
        {
            var s = new ClassSession { Id = Guid.NewGuid(), SessionNumber = i, IsFinalized = true };
            sessions.Add(s);
            records.Add(new AttendanceRecord { ClassSessionId = s.Id, Status = AttendanceStatus.Present });
        }

        var result = _service.ComputeForecast(courseClass, sessions, records);

        Assert.Equal(5, result.M);
        Assert.Equal(0, result.A);
        Assert.Equal(100.0, result.CurrentPercentage);
        Assert.Null(result.NextAbsentPercentage); // Không có buổi tiếp theo
        Assert.Equal(0, result.RemainingAbsencesAllowed);
    }

    [Fact]
    public void Forecast_Boundary_AbsencesExceedLimit_FlagsExceeded()
    {
        // Khi A > L: hiển thị rõ vượt giới hạn
        var courseClass = new CourseClass
        {
            Id = Guid.NewGuid(),
            TotalSessions = 10,
            MaxAbsencesAllowed = 2
        };

        var sessions = new List<ClassSession>();
        var records = new List<AttendanceRecord>();
        for (int i = 1; i <= 5; i++)
        {
            var s = new ClassSession { Id = Guid.NewGuid(), SessionNumber = i, IsFinalized = true };
            sessions.Add(s);
            // Vắng 3 buổi > L (2)
            bool isAbsent = i <= 3;
            records.Add(new AttendanceRecord
            {
                ClassSessionId = s.Id,
                Status = isAbsent ? AttendanceStatus.Absent : AttendanceStatus.Present
            });
        }

        var result = _service.ComputeForecast(courseClass, sessions, records);

        Assert.Equal(3, result.A);
        Assert.True(result.IsLimitExceeded);
        Assert.Equal(0, result.RemainingAbsencesAllowed);
        Assert.Contains("ĐÃ VƯỢT GIỚI HẠN VẮNG", result.StatusDescription);
    }

    [Fact]
    public void Forecast_ExcusedAbsenceAndLate_DoesNotIncreaseA()
    {
        // Có mặt và Đi muộn tính tham dự; Vắng có phép (Excused) không làm tăng A
        var courseClass = new CourseClass
        {
            Id = Guid.NewGuid(),
            TotalSessions = 10,
            MaxAbsencesAllowed = 2
        };

        var sessions = new List<ClassSession>();
        var records = new List<AttendanceRecord>();

        var s1 = new ClassSession { Id = Guid.NewGuid(), SessionNumber = 1, IsFinalized = true };
        var s2 = new ClassSession { Id = Guid.NewGuid(), SessionNumber = 2, IsFinalized = true };
        var s3 = new ClassSession { Id = Guid.NewGuid(), SessionNumber = 3, IsFinalized = true };
        sessions.AddRange(new[] { s1, s2, s3 });

        records.Add(new AttendanceRecord { ClassSessionId = s1.Id, Status = AttendanceStatus.Late });
        records.Add(new AttendanceRecord { ClassSessionId = s2.Id, Status = AttendanceStatus.Excused });
        records.Add(new AttendanceRecord { ClassSessionId = s3.Id, Status = AttendanceStatus.Present });

        var result = _service.ComputeForecast(courseClass, sessions, records);

        Assert.Equal(3, result.M);
        Assert.Equal(0, result.A); // A không tăng vì không có Absent (vắng không phép)
        Assert.Equal(100.0, result.CurrentPercentage);
    }
}
