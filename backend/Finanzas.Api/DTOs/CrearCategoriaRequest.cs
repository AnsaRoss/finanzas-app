using Finanzas.Api.Models;

namespace Finanzas.Api.DTOs;

public class CrearCategoriaRequest
{
    public long EspacioFinancieroId { get; set; }

    public string Nombre { get; set; } = string.Empty;

    public TipoCategoria Tipo { get; set; }
}