using System.Security.Claims;
using Finanzas.Api.Data;
using Finanzas.Api.DTOs;
using Finanzas.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Finanzas.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ConceptosController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly ConceptoService _conceptoService;

    public ConceptosController(
        AppDbContext context,
        ConceptoService conceptoService)
    {
        _context = context;
        _conceptoService = conceptoService;
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

    [HttpPost("similares")]
    public async Task<IActionResult> BuscarSimilares(
        BuscarConceptosSimilaresRequest request)
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
            return BadRequest(
                "El concepto es obligatorio."
            );
        }

        var conceptos = await _context.Gastos
            .Where(x =>
                x.EspacioFinancieroId ==
                    request.EspacioFinancieroId)
            .Select(x => new
            {
                x.Id,
                x.Concepto,
                x.CategoriaId
            })
            .ToListAsync();

        var similares = conceptos
            .Select(x => new
            {
                x.Id,
                x.Concepto,
                x.CategoriaId,

                Similitud =
                    _conceptoService.CalcularSimilitud(
                        request.Concepto,
                        x.Concepto
                    )
            })
            .Where(x => x.Similitud >= 0.5)
            .OrderByDescending(x => x.Similitud)
            .Take(5)
            .ToList();

        return Ok(similares);
    }
}