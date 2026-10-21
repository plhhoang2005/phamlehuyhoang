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
public class SubjectsController : ControllerBase
{
    private readonly AppDbContext _context;

    public SubjectsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<List<SubjectDto>>> GetSubjects()
    {
        var subjects = await _context.Subjects
            .OrderBy(s => s.Code)
            .Select(s => new SubjectDto(s.Id, s.Code, s.Name, s.Credits))
            .ToListAsync();

        return Ok(subjects);
    }

    [HttpPost]
    [Authorize(Roles = UserRole.Admin)]
    public async Task<ActionResult<SubjectDto>> CreateSubject([FromBody] CreateSubjectRequest request)
    {
        if (!ValidSubject(request)) return BadRequest(new { message = "Thông tin môn học không hợp lệ" });
        var cleanCode = request.Code.Trim().ToUpperInvariant();
        if (await _context.Subjects.AnyAsync(s => s.Code == cleanCode))
        {
            return BadRequest(new { message = "Mã môn học đã tồn tại" });
        }

        var subject = new Subject
        {
            Id = Guid.NewGuid(),
            Code = cleanCode,
            Name = request.Name.Trim(),
            Credits = request.Credits,
            CreatedAtUtc = DateTime.UtcNow
        };

        _context.Subjects.Add(subject);
        await _context.SaveChangesAsync();

        return Ok(new SubjectDto(subject.Id, subject.Code, subject.Name, subject.Credits));
    }

    [HttpPut("{id}")]
    [Authorize(Roles = UserRole.Admin)]
    public async Task<IActionResult> UpdateSubject(Guid id, [FromBody] CreateSubjectRequest request)
    {
        var subject = await _context.Subjects.FindAsync(id);
        if (subject == null) return NotFound(new { message = "Môn học không tồn tại" });
        if (!ValidSubject(request)) return BadRequest(new { message = "Thông tin môn học không hợp lệ" });
        var code = request.Code.Trim().ToUpperInvariant();
        if (await _context.Subjects.AnyAsync(s => s.Id != id && s.Code == code))
            return BadRequest(new { message = "Mã môn học đã tồn tại" });
        subject.Code = code;
        subject.Name = request.Name.Trim();
        subject.Credits = request.Credits;
        await _context.SaveChangesAsync();
        return Ok(new SubjectDto(subject.Id, subject.Code, subject.Name, subject.Credits));
    }

    private static bool ValidSubject(CreateSubjectRequest request) =>
        !string.IsNullOrWhiteSpace(request.Code) && request.Code.Trim().Length <= 20 &&
        !string.IsNullOrWhiteSpace(request.Name) && request.Name.Trim().Length <= 150 && request.Credits > 0;

    [HttpDelete("{id}")]
    [Authorize(Roles = UserRole.Admin)]
    public async Task<IActionResult> DeleteSubject(Guid id)
    {
        var subject = await _context.Subjects.FindAsync(id);
        if (subject == null) return NotFound(new { message = "Môn học không tồn tại" });

        var inUse = await _context.CourseClasses.AnyAsync(c => c.SubjectId == id);
        if (inUse)
        {
            return BadRequest(new { message = "Không thể xóa môn học này vì đã có lớp học phần đang sử dụng" });
        }

        _context.Subjects.Remove(subject);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Đã xóa môn học thành công" });
    }
}
