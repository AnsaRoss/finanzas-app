using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Finanzas.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddFixedExpenseDistributionConfig : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "DistribucionPersonalizadaJson",
                table: "GastosFijos",
                type: "longtext",
                nullable: true);

            migrationBuilder.AddColumn<long>(
                name: "ResponsableId",
                table: "GastosFijos",
                type: "bigint",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "TipoReparto",
                table: "GastosFijos",
                type: "int",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.CreateIndex(
                name: "IX_GastosFijos_ResponsableId",
                table: "GastosFijos",
                column: "ResponsableId");

            migrationBuilder.AddForeignKey(
                name: "FK_GastosFijos_Usuarios_ResponsableId",
                table: "GastosFijos",
                column: "ResponsableId",
                principalTable: "Usuarios",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_GastosFijos_Usuarios_ResponsableId",
                table: "GastosFijos");

            migrationBuilder.DropIndex(
                name: "IX_GastosFijos_ResponsableId",
                table: "GastosFijos");

            migrationBuilder.DropColumn(
                name: "DistribucionPersonalizadaJson",
                table: "GastosFijos");

            migrationBuilder.DropColumn(
                name: "ResponsableId",
                table: "GastosFijos");

            migrationBuilder.DropColumn(
                name: "TipoReparto",
                table: "GastosFijos");
        }
    }
}
