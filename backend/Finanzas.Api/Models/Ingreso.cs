using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Finanzas.Api.Models;

public class Ingreso
{
    public long Id { get; set; }

    public long EspacioFinancieroId { get; set; }

    public EspacioFinanciero EspacioFinanciero { get; set; } = null!;

    public long UsuarioId { get; set; }

    public Usuario Usuario { get; set; } = null!;

    public long? CategoriaId { get; set; }

    public Categoria? Categoria { get; set; }

    public long? CuentaId { get; set; }

    public Cuenta? Cuenta { get; set; }

    [Required]
    [MaxLength(200)]
    public string Concepto { get; set; } = string.Empty;

    [Column(TypeName = "decimal(12,2)")]
    public decimal Valor { get; set; }

    [Column(TypeName = "decimal(5,2)")]
    public decimal PorcentajeAporte { get; set; }

    public DateOnly Fecha { get; set; }

    public string? Observacion { get; set; }

    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
}