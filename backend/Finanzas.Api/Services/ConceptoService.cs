
using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace Finanzas.Api.Services;

public class ConceptoService
{
    public string Normalizar(string texto)
    {
        if (string.IsNullOrWhiteSpace(texto))
        {
            return string.Empty;
        }

        texto = texto.Trim().ToLowerInvariant();

        var normalized = texto.Normalize(NormalizationForm.FormD);

        var builder = new StringBuilder();

        foreach (var c in normalized)
        {
            var category = CharUnicodeInfo.GetUnicodeCategory(c);

            if (category != UnicodeCategory.NonSpacingMark)
            {
                builder.Append(c);
            }
        }

        texto = builder
            .ToString()
            .Normalize(NormalizationForm.FormC);

        texto = Regex.Replace(
            texto,
            @"[^a-z0-9\s]",
            " "
        );

        texto = Regex.Replace(
            texto,
            @"\s+",
            " "
        );

        return texto.Trim();
    }

    public double CalcularSimilitud(string texto1, string texto2)
    {
        var palabras1 = Normalizar(texto1)
            .Split(' ', StringSplitOptions.RemoveEmptyEntries)
            .ToHashSet();

        var palabras2 = Normalizar(texto2)
            .Split(' ', StringSplitOptions.RemoveEmptyEntries)
            .ToHashSet();

        if (palabras1.Count == 0 || palabras2.Count == 0)
        {
            return 0;
        }

        var interseccion = palabras1.Intersect(palabras2).Count();
        var union = palabras1.Union(palabras2).Count();

        return (double)interseccion / union;
    }
}