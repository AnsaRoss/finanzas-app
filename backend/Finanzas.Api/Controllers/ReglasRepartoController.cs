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
public class ReglasRepartoController : ControllerBase
{
    private readonly AppDbContext _context;

    public ReglasRepartoController(AppDbContext context)
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

    [HttpGet("espacio/{espacioId:long}")]
    public async Task<IActionResult> GetPorEspacio(long espacioId)
    {
        var usuarioId = GetUsuarioId();

        var pertenece = await _context.EspaciosUsuarios
            .AnyAsync(x =>
                x.EspacioFinancieroId == espacioId &&
                x.UsuarioId == usuarioId);

        if (!pertenece)
        {
            return Forbid();
        }

        var reglas = await _context.ReglasReparto
            .Where(x =>
                x.EspacioFinancieroId == espacioId &&
                x.Activo)
            .OrderBy(x => x.Usuario.Nombre)
            .Select(x => new
            {
                x.UsuarioId,
                Usuario = x.Usuario.Nombre,
                x.Porcentaje
            })
            .ToListAsync();

        return Ok(reglas);
    }

    [HttpPut("espacio/{espacioId:long}")]
    public async Task<IActionResult> Guardar(
        long espacioId,
        GuardarReglasRepartoRequest request)
    {
        var usuarioId = GetUsuarioId();

        var membresia = await _context.EspaciosUsuarios
            .FirstOrDefaultAsync(x =>
                x.EspacioFinancieroId == espacioId &&
                x.UsuarioId == usuarioId);

        if (membresia is null)
        {
            return Forbid();
        }

        // Por ahora solo el propietario configura el reparto.
        if (membresia.Rol != RolEspacio.Propietario)
        {
            return Forbid();
        }

        var espacio = await _context.EspaciosFinancieros
            .FirstOrDefaultAsync(x => x.Id == espacioId);

        if (espacio is null)
        {
            return NotFound("Espacio financiero no encontrado.");
        }

        if (espacio.Tipo != TipoEspacio.Hogar)
        {
            return BadRequest(
                "Las reglas de reparto solo aplican a espacios de tipo Hogar."
            );
        }

        if (request.Distribuciones.Count == 0)
        {
            return BadRequest(
                "Debe ingresar al menos una distribución."
            );
        }

        if (request.Distribuciones
            .GroupBy(x => x.UsuarioId)
            .Any(x => x.Count() > 1))
        {
            return BadRequest(
                "No puede repetir un usuario en la distribución."
            );
        }

        if (request.Distribuciones.Any(x =>
                x.Porcentaje <= 0 ||
                x.Porcentaje > 100))
        {
            return BadRequest(
                "Cada porcentaje debe ser mayor a 0 y menor o igual a 100."
            );
        }

        var total = request.Distribuciones.Sum(x => x.Porcentaje);

        if (total != 100m)
        {
            return BadRequest(
                $"Los porcentajes deben sumar 100%. Actualmente suman {total}%."
            );
        }

        var usuariosIds = request.Distribuciones
            .Select(x => x.UsuarioId)
            .ToList();

        var miembrosValidos = await _context.EspaciosUsuarios
            .Where(x =>
                x.EspacioFinancieroId == espacioId &&
                usuariosIds.Contains(x.UsuarioId))
            .Select(x => x.UsuarioId)
            .ToListAsync();

        if (miembrosValidos.Count != usuariosIds.Count)
        {
            return BadRequest(
                "Todos los usuarios deben pertenecer al hogar."
            );
        }

        var reglasActuales = await _context.ReglasReparto
            .Where(x => x.EspacioFinancieroId == espacioId)
            .ToListAsync();

        foreach (var item in request.Distribuciones)
        {
            var regla = reglasActuales
                .FirstOrDefault(x => x.UsuarioId == item.UsuarioId);

            if (regla is null)
            {
                _context.ReglasReparto.Add(new ReglaReparto
                {
                    EspacioFinancieroId = espacioId,
                    UsuarioId = item.UsuarioId,
                    Porcentaje = item.Porcentaje,
                    Activo = true
                });
            }
            else
            {
                regla.Porcentaje = item.Porcentaje;
                regla.Activo = true;
            }
        }

        // Si antes había una persona en el reparto y ahora fue retirada,
        // dejamos su regla inactiva.
        foreach (var regla in reglasActuales)
        {
            if (!usuariosIds.Contains(regla.UsuarioId))
            {
                regla.Activo = false;
            }
        }

        await _context.SaveChangesAsync();

        return Ok(new
        {
            EspacioFinancieroId = espacioId,
            TotalPorcentaje = total,
            Distribuciones = request.Distribuciones
        });
    }
}