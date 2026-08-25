using System.Security.Claims;
using Finanzas.Api.Data;
using Finanzas.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Finanzas.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ReportesController : ControllerBase
{
    private readonly AppDbContext _context;

    public ReportesController(AppDbContext context)
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

    [HttpGet("resumen")]
    public async Task<IActionResult> GetResumen(
        [FromQuery] long espacioId,
        [FromQuery] int anio,
        [FromQuery] int mes)
    {
        var usuarioId = GetUsuarioId();

        if (mes < 1 || mes > 12)
        {
            return BadRequest("El mes debe estar entre 1 y 12.");
        }

        var pertenece = await _context.EspaciosUsuarios
            .AnyAsync(x =>
                x.EspacioFinancieroId == espacioId &&
                x.UsuarioId == usuarioId);

        if (!pertenece)
        {
            return Forbid();
        }

        var ingresos = await _context.Ingresos
            .Where(x =>
                x.EspacioFinancieroId == espacioId &&
                x.Fecha.Year == anio &&
                x.Fecha.Month == mes &&
                x.Estado != EstadoIngreso.Anulado)
            .ToListAsync();

        var gastos = await _context.Gastos
            .Where(x =>
                x.EspacioFinancieroId == espacioId &&
                x.Fecha.Year == anio &&
                x.Fecha.Month == mes &&
                x.Estado != EstadoGasto.Anulado)
            .ToListAsync();

        var devoluciones = await _context.Devoluciones
            .Where(x =>
                x.Gasto.EspacioFinancieroId == espacioId &&
                x.Gasto.Fecha.Year == anio &&
                x.Gasto.Fecha.Month == mes)
            .ToListAsync();

        var totalIngresos = ingresos.Sum(x => x.Valor);

        var totalGastos = gastos.Sum(x => x.Valor);

        var gastosPagados = gastos
            .Where(x => x.Estado == EstadoGasto.Pagado)
            .Sum(x => x.Valor);

        var gastosPendientes = gastos
            .Where(x => x.Estado == EstadoGasto.Pendiente)
            .Sum(x => x.Valor);

        var gastosFijos = gastos
            .Where(x => x.Tipo == TipoGasto.Fijo)
            .Sum(x => x.Valor);

        var gastosVariables = gastos
            .Where(x => x.Tipo == TipoGasto.Variable)
            .Sum(x => x.Valor);

        var devolucionesPendientes = devoluciones
            .Sum(x => x.Valor - x.ValorPagado);

        var saldo = totalIngresos - totalGastos;

        return Ok(new
        {
            EspacioFinancieroId = espacioId,
            Anio = anio,
            Mes = mes,

            TotalIngresos = totalIngresos,
            TotalGastos = totalGastos,
            Saldo = saldo,

            GastosPagados = gastosPagados,
            GastosPendientes = gastosPendientes,

            GastosFijos = gastosFijos,
            GastosVariables = gastosVariables,

            DevolucionesPendientes = devolucionesPendientes
        });
    }

    [HttpGet("libro-diario")]
    public async Task<IActionResult> GetLibroDiario(
        [FromQuery] long espacioId,
        [FromQuery] int anio,
        [FromQuery] int mes)
    {
        var usuarioId = GetUsuarioId();

        if (mes < 1 || mes > 12)
        {
            return BadRequest("El mes debe estar entre 1 y 12.");
        }

        var pertenece = await _context.EspaciosUsuarios
            .AnyAsync(x =>
                x.EspacioFinancieroId == espacioId &&
                x.UsuarioId == usuarioId);

        if (!pertenece)
        {
            return Forbid();
        }

        var ingresos = await _context.Ingresos
            .Where(x =>
                x.EspacioFinancieroId == espacioId &&
                x.Fecha.Year == anio &&
                x.Fecha.Month == mes)
            .Select(x => new
            {
                Id = x.Id,
                Fecha = x.Fecha,
                Tipo = "INGRESO",
                Concepto = x.Concepto,
                Ingreso = x.Valor,
                Gasto = 0m,

                Estado = (int?)null,

                Persona = (string?)x.Usuario.Nombre,

                Categoria = x.Categoria != null
                    ? x.Categoria.Nombre
                    : null,

                Cuenta = x.Cuenta != null
                    ? x.Cuenta.Nombre
                    : null,

                Observacion = x.Observacion
            })
            .ToListAsync();

        var gastos = await _context.Gastos
            .Where(x =>
                x.EspacioFinancieroId == espacioId &&
                x.Fecha.Year == anio &&
                x.Fecha.Month == mes)
            .Select(x => new
            {
                Id = x.Id,
                Fecha = x.Fecha,
                Tipo = x.Tipo == TipoGasto.Fijo
                    ? "GASTO_FIJO"
                    : "GASTO_VARIABLE",

                Concepto = x.Concepto,

                Ingreso = 0m,
                Gasto = x.Valor,

                Estado = (int?)x.Estado,

                Persona = x.PagadoPor != null
                    ? x.PagadoPor.Nombre
                    : null,

                Categoria = x.Categoria != null
                    ? x.Categoria.Nombre
                    : null,

                Cuenta = x.Cuenta != null
                    ? x.Cuenta.Nombre
                    : null,

                Observacion = x.Observacion
            })
            .ToListAsync();

        var movimientos = ingresos
            .Concat(gastos)
            .OrderByDescending(x => x.Fecha)
            .ThenByDescending(x => x.Id)
            .ToList();

        return Ok(movimientos);
    }

    [HttpGet("devoluciones")]
    public async Task<IActionResult> GetResumenDevoluciones(
        [FromQuery] long espacioId,
        [FromQuery] int? anio,
        [FromQuery] int? mes)
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

        var query = _context.Devoluciones
            .Where(x =>
                x.Gasto.EspacioFinancieroId == espacioId)
            .AsQueryable();

        if (anio.HasValue)
        {
            query = query.Where(x =>
                x.Gasto.Fecha.Year == anio.Value);
        }

        if (mes.HasValue)
        {
            if (mes < 1 || mes > 12)
            {
                return BadRequest(
                    "El mes debe estar entre 1 y 12."
                );
            }

            query = query.Where(x =>
                x.Gasto.Fecha.Month == mes.Value);
        }

        var detalle = await query
            .OrderByDescending(x => x.Gasto.Fecha)
            .Select(x => new
            {
                x.Id,
                x.GastoId,
                Gasto = x.Gasto.Concepto,
                Fecha = x.Gasto.Fecha,

                x.DebeUsuarioId,
                DebeUsuario = x.DebeUsuario != null
                    ? x.DebeUsuario.Nombre
                    : null,

                x.RecibeUsuarioId,
                RecibeUsuario = x.RecibeUsuario != null
                    ? x.RecibeUsuario.Nombre
                    : null,

                x.Valor,
                x.ValorPagado,

                Pendiente =
                    x.Valor - x.ValorPagado,

                x.Estado
            })
            .ToListAsync();

        var resumen = detalle
            .Where(x => x.Pendiente > 0)
            .GroupBy(x => new
            {
                x.DebeUsuarioId,
                x.DebeUsuario,
                x.RecibeUsuarioId,
                x.RecibeUsuario
            })
            .Select(x => new
            {
                x.Key.DebeUsuarioId,
                x.Key.DebeUsuario,
                x.Key.RecibeUsuarioId,
                x.Key.RecibeUsuario,

                TotalPendiente =
                    x.Sum(d => d.Pendiente)
            })
            .ToList();

        return Ok(new
        {
            Resumen = resumen,
            Detalle = detalle
        });
    }


}