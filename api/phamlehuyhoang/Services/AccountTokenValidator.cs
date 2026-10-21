using System.Security.Claims;
using phamlehuyhoang.Entities;

namespace phamlehuyhoang.Services;

public static class AccountTokenValidator
{
    public static bool MatchesCurrentAccount(User? user, ClaimsPrincipal? principal) =>
        user is { IsActive: true, EmailConfirmed: true } && principal != null &&
        Guid.TryParse(principal.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var id) &&
        user.Id == id &&
        int.TryParse(principal.FindFirst("auth_version")?.Value, out var version) && user.AuthVersion == version &&
        string.Equals(user.Role, principal.FindFirst(ClaimTypes.Role)?.Value, StringComparison.Ordinal) &&
        string.Equals(user.Email, principal.FindFirst(ClaimTypes.Email)?.Value, StringComparison.OrdinalIgnoreCase);
}
