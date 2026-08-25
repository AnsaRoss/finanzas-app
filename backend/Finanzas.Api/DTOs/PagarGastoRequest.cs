namespace Finanzas.Api.DTOs;

public class PagarGastoRequest
{
    public long PagadoPorId { get; set; }

    public long? CuentaId { get; set; }

    public DateOnly FechaPago { get; set; }
}