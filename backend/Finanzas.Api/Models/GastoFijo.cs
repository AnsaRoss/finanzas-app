using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Finanzas.Api.Models;

public class GastoFijo
{
    public long Id { get; set; }

    public long EspacioFinancieroId { get; set; }

    public EspacioFinanciero EspacioFinanciero { get; set; } = null!;

    public long? CategoriaId { get; set; }

    public Categoria? Categoria { get; set; }

    public long? ResponsableId { get; set; }

    public Usuario? Responsable { get; set; }

    [Required]
    [MaxLength(200)]
    public string Concepto { get; set; } = string.Empty;

    [Column(TypeName = "decimal(12,2)")]
    public decimal? ValorEstimado { get; set; }

    public byte? DiaVencimiento { get; set; }

    public TipoRepartoGasto TipoReparto { get; set; } =
        TipoRepartoGasto.ReglaHogar;

    public string? DistribucionPersonalizadaJson { get; set; }

    public bool Activo { get; set; } = true;

    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
}
