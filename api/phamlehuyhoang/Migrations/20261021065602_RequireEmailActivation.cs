using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace phamlehuyhoang.Migrations
{
    /// <inheritdoc />
    public partial class RequireEmailActivation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Code",
                table: "OtpChallenges");

            migrationBuilder.AddColumn<bool>(
                name: "EmailConfirmed",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "CodeHash",
                table: "OtpChallenges",
                type: "character varying(64)",
                maxLength: 64,
                nullable: false,
                defaultValue: "");
            // Các mã từ luồng dev cũ không còn hợp lệ; giữ nguyên tài khoản và dữ liệu học tập.
            migrationBuilder.Sql("UPDATE \"OtpChallenges\" SET \"IsUsed\" = TRUE;");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "EmailConfirmed",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "CodeHash",
                table: "OtpChallenges");

            migrationBuilder.AddColumn<string>(
                name: "Code",
                table: "OtpChallenges",
                type: "character varying(6)",
                maxLength: 6,
                nullable: false,
                defaultValue: "");
        }
    }
}
