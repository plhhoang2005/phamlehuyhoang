using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace phamlehuyhoang.Migrations
{
    /// <inheritdoc />
    public partial class RevokeChangedAccountSessions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "AuthVersion",
                table: "Users",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AuthVersion",
                table: "Users");
        }
    }
}
