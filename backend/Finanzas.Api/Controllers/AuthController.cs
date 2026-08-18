using Finanzas.Api.Data;
using Finanzas.Api.DTOs;
using Finanzas.Api.Models;
using Finanzas.Api.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Finanzas.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly TokenService _tokenService;

    public AuthController(
        AppDbContext context,
        TokenService tokenService)
    {
        _context = context;
        _tokenService = tokenService;
    }

    [HttpPost("register")]
    public async Task<ActionResult<AuthResponse>> Register(
        RegisterRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();

        var existe = await _context.Usuarios
            .AnyAsync(x => x.Email == email);

        if (existe)
        {
            return BadRequest("El correo ya está registrado.");
        }

        var usuario = new Usuario
        {
            Nombre = request.Nombre.Trim(),
            Email = email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password)
        };

        _context.Usuarios.Add(usuario);

        await _context.SaveChangesAsync();

        var espacioPersonal = new EspacioFinanciero
        {
            Nombre = $"Personal - {usuario.Nombre}",
            Tipo = TipoEspacio.Personal,
            CreadoPorId = usuario.Id
        };

        _context.EspaciosFinancieros.Add(espacioPersonal);

        await _context.SaveChangesAsync();

        var espacioUsuario = new EspacioUsuario
        {
            EspacioFinancieroId = espacioPersonal.Id,
            UsuarioId = usuario.Id,
            Rol = RolEspacio.Propietario
        };

        _context.EspaciosUsuarios.Add(espacioUsuario);

        await _context.SaveChangesAsync();

        return Ok(new AuthResponse
        {
            UsuarioId = usuario.Id,
            Nombre = usuario.Nombre,
            Email = usuario.Email,
            Token = _tokenService.CreateToken(usuario)
        });
    }

    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login(
        LoginRequest request)
    {
        var email = request.Email.Trim().ToLowerInvariant();

        var usuario = await _context.Usuarios
            .FirstOrDefaultAsync(x =>
                x.Email == email &&
                x.Activo);

        if (usuario is null)
        {
            return Unauthorized("Credenciales incorrectas.");
        }

        var passwordValido =
            BCrypt.Net.BCrypt.Verify(
                request.Password,
                usuario.PasswordHash
            );

        if (!passwordValido)
        {
            return Unauthorized("Credenciales incorrectas.");
        }

        return Ok(new AuthResponse
        {
            UsuarioId = usuario.Id,
            Nombre = usuario.Nombre,
            Email = usuario.Email,
            Token = _tokenService.CreateToken(usuario)
        });
    }
}