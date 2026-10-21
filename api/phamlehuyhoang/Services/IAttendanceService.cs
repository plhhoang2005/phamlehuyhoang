using phamlehuyhoang.DTOs;
using phamlehuyhoang.Entities;
using phamlehuyhoang.Enums;

namespace phamlehuyhoang.Services;

public interface IAttendanceService
{
    double CalculateHaversineDistance(double lat1, double lon1, double lat2, double lon2);
    Task<QrSessionDto> OpenOrRefreshQrSessionAsync(Guid classSessionId, Guid lecturerUserId, int lifetimeSeconds = 60);
    Task<bool> CloseQrSessionAsync(Guid classSessionId, Guid lecturerUserId);
    Task<CheckInResultDto> ProcessQrCheckInAsync(Guid studentUserId, CheckInQrRequest request);
    Task<bool> FinalizeSessionAsync(Guid classSessionId, Guid lecturerUserId);
    Task<AttendanceRecordDto> AdjustAttendanceAsync(Guid recordId, AttendanceStatus newStatus, string reason, Guid changedByUserId);
    Task<AttendanceForecastDto> GetStudentForecastAsync(Guid courseClassId, Guid studentUserId);
    Task<List<AttendanceForecastDto>> GetAllForecastsForStudentAsync(Guid studentUserId);
    AttendanceForecastDto ComputeForecast(CourseClass courseClass, List<ClassSession> finalizedSessions, List<AttendanceRecord> studentRecords);
}
