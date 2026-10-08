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
public class GastosFijosController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly GastoService _gastoService;

    public GastosFijosController(
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

        var gastosData = await _context.GastosFijos
            .Where(x =>
                x.EspacioFinancieroId == espacioId &&
                x.Activo)
            .OrderBy(x => x.DiaVencimiento)
            .ThenBy(x => x.Concepto)
            .Select(x => new
            {
                x.Id,
                x.Concepto,
                x.ValorEstimado,
                x.DiaVencimiento,
                x.CategoriaId,
                Categoria = x.Categoria != null
                    ? x.Categoria.Nombre
                    : null,
                x.TipoReparto,
                x.ResponsableId,
                Responsable = x.Responsable != null
                    ? x.Responsable.Nombre
                    : null,
                x.DistribucionPersonalizadaJson,
                x.Activo
            })
            .ToListAsync();

        var gastos = gastosData.Select(x => new
        {
            x.Id,
            x.Concepto,
            x.ValorEstimado,
            x.DiaVencimiento,
            x.CategoriaId,
            x.Categoria,
            x.TipoReparto,
            x.ResponsableId,
            x.Responsable,
            Distribucion =
                _gastoService.LeerDistribucionPersonalizada(
                    x.DistribucionPersonalizadaJson),
            x.Activo
        });

        return Ok(gastos);
    }

    [HttpPost]
    public async Task<IActionResult> Crear(
        CrearGastoFijoRequest request)
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

        if (request.ValorEstimado.HasValue &&
            request.ValorEstimado <= 0)
        {
            return BadRequest(
                "El valor estimado debe ser mayor a cero."
            );
        }

        if (request.DiaVencimiento.HasValue &&
            (request.DiaVencimiento < 1 ||
             request.DiaVencimiento > 31))
        {
            return BadRequest(
                "El día de vencimiento debe estar entre 1 y 31."
            );
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
                    "La categoría seleccionada no es válida para gastos."
                );
            }
        }

        var validacionReparto =
            await _gastoService.ValidarConfiguracionRepartoAsync(
                request.EspacioFinancieroId,
                request.TipoReparto,
                request.ResponsableId,
                request.Distribucion);

        if (!validacionReparto.EsValido)
        {
            return BadRequest(validacionReparto.Error);
        }

        var gasto = new GastoFijo
        {
            EspacioFinancieroId = request.EspacioFinancieroId,
            CategoriaId = request.CategoriaId,
            Concepto = request.Concepto.Trim(),
            ValorEstimado = request.ValorEstimado,
            DiaVencimiento = request.DiaVencimiento,
            TipoReparto = request.TipoReparto,
            ResponsableId = request.TipoReparto == TipoRepartoGasto.Individual
                ? request.ResponsableId
                : null,
            DistribucionPersonalizadaJson =
                _gastoService.SerializarDistribucionPersonalizada(
                    request.TipoReparto,
                    request.Distribucion)
        };

        _context.GastosFijos.Add(gasto);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            gasto.Id,
            gasto.Concepto,
            gasto.ValorEstimado,
            gasto.DiaVencimiento,
            gasto.CategoriaId,
            gasto.TipoReparto,
            gasto.ResponsableId,
            Distribucion =
                _gastoService.LeerDistribucionPersonalizada(
                    gasto.DistribucionPersonalizadaJson)
        });
    }

    [HttpPut("{id:long}")]
    public async Task<IActionResult> Actualizar(
        long id,
        CrearGastoFijoRequest request)
    {
        var usuarioId = GetUsuarioId();

        var gasto = await _context.GastosFijos
            .FirstOrDefaultAsync(x => x.Id == id);

        if (gasto is null)
        {
            return NotFound("Gasto fijo no encontrado.");
        }

        var pertenece = await _context.EspaciosUsuarios
            .AnyAsync(x =>
                x.EspacioFinancieroId == gasto.EspacioFinancieroId &&
                x.UsuarioId == usuarioId);

        if (!pertenece)
        {
            return Forbid();
        }

        if (string.IsNullOrWhiteSpace(request.Concepto))
        {
            return BadRequest("El concepto es obligatorio.");
        }

        if (request.ValorEstimado.HasValue &&
            request.ValorEstimado <= 0)
        {
            return BadRequest(
                "El valor estimado debe ser mayor a cero."
            );
        }

        if (request.DiaVencimiento.HasValue &&
            (request.DiaVencimiento < 1 ||
             request.DiaVencimiento > 31))
        {
            return BadRequest(
                "El día de vencimiento debe estar entre 1 y 31."
            );
        }

        var validacionReparto =
            await _gastoService.ValidarConfiguracionRepartoAsync(
                gasto.EspacioFinancieroId,
                request.TipoReparto,
                request.ResponsableId,
                request.Distribucion);

        if (!validacionReparto.EsValido)
        {
            return BadRequest(validacionReparto.Error);
        }

        gasto.CategoriaId = request.CategoriaId;
        gasto.Concepto = request.Concepto.Trim();
        gasto.ValorEstimado = request.ValorEstimado;
        gasto.DiaVencimiento = request.DiaVencimiento;
        gasto.TipoReparto = request.TipoReparto;
        gasto.ResponsableId = request.TipoReparto == TipoRepartoGasto.Individual
            ? request.ResponsableId
            : null;
        gasto.DistribucionPersonalizadaJson =
            _gastoService.SerializarDistribucionPersonalizada(
                request.TipoReparto,
                request.Distribucion);

        await _context.SaveChangesAsync();

        return Ok();
    }

    [HttpPatch("{id:long}/estado")]
    public async Task<IActionResult> CambiarEstado(long id,[FromQuery] bool activo)
    {
        var usuarioId = GetUsuarioId();

        var gasto = await _context.GastosFijos
            .FirstOrDefaultAsync(x => x.Id == id);

        if (gasto is null)
        {
            return NotFound("Gasto fijo no encontrado.");
        }

        var pertenece = await _context.EspaciosUsuarios
            .AnyAsync(x =>
                x.EspacioFinancieroId == gasto.EspacioFinancieroId &&
                x.UsuarioId == usuarioId);

        if (!pertenece)
        {
            return Forbid();
        }

        gasto.Activo = activo;

        await _context.SaveChangesAsync();

        return Ok(new
        {
            gasto.Id,
            gasto.Activo
        });
    }
    [HttpPost("{id:long}/generar")]
    public async Task<IActionResult> GenerarGasto(long id,GenerarGastoFijoRequest request)
    {
        var usuarioId = GetUsuarioId();

        var gastoFijo = await _context.GastosFijos
            .FirstOrDefaultAsync(x =>
                x.Id == id &&
                x.Activo);

        if (gastoFijo is null)
        {
            return NotFound("Gasto fijo no encontrado.");
        }

        var pertenece = await _context.EspaciosUsuarios
            .AnyAsync(x =>
                x.EspacioFinancieroId == gastoFijo.EspacioFinancieroId &&
                x.UsuarioId == usuarioId);

        if (!pertenece)
        {
            return Forbid();
        }

        var valor = request.Valor ?? gastoFijo.ValorEstimado;

        if (!valor.HasValue || valor.Value <= 0)
        {
            return BadRequest(
                "Debe indicar un valor válido para generar el gasto."
            );
        }

        var yaGenerado = await _context.Gastos.AnyAsync(x =>
            x.GastoFijoId == gastoFijo.Id &&
            x.Fecha.Year == request.Fecha.Year &&
            x.Fecha.Month == request.Fecha.Month);

        if (yaGenerado)
        {
            return BadRequest(
                "Este gasto fijo ya fue generado para el mes seleccionado."
            );
        }

        var espacio = await _context.EspaciosFinancieros
            .FirstAsync(x =>
                x.Id == gastoFijo.EspacioFinancieroId);

        var distribucionResult =
            await _gastoService.PrepararDistribucionGastoFijoAsync(
                gastoFijo,
                espacio.Tipo,
                valor.Value);

        if (!distribucionResult.EsValido)
        {
            return BadRequest(distribucionResult.Error);
        }

        var gasto = new Gasto
        {
            EspacioFinancieroId = gastoFijo.EspacioFinancieroId,
            CategoriaId = gastoFijo.CategoriaId,
            GastoFijoId = gastoFijo.Id,

            RegistradoPorId = usuarioId,

            Concepto = gastoFijo.Concepto,
            Tipo = TipoGasto.Fijo,
            TipoReparto = gastoFijo.TipoReparto,
            Valor = valor.Value,
            Fecha = request.Fecha,
            Observacion = request.Observacion?.Trim()
        };

        _context.Gastos.Add(gasto);

        await _context.SaveChangesAsync();

        await _gastoService.CrearDistribucionHistoricaAsync(
            gasto,
            distribucionResult.Distribucion);

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
            gasto.Valor,
            gasto.Fecha,
            gasto.FechaPago,
            gasto.Estado,
            gasto.TipoReparto,
            Distribucion = distribucion
        });
    }
}
