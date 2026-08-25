using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Finanzas.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddExpenseDistribution : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "DistribucionesGasto",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    GastoId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioId = table.Column<long>(type: "bigint", nullable: false),
                    Porcentaje = table.Column<decimal>(type: "decimal(5,2)", precision: 5, scale: 2, nullable: false),
                    Valor = table.Column<decimal>(type: "decimal(12,2)", precision: 12, scale: 2, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DistribucionesGasto", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DistribucionesGasto_Gastos_GastoId",
                        column: x => x.GastoId,
                        principalTable: "Gastos",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_DistribucionesGasto_Usuarios_UsuarioId",
                        column: x => x.UsuarioId,
                        principalTable: "Usuarios",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "ReglasReparto",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    EspacioFinancieroId = table.Column<long>(type: "bigint", nullable: false),
                    UsuarioId = table.Column<long>(type: "bigint", nullable: false),
                    Porcentaje = table.Column<decimal>(type: "decimal(5,2)", precision: 5, scale: 2, nullable: false),
                    Activo = table.Column<bool>(type: "tinyint(1)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ReglasReparto", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ReglasReparto_EspaciosFinancieros_EspacioFinancieroId",
                        column: x => x.EspacioFinancieroId,
                        principalTable: "EspaciosFinancieros",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ReglasReparto_Usuarios_UsuarioId",
                        column: x => x.UsuarioId,
                        principalTable: "Usuarios",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "IX_DistribucionesGasto_GastoId_UsuarioId",
                table: "DistribucionesGasto",
                columns: new[] { "GastoId", "UsuarioId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_DistribucionesGasto_UsuarioId",
                table: "DistribucionesGasto",
                column: "UsuarioId");

            migrationBuilder.CreateIndex(
                name: "IX_ReglasReparto_EspacioFinancieroId_UsuarioId",
                table: "ReglasReparto",
                columns: new[] { "EspacioFinancieroId", "UsuarioId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ReglasReparto_UsuarioId",
                table: "ReglasReparto",
                column: "UsuarioId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DistribucionesGasto");

            migrationBuilder.DropTable(
                name: "ReglasReparto");
        }
    }
}
