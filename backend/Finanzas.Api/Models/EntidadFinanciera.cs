using System.ComponentModel.DataAnnotations;

namespace Finanzas.Api.Models;

public class EntidadFinanciera
{
    public long Id { get; set; }

    [Required]
    [MaxLength(100)]
    public string Nombre { get; set; } = string.Empty;

    public bool Activo { get; set; } = true;
}