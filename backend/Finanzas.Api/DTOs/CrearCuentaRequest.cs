using Finanzas.Api.Models;

namespace Finanzas.Api.DTOs;

public class CrearCuentaRequest
{
    public long EspacioFinancieroId { get; set; }

    public long? PropietarioId { get; set; }

    public long? EntidadFinancieraId { get; set; }

    public string Nombre { get; set; } = string.Empty;

    public TipoCuenta Tipo { get; set; }
}