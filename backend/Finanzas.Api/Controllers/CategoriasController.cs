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
public class CategoriasController : ControllerBase
{
    private readonly AppDbContext _context;

    public CategoriasController(AppDbContext context)
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

        var categorias = await _context.Categorias
            .Where(x =>
                x.EspacioFinancieroId == espacioId &&
                x.Activo)
            .OrderBy(x => x.Tipo)
            .ThenBy(x => x.Nombre)
            .Select(x => new
            {
                x.Id,
                x.Nombre,
                x.Tipo
            })
            .ToListAsync();

        return Ok(categorias);
    }

    [HttpPost]
    public async Task<IActionResult> Crear(
        CrearCategoriaRequest request)
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

        var nombre = request.Nombre.Trim();

        var existe = await _context.Categorias.AnyAsync(x =>
            x.EspacioFinancieroId == request.EspacioFinancieroId &&
            x.Nombre == nombre &&
            x.Tipo == request.Tipo);

        if (existe)
        {
            return BadRequest(
                "Ya existe una categoría con ese nombre."
            );
        }

        var categoria = new Categoria
        {
            EspacioFinancieroId = request.EspacioFinancieroId,
            Nombre = nombre,
            Tipo = request.Tipo
        };

        _context.Categorias.Add(categoria);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            categoria.Id,
            categoria.Nombre,
            categoria.Tipo
        });
    }
}