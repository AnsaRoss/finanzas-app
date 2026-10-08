using System.Security.Claims;
using Finanzas.Api.Data;
using Finanzas.Api.DTOs;
using Finanzas.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Finanzas.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class EspaciosController : ControllerBase
{
    private readonly AppDbContext _context;

    public EspaciosController(AppDbContext context)
    {
        _context = context;
    }

    private long GetUsuarioId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? User.FindFirstValue("sub");

        if (!long.TryParse(sub, out var usuarioId))
        {
            throw new UnauthorizedAccessException();
        }

        return usuarioId;
    }

    [HttpGet]
    public async Task<IActionResult> GetMisEspacios()
    {
        var usuarioId = GetUsuarioId();

        var espacios = await _context.EspaciosUsuarios
            .Where(x => x.UsuarioId == usuarioId)
            .Select(x => new
            {
                x.EspacioFinanciero.Id,
                x.EspacioFinanciero.Nombre,
                x.EspacioFinanciero.Tipo,
                Rol = x.Rol
            })
            .ToListAsync();

        return Ok(espacios);
    }

    [HttpPost("hogar")]
    public async Task<IActionResult> CrearHogar(
        CrearHogarRequest request)
    {
        var usuarioId = GetUsuarioId();

        if (string.IsNullOrWhiteSpace(request.Nombre))
        {
            return BadRequest("El nombre del hogar es obligatorio.");
        }

        var hogar = new EspacioFinanciero
        {
            Nombre = request.Nombre.Trim(),
            Tipo = TipoEspacio.Hogar,
            CreadoPorId = usuarioId
        };

        _context.EspaciosFinancieros.Add(hogar);
        await _context.SaveChangesAsync();

        _context.EspaciosUsuarios.Add(new EspacioUsuario
        {
            EspacioFinancieroId = hogar.Id,
            UsuarioId = usuarioId,
            Rol = RolEspacio.Propietario
        });

        await _context.SaveChangesAsync();

        return Ok(new
        {
            hogar.Id,
            hogar.Nombre,
            hogar.Tipo
        });
    }

    [HttpPost("{id:long}/miembros")]
    public async Task<IActionResult> AgregarMiembro(
        long id,
        AgregarMiembroRequest request)
    {
        var usuarioId = GetUsuarioId();

        var membresiaActual = await _context.EspaciosUsuarios
            .FirstOrDefaultAsync(x =>
                x.EspacioFinancieroId == id &&
                x.UsuarioId == usuarioId);

        if (membresiaActual is null ||
            membresiaActual.Rol != RolEspacio.Propietario)
        {
            return Forbid();
        }

        var espacio = await _context.EspaciosFinancieros
            .FirstOrDefaultAsync(x => x.Id == id);

        if (espacio is null)
        {
            return NotFound("Espacio no encontrado.");
        }

        if (espacio.Tipo != TipoEspacio.Hogar)
        {
            return BadRequest(
                "Solo se pueden agregar miembros a un hogar."
            );
        }

        var email = request.Email.Trim().ToLowerInvariant();

        var usuario = await _context.Usuarios
            .FirstOrDefaultAsync(x => x.Email == email);

        if (usuario is null)
        {
            return NotFound(
                "No existe un usuario registrado con ese correo."
            );
        }

        var yaExiste = await _context.EspaciosUsuarios
            .AnyAsync(x =>
                x.EspacioFinancieroId == id &&
                x.UsuarioId == usuario.Id);

        if (yaExiste)
        {
            return BadRequest(
                "El usuario ya pertenece a este hogar."
            );
        }

        _context.EspaciosUsuarios.Add(new EspacioUsuario
        {
            EspacioFinancieroId = id,
            UsuarioId = usuario.Id,
            Rol = RolEspacio.Miembro
        });

        await _context.SaveChangesAsync();

        return Ok(new
        {
            usuario.Id,
            usuario.Nombre,
            usuario.Email
        });
    }

    [HttpGet("{id:long}/miembros")]
    public async Task<IActionResult> GetMiembros(long id)
    {
        var usuarioId = GetUsuarioId();

        var pertenece = await _context.EspaciosUsuarios
            .AnyAsync(x =>
                x.EspacioFinancieroId == id &&
                x.UsuarioId == usuarioId);

        if (!pertenece)
        {
            return Forbid();
        }

        var espacio = await _context.EspaciosFinancieros
            .FirstOrDefaultAsync(x => x.Id == id);

        if (espacio is null)
        {
            return NotFound("Espacio no encontrado.");
        }

        if (espacio.Tipo != TipoEspacio.Hogar)
        {
            return BadRequest(
                "Los miembros solo aplican a espacios de tipo Hogar."
            );
        }

        var miembros = await _context.EspaciosUsuarios
            .Where(x => x.EspacioFinancieroId == id)
            .OrderBy(x => x.Usuario.Nombre)
            .Select(x => new
            {
                usuarioId = x.UsuarioId,
                nombre = x.Usuario.Nombre,
                email = x.Usuario.Email,
                rol = x.Rol
            })
            .ToListAsync();

        return Ok(miembros);
    }
}
