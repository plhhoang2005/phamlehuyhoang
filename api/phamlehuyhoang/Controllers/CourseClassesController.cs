using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using phamlehuyhoang.Data;
using phamlehuyhoang.DTOs;
using phamlehuyhoang.Entities;
using phamlehuyhoang.Enums;

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
        Guid.TryParse(userIdStr, out var userId);

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
            TotalSessions = request.TotalSessions > 0 ? request.TotalSessions : 15,
            MaxAbsencesAllowed = request.MaxAbsencesAllowed >= 0 ? request.MaxAbsencesAllowed : 3,
            DefaultLatitude = request.DefaultLatitude,
            DefaultLongitude = request.DefaultLongitude,
            DefaultRadiusMeters = request.DefaultRadiusMeters > 0 ? request.DefaultRadiusMeters : 100.0,
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

        courseClass.LecturerId = request.LecturerId;
        courseClass.TotalSessions = request.TotalSessions;
        courseClass.MaxAbsencesAllowed = request.MaxAbsencesAllowed;
        courseClass.DefaultLatitude = request.DefaultLatitude;
        courseClass.DefaultLongitude = request.DefaultLongitude;
        courseClass.DefaultRadiusMeters = request.DefaultRadiusMeters;

        await _context.SaveChangesAsync();
        return Ok(new { message = "Cập nhật lớp học phần thành công" });
    }

    [HttpGet("{id}/students")]
    public async Task<ActionResult<List<EnrollmentDto>>> GetEnrolledStudents(Guid id)
    {
        var enrollments = await _context.ClassEnrollments
            .Include(e => e.Student)
            .Where(e => e.CourseClassId == id)
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
        if (student == null || student.Role != UserRole.Student)
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
