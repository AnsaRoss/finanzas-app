using System.ComponentModel.DataAnnotations;

namespace Finanzas.Api.Models;

public class Categoria
{
    public long Id { get; set; }

    public long EspacioFinancieroId { get; set; }

    public EspacioFinanciero EspacioFinanciero { get; set; } = null!;

    [Required]
    [MaxLength(100)]
    public string Nombre { get; set; } = string.Empty;

    public TipoCategoria Tipo { get; set; }

    public bool Activo { get; set; } = true;
}

public enum TipoCategoria
{
    Ingreso = 1,
    Gasto = 2
}