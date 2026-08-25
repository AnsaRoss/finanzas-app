using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Finanzas.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddExpenseStatus : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "Estado",
                table: "Gastos",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateOnly>(
                name: "FechaPago",
                table: "Gastos",
                type: "date",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Estado",
                table: "Gastos");

            migrationBuilder.DropColumn(
                name: "FechaPago",
                table: "Gastos");
        }
    }
}
