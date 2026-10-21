using System.Security.Cryptography;
using Microsoft.EntityFrameworkCore;
using phamlehuyhoang.Data;
using phamlehuyhoang.DTOs;
using phamlehuyhoang.Entities;
using phamlehuyhoang.Enums;

namespace phamlehuyhoang.Services;

public class AttendanceService : IAttendanceService
{
    private readonly AppDbContext _context;
    private readonly ILogger<AttendanceService> _logger;

    public const double EarthRadiusMeters = 6371000.0;
    public const double MaxAllowedAccuracyMeters = 50.0;
    public const double MaxLocationAgeSeconds = 60.0;

    public AttendanceService(AppDbContext context, ILogger<AttendanceService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public double CalculateHaversineDistance(double lat1, double lon1, double lat2, double lon2)
    {
        if (double.IsNaN(lat1) || double.IsNaN(lon1) || double.IsNaN(lat2) || double.IsNaN(lon2) ||
            double.IsInfinity(lat1) || double.IsInfinity(lon1) || double.IsInfinity(lat2) || double.IsInfinity(lon2))
        {
            throw new ArgumentException("Tọa độ không hợp lệ");
        }

        if (lat1 < -90 || lat1 > 90 || lat2 < -90 || lat2 > 90 ||
            lon1 < -180 || lon1 > 180 || lon2 < -180 || lon2 > 180)
        {
            throw new ArgumentException("Tọa độ nằm ngoài phạm vi trái đất");
        }

        double dLat = ToRadians(lat2 - lat1);
        double dLon = ToRadians(lon2 - lon1);

        double a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                   Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                   Math.Sin(dLon / 2) * Math.Sin(dLon / 2);

        double c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return EarthRadiusMeters * c;
    }

    private static double ToRadians(double degrees) => degrees * Math.PI / 180.0;

    public async Task<QrSessionDto> OpenOrRefreshQrSessionAsync(Guid classSessionId, Guid lecturerUserId, int lifetimeSeconds = 60)
    {
        var session = await _context.ClassSessions
            .Include(s => s.CourseClass)
            .FirstOrDefaultAsync(s => s.Id == classSessionId);

        if (session == null) throw new InvalidOperationException("Buổi học không tồn tại");

        await ResourceAuthorization.DemandManageClassAsync(_context, lecturerUserId, session.CourseClassId);

        if (session.IsFinalized || session.IsCancelled)
        {
            throw new InvalidOperationException("Buổi học đã hủy hoặc đã chốt kết quả, không thể mở lại QR");
        }
        if (lifetimeSeconds < 1 || lifetimeSeconds > 300)
            throw new ArgumentException("Thời hạn QR phải từ 1 đến 300 giây");

        // Đóng các phiên QR cũ đang mở
        var oldQrSessions = await _context.AttendanceQrSessions
            .Where(q => q.ClassSessionId == classSessionId && q.IsOpen)
            .ToListAsync();
        foreach (var old in oldQrSessions)
        {
            old.IsOpen = false;
        }

        // Tạo mã QR token ngẫu nhiên bảo mật
        var token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(24))
            .Replace('+', '-').Replace('/', '_').TrimEnd('=');

        var now = DateTime.UtcNow;
        var newQr = new AttendanceQrSession
        {
            Id = Guid.NewGuid(),
            ClassSessionId = classSessionId,
            QrToken = token,
            CreatedAtUtc = now,
            ExpiresAtUtc = now.AddSeconds(lifetimeSeconds),
            IsOpen = true
        };

        _context.AttendanceQrSessions.Add(newQr);
        await _context.SaveChangesAsync();

        return new QrSessionDto(newQr.Id, classSessionId, newQr.QrToken, newQr.ExpiresAtUtc, true, lifetimeSeconds);
    }

    public async Task<bool> CloseQrSessionAsync(Guid classSessionId, Guid lecturerUserId)
    {
        var session = await _context.ClassSessions.FindAsync(classSessionId)
            ?? throw new InvalidOperationException("Buổi học không tồn tại");
        await ResourceAuthorization.DemandManageClassAsync(_context, lecturerUserId, session.CourseClassId);
        var activeSessions = await _context.AttendanceQrSessions
            .Where(q => q.ClassSessionId == classSessionId && q.IsOpen)
            .ToListAsync();

        foreach (var s in activeSessions)
        {
            s.IsOpen = false;
        }

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<CheckInResultDto> ProcessQrCheckInAsync(Guid studentUserId, CheckInQrRequest request)
    {
        // 1. Kiểm tra tọa độ hợp lệ
        if (double.IsNaN(request.Latitude) || double.IsNaN(request.Longitude) ||
            request.Latitude < -90 || request.Latitude > 90 ||
            request.Longitude < -180 || request.Longitude > 180)
        {
            return new CheckInResultDto(false, "Tọa độ GPS gửi lên không hợp lệ", null, null, null);
        }

        // 2. Kiểm tra độ chính xác GPS
        if (!double.IsFinite(request.Accuracy) || request.Accuracy < 0 || request.Accuracy > MaxAllowedAccuracyMeters)
        {
            return new CheckInResultDto(false,
                $"Độ chính xác GPS ({request.Accuracy:F1}m) không đạt yêu cầu (tối đa {MaxAllowedAccuracyMeters}m). Vui lòng ra nơi thông thoáng và thử lại",
                null, null, null);
        }

        // 3. Kiểm tra thời gian lấy vị trí (không nhận mẫu quá cũ)
        var now = DateTime.UtcNow;
        if (!request.ClientTimestampUtc.HasValue)
            return new CheckInResultDto(false, "Thiếu thời gian lấy vị trí GPS. Vui lòng lấy vị trí mới và quét lại", null, null, null);
        {
            var age = (now - request.ClientTimestampUtc.Value).TotalSeconds;
            if (age > MaxLocationAgeSeconds || age < -30) // Chặn tương lai bất thường > 30s
            {
                return new CheckInResultDto(false, "Dữ liệu vị trí đã quá cũ hoặc sai lệch thời gian hệ thống. Vui lòng quét lại", null, null, null);
            }
        }

        // 4. Tìm phiên QR
        var qrSession = await _context.AttendanceQrSessions
            .Include(q => q.ClassSession)
            .ThenInclude(s => s!.CourseClass)
            .FirstOrDefaultAsync(q => q.QrToken == request.QrToken);

        if (qrSession == null)
        {
            return new CheckInResultDto(false, "Mã QR không tồn tại hoặc không hợp lệ", null, null, null);
        }

        if (!qrSession.IsOpen)
        {
            return new CheckInResultDto(false, "Phiên điểm danh này đã được giảng viên đóng", null, null, null);
        }

        if (now > qrSession.ExpiresAtUtc)
        {
            return new CheckInResultDto(false, "Mã QR này đã hết thời gian hiệu lực (60 giây). Vui lòng quét mã mới trên màn hình giảng viên", null, null, null);
        }

        var classSession = qrSession.ClassSession;
        if (classSession == null || classSession.IsFinalized || classSession.IsCancelled)
        {
            return new CheckInResultDto(false, "Buổi học này đã kết thúc hoặc đã chốt điểm danh", null, null, null);
        }

        // 5. Kiểm tra tư cách thành viên lớp học phần
        var isEnrolled = await _context.ClassEnrollments
            .AnyAsync(e => e.CourseClassId == classSession.CourseClassId && e.StudentId == studentUserId);

        if (!isEnrolled)
        {
            return new CheckInResultDto(false, "Bạn không phải là sinh viên thuộc danh sách lớp học phần này", null, null, null);
        }

        // 6. Tính khoảng cách độc lập tại máy chủ
        double distance = CalculateHaversineDistance(request.Latitude, request.Longitude, classSession.Latitude, classSession.Longitude);
        if (distance > classSession.RadiusMeters)
        {
            return new CheckInResultDto(false,
                $"Vị trí của bạn cách phòng học {distance:F1}m, vượt quá bán kính cho phép ({classSession.RadiusMeters:F1}m). Không thể điểm danh",
                null, distance, null);
        }

        // 7. Chống điểm danh trùng lặp
        var existingRecord = await _context.AttendanceRecords
            .FirstOrDefaultAsync(r => r.ClassSessionId == classSession.Id && r.StudentId == studentUserId);

        if (existingRecord != null)
        {
            var checkedIn = IsPersistedCheckIn(existingRecord);
            return new CheckInResultDto(checkedIn,
                checkedIn ? $"Bạn đã điểm danh buổi học này trước đó lúc {existingRecord.CheckedInAtUtc?.ToLocalTime():HH:mm:ss dd/MM/yyyy}"
                    : "Đã có kết quả điểm danh do giảng viên ghi nhận. Vui lòng liên hệ giảng viên để kiểm tra.",
                existingRecord.Status, existingRecord.DistanceMeters, existingRecord.CheckedInAtUtc);
        }

        // Xác định trạng thái: Có mặt hoặc Đi muộn
        var status = AttendanceStatus.Present;
        if (now > classSession.StartTimeUtc.AddMinutes(15))
        {
            status = AttendanceStatus.Late;
        }

        var newRecord = new AttendanceRecord
        {
            Id = Guid.NewGuid(),
            ClassSessionId = classSession.Id,
            StudentId = studentUserId,
            Status = status,
            CheckedInAtUtc = now,
            CheckInMethod = "QrLocation",
            StudentLatitude = request.Latitude,
            StudentLongitude = request.Longitude,
            DistanceMeters = distance,
            AccuracyMeters = request.Accuracy,
            CreatedAtUtc = now,
            Note = status == AttendanceStatus.Late ? "Điểm danh muộn qua QR + Vị trí" : "Điểm danh đúng giờ qua QR + Vị trí"
        };

        try
        {
            _context.AttendanceRecords.Add(newRecord);
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException ex)
        {
            // Chỉ trả thành công khi có bản ghi đã lưu từ một yêu cầu đồng thời.
            _context.Entry(newRecord).State = EntityState.Detached;
            var raceRecord = await _context.AttendanceRecords.AsNoTracking()
                .FirstOrDefaultAsync(r => r.ClassSessionId == classSession.Id && r.StudentId == studentUserId);
            if (raceRecord != null)
                return new CheckInResultDto(IsPersistedCheckIn(raceRecord),
                    IsPersistedCheckIn(raceRecord) ? "Bạn đã được ghi nhận điểm danh"
                        : "Buổi học đã chốt hoặc kết quả đã thay đổi. Vui lòng liên hệ giảng viên.",
                    raceRecord.Status, raceRecord.DistanceMeters, raceRecord.CheckedInAtUtc);
            _logger.LogError(ex, "Could not persist attendance for session {SessionId}", classSession.Id);
            return new CheckInResultDto(false, "Không thể lưu kết quả điểm danh. Vui lòng thử lại", null, null, null);
        }

        string successMsg = status == AttendanceStatus.Late
            ? $"Điểm danh thành công (Ghi nhận đi muộn). Khoảng cách: {distance:F1}m"
            : $"Điểm danh thành công! Khoảng cách tới phòng học: {distance:F1}m";

        return new CheckInResultDto(true, successMsg, status, distance, now);
    }

    private static bool IsPersistedCheckIn(AttendanceRecord record) =>
        record.CheckedInAtUtc.HasValue && record.Status is AttendanceStatus.Present or AttendanceStatus.Late;

    public async Task<bool> FinalizeSessionAsync(Guid classSessionId, Guid lecturerUserId)
    {
        var session = await _context.ClassSessions
            .Include(s => s.CourseClass)
            .FirstOrDefaultAsync(s => s.Id == classSessionId);

        if (session == null) throw new InvalidOperationException("Buổi học không tồn tại");

        await ResourceAuthorization.DemandManageClassAsync(_context, lecturerUserId, session.CourseClassId);
        if (session.IsCancelled) throw new InvalidOperationException("Không thể chốt buổi học đã hủy");
        if (session.IsFinalized) return true;

        // Đóng toàn bộ QR đang mở
        var openQrs = await _context.AttendanceQrSessions
            .Where(q => q.ClassSessionId == classSessionId && q.IsOpen)
            .ToListAsync();
        foreach (var q in openQrs) q.IsOpen = false;

        // Lấy danh sách toàn bộ sinh viên đã ghi danh vào lớp này
        var enrolledStudentIds = await _context.ClassEnrollments
            .Where(e => e.CourseClassId == session.CourseClassId)
            .Select(e => e.StudentId)
            .ToListAsync();

        // Lấy các sinh viên đã có bản ghi điểm danh trong buổi này
        var existingStudentIds = await _context.AttendanceRecords
            .Where(r => r.ClassSessionId == classSessionId)
            .Select(r => r.StudentId)
            .ToListAsync();

        var absentStudentIds = enrolledStudentIds.Except(existingStudentIds).ToList();
        var now = DateTime.UtcNow;

        foreach (var studentId in absentStudentIds)
        {
            _context.AttendanceRecords.Add(new AttendanceRecord
            {
                Id = Guid.NewGuid(),
                ClassSessionId = classSessionId,
                StudentId = studentId,
                Status = AttendanceStatus.Absent, // Vắng không phép
                CheckedInAtUtc = null,
                CheckInMethod = "AutoFinalize",
                CreatedAtUtc = now,
                Note = "Vắng mặt khi chốt buổi học"
            });
        }

        session.IsFinalized = true;
        session.FinalizedAtUtc = now;
        session.FinalizedByUserId = lecturerUserId;

        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<AttendanceRecordDto> AdjustAttendanceAsync(Guid recordId, AttendanceStatus newStatus, string reason, Guid changedByUserId)
    {
        var record = await _context.AttendanceRecords
            .Include(r => r.Student)
            .FirstOrDefaultAsync(r => r.Id == recordId);

        if (record == null) throw new InvalidOperationException("Bản ghi điểm danh không tồn tại");

        var session = await _context.ClassSessions.FindAsync(record.ClassSessionId)
            ?? throw new InvalidOperationException("Buổi học không tồn tại");
        await ResourceAuthorization.DemandManageClassAsync(_context, changedByUserId, session.CourseClassId);
        if (!Enum.IsDefined(newStatus) || string.IsNullOrWhiteSpace(reason) || reason.Trim().Length > 230)
            throw new ArgumentException("Trạng thái hoặc lý do điều chỉnh không hợp lệ (tối đa 230 ký tự)");
        reason = reason.Trim();

        var oldStatus = record.Status;
        record.Status = newStatus;
        record.Note = $"Điều chỉnh: {reason}";

        var history = new AttendanceHistory
        {
            Id = Guid.NewGuid(),
            AttendanceRecordId = record.Id,
            OldStatus = oldStatus,
            NewStatus = newStatus,
            Reason = reason,
            ChangedByUserId = changedByUserId,
            ChangedAtUtc = DateTime.UtcNow
        };

        _context.AttendanceHistories.Add(history);
        await _context.SaveChangesAsync();

        return new AttendanceRecordDto(
            record.Id,
            record.ClassSessionId,
            record.StudentId,
            record.Student?.FullName ?? "N/A",
            record.Student?.StudentCode,
            record.Status,
            record.CheckedInAtUtc,
            record.CheckInMethod,
            record.DistanceMeters,
            record.AccuracyMeters,
            record.Note
        );
    }

    public async Task<AttendanceForecastDto> GetStudentForecastAsync(Guid courseClassId, Guid studentUserId)
    {
        var courseClass = await _context.CourseClasses
            .Include(c => c.Subject)
            .FirstOrDefaultAsync(c => c.Id == courseClassId);

        if (courseClass == null) throw new InvalidOperationException("Lớp học phần không tồn tại");

        var finalizedSessions = await _context.ClassSessions
            .Where(s => s.CourseClassId == courseClassId && s.IsFinalized && !s.IsCancelled)
            .OrderBy(s => s.SessionNumber)
            .ToListAsync();

        var finalizedSessionIds = finalizedSessions.Select(s => s.Id).ToList();

        var studentRecords = await _context.AttendanceRecords
            .Where(r => r.StudentId == studentUserId && finalizedSessionIds.Contains(r.ClassSessionId))
            .ToListAsync();

        return ComputeForecast(courseClass, finalizedSessions, studentRecords);
    }

    public async Task<List<AttendanceForecastDto>> GetAllForecastsForStudentAsync(Guid studentUserId)
    {
        var enrollments = await _context.ClassEnrollments
            .Where(e => e.StudentId == studentUserId)
            .Select(e => e.CourseClassId)
            .ToListAsync();

        var results = new List<AttendanceForecastDto>();
        foreach (var classId in enrollments)
        {
            var forecast = await GetStudentForecastAsync(classId, studentUserId);
            results.Add(forecast);
        }

        return results;
    }

    public AttendanceForecastDto ComputeForecast(
        CourseClass courseClass,
        List<ClassSession> finalizedSessions,
        List<AttendanceRecord> studentRecords)
    {
        int N = courseClass.TotalSessions;
        int L = courseClass.MaxAbsencesAllowed;

        // M: Số buổi đã chốt kết quả chính thức cho lớp
        int M = finalizedSessions.Count;

        // A: Số buổi bị tính vắng (vắng không phép)
        // Present, Late: tính tham dự
        // Excused: vắng có phép -> KHÔNG tăng A
        // Absent: vắng không phép -> tăng A
        int A = 0;
        var recordDict = studentRecords.ToDictionary(r => r.ClassSessionId);

        foreach (var session in finalizedSessions)
        {
            if (recordDict.TryGetValue(session.Id, out var rec))
            {
                if (rec.Status == AttendanceStatus.Absent)
                {
                    A++;
                }
            }
            else
            {
                // Chưa có bản ghi trong buổi đã chốt -> tính là vắng
                A++;
            }
        }

        double? currentPercentage = null;
        if (M > 0)
        {
            currentPercentage = (double)(M - A) / M * 100.0;
        }

        double? nextAbsentPercentage = null;
        if (M < N)
        {
            nextAbsentPercentage = (double)(M - A) / (M + 1) * 100.0;
        }

        int remainingAbsencesAllowed = Math.Min(N - M, Math.Max(0, L - A));
        bool isLimitExceeded = A > L;

        string statusDesc;
        if (M == 0)
        {
            statusDesc = "Chưa có dữ liệu buổi học đã chốt";
        }
        else if (isLimitExceeded)
        {
            statusDesc = $"ĐÃ VƯỢT GIỚI HẠN VẮNG: Đã vắng {A}/{L} buổi cho phép! Bạn có nguy cơ bị cấm thi.";
        }
        else if (remainingAbsencesAllowed == 0 && M < N)
        {
            statusDesc = $"CẢNH BÁO NGUY HIỂM: Bạn đã vắng {A}/{L} buổi cho phép. Không được vắng thêm bất kỳ buổi nào nữa!";
        }
        else if (M == N)
        {
            statusDesc = "Lớp học phần đã hoàn thành toàn bộ các buổi học.";
        }
        else
        {
            statusDesc = $"Chuyên cần ổn định: Bạn còn có thể vắng tối đa {remainingAbsencesAllowed} buổi nữa mà không vượt giới hạn.";
        }

        var dtoList = studentRecords.Select(r => new AttendanceRecordDto(
            r.Id,
            r.ClassSessionId,
            r.StudentId,
            r.Student?.FullName ?? "N/A",
            r.Student?.StudentCode,
            r.Status,
            r.CheckedInAtUtc,
            r.CheckInMethod,
            r.DistanceMeters,
            r.AccuracyMeters,
            r.Note
        )).ToList();

        return new AttendanceForecastDto(
            courseClass.Id,
            courseClass.Code,
            courseClass.Subject?.Name ?? "Môn học",
            N,
            L,
            M,
            A,
            currentPercentage,
            nextAbsentPercentage,
            remainingAbsencesAllowed,
            isLimitExceeded,
            statusDesc,
            dtoList
        );
    }
}
