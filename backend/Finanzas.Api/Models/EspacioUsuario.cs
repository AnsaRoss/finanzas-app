namespace Finanzas.Api.Models;

public class EspacioUsuario
{
    public long Id { get; set; }

    public long EspacioFinancieroId { get; set; }

    public EspacioFinanciero EspacioFinanciero { get; set; } = null!;

    public long UsuarioId { get; set; }

    public Usuario Usuario { get; set; } = null!;

    public RolEspacio Rol { get; set; } = RolEspacio.Miembro;

    public DateTime FechaUnion { get; set; } = DateTime.UtcNow;
}

public enum RolEspacio
{
    Propietario = 1,
    Miembro = 2
}