using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace phamlehuyhoang.Entities;

public class ClassSession
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid CourseClassId { get; set; }

    [ForeignKey(nameof(CourseClassId))]
    public CourseClass? CourseClass { get; set; }

    public int SessionNumber { get; set; } = 1;

    [Required]
    [MaxLength(150)]
    public string Title { get; set; } = string.Empty;

    public DateTime StartTimeUtc { get; set; }

    public DateTime EndTimeUtc { get; set; }

    [MaxLength(50)]
    public string RoomName { get; set; } = "Phòng A.101";

    public double Latitude { get; set; } = 10.762622;

    public double Longitude { get; set; } = 106.682333;

    public double RadiusMeters { get; set; } = 100.0;

    public bool IsCancelled { get; set; } = false;

    // Chốt kết quả buổi học
    public bool IsFinalized { get; set; } = false;

    public DateTime? FinalizedAtUtc { get; set; }

    public Guid? FinalizedByUserId { get; set; }

    public ICollection<AttendanceQrSession> QrSessions { get; set; } = new List<AttendanceQrSession>();

    public ICollection<AttendanceRecord> AttendanceRecords { get; set; } = new List<AttendanceRecord>();
}
