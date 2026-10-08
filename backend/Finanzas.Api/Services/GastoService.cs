using System.Text.Json;
using Finanzas.Api.Data;
using Finanzas.Api.DTOs;
using Finanzas.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace Finanzas.Api.Services;

public class GastoService
{
    private readonly AppDbContext _context;

    public GastoService(AppDbContext context)
    {
        _context = context;
    }

    public async Task<ValidacionRepartoResult>
        ValidarConfiguracionRepartoAsync(
            long espacioFinancieroId,
            TipoRepartoGasto tipoReparto,
            long? responsableId,
            IReadOnlyCollection<ReglaRepartoItemRequest>? distribucion)
    {
        return tipoReparto switch
        {
            TipoRepartoGasto.ReglaHogar =>
                ValidacionRepartoResult.Ok(),

            TipoRepartoGasto.Individual =>
                await ValidarResponsableAsync(
                    espacioFinancieroId,
                    responsableId),

            TipoRepartoGasto.Personalizado =>
                await ValidarDistribucionPersonalizadaAsync(
                    espacioFinancieroId,
                    distribucion),

            _ => ValidacionRepartoResult.Fallo(
                "El tipo de reparto no es válido.")
        };
    }

    public async Task<DistribucionGastoResult>
        PrepararDistribucionGastoFijoAsync(
            GastoFijo gastoFijo,
            TipoEspacio tipoEspacio,
            decimal valor)
    {
        return await PrepararDistribucionAsync(
            gastoFijo.EspacioFinancieroId,
            tipoEspacio,
            gastoFijo.TipoReparto,
            valor,
            gastoFijo.ResponsableId,
            LeerDistribucionPersonalizada(
                gastoFijo.DistribucionPersonalizadaJson));
    }

    public string? SerializarDistribucionPersonalizada(
        TipoRepartoGasto tipoReparto,
        IReadOnlyCollection<ReglaRepartoItemRequest>? distribucion)
    {
        if (tipoReparto != TipoRepartoGasto.Personalizado)
        {
            return null;
        }

        var items = distribucion ??
            Array.Empty<ReglaRepartoItemRequest>();

        return JsonSerializer.Serialize(items);
    }

    public IReadOnlyCollection<ReglaRepartoItemRequest>
        LeerDistribucionPersonalizada(string? distribucionJson)
    {
        if (string.IsNullOrWhiteSpace(distribucionJson))
        {
            return [];
        }

        return JsonSerializer.Deserialize<List<ReglaRepartoItemRequest>>(
            distribucionJson) ?? [];
    }

    public async Task<DistribucionGastoResult> PrepararDistribucionAsync(
        long espacioFinancieroId,
        TipoEspacio tipoEspacio,
        TipoRepartoGasto tipoReparto,
        decimal valor,
        long? responsableId,
        IReadOnlyCollection<ReglaRepartoItemRequest>? distribucion)
    {
        return tipoReparto switch
        {
            TipoRepartoGasto.ReglaHogar =>
                await PrepararDistribucionReglaHogarAsync(
                    espacioFinancieroId,
                    tipoEspacio,
                    valor),

            TipoRepartoGasto.Individual =>
                await PrepararDistribucionIndividualAsync(
                    espacioFinancieroId,
                    valor,
                    responsableId),

            TipoRepartoGasto.Personalizado =>
                await PrepararDistribucionPersonalizadaAsync(
                    espacioFinancieroId,
                    valor,
                    distribucion),

            _ => DistribucionGastoResult.Fallo(
                "El tipo de reparto no es válido.")
        };
    }

    private async Task<DistribucionGastoResult>
        PrepararDistribucionReglaHogarAsync(
            long espacioFinancieroId,
            TipoEspacio tipoEspacio,
            decimal valor)
    {
        if (tipoEspacio != TipoEspacio.Hogar)
        {
            return DistribucionGastoResult.Ok(
                Array.Empty<DistribucionGastoPreparada>());
        }

        var reglas = await _context.ReglasReparto
            .Where(x =>
                x.EspacioFinancieroId == espacioFinancieroId &&
                x.Activo)
            .ToListAsync();

        if (reglas.Count == 0)
        {
            return DistribucionGastoResult.Fallo(
                "El hogar no tiene configurada una regla de reparto."
            );
        }

        var total = reglas.Sum(x => x.Porcentaje);

        if (total != 100m)
        {
            return DistribucionGastoResult.Fallo(
                $"La distribución actual suma {total}% y debe sumar 100%."
            );
        }

        return DistribucionGastoResult.Ok(
            CrearDistribucionesPreparadas(valor, reglas));
    }

