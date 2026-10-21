using System.ComponentModel.DataAnnotations;
using phamlehuyhoang.Enums;

namespace phamlehuyhoang.DTOs;

public record OpenQrSessionRequest(
    [Required] Guid ClassSessionId,
    int LifetimeSeconds = 60
);

public record QrSessionDto(
    Guid Id,
    Guid ClassSessionId,
    string QrToken,
    DateTime ExpiresAtUtc,
    bool IsOpen,
    int RemainingSeconds
);

public record CheckInQrRequest(
    [Required] string QrToken,
    [Required] double Latitude,
    [Required] double Longitude,
    [Required] double Accuracy,
    DateTime? ClientTimestampUtc
);

public record CheckInResultDto(
    bool Success,
    string Message,
    AttendanceStatus? Status,
    double? DistanceMeters,
    DateTime? CheckedInAtUtc
);

public record AttendanceRecordDto(
    Guid Id,
    Guid ClassSessionId,
    Guid StudentId,
    string StudentName,
    string? StudentCode,
    AttendanceStatus Status,
    DateTime? CheckedInAtUtc,
    string CheckInMethod,
    double? DistanceMeters,
    double? AccuracyMeters,
    string? Note
);

public record AdjustAttendanceRequest(
    [Required] Guid AttendanceRecordId,
    [Required] AttendanceStatus NewStatus,
    [Required] string Reason
);

public record FinalizeSessionRequest(
    [Required] Guid ClassSessionId
);

public record AttendanceForecastDto(
    Guid CourseClassId,
    string ClassCode,
    string SubjectName,
    int N,                             // Tổng số buổi chính thức
    int L,                             // Tối đa được vắng
    int M,                             // Số buổi đã chốt
    int A,                             // Số buổi vắng tính vào kỷ luật
    double? CurrentPercentage,         // (M-A)/M * 100%
    double? NextAbsentPercentage,      // (M-A)/(M+1) * 100%
    int RemainingAbsencesAllowed,      // min(N-M, max(0, L-A))
    bool IsLimitExceeded,              // A > L
    string StatusDescription,          // Giải thích trạng thái
    List<AttendanceRecordDto> SessionRecords
);
