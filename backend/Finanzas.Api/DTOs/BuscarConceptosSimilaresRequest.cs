namespace Finanzas.Api.DTOs;

public class BuscarConceptosSimilaresRequest
{
    public long EspacioFinancieroId { get; set; }

    public string Concepto { get; set; } = string.Empty;
}