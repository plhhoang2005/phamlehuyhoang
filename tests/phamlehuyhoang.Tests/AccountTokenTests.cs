using System.Security.Claims;
using phamlehuyhoang.Entities;
using phamlehuyhoang.Services;
using Microsoft.EntityFrameworkCore;
using phamlehuyhoang.Controllers;
using phamlehuyhoang.Data;

namespace phamlehuyhoang.Tests;

public class AccountTokenTests
{
    [Theory]
    [InlineData("lock")]
    [InlineData("role")]
    [InlineData("email")]
    public async Task SecurityChanges_DoNotReviveTokenWhenValuesAreRestored(string change)
    {
        await using var db = new AppDbContext(new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);
        var user = new User { Username = "student", FullName = "Student", Email = "student@example.com", EmailConfirmed = true };
        db.Add(user); await db.SaveChangesAsync();
        var principal = Principal(user);
        var controller = new UsersController(db);
        if (change == "lock") { await controller.DeactivateUser(user.Id); await controller.DeactivateUser(user.Id); }
        else if (change == "role") {
            await controller.UpdateUser(user.Id, new(user.Email, user.FullName, "Lecturer", null, true));
            await controller.UpdateUser(user.Id, new(user.Email, user.FullName, "Student", null, true));
        } else {
            await controller.UpdateUser(user.Id, new("new@example.com", user.FullName, "Student", null, true));
            await controller.UpdateUser(user.Id, new("student@example.com", user.FullName, "Student", null, true));
            user.EmailConfirmed = true; await db.SaveChangesAsync();
        }
        Assert.True(user.IsActive);
        Assert.Equal("Student", user.Role);
        Assert.Equal("student@example.com", user.Email);
        Assert.False(AccountTokenValidator.MatchesCurrentAccount(user, principal));
    }
    [Fact]
    public void RestoringAccountState_DoesNotReviveAnOldToken()
    {
        var user = new User { Email = "student@example.com", Role = "Student", IsActive = true, EmailConfirmed = true };
        var principal = Principal(user);
        Assert.True(AccountTokenValidator.MatchesCurrentAccount(user, principal));
        // Lock/unlock or role change/back completes with identical visible account state.
        user.AuthVersion = 2;
        Assert.False(AccountTokenValidator.MatchesCurrentAccount(user, principal));
    }

    private static ClaimsPrincipal Principal(User user) => new(new ClaimsIdentity(new[] {
        new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
        new Claim(ClaimTypes.Role, "Student"), new Claim(ClaimTypes.Email, "student@example.com"),
        new Claim("auth_version", "0")
    }, "Bearer"));
    [Theory]
    [InlineData("Student", "student@example.com", true, true, true)]
    [InlineData("Admin", "student@example.com", true, true, false)]
    [InlineData("Student", "changed@example.com", true, true, false)]
    [InlineData("Student", "student@example.com", false, true, false)]
    [InlineData("Student", "student@example.com", true, false, false)]
    public void OldToken_LosesAccessWhenAccountOrPermissionsChange(
        string storedRole, string storedEmail, bool active, bool confirmed, bool expected)
    {
        var id = Guid.NewGuid();
        var user = new User { Id = id, Role = storedRole, Email = storedEmail,
            IsActive = active, EmailConfirmed = confirmed };
        var principal = new ClaimsPrincipal(new ClaimsIdentity(new[] {
            new Claim(ClaimTypes.NameIdentifier, id.ToString()),
            new Claim(ClaimTypes.Role, "Student"),
            new Claim(ClaimTypes.Email, "student@example.com"),
            new Claim("auth_version", "0")
        }, "Bearer"));
        Assert.Equal(expected, AccountTokenValidator.MatchesCurrentAccount(user, principal));
    }
}
