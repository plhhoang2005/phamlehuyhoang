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
public class CourseClassesController : ControllerBase
{
    private readonly AppDbContext _context;

    public CourseClassesController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<List<CourseClassDto>>> GetClasses()
    {
        var role = User.FindFirstValue(ClaimTypes.Role);
        var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!Guid.TryParse(userIdStr, out var userId)) return Unauthorized();
        if (role != UserRole.Admin && role != UserRole.Lecturer && role != UserRole.Student) return Forbid();

        var query = _context.CourseClasses
            .Include(c => c.Subject)
            .Include(c => c.Lecturer)
            .Include(c => c.Enrollments)
            .AsQueryable();

        // Phân quyền dữ liệu theo vai trò
        if (role == UserRole.Lecturer)
        {
            query = query.Where(c => c.LecturerId == userId);
        }
        else if (role == UserRole.Student)
        {
            query = query.Where(c => c.Enrollments.Any(e => e.StudentId == userId));
        }

        var classes = await query
            .OrderBy(c => c.Code)
            .Select(c => new CourseClassDto(
                c.Id,
                c.Code,
                c.SubjectId,
                c.Subject != null ? c.Subject.Code : "",
                c.Subject != null ? c.Subject.Name : "",
                c.LecturerId,
                c.Lecturer != null ? c.Lecturer.FullName : null,
                c.TotalSessions,
                c.MaxAbsencesAllowed,
                c.DefaultLatitude,
                c.DefaultLongitude,
                c.DefaultRadiusMeters,
                c.Enrollments.Count
            ))
            .ToListAsync();

        return Ok(classes);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<CourseClassDto>> GetClassById(Guid id)
    {
        var c = await _context.CourseClasses
            .Include(c => c.Subject)
            .Include(c => c.Lecturer)
            .Include(c => c.Enrollments)
            .FirstOrDefaultAsync(c => c.Id == id);

        if (c == null) return NotFound(new { message = "Lớp học phần không tồn tại" });
        if (!await ResourceAuthorization.CanReadClassAsync(_context, User, id)) return Forbid();

        return Ok(new CourseClassDto(
            c.Id,
            c.Code,
            c.SubjectId,
            c.Subject != null ? c.Subject.Code : "",
            c.Subject != null ? c.Subject.Name : "",
            c.LecturerId,
            c.Lecturer != null ? c.Lecturer.FullName : null,
            c.TotalSessions,
            c.MaxAbsencesAllowed,
            c.DefaultLatitude,
            c.DefaultLongitude,
            c.DefaultRadiusMeters,
            c.Enrollments.Count
        ));
    }

