using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace phamlehuyhoang.Entities;

public class AttendanceQrSession
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid ClassSessionId { get; set; }

    [ForeignKey(nameof(ClassSessionId))]
    public ClassSession? ClassSession { get; set; }

    [Required]
    [MaxLength(100)]
    public string QrToken { get; set; } = string.Empty;

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    public DateTime ExpiresAtUtc { get; set; }

    public bool IsOpen { get; set; } = true;
}