    private async Task<DistribucionGastoResult>
        PrepararDistribucionIndividualAsync(
            long espacioFinancieroId,
            decimal valor,
            long? responsableId)
    {
        if (!responsableId.HasValue)
        {
            return DistribucionGastoResult.Fallo(
                "Debe indicar el responsable del gasto individual."
            );
        }

        var validacion = await ValidarResponsableAsync(
            espacioFinancieroId,
            responsableId);

        if (!validacion.EsValido)
        {
            return DistribucionGastoResult.Fallo(
                validacion.Error!
            );
        }

        return DistribucionGastoResult.Ok(
            new[]
            {
                new DistribucionGastoPreparada(
                    responsableId.Value,
                    100m,
                    valor)
            });
    }

    private async Task<DistribucionGastoResult>
        PrepararDistribucionPersonalizadaAsync(
            long espacioFinancieroId,
            decimal valor,
            IReadOnlyCollection<ReglaRepartoItemRequest>? distribucion)
    {
        if (distribucion is null || distribucion.Count == 0)
        {
            return DistribucionGastoResult.Fallo(
                "Debe ingresar al menos una distribución."
            );
        }

        var validacion = await ValidarDistribucionPersonalizadaAsync(
            espacioFinancieroId,
            distribucion);

        if (!validacion.EsValido)
        {
            return DistribucionGastoResult.Fallo(validacion.Error!);
        }

        return DistribucionGastoResult.Ok(
            CrearDistribucionesPreparadas(valor, distribucion));
    }

    private async Task<ValidacionRepartoResult> ValidarResponsableAsync(
        long espacioFinancieroId,
        long? responsableId)
    {
        if (!responsableId.HasValue)
        {
            return ValidacionRepartoResult.Fallo(
                "Debe indicar el responsable del gasto individual."
            );
        }

        var responsablePertenece = await _context.EspaciosUsuarios
            .AnyAsync(x =>
                x.EspacioFinancieroId == espacioFinancieroId &&
                x.UsuarioId == responsableId.Value);

        if (!responsablePertenece)
        {
            return ValidacionRepartoResult.Fallo(
                "El responsable debe pertenecer al espacio financiero."
            );
        }

        return ValidacionRepartoResult.Ok();
    }

    private async Task<ValidacionRepartoResult>
        ValidarDistribucionPersonalizadaAsync(
            long espacioFinancieroId,
            IReadOnlyCollection<ReglaRepartoItemRequest>? distribucion)
    {
        if (distribucion is null || distribucion.Count == 0)
        {
            return ValidacionRepartoResult.Fallo(
                "Debe ingresar al menos una distribución."
            );
        }

        if (distribucion
            .GroupBy(x => x.UsuarioId)
            .Any(x => x.Count() > 1))
        {
            return ValidacionRepartoResult.Fallo(
                "No puede repetir un usuario en la distribución."
            );
        }

        if (distribucion.Any(x => x.Porcentaje <= 0))
        {
            return ValidacionRepartoResult.Fallo(
                "Cada porcentaje debe ser mayor a 0."
            );
        }

        var total = distribucion.Sum(x => x.Porcentaje);

        if (total != 100m)
        {
            return ValidacionRepartoResult.Fallo(
                $"Los porcentajes deben sumar 100%. Actualmente suman {total}%."
            );
        }

        var usuariosIds = distribucion
            .Select(x => x.UsuarioId)
            .ToList();

        var miembrosValidos = await _context.EspaciosUsuarios
            .Where(x =>
                x.EspacioFinancieroId == espacioFinancieroId &&
                usuariosIds.Contains(x.UsuarioId))
            .Select(x => x.UsuarioId)
            .ToListAsync();

        if (miembrosValidos.Count != usuariosIds.Count)
        {
            return ValidacionRepartoResult.Fallo(
                "Todos los usuarios deben pertenecer al espacio financiero."
            );
        }

        return ValidacionRepartoResult.Ok();
    }

