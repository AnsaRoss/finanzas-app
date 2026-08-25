namespace Finanzas.Api.DTOs;

public class PagarDevolucionRequest
{
    public decimal Valor { get; set; }

    public DateOnly FechaPago { get; set; }
}