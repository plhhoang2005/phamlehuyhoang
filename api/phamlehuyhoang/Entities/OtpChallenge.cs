using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace phamlehuyhoang.Entities;

public class OtpChallenge
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required]
    [MaxLength(100)]
    public string Ticket { get; set; } = string.Empty;

    public Guid UserId { get; set; }

    [ForeignKey(nameof(UserId))]
    public User? User { get; set; }

    [Required]
    [MaxLength(6)]
    public string Code { get; set; } = string.Empty;

    [Required]
    [MaxLength(30)]
    public string Purpose { get; set; } = "Login";

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    public DateTime ExpiresAtUtc { get; set; }

    public int AttemptCount { get; set; } = 0;

    public bool IsUsed { get; set; } = false;

    public DateTime LastSentAtUtc { get; set; } = DateTime.UtcNow;
}
