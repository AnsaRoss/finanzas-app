using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Finanzas.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddExpenseDistributionType : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "TipoReparto",
                table: "Gastos",
                type: "int",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "TipoReparto",
                table: "Gastos");
        }
    }
}
