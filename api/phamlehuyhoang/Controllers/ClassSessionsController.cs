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
        var courseClass = await _context.CourseClasses.FindAsync(request.CourseClassId);
        if (courseClass == null) return BadRequest(new { message = "Lớp học phần không tồn tại" });

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
            RadiusMeters = request.RadiusMeters > 0 ? request.RadiusMeters : courseClass.DefaultRadiusMeters,
            IsCancelled = false,
            IsFinalized = false
        };

        _context.ClassSessions.Add(session);
        await _context.SaveChangesAsync();

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
        var session = await _context.ClassSessions.FindAsync(id);
        if (session == null) return NotFound(new { message = "Buổi học không tồn tại" });

        if (session.IsFinalized)
        {
            return BadRequest(new { message = "Không thể chỉnh sửa thông tin buổi học đã chốt kết quả" });
        }

        session.Title = request.Title.Trim();
        session.StartTimeUtc = request.StartTimeUtc;
        session.EndTimeUtc = request.EndTimeUtc;
        session.RoomName = request.RoomName.Trim();
        session.Latitude = request.Latitude;
        session.Longitude = request.Longitude;
        session.RadiusMeters = request.RadiusMeters;
        session.IsCancelled = request.IsCancelled;

        await _context.SaveChangesAsync();
        return Ok(new { message = "Cập nhật buổi học thành công" });
    }

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
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
