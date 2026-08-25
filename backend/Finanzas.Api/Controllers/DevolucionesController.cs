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
public class DevolucionesController : ControllerBase
{
    private readonly AppDbContext _context;

    public DevolucionesController(AppDbContext context)
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

        var devoluciones = await _context.Devoluciones
            .Where(x =>
                x.Gasto.EspacioFinancieroId == espacioId)
            .OrderBy(x => x.Estado)
            .ThenByDescending(x => x.Gasto.Fecha)
            .Select(x => new
            {
                x.Id,

                x.GastoId,
                Gasto = x.Gasto.Concepto,
                ValorGasto = x.Gasto.Valor,

                x.DebeUsuarioId,
                DebeUsuario = x.DebeUsuario != null
                    ? x.DebeUsuario.Nombre
                    : null,

                x.RecibeUsuarioId,
                RecibeUsuario = x.RecibeUsuario != null
                    ? x.RecibeUsuario.Nombre
                    : null,

                x.RecibeCuentaId,
                RecibeCuenta = x.RecibeCuenta != null
                    ? x.RecibeCuenta.Nombre
                    : null,

                x.Valor,
                x.ValorPagado,

                Pendiente = x.Valor - x.ValorPagado,

                x.Estado,
                x.FechaPago,
                x.Observacion
            })
            .ToListAsync();

        return Ok(devoluciones);
    }

    [HttpPatch("{id:long}/pagar")]
    public async Task<IActionResult> Pagar(
        long id,
        PagarDevolucionRequest request)
    {
        var usuarioId = GetUsuarioId();

        var devolucion = await _context.Devoluciones
            .Include(x => x.Gasto)
            .FirstOrDefaultAsync(x => x.Id == id);

        if (devolucion is null)
        {
            return NotFound("Devolución no encontrada.");
        }

        var pertenece = await _context.EspaciosUsuarios
            .AnyAsync(x =>
                x.EspacioFinancieroId ==
                    devolucion.Gasto.EspacioFinancieroId &&
                x.UsuarioId == usuarioId);

        if (!pertenece)
        {
            return Forbid();
        }

        if (devolucion.Estado == EstadoDevolucion.Pagada)
        {
            return BadRequest(
                "La devolución ya está completamente pagada."
            );
        }

        if (request.Valor <= 0)
        {
            return BadRequest(
                "El valor pagado debe ser mayor a cero."
            );
        }

        var pendiente =
            devolucion.Valor - devolucion.ValorPagado;

        if (request.Valor > pendiente)
        {
            return BadRequest(
                $"El valor supera el saldo pendiente de {pendiente}."
            );
        }

        devolucion.ValorPagado += request.Valor;
        devolucion.FechaPago = request.FechaPago;

        if (devolucion.ValorPagado == devolucion.Valor)
        {
            devolucion.Estado = EstadoDevolucion.Pagada;
        }
        else
        {
            devolucion.Estado = EstadoDevolucion.Parcial;
        }

        await _context.SaveChangesAsync();

        return Ok(new
        {
            devolucion.Id,
            devolucion.Valor,
            devolucion.ValorPagado,

            Pendiente =
                devolucion.Valor - devolucion.ValorPagado,

            devolucion.Estado,
            devolucion.FechaPago
        });
    }
}