using System.ComponentModel.DataAnnotations;

namespace Finanzas.Api.Models;

public class EspacioFinanciero
{
    public long Id { get; set; }

    [Required]
    [MaxLength(100)]
    public string Nombre { get; set; } = string.Empty;

    public TipoEspacio Tipo { get; set; }

    public long CreadoPorId { get; set; }

    public Usuario CreadoPor { get; set; } = null!;

    public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;

    public ICollection<EspacioUsuario> Usuarios { get; set; } = [];
}

public enum TipoEspacio
{
    Personal = 1,
    Hogar = 2
}