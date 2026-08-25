namespace Finanzas.Api.DTOs;

public class GenerarGastoFijoRequest
{
    public decimal? Valor { get; set; }

    public DateOnly Fecha { get; set; }

    public string? Observacion { get; set; }
}