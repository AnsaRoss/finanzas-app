using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Finanzas.Api.Models;

public class DistribucionGasto
{
    public long Id { get; set; }

    public long GastoId { get; set; }
    public Gasto Gasto { get; set; } = null!;

    public long UsuarioId { get; set; }
    public Usuario Usuario { get; set; } = null!;

    public decimal Porcentaje { get; set; }

    public decimal Valor { get; set; }
}