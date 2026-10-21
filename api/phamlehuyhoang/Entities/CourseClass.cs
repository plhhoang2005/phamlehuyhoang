using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace phamlehuyhoang.Entities;

public class CourseClass
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required]
    [MaxLength(50)]
    public string Code { get; set; } = string.Empty;

    public Guid SubjectId { get; set; }

    [ForeignKey(nameof(SubjectId))]
    public Subject? Subject { get; set; }

    public Guid? LecturerId { get; set; }

    [ForeignKey(nameof(LecturerId))]
    public User? Lecturer { get; set; }

    // N: Tổng số buổi chính thức (mặc định 15)
    public int TotalSessions { get; set; } = 15;

    // L: Số buổi được phép vắng tối đa (mặc định 3)
    public int MaxAbsencesAllowed { get; set; } = 3;

    public double DefaultLatitude { get; set; } = 10.762622; // Ví dụ vị trí ĐHQG / Trường

    public double DefaultLongitude { get; set; } = 106.682333;

    public double DefaultRadiusMeters { get; set; } = 100.0; // 100 mét mặc định

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    public ICollection<ClassEnrollment> Enrollments { get; set; } = new List<ClassEnrollment>();

    public ICollection<ClassSession> Sessions { get; set; } = new List<ClassSession>();
}
