using Finanzas.Api.Models;

namespace Finanzas.Api.DTOs;

public class CrearGastoFijoRequest
{
    public long EspacioFinancieroId { get; set; }

    public long? CategoriaId { get; set; }

    public string Concepto { get; set; } = string.Empty;

    public decimal? ValorEstimado { get; set; }

    public byte? DiaVencimiento { get; set; }

    public TipoRepartoGasto TipoReparto { get; set; } =
        TipoRepartoGasto.ReglaHogar;

    public long? ResponsableId { get; set; }

    public List<ReglaRepartoItemRequest> Distribucion { get; set; } = [];
}
