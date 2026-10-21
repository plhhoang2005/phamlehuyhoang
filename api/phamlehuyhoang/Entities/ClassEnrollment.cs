using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace phamlehuyhoang.Entities;

public class ClassEnrollment
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid CourseClassId { get; set; }

    [ForeignKey(nameof(CourseClassId))]
    public CourseClass? CourseClass { get; set; }

    public Guid StudentId { get; set; }

    [ForeignKey(nameof(StudentId))]
    public User? Student { get; set; }

    public DateTime EnrolledAtUtc { get; set; } = DateTime.UtcNow;
}
