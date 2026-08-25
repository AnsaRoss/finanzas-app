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

    public DateOnly Fecha { get; set; } //fecha del gasto / mes / vencimiento generado.

    public DateOnly? FechaPago { get; set; } //cuándo realmente se pagó.

    public string? Observacion { get; set; }

    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
    
    public ICollection<Devolucion> Devoluciones { get; set; } = [];

    public ICollection<DistribucionGasto> Distribuciones { get; set; } = [];
    
    public EstadoGasto Estado { get; set; } = EstadoGasto.Pendiente;

    public TipoRepartoGasto TipoReparto { get; set; } = TipoRepartoGasto.ReglaHogar;

}

public enum TipoGasto
{
    Fijo = 1,
    Variable = 2
}

public enum EstadoGasto
{
    Pendiente = 1,
    Pagado = 2,
    Anulado = 3
}

public enum TipoRepartoGasto
{
    ReglaHogar = 1,
    Individual = 2,
    Personalizado = 3
}