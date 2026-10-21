using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using phamlehuyhoang.Data;
using phamlehuyhoang.DTOs;
using phamlehuyhoang.Enums;
using phamlehuyhoang.Services;

namespace phamlehuyhoang.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AttendanceController : ControllerBase
{
    private readonly IAttendanceService _attendanceService;
    private readonly AppDbContext _context;

    public AttendanceController(IAttendanceService attendanceService, AppDbContext context)
    {
        _attendanceService = attendanceService;
        _context = context;
    }

    [HttpPost("qr/open")]
    [Authorize(Roles = $"{UserRole.Admin},{UserRole.Lecturer}")]
    public async Task<ActionResult<QrSessionDto>> OpenQrSession([FromBody] OpenQrSessionRequest request)
    {
        var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!Guid.TryParse(userIdStr, out var userId)) return Unauthorized();

        try
        {
            var qr = await _attendanceService.OpenOrRefreshQrSessionAsync(request.ClassSessionId, userId, request.LifetimeSeconds);
            return Ok(qr);
        }
        catch (UnauthorizedAccessException ex)
        {
            return Forbid(ex.Message);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("qr/close/{classSessionId}")]
    [Authorize(Roles = $"{UserRole.Admin},{UserRole.Lecturer}")]
    public async Task<IActionResult> CloseQrSession(Guid classSessionId)
    {
        var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!Guid.TryParse(userIdStr, out var userId)) return Unauthorized();

        await _attendanceService.CloseQrSessionAsync(classSessionId, userId);
        return Ok(new { message = "Đã đóng phiên điểm danh QR" });
    }

    [HttpGet("qr/active/{classSessionId}")]
    public async Task<ActionResult<QrSessionDto>> GetActiveQrSession(Guid classSessionId)
    {
        var now = DateTime.UtcNow;
        var qr = await _context.AttendanceQrSessions
            .Where(q => q.ClassSessionId == classSessionId && q.IsOpen && q.ExpiresAtUtc > now)
            .OrderByDescending(q => q.CreatedAtUtc)
            .FirstOrDefaultAsync();

        if (qr == null)
        {
            return NotFound(new { message = "Không có phiên QR nào đang hoạt động" });
        }

        int remaining = (int)Math.Max(0, (qr.ExpiresAtUtc - now).TotalSeconds);
        return Ok(new QrSessionDto(qr.Id, qr.ClassSessionId, qr.QrToken, qr.ExpiresAtUtc, qr.IsOpen, remaining));
    }

    [HttpPost("check-in")]
    [Authorize(Roles = UserRole.Student)]
    public async Task<ActionResult<CheckInResultDto>> CheckIn([FromBody] CheckInQrRequest request)
    {
        var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!Guid.TryParse(userIdStr, out var userId)) return Unauthorized();

        var result = await _attendanceService.ProcessQrCheckInAsync(userId, request);
        if (!result.Success)
        {
            return BadRequest(result);
        }

        return Ok(result);
    }

    [HttpPost("adjust")]
    [Authorize(Roles = $"{UserRole.Admin},{UserRole.Lecturer}")]
    public async Task<ActionResult<AttendanceRecordDto>> AdjustAttendance([FromBody] AdjustAttendanceRequest request)
    {
        var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!Guid.TryParse(userIdStr, out var userId)) return Unauthorized();

        try
        {
            var updated = await _attendanceService.AdjustAttendanceAsync(
                request.AttendanceRecordId,
                request.NewStatus,
                request.Reason,
                userId
            );
            return Ok(updated);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("session/{sessionId}/records")]
    [Authorize(Roles = $"{UserRole.Admin},{UserRole.Lecturer}")]
    public async Task<ActionResult<List<AttendanceRecordDto>>> GetSessionAttendance(Guid sessionId)
    {
        var records = await _context.AttendanceRecords
            .Include(r => r.Student)
            .Where(r => r.ClassSessionId == sessionId)
            .OrderBy(r => r.Student != null ? r.Student.FullName : "")
            .Select(r => new AttendanceRecordDto(
                r.Id,
                r.ClassSessionId,
                r.StudentId,
                r.Student != null ? r.Student.FullName : "N/A",
                r.Student != null ? r.Student.StudentCode : null,
                r.Status,
                r.CheckedInAtUtc,
                r.CheckInMethod,
                r.DistanceMeters,
                r.AccuracyMeters,
                r.Note
            ))
            .ToListAsync();

        return Ok(records);
    }

    [HttpGet("forecast/class/{courseClassId}")]
    [Authorize]
    public async Task<ActionResult<AttendanceForecastDto>> GetForecast(Guid courseClassId)
    {
        var role = User.FindFirstValue(ClaimTypes.Role);
        var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!Guid.TryParse(userIdStr, out var userId)) return Unauthorized();

        try
        {
            var forecast = await _attendanceService.GetStudentForecastAsync(courseClassId, userId);
            return Ok(forecast);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("forecast/my")]
    [Authorize(Roles = UserRole.Student)]
    public async Task<ActionResult<List<AttendanceForecastDto>>> GetMyForecasts()
    {
        var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!Guid.TryParse(userIdStr, out var userId)) return Unauthorized();

        var forecasts = await _attendanceService.GetAllForecastsForStudentAsync(userId);
        return Ok(forecasts);
    }
}