    private static IReadOnlyCollection<DistribucionGastoPreparada>
        CrearDistribucionesPreparadas(
            decimal valor,
            IEnumerable<ReglaReparto> reglas)
    {
        return reglas
            .Select(x => new DistribucionGastoPreparada(
                x.UsuarioId,
                x.Porcentaje,
                CalcularValorDistribucion(valor, x.Porcentaje)))
            .ToList();
    }

    private static IReadOnlyCollection<DistribucionGastoPreparada>
        CrearDistribucionesPreparadas(
            decimal valor,
            IEnumerable<ReglaRepartoItemRequest> distribucion)
    {
        return distribucion
            .Select(x => new DistribucionGastoPreparada(
                x.UsuarioId,
                x.Porcentaje,
                CalcularValorDistribucion(valor, x.Porcentaje)))
            .ToList();
    }

    private static decimal CalcularValorDistribucion(
        decimal valor,
        decimal porcentaje)
    {
        return Math.Round(
            valor * porcentaje / 100m,
            2
        );
    }

    public async Task CrearDistribucionHistoricaAsync(
        Gasto gasto,
        IReadOnlyCollection<DistribucionGastoPreparada> distribucion)
    {
        if (distribucion.Count == 0)
        {
            return;
        }

        var usuariosConDistribucion = await _context.DistribucionesGasto
            .Where(x => x.GastoId == gasto.Id)
            .Select(x => x.UsuarioId)
            .ToListAsync();

        foreach (var item in distribucion)
        {
            if (usuariosConDistribucion.Contains(item.UsuarioId))
            {
                continue;
            }

            _context.DistribucionesGasto.Add(
                new DistribucionGasto
                {
                    GastoId = gasto.Id,
                    UsuarioId = item.UsuarioId,
                    Porcentaje = item.Porcentaje,
                    Valor = item.Valor
                }
            );
        }

        await _context.SaveChangesAsync();
    }

    public async Task GenerarDevolucionesAsync(
        long gastoId,
        long pagadoPorId)
    {
        var distribuciones = await _context.DistribucionesGasto
            .Where(x => x.GastoId == gastoId)
            .ToListAsync();

        if (distribuciones.Count == 0)
        {
            return;
        }

        var yaTieneDevoluciones = await _context.Devoluciones
            .AnyAsync(x => x.GastoId == gastoId);

        if (yaTieneDevoluciones)
        {
            return;
        }

        var otros = distribuciones
            .Where(x =>
                x.UsuarioId != pagadoPorId &&
                x.Valor > 0);

        foreach (var distribucion in otros)
        {
            _context.Devoluciones.Add(
                new Devolucion
                {
                    GastoId = gastoId,
                    DebeUsuarioId = distribucion.UsuarioId,
                    RecibeUsuarioId = pagadoPorId,
                    RecibeCuentaId = null,
                    Valor = distribucion.Valor,
                    ValorPagado = 0,
                    Estado = EstadoDevolucion.Pendiente
                }
            );
        }

        await _context.SaveChangesAsync();
    }
}

public class DistribucionGastoResult
{
    private DistribucionGastoResult(
        bool esValido,
        IReadOnlyCollection<DistribucionGastoPreparada> distribucion,
        string? error)
    {
        EsValido = esValido;
        Distribucion = distribucion;
        Error = error;
    }

    public bool EsValido { get; }

    public IReadOnlyCollection<DistribucionGastoPreparada> Distribucion
    {
        get;
    }

    public string? Error { get; }

    public static DistribucionGastoResult Ok(
        IReadOnlyCollection<DistribucionGastoPreparada> distribucion) =>
        new(true, distribucion, null);

    public static DistribucionGastoResult Fallo(string error) =>
        new(false, Array.Empty<DistribucionGastoPreparada>(), error);
}

public record DistribucionGastoPreparada(
    long UsuarioId,
    decimal Porcentaje,
    decimal Valor);

public class ValidacionRepartoResult
{
    private ValidacionRepartoResult(bool esValido, string? error)
    {
        EsValido = esValido;
        Error = error;
    }

    public bool EsValido { get; }

    public string? Error { get; }

    public static ValidacionRepartoResult Ok() =>
        new(true, null);

    public static ValidacionRepartoResult Fallo(string error) =>
        new(false, error);
}
