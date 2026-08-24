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
public class EntidadesFinancierasController : ControllerBase
{
    private readonly AppDbContext _context;

    public EntidadesFinancierasController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> Get()
    {
        var entidades = await _context.EntidadesFinancieras
            .Where(x => x.Activo)
            .OrderBy(x => x.Nombre)
            .Select(x => new
            {
                x.Id,
                x.Nombre
            })
            .ToListAsync();

        return Ok(entidades);
    }

    [HttpPost]
    public async Task<IActionResult> Crear(
        CrearEntidadFinancieraRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Nombre))
        {
            return BadRequest("El nombre es obligatorio.");
        }

        var nombre = request.Nombre.Trim();

        var existe = await _context.EntidadesFinancieras
            .AnyAsync(x => x.Nombre == nombre);

        if (existe)
        {
            return BadRequest(
                "Ya existe una entidad financiera con ese nombre."
            );
        }

        var entidad = new EntidadFinanciera
        {
            Nombre = nombre
        };

        _context.EntidadesFinancieras.Add(entidad);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            entidad.Id,
            entidad.Nombre
        });
    }
}