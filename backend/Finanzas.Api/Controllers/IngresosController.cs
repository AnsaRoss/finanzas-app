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
public class IngresosController : ControllerBase
{
    private readonly AppDbContext _context;

    public IngresosController(AppDbContext context)
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

        var ingresos = await _context.Ingresos
            .Where(x => x.EspacioFinancieroId == espacioId &&
                        x.Estado == EstadoIngreso.Activo)
            .OrderByDescending(x => x.Fecha)
            .ThenByDescending(x => x.Id)
            .Select(x => new
            {
                x.Id,
                x.Concepto,
                x.Valor,
                x.Fecha,
                x.Observacion,

                x.UsuarioId,
                Usuario = x.Usuario.Nombre,

                x.CategoriaId,
                Categoria = x.Categoria != null
                    ? x.Categoria.Nombre
                    : null,

                x.CuentaId,
                Cuenta = x.Cuenta != null
                    ? x.Cuenta.Nombre
                    : null
            })
            .ToListAsync();

        return Ok(ingresos);
    }

    [HttpPost]
    public async Task<IActionResult> Crear(CrearIngresoRequest request)
    {
        var usuarioAutenticadoId = GetUsuarioId();

        var pertenece = await _context.EspaciosUsuarios
            .AnyAsync(x =>
                x.EspacioFinancieroId == request.EspacioFinancieroId &&
                x.UsuarioId == usuarioAutenticadoId);

        if (!pertenece)
        {
            return Forbid();
        }

        var usuarioPertenece = await _context.EspaciosUsuarios
            .AnyAsync(x =>
                x.EspacioFinancieroId == request.EspacioFinancieroId &&
                x.UsuarioId == request.UsuarioId);

        if (!usuarioPertenece)
        {
            return BadRequest(
                "El usuario del ingreso no pertenece al espacio financiero."
            );
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
                    x.Tipo == TipoCategoria.Ingreso &&
                    x.Activo);

            if (!categoriaValida)
            {
                return BadRequest(
                    "La categoría no es válida para este ingreso."
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
                    "La cuenta no pertenece al espacio financiero."
                );
            }
        }

        var ingreso = new Ingreso
        {
            EspacioFinancieroId = request.EspacioFinancieroId,
            UsuarioId = request.UsuarioId,
            CategoriaId = request.CategoriaId,
            CuentaId = request.CuentaId,
            Concepto = request.Concepto.Trim(),
            Valor = request.Valor,
            Fecha = request.Fecha,
            Observacion = request.Observacion?.Trim()
        };

        _context.Ingresos.Add(ingreso);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            ingreso.Id,
            ingreso.Concepto,
            ingreso.Valor,
            ingreso.Fecha
        });
    }

    [HttpPut("{id:long}")]
    public async Task<IActionResult> Actualizar(long id,ActualizarIngresoRequest request)
    {
        var usuarioId = GetUsuarioId();

        var ingreso = await _context.Ingresos
            .FirstOrDefaultAsync(x => x.Id == id);

        if (ingreso is null)
        {
            return NotFound("Ingreso no encontrado.");
        }

        var pertenece = await _context.EspaciosUsuarios
            .AnyAsync(x =>
                x.EspacioFinancieroId == ingreso.EspacioFinancieroId &&
                x.UsuarioId == usuarioId);

        if (!pertenece)
        {
            return Forbid();
        }

        if (ingreso.Estado == EstadoIngreso.Anulado)
        {
            return BadRequest("No se puede editar un ingreso anulado.");
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
                    x.EspacioFinancieroId == ingreso.EspacioFinancieroId &&
                    x.Tipo == TipoCategoria.Ingreso &&
                    x.Activo);

            if (!categoriaValida)
            {
                return BadRequest(
                    "La categoría seleccionada no es válida para ingresos."
                );
            }
        }

        if (request.CuentaId.HasValue)
        {
            var cuentaValida = await _context.Cuentas
                .AnyAsync(x =>
                    x.Id == request.CuentaId.Value &&
                    x.EspacioFinancieroId == ingreso.EspacioFinancieroId &&
                    x.Activo);

            if (!cuentaValida)
            {
                return BadRequest(
                    "La cuenta no pertenece al espacio financiero."
                );
            }
        }

        ingreso.CategoriaId = request.CategoriaId;
        ingreso.CuentaId = request.CuentaId;
        ingreso.Concepto = request.Concepto.Trim();
        ingreso.Valor = request.Valor;
        ingreso.Fecha = request.Fecha;
        ingreso.Observacion = request.Observacion?.Trim();

        await _context.SaveChangesAsync();

        return Ok(new
        {
            ingreso.Id,
            ingreso.Concepto,
            ingreso.Valor,
            ingreso.Fecha,
            ingreso.Estado
        });
    }

    [HttpPatch("{id:long}/anular")]
    public async Task<IActionResult> Anular(long id)
    {
        var usuarioId = GetUsuarioId();

        var ingreso = await _context.Ingresos
            .FirstOrDefaultAsync(x => x.Id == id);

        if (ingreso is null)
        {
            return NotFound("Ingreso no encontrado.");
        }

        var pertenece = await _context.EspaciosUsuarios
            .AnyAsync(x =>
                x.EspacioFinancieroId == ingreso.EspacioFinancieroId &&
                x.UsuarioId == usuarioId);

        if (!pertenece)
        {
            return Forbid();
        }

        if (ingreso.Estado == EstadoIngreso.Anulado)
        {
            return BadRequest("El ingreso ya está anulado.");
        }

        ingreso.Estado = EstadoIngreso.Anulado;

        await _context.SaveChangesAsync();

        return Ok(new
        {
            ingreso.Id,
            ingreso.Concepto,
            ingreso.Estado
        });
    }

}