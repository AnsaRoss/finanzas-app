namespace Finanzas.Api.DTOs;

public class CrearIngresoRequest
{
    public long EspacioFinancieroId { get; set; }
    public long UsuarioId { get; set; }
    public long? CategoriaId { get; set; }
    public long? CuentaId { get; set; }

    public string Concepto { get; set; } = string.Empty;

    public decimal Valor { get; set; }

    public DateOnly Fecha { get; set; }

    public string? Observacion { get; set; }
}