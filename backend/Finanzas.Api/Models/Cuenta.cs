using System.ComponentModel.DataAnnotations;

namespace Finanzas.Api.Models;

public class Cuenta
{
    public long Id { get; set; }

    public long EspacioFinancieroId { get; set; }

    public EspacioFinanciero EspacioFinanciero { get; set; } = null!;

    public long? PropietarioId { get; set; }

    public Usuario? Propietario { get; set; }

    public long? EntidadFinancieraId { get; set; }

    public EntidadFinanciera? EntidadFinanciera { get; set; }

    [Required]
    [MaxLength(100)]
    public string Nombre { get; set; } = string.Empty;

    public TipoCuenta Tipo { get; set; }

    public bool Activo { get; set; } = true;
}

public enum TipoCuenta
{
    Efectivo = 1,
    CuentaAhorros = 2,
    CuentaCorriente = 3,
    TarjetaCredito = 4,
    Otro = 5
}