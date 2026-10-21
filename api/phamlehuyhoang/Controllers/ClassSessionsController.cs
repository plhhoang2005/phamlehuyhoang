using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using phamlehuyhoang.Data;
using phamlehuyhoang.DTOs;
using phamlehuyhoang.Entities;
using phamlehuyhoang.Enums;
using phamlehuyhoang.Services;

namespace phamlehuyhoang.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ClassSessionsController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IAttendanceService _attendanceService;

    public ClassSessionsController(AppDbContext context, IAttendanceService attendanceService)
    {
        _context = context;
        _attendanceService = attendanceService;
    }

    [HttpGet("class/{courseClassId}")]
    public async Task<ActionResult<List<ClassSessionDto>>> GetSessionsForClass(Guid courseClassId)
    {
        if (!await _context.CourseClasses.AnyAsync(c => c.Id == courseClassId)) return NotFound(new { message = "Lớp học phần không tồn tại" });
        if (!await ResourceAuthorization.CanReadClassAsync(_context, User, courseClassId)) return Forbid();
        var now = DateTime.UtcNow;

        var sessions = await _context.ClassSessions
            .Where(s => s.CourseClassId == courseClassId)
            .OrderBy(s => s.SessionNumber)
            .Select(s => new ClassSessionDto(
                s.Id,
                s.CourseClassId,
                s.SessionNumber,
                s.Title,
                s.StartTimeUtc,
                s.EndTimeUtc,
                s.RoomName,
                s.Latitude,
                s.Longitude,
                s.RadiusMeters,
                s.IsCancelled,
                s.IsFinalized,
                s.FinalizedAtUtc,
                s.QrSessions.Any(q => q.IsOpen && q.ExpiresAtUtc > now)
            ))
            .ToListAsync();

        return Ok(sessions);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ClassSessionDto>> GetSessionById(Guid id)
    {
        var now = DateTime.UtcNow;

        var s = await _context.ClassSessions
            .Include(s => s.QrSessions)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (s == null) return NotFound(new { message = "Buổi học không tồn tại" });
        if (!await ResourceAuthorization.CanReadClassAsync(_context, User, s.CourseClassId)) return Forbid();

        return Ok(new ClassSessionDto(
            s.Id,
            s.CourseClassId,
            s.SessionNumber,
            s.Title,
            s.StartTimeUtc,
            s.EndTimeUtc,
            s.RoomName,
            s.Latitude,
            s.Longitude,
            s.RadiusMeters,
            s.IsCancelled,
            s.IsFinalized,
            s.FinalizedAtUtc,
            s.QrSessions.Any(q => q.IsOpen && q.ExpiresAtUtc > now)
        ));
    }

    [HttpPost]
    [Authorize(Roles = $"{UserRole.Admin},{UserRole.Lecturer}")]
    public async Task<ActionResult<ClassSessionDto>> CreateSession([FromBody] CreateClassSessionRequest request)
    {
        await using var transaction = _context.Database.IsRelational()
            ? await _context.Database.BeginTransactionAsync(System.Data.IsolationLevel.Serializable) : null;
        var courseClass = await _context.CourseClasses.FindAsync(request.CourseClassId);
        if (courseClass == null) return BadRequest(new { message = "Lớp học phần không tồn tại" });
        if (!await ResourceAuthorization.CanManageClassAsync(_context, User, courseClass.Id)) return Forbid();
        if (!ValidSession(request.Title, request.RoomName, request.StartTimeUtc, request.EndTimeUtc,
                request.Latitude, request.Longitude, request.RadiusMeters) || request.SessionNumber < 1 || request.SessionNumber > courseClass.TotalSessions ||
            await _context.ClassSessions.AnyAsync(s => s.CourseClassId == courseClass.Id && s.SessionNumber == request.SessionNumber))
            return BadRequest(new { message = "Thông tin buổi học không hợp lệ hoặc số thứ tự buổi học đã tồn tại" });

        var session = new ClassSession
        {
            Id = Guid.NewGuid(),
            CourseClassId = request.CourseClassId,
            SessionNumber = request.SessionNumber,
            Title = request.Title.Trim(),
            StartTimeUtc = request.StartTimeUtc,
            EndTimeUtc = request.EndTimeUtc,
            RoomName = request.RoomName.Trim(),
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            RadiusMeters = request.RadiusMeters,
            IsCancelled = false,
            IsFinalized = false
        };

        _context.ClassSessions.Add(session);
        await _context.SaveChangesAsync();
        if (transaction != null) await transaction.CommitAsync();

        return CreatedAtAction(nameof(GetSessionById), new { id = session.Id }, new ClassSessionDto(
            session.Id,
            session.CourseClassId,
            session.SessionNumber,
            session.Title,
            session.StartTimeUtc,
            session.EndTimeUtc,
            session.RoomName,
            session.Latitude,
            session.Longitude,
            session.RadiusMeters,
            false,
            false,
            null,
            false
        ));
    }

    [HttpPut("{id}")]
    [Authorize(Roles = $"{UserRole.Admin},{UserRole.Lecturer}")]
    public async Task<IActionResult> UpdateSession(Guid id, [FromBody] UpdateClassSessionRequest request)
    {
        await using var transaction = _context.Database.IsRelational()
            ? await _context.Database.BeginTransactionAsync(System.Data.IsolationLevel.Serializable) : null;
        var session = await _context.ClassSessions.FindAsync(id);
        if (session == null) return NotFound(new { message = "Buổi học không tồn tại" });
        if (!await ResourceAuthorization.CanManageClassAsync(_context, User, session.CourseClassId)) return Forbid();

        if (session.IsFinalized)
        {
            return BadRequest(new { message = "Không thể chỉnh sửa thông tin buổi học đã chốt kết quả" });
        }
        if (!ValidSession(request.Title, request.RoomName, request.StartTimeUtc, request.EndTimeUtc,
                request.Latitude, request.Longitude, request.RadiusMeters))
            return BadRequest(new { message = "Tiêu đề, thời gian hoặc vị trí buổi học không hợp lệ" });

        var number = request.SessionNumber ?? session.SessionNumber;
        var courseClass = await _context.CourseClasses.FindAsync(session.CourseClassId);
        if (courseClass == null || number < 1 || number > courseClass.TotalSessions ||
            await _context.ClassSessions.AnyAsync(s => s.Id != id && s.CourseClassId == session.CourseClassId && s.SessionNumber == number))
            return BadRequest(new { message = "Số thứ tự buổi học không hợp lệ hoặc đã tồn tại" });

        session.SessionNumber = number;
        session.Title = request.Title.Trim();
        session.StartTimeUtc = request.StartTimeUtc;
        session.EndTimeUtc = request.EndTimeUtc;
        session.RoomName = request.RoomName.Trim();
        session.Latitude = request.Latitude;
        session.Longitude = request.Longitude;
        session.RadiusMeters = request.RadiusMeters;
        session.IsCancelled = request.IsCancelled;

        if (session.IsCancelled)
        {
            var qrs = await _context.AttendanceQrSessions.Where(q => q.ClassSessionId == id && q.IsOpen).ToListAsync();
            foreach (var qr in qrs) qr.IsOpen = false;
        }

        await _context.SaveChangesAsync();
        if (transaction != null) await transaction.CommitAsync();
        return Ok(new { message = "Cập nhật buổi học thành công" });
    }

    private static bool ValidSession(string title, string room, DateTime start, DateTime end, double latitude, double longitude, double radius) =>
        !string.IsNullOrWhiteSpace(title) && title.Trim().Length <= 150 && room != null && room.Trim().Length <= 50 &&
        start != default && end > start && ResourceAuthorization.ValidLocation(latitude, longitude, radius);

    [HttpPost("{id}/finalize")]
    [Authorize(Roles = $"{UserRole.Admin},{UserRole.Lecturer}")]
    public async Task<IActionResult> FinalizeSession(Guid id)
    {
        var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!Guid.TryParse(userIdStr, out var userId)) return Unauthorized();

        try
        {
            await _attendanceService.FinalizeSessionAsync(id, userId);
            return Ok(new { message = "Đã chốt danh sách điểm danh buổi học thành công. Các sinh viên chưa điểm danh đã được ghi nhận vắng." });
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
