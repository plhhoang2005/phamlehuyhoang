using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using phamlehuyhoang.Data;
using phamlehuyhoang.Entities;

namespace phamlehuyhoang.Tests;

public class AdminProvisioningTests
{
    private static IConfiguration Config() => new ConfigurationBuilder().AddInMemoryCollection(
        new Dictionary<string, string?> { ["BootstrapAdmin:Username"] = "realadmin",
            ["BootstrapAdmin:Email"] = "admin@example.com", ["BootstrapAdmin:Password"] = "StrongPassword123!" }).Build();
    private static AppDbContext Database() => new(new DbContextOptionsBuilder<AppDbContext>()
        .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);
    private static Task Provision(AppDbContext db) => DbInitializer.EnsureConfiguredAdminAsync(db, Config());
    [Fact]
    public async Task NewAdmin_IsPendingEmailActivationAndRepeatStartupDoesNotDuplicate()
    {
        using var db = Database();
        await Provision(db); await Provision(db);
        var admin = Assert.Single(await db.Users.ToListAsync());
        Assert.Equal("Admin", admin.Role);
        Assert.False(admin.EmailConfirmed);
        Assert.NotEqual("StrongPassword123!", admin.PasswordHash);
    }
    [Fact]
    public async Task ExistingUsernameConflict_FailsClearlyWithoutOverwritingAccount()
    {
        using var db = Database();
        var original = new User { Username = "realadmin", Email = "old@example.com", PasswordHash = "original" };
        db.Add(original); await db.SaveChangesAsync();
        await Assert.ThrowsAsync<InvalidOperationException>(() => Provision(db));
        Assert.Equal("old@example.com", original.Email);
        Assert.Equal("Student", original.Role);
        Assert.Equal("original", original.PasswordHash);
    }
}
