using System.ComponentModel.DataAnnotations.Schema;

namespace Finanzas.Api.Models;

public class Devolucion
{
    public long Id { get; set; }

    public long GastoId { get; set; }
    public Gasto Gasto { get; set; } = null!;

    // Persona que debe devolver el dinero.
    public long? DebeUsuarioId { get; set; }
    public Usuario? DebeUsuario { get; set; }

    // Puede devolver a una persona...
    public long? RecibeUsuarioId { get; set; }
    public Usuario? RecibeUsuario { get; set; }

    // ...o directamente a una cuenta/tarjeta.
    public long? RecibeCuentaId { get; set; }
    public Cuenta? RecibeCuenta { get; set; }

    [Column(TypeName = "decimal(12,2)")]
    public decimal Valor { get; set; }

    [Column(TypeName = "decimal(12,2)")]
    public decimal ValorPagado { get; set; }

    public EstadoDevolucion Estado { get; set; } = EstadoDevolucion.Pendiente;

    public DateOnly? FechaPago { get; set; }

    public string? Observacion { get; set; }

    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
}

public enum EstadoDevolucion
{
    Pendiente = 1,
    Parcial = 2,
    Pagada = 3
}