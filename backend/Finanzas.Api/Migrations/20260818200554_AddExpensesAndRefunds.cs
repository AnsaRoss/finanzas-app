using System;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Finanzas.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddExpensesAndRefunds : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Gastos",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    EspacioFinancieroId = table.Column<long>(type: "bigint", nullable: false),
                    CategoriaId = table.Column<long>(type: "bigint", nullable: true),
                    GastoFijoId = table.Column<long>(type: "bigint", nullable: true),
                    RegistradoPorId = table.Column<long>(type: "bigint", nullable: false),
                    PagadoPorId = table.Column<long>(type: "bigint", nullable: true),
                    CuentaId = table.Column<long>(type: "bigint", nullable: true),
                    Concepto = table.Column<string>(type: "varchar(200)", maxLength: 200, nullable: false)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    Tipo = table.Column<int>(type: "int", nullable: false),
                    Valor = table.Column<decimal>(type: "decimal(12,2)", precision: 12, scale: 2, nullable: false),
                    Fecha = table.Column<DateOnly>(type: "date", nullable: false),
                    Observacion = table.Column<string>(type: "longtext", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    FechaCreacion = table.Column<DateTime>(type: "datetime(6)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Gastos", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Gastos_Categorias_CategoriaId",
                        column: x => x.CategoriaId,
                        principalTable: "Categorias",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Gastos_Cuentas_CuentaId",
                        column: x => x.CuentaId,
                        principalTable: "Cuentas",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Gastos_EspaciosFinancieros_EspacioFinancieroId",
                        column: x => x.EspacioFinancieroId,
                        principalTable: "EspaciosFinancieros",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Gastos_GastosFijos_GastoFijoId",
                        column: x => x.GastoFijoId,
                        principalTable: "GastosFijos",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Gastos_Usuarios_PagadoPorId",
                        column: x => x.PagadoPorId,
                        principalTable: "Usuarios",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Gastos_Usuarios_RegistradoPorId",
                        column: x => x.RegistradoPorId,
                        principalTable: "Usuarios",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateTable(
                name: "Devoluciones",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("MySql:ValueGenerationStrategy", MySqlValueGenerationStrategy.IdentityColumn),
                    GastoId = table.Column<long>(type: "bigint", nullable: false),
                    DebeUsuarioId = table.Column<long>(type: "bigint", nullable: true),
                    RecibeUsuarioId = table.Column<long>(type: "bigint", nullable: true),
                    RecibeCuentaId = table.Column<long>(type: "bigint", nullable: true),
                    Valor = table.Column<decimal>(type: "decimal(12,2)", precision: 12, scale: 2, nullable: false),
                    ValorPagado = table.Column<decimal>(type: "decimal(12,2)", precision: 12, scale: 2, nullable: false),
                    Estado = table.Column<int>(type: "int", nullable: false),
                    FechaPago = table.Column<DateOnly>(type: "date", nullable: true),
                    Observacion = table.Column<string>(type: "longtext", nullable: true)
                        .Annotation("MySql:CharSet", "utf8mb4"),
                    FechaCreacion = table.Column<DateTime>(type: "datetime(6)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Devoluciones", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Devoluciones_Cuentas_RecibeCuentaId",
                        column: x => x.RecibeCuentaId,
                        principalTable: "Cuentas",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Devoluciones_Gastos_GastoId",
                        column: x => x.GastoId,
                        principalTable: "Gastos",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Devoluciones_Usuarios_DebeUsuarioId",
                        column: x => x.DebeUsuarioId,
                        principalTable: "Usuarios",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Devoluciones_Usuarios_RecibeUsuarioId",
                        column: x => x.RecibeUsuarioId,
                        principalTable: "Usuarios",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                })
                .Annotation("MySql:CharSet", "utf8mb4");

            migrationBuilder.CreateIndex(
                name: "IX_Devoluciones_DebeUsuarioId",
                table: "Devoluciones",
                column: "DebeUsuarioId");

            migrationBuilder.CreateIndex(
                name: "IX_Devoluciones_GastoId",
                table: "Devoluciones",
                column: "GastoId");

            migrationBuilder.CreateIndex(
                name: "IX_Devoluciones_RecibeCuentaId",
                table: "Devoluciones",
                column: "RecibeCuentaId");

            migrationBuilder.CreateIndex(
                name: "IX_Devoluciones_RecibeUsuarioId",
                table: "Devoluciones",
                column: "RecibeUsuarioId");

            migrationBuilder.CreateIndex(
                name: "IX_Gastos_CategoriaId",
                table: "Gastos",
                column: "CategoriaId");

            migrationBuilder.CreateIndex(
                name: "IX_Gastos_CuentaId",
                table: "Gastos",
                column: "CuentaId");

            migrationBuilder.CreateIndex(
                name: "IX_Gastos_EspacioFinancieroId",
                table: "Gastos",
                column: "EspacioFinancieroId");

            migrationBuilder.CreateIndex(
                name: "IX_Gastos_GastoFijoId",
                table: "Gastos",
                column: "GastoFijoId");

            migrationBuilder.CreateIndex(
                name: "IX_Gastos_PagadoPorId",
                table: "Gastos",
                column: "PagadoPorId");

            migrationBuilder.CreateIndex(
                name: "IX_Gastos_RegistradoPorId",
                table: "Gastos",
                column: "RegistradoPorId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Devoluciones");

            migrationBuilder.DropTable(
                name: "Gastos");
        }
    }
}
