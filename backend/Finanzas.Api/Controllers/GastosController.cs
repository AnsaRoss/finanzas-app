using System.Security.Claims;
using Finanzas.Api.Data;
using Finanzas.Api.DTOs;
using Finanzas.Api.Models;
using Finanzas.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Finanzas.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class GastosController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly GastoService _gastoService;

    public GastosController(
        AppDbContext context,
        GastoService gastoService)
    {
        _context = context;
        _gastoService = gastoService;
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

    [HttpPatch("{id:long}/pagar")]
    public async Task<IActionResult> Pagar(
        long id,
        PagarGastoRequest request)
    {
        var usuarioId = GetUsuarioId();

        var gasto = await _context.Gastos
            .FirstOrDefaultAsync(x => x.Id == id);

        if (gasto is null)
        {
            return NotFound("Gasto no encontrado.");
        }

        var pertenece = await _context.EspaciosUsuarios
            .AnyAsync(x =>
                x.EspacioFinancieroId == gasto.EspacioFinancieroId &&
                x.UsuarioId == usuarioId);

        if (!pertenece)
        {
            return Forbid();
        }

        if (gasto.Estado == EstadoGasto.Pagado)
        {
            return BadRequest("El gasto ya está pagado.");
        }

        var pagadorPertenece = await _context.EspaciosUsuarios
            .AnyAsync(x =>
                x.EspacioFinancieroId == gasto.EspacioFinancieroId &&
                x.UsuarioId == request.PagadoPorId);

        if (!pagadorPertenece)
        {
            return BadRequest(
                "La persona que pagó no pertenece al espacio financiero."
            );
        }

        if (request.CuentaId.HasValue)
        {
            var cuentaValida = await _context.Cuentas
                .AnyAsync(x =>
                    x.Id == request.CuentaId.Value &&
                    x.EspacioFinancieroId == gasto.EspacioFinancieroId &&
                    x.Activo);

            if (!cuentaValida)
            {
                return BadRequest(
                    "La cuenta seleccionada no pertenece al espacio financiero."
                );
            }
        }

        await using var transaction =
            await _context.Database.BeginTransactionAsync();

        gasto.PagadoPorId = request.PagadoPorId;
        gasto.CuentaId = request.CuentaId;
        gasto.FechaPago = request.FechaPago;
        gasto.Estado = EstadoGasto.Pagado;

        await _context.SaveChangesAsync();

        await _gastoService.GenerarDevolucionesAsync(
            gasto.Id,
            request.PagadoPorId);

        await transaction.CommitAsync();

        var devoluciones = await _context.Devoluciones
            .Where(x => x.GastoId == gasto.Id)
            .Select(x => new
            {
                x.Id,
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
                x.Estado
            })
            .ToListAsync();

        return Ok(new
        {
            gasto.Id,
            gasto.Concepto,
            gasto.Valor,
            gasto.Estado,
            gasto.FechaPago,
            gasto.PagadoPorId,
            gasto.CuentaId,
            Devoluciones = devoluciones
        });
    }

    [HttpGet("espacio/{espacioId:long}")]
    public async Task<IActionResult> GetPorEspacio(
        long espacioId,
        [FromQuery] int? anio,
        [FromQuery] int? mes,
        [FromQuery] EstadoGasto? estado,
        [FromQuery] TipoGasto? tipo)
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

        var query = _context.Gastos
            .Where(x => x.EspacioFinancieroId == espacioId)
            .AsQueryable();

        if (anio.HasValue)
        {
            query = query.Where(x => x.Fecha.Year == anio.Value);
        }

        if (mes.HasValue)
        {
            if (mes < 1 || mes > 12)
            {
                return BadRequest("El mes debe estar entre 1 y 12.");
            }

            query = query.Where(x => x.Fecha.Month == mes.Value);
        }

        if (estado.HasValue)
        {
            query = query.Where(x => x.Estado == estado.Value);
        }

        if (tipo.HasValue)
        {
            query = query.Where(x => x.Tipo == tipo.Value);
        }

        var gastos = await query
            .OrderByDescending(x => x.Fecha)
            .ThenByDescending(x => x.Id)
            .Select(x => new
            {
                x.Id,
                x.Concepto,
                x.Tipo,
                x.Valor,
                x.Fecha,
                x.FechaPago,
                x.Estado,
                x.Observacion,

                x.CategoriaId,
                Categoria = x.Categoria != null
                    ? x.Categoria.Nombre
                    : null,

                x.PagadoPorId,
                PagadoPor = x.PagadoPor != null
                    ? x.PagadoPor.Nombre
                    : null,

                x.CuentaId,
                Cuenta = x.Cuenta != null
                    ? x.Cuenta.Nombre
                    : null,

                Distribucion = x.Distribuciones
                    .Select(d => new
                    {
                        d.UsuarioId,
                        Usuario = d.Usuario.Nombre,
                        d.Porcentaje,
                        d.Valor
                    })
                    .ToList()
            })
            .ToListAsync();

        return Ok(gastos);
    }

    [HttpPost("variable")]
    public async Task<IActionResult> CrearVariable(
        CrearGastoVariableRequest request)
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

        if (string.IsNullOrWhiteSpace(request.Concepto))
        {
            return BadRequest("El concepto es obligatorio.");
        }

        if (request.Valor <= 0)
        {
            return BadRequest("El valor debe ser mayor a cero.");
        }

        if (request.CategoriaId.HasValue)
        {
            var categoriaValida = await _context.Categorias
                .AnyAsync(x =>
                    x.Id == request.CategoriaId.Value &&
                    x.EspacioFinancieroId == request.EspacioFinancieroId &&
                    x.Tipo == TipoCategoria.Gasto &&
                    x.Activo);

            if (!categoriaValida)
            {
                return BadRequest(
                    "La categoría seleccionada no es válida."
                );
            }
        }

        if (request.PagadoPorId.HasValue)
        {
            var pagadorValido = await _context.EspaciosUsuarios
                .AnyAsync(x =>
                    x.EspacioFinancieroId == request.EspacioFinancieroId &&
                    x.UsuarioId == request.PagadoPorId.Value);

            if (!pagadorValido)
            {
                return BadRequest(
                    "La persona que pagó no pertenece al espacio financiero."
                );
            }
        }

        if (request.CuentaId.HasValue)
        {
            var cuentaValida = await _context.Cuentas
                .AnyAsync(x =>
                    x.Id == request.CuentaId.Value &&
                    x.EspacioFinancieroId == request.EspacioFinancieroId &&
                    x.Activo);

            if (!cuentaValida)
            {
                return BadRequest(
                    "La cuenta seleccionada no pertenece al espacio financiero."
                );
            }
        }

        if (request.MarcarPagado && !request.PagadoPorId.HasValue)
        {
            return BadRequest(
                "Debe indicar quién pagó si el gasto se registra como pagado."
            );
        }

        var espacio = await _context.EspaciosFinancieros
            .FirstOrDefaultAsync(x =>
                x.Id == request.EspacioFinancieroId);

        if (espacio is null)
        {
            return NotFound("Espacio financiero no encontrado.");
        }

        var distribucionResult =
            await _gastoService.PrepararDistribucionAsync(
                request.EspacioFinancieroId,
                espacio.Tipo,
                request.TipoReparto,
                request.Valor,
                request.ResponsableId,
                request.Distribucion);

        if (!distribucionResult.EsValido)
        {
            return BadRequest(distribucionResult.Error);
        }

        var gasto = new Gasto
        {
            EspacioFinancieroId = request.EspacioFinancieroId,
            CategoriaId = request.CategoriaId,
            GastoFijoId = null,

            RegistradoPorId = usuarioId,

            PagadoPorId = request.MarcarPagado
                ? request.PagadoPorId
                : null,

            CuentaId = request.MarcarPagado
                ? request.CuentaId
                : null,

            Concepto = request.Concepto.Trim(),

            Tipo = TipoGasto.Variable,
            TipoReparto = request.TipoReparto,

            Valor = request.Valor,

            Fecha = request.Fecha,

            FechaPago = request.MarcarPagado
                ? request.Fecha
                : null,

            Estado = request.MarcarPagado
                ? EstadoGasto.Pagado
                : EstadoGasto.Pendiente,

            Observacion = request.Observacion?.Trim()
        };

        await using var transaction =
            await _context.Database.BeginTransactionAsync();

        _context.Gastos.Add(gasto);

        await _context.SaveChangesAsync();

        await _gastoService.CrearDistribucionHistoricaAsync(
            gasto,
            distribucionResult.Distribucion);

        // Si se registró directamente como pagado,
        // generamos las devoluciones correspondientes.
        if (gasto.Estado == EstadoGasto.Pagado &&
            gasto.PagadoPorId.HasValue)
        {
            await _gastoService.GenerarDevolucionesAsync(
                gasto.Id,
                gasto.PagadoPorId.Value);
        }

        await transaction.CommitAsync();

        var distribucion = await _context.DistribucionesGasto
            .Where(x => x.GastoId == gasto.Id)
            .Select(x => new
            {
                x.UsuarioId,
                Usuario = x.Usuario.Nombre,
                x.Porcentaje,
                x.Valor
            })
            .ToListAsync();

        return Ok(new
        {
            gasto.Id,
            gasto.Concepto,
            gasto.Tipo,
            gasto.Valor,
            gasto.Fecha,
            gasto.FechaPago,
            gasto.Estado,
            gasto.PagadoPorId,
            gasto.CuentaId,
            Distribucion = distribucion
        });
    }

    [HttpPatch("{id:long}/anular")]
    public async Task<IActionResult> Anular(long id)
    {
        var usuarioId = GetUsuarioId();

        var gasto = await _context.Gastos
            .Include(x => x.Devoluciones)
            .FirstOrDefaultAsync(x => x.Id == id);

        if (gasto is null)
        {
            return NotFound("Gasto no encontrado.");
        }

        var pertenece = await _context.EspaciosUsuarios
            .AnyAsync(x =>
                x.EspacioFinancieroId == gasto.EspacioFinancieroId &&
                x.UsuarioId == usuarioId);

        if (!pertenece)
        {
            return Forbid();
        }

        if (gasto.Estado == EstadoGasto.Anulado)
        {
            return BadRequest("El gasto ya está anulado.");
        }

        // Por seguridad, no anulamos si ya existen devoluciones
        // parcial o completamente pagadas.
        var tieneDevolucionesPagadas = gasto.Devoluciones.Any(x =>
            x.ValorPagado > 0);

        if (tieneDevolucionesPagadas)
        {
            return BadRequest(
                "No se puede anular el gasto porque tiene devoluciones con pagos registrados."
            );
        }

        await using var transaction =
            await _context.Database.BeginTransactionAsync();

        try
        {
            // Eliminamos devoluciones todavía no pagadas.
            if (gasto.Devoluciones.Count > 0)
            {
                _context.Devoluciones.RemoveRange(gasto.Devoluciones);
            }

            gasto.Estado = EstadoGasto.Anulado;

            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            return Ok(new
            {
                gasto.Id,
                gasto.Concepto,
                gasto.Estado
            });
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }
    }
}