    [HttpPost]
    [Authorize(Roles = UserRole.Admin)]
    public async Task<ActionResult<CourseClassDto>> CreateClass([FromBody] CreateCourseClassRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Code) || request.Code.Trim().Length > 50 ||
            !await ValidClassSettings(request.LecturerId, request.TotalSessions, request.MaxAbsencesAllowed,
                request.DefaultLatitude, request.DefaultLongitude, request.DefaultRadiusMeters))
            return BadRequest(new { message = "Thông tin lớp, giảng viên, số buổi hoặc vị trí không hợp lệ" });
        var cleanCode = request.Code.Trim().ToUpperInvariant();
        if (await _context.CourseClasses.AnyAsync(c => c.Code == cleanCode))
        {
            return BadRequest(new { message = "Mã lớp học phần đã tồn tại" });
        }

        var subject = await _context.Subjects.FindAsync(request.SubjectId);
        if (subject == null) return BadRequest(new { message = "Môn học không tồn tại" });

        var newClass = new CourseClass
        {
            Id = Guid.NewGuid(),
            Code = cleanCode,
            SubjectId = request.SubjectId,
            LecturerId = request.LecturerId,
            TotalSessions = request.TotalSessions,
            MaxAbsencesAllowed = request.MaxAbsencesAllowed,
            DefaultLatitude = request.DefaultLatitude,
            DefaultLongitude = request.DefaultLongitude,
            DefaultRadiusMeters = request.DefaultRadiusMeters,
            CreatedAtUtc = DateTime.UtcNow
        };

        _context.CourseClasses.Add(newClass);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetClassById), new { id = newClass.Id }, new CourseClassDto(
            newClass.Id,
            newClass.Code,
            newClass.SubjectId,
            subject.Code,
            subject.Name,
            newClass.LecturerId,
            null,
            newClass.TotalSessions,
            newClass.MaxAbsencesAllowed,
            newClass.DefaultLatitude,
            newClass.DefaultLongitude,
            newClass.DefaultRadiusMeters,
            0
        ));
    }

    [HttpPut("{id}")]
    [Authorize(Roles = UserRole.Admin)]
    public async Task<IActionResult> UpdateClass(Guid id, [FromBody] UpdateCourseClassRequest request)
    {
        var courseClass = await _context.CourseClasses.FindAsync(id);
        if (courseClass == null) return NotFound(new { message = "Lớp học phần không tồn tại" });

        if (!await ValidClassSettings(request.LecturerId, request.TotalSessions, request.MaxAbsencesAllowed,
                request.DefaultLatitude, request.DefaultLongitude, request.DefaultRadiusMeters) ||
            await _context.ClassSessions.AnyAsync(s => s.CourseClassId == id && s.SessionNumber > request.TotalSessions))
            return BadRequest(new { message = "Giảng viên, số buổi hoặc vị trí không hợp lệ; số buổi phải bao gồm các buổi đã tạo" });

        var code = request.Code?.Trim().ToUpperInvariant() ?? courseClass.Code;
        var subjectId = request.SubjectId ?? courseClass.SubjectId;
        if (string.IsNullOrWhiteSpace(code) || code.Length > 50 ||
            await _context.CourseClasses.AnyAsync(c => c.Id != id && c.Code == code) ||
            !await _context.Subjects.AnyAsync(s => s.Id == subjectId))
            return BadRequest(new { message = "Mã lớp đã tồn tại hoặc môn học không hợp lệ" });

        courseClass.Code = code;
        courseClass.SubjectId = subjectId;
        courseClass.LecturerId = request.LecturerId;
        courseClass.TotalSessions = request.TotalSessions;
        courseClass.MaxAbsencesAllowed = request.MaxAbsencesAllowed;
        courseClass.DefaultLatitude = request.DefaultLatitude;
        courseClass.DefaultLongitude = request.DefaultLongitude;
        courseClass.DefaultRadiusMeters = request.DefaultRadiusMeters;

        await _context.SaveChangesAsync();
        return Ok(new { message = "Cập nhật lớp học phần thành công" });
    }

    private async Task<bool> ValidClassSettings(Guid? lecturerId, int total, int absences, double latitude, double longitude, double radius) =>
        total > 0 && absences >= 0 && absences <= total && ResourceAuthorization.ValidLocation(latitude, longitude, radius) &&
        (!lecturerId.HasValue || await _context.Users.AnyAsync(u => u.Id == lecturerId && u.Role == UserRole.Lecturer && u.IsActive));

    [HttpDelete("{id}")]
    [Authorize(Roles = UserRole.Admin)]
    public async Task<IActionResult> DeleteClass(Guid id)
    {
        await using var transaction = _context.Database.IsRelational()
            ? await _context.Database.BeginTransactionAsync(System.Data.IsolationLevel.Serializable) : null;
        var courseClass = await _context.CourseClasses.FindAsync(id);
        if (courseClass == null) return NotFound(new { message = "Lớp học phần không tồn tại" });
        var sessions = await _context.ClassSessions.Where(s => s.CourseClassId == id).ToListAsync();
        var sessionIds = sessions.Select(s => s.Id).ToList();
        if (sessions.Any(s => s.IsFinalized) || await _context.AttendanceRecords.AnyAsync(r => sessionIds.Contains(r.ClassSessionId)))
            return Conflict(new { message = "Không thể xóa lớp đã có lịch sử điểm danh hoặc buổi học đã chốt. Dữ liệu được giữ để bảo toàn lịch sử." });
        _context.AttendanceQrSessions.RemoveRange(await _context.AttendanceQrSessions.Where(q => sessionIds.Contains(q.ClassSessionId)).ToListAsync());
        _context.ClassEnrollments.RemoveRange(await _context.ClassEnrollments.Where(e => e.CourseClassId == id).ToListAsync());
        _context.ClassSessions.RemoveRange(sessions);
        _context.CourseClasses.Remove(courseClass);
        await _context.SaveChangesAsync();
        if (transaction != null) await transaction.CommitAsync();
        return Ok(new { message = "Đã xóa lớp học phần thành công" });
    }

    [HttpGet("{id}/students")]
    public async Task<ActionResult<List<EnrollmentDto>>> GetEnrolledStudents(Guid id)
    {
        if (!await _context.CourseClasses.AnyAsync(c => c.Id == id)) return NotFound(new { message = "Lớp học phần không tồn tại" });
        if (!await ResourceAuthorization.CanReadClassAsync(_context, User, id)) return Forbid();
        var query = _context.ClassEnrollments
            .Include(e => e.Student)
            .Where(e => e.CourseClassId == id);
        if (User.IsInRole(UserRole.Student))
        {
            var studentId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            query = query.Where(e => e.StudentId == studentId);
        }
        var enrollments = await query
            .OrderBy(e => e.Student != null ? e.Student.FullName : "")
            .Select(e => new EnrollmentDto(
                e.Id,
                e.StudentId,
                e.Student != null ? e.Student.FullName : "",
                e.Student != null ? e.Student.StudentCode : null,
                e.Student != null ? e.Student.Email : "",
                e.EnrolledAtUtc
            ))
            .ToListAsync();

        return Ok(enrollments);
    }

    [HttpPost("{id}/enroll")]
    [Authorize(Roles = UserRole.Admin)]
    public async Task<IActionResult> EnrollStudent(Guid id, [FromBody] EnrollStudentRequest request)
    {
        var courseClass = await _context.CourseClasses.FindAsync(id);
        if (courseClass == null) return NotFound(new { message = "Lớp học phần không tồn tại" });

        var student = await _context.Users.FindAsync(request.StudentId);
        if (student == null || student.Role != UserRole.Student || !student.IsActive)
        {
            return BadRequest(new { message = "Sinh viên không hợp lệ" });
        }

        var exists = await _context.ClassEnrollments
            .AnyAsync(e => e.CourseClassId == id && e.StudentId == request.StudentId);

        if (exists)
        {
            return BadRequest(new { message = "Sinh viên này đã có trong danh sách lớp" });
        }

        _context.ClassEnrollments.Add(new ClassEnrollment
        {
            Id = Guid.NewGuid(),
            CourseClassId = id,
            StudentId = request.StudentId,
            EnrolledAtUtc = DateTime.UtcNow
        });

        await _context.SaveChangesAsync();
        return Ok(new { message = "Ghi danh sinh viên vào lớp thành công" });
    }

    [HttpDelete("{id}/enroll/{studentId}")]
    [Authorize(Roles = UserRole.Admin)]
    public async Task<IActionResult> UnenrollStudent(Guid id, Guid studentId)
    {
        var enrollment = await _context.ClassEnrollments
            .FirstOrDefaultAsync(e => e.CourseClassId == id && e.StudentId == studentId);

        if (enrollment == null) return NotFound(new { message = "Sinh viên không thuộc lớp này" });

        _context.ClassEnrollments.Remove(enrollment);
        await _context.SaveChangesAsync();
        return Ok(new { message = "Đã xóa sinh viên khỏi lớp" });
    }
}
