namespace Finanzas.Api.DTOs;

public class GuardarReglasRepartoRequest
{
    public List<ReglaRepartoItemRequest> Distribuciones { get; set; } = [];
}

public class ReglaRepartoItemRequest
{
    public long UsuarioId { get; set; }

    public decimal Porcentaje { get; set; }
}