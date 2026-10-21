using System.ComponentModel.DataAnnotations;

namespace phamlehuyhoang.Entities;

public class Subject
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required]
    [MaxLength(20)]
    public string Code { get; set; } = string.Empty;

    [Required]
    [MaxLength(150)]
    public string Name { get; set; } = string.Empty;

    public int Credits { get; set; } = 3;

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}
