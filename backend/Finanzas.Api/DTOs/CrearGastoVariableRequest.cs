using Finanzas.Api.Models;

namespace Finanzas.Api.DTOs;

public class CrearGastoVariableRequest
{
    public long EspacioFinancieroId { get; set; }

    public long? CategoriaId { get; set; }

    public string Concepto { get; set; } = string.Empty;

    public decimal Valor { get; set; }

    public DateOnly Fecha { get; set; }

    public long? PagadoPorId { get; set; }

    public long? CuentaId { get; set; }

    public bool MarcarPagado { get; set; }

    public TipoRepartoGasto TipoReparto { get; set; } =
        TipoRepartoGasto.ReglaHogar;

    public long? ResponsableId { get; set; }

    public List<ReglaRepartoItemRequest>? Distribucion { get; set; }
    
    public string? Observacion { get; set; }
}
