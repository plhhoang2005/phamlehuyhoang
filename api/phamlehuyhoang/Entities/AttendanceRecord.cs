using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using phamlehuyhoang.Enums;

namespace phamlehuyhoang.Entities;

public class AttendanceRecord
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid ClassSessionId { get; set; }

    [ForeignKey(nameof(ClassSessionId))]
    public ClassSession? ClassSession { get; set; }

    public Guid StudentId { get; set; }

    [ForeignKey(nameof(StudentId))]
    public User? Student { get; set; }

    public AttendanceStatus Status { get; set; } = AttendanceStatus.Present;

    public DateTime? CheckedInAtUtc { get; set; }

    [MaxLength(50)]
    public string CheckInMethod { get; set; } = "QrLocation";

    public double? StudentLatitude { get; set; }

    public double? StudentLongitude { get; set; }

    public double? DistanceMeters { get; set; }

    public double? AccuracyMeters { get; set; }

    [MaxLength(250)]
    public string? Note { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    public ICollection<AttendanceHistory> Histories { get; set; } = new List<AttendanceHistory>();
}
