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
public class CuentasController : ControllerBase
{
    private readonly AppDbContext _context;

    public CuentasController(AppDbContext context)
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

        var cuentas = await _context.Cuentas
            .Where(x =>
                x.EspacioFinancieroId == espacioId &&
                x.Activo)
            .OrderBy(x => x.Nombre)
            .Select(x => new
            {
                x.Id,
                x.Nombre,
                x.Tipo,
                x.PropietarioId,
                Propietario = x.Propietario != null
                    ? x.Propietario.Nombre
                    : null,
                x.EntidadFinancieraId,
                EntidadFinanciera = x.EntidadFinanciera != null
                    ? x.EntidadFinanciera.Nombre
                    : null
            })
            .ToListAsync();

        return Ok(cuentas);
    }

    [HttpPost]
    public async Task<IActionResult> Crear(
        CrearCuentaRequest request)
    {
        var usuarioId = GetUsuarioId();

        var pertenece = await _context.EspaciosUsuarios
            .AnyAsync(x =>
                x.EspacioFinancieroId == request.EspacioFinancieroId &&
                x.UsuarioId == usuarioId);

        if (!pertenece)
        {
            return Forbid();
        }

        if (string.IsNullOrWhiteSpace(request.Nombre))
        {
            return BadRequest("El nombre es obligatorio.");
        }

        if (request.PropietarioId.HasValue)
        {
            var propietarioPertenece = await _context.EspaciosUsuarios
                .AnyAsync(x =>
                    x.EspacioFinancieroId == request.EspacioFinancieroId &&
                    x.UsuarioId == request.PropietarioId.Value);

            if (!propietarioPertenece)
            {
                return BadRequest(
                    "El propietario no pertenece al espacio financiero."
                );
            }
        }

        if (request.EntidadFinancieraId.HasValue)
        {
            var existeEntidad = await _context.EntidadesFinancieras
                .AnyAsync(x =>
                    x.Id == request.EntidadFinancieraId.Value &&
                    x.Activo);

            if (!existeEntidad)
            {
                return BadRequest(
                    "La entidad financiera seleccionada no existe."
                );
            }
        }

        var cuenta = new Cuenta
        {
            EspacioFinancieroId = request.EspacioFinancieroId,
            PropietarioId = request.PropietarioId,
            EntidadFinancieraId = request.EntidadFinancieraId,
            Nombre = request.Nombre.Trim(),
            Tipo = request.Tipo
        };

        _context.Cuentas.Add(cuenta);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            cuenta.Id,
            cuenta.Nombre,
            cuenta.Tipo,
            cuenta.PropietarioId,
            cuenta.EntidadFinancieraId
        });
    }
}