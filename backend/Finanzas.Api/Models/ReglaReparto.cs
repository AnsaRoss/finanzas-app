using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Finanzas.Api.Models;

public class ReglaReparto
{
    public long Id { get; set; }

    public long EspacioFinancieroId { get; set; }
    public EspacioFinanciero EspacioFinanciero { get; set; } = null!;

    public long UsuarioId { get; set; }
    public Usuario Usuario { get; set; } = null!;

    public decimal Porcentaje { get; set; }

    public bool Activo { get; set; } = true;
}