using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using phamlehuyhoang.Enums;

namespace phamlehuyhoang.Entities;

public class AttendanceHistory
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid AttendanceRecordId { get; set; }

    [ForeignKey(nameof(AttendanceRecordId))]
    public AttendanceRecord? AttendanceRecord { get; set; }

    public AttendanceStatus OldStatus { get; set; }

    public AttendanceStatus NewStatus { get; set; }

    [Required]
    [MaxLength(250)]
    public string Reason { get; set; } = string.Empty;

    public Guid ChangedByUserId { get; set; }

    [ForeignKey(nameof(ChangedByUserId))]
    public User? ChangedByUser { get; set; }

    public DateTime ChangedAtUtc { get; set; } = DateTime.UtcNow;
}
