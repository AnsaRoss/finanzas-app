namespace Finanzas.Api.DTOs;

public class AuthResponse
{
    public long UsuarioId { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Token { get; set; } = string.Empty;
}