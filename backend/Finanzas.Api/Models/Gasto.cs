using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Finanzas.Api.Models;

public class Gasto
{
    public long Id { get; set; }

    public long EspacioFinancieroId { get; set; }
    public EspacioFinanciero EspacioFinanciero { get; set; } = null!;

    public long? CategoriaId { get; set; }
    public Categoria? Categoria { get; set; }

    public long? GastoFijoId { get; set; }
    public GastoFijo? GastoFijo { get; set; }

    public long RegistradoPorId { get; set; }
    public Usuario RegistradoPor { get; set; } = null!;

    public long? PagadoPorId { get; set; }
    public Usuario? PagadoPor { get; set; }

    public long? CuentaId { get; set; }
    public Cuenta? Cuenta { get; set; }

    [Required]
    [MaxLength(200)]
    public string Concepto { get; set; } = string.Empty;

    public TipoGasto Tipo { get; set; }

    [Column(TypeName = "decimal(12,2)")]
    public decimal Valor { get; set; }

    public DateOnly Fecha { get; set; }

    public string? Observacion { get; set; }

    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;

    public ICollection<Devolucion> Devoluciones { get; set; } = [];
}

public enum TipoGasto
{
    Fijo = 1,
    Variable = 2
}