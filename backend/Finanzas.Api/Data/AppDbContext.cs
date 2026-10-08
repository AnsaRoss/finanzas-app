using Finanzas.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace Finanzas.Api.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public DbSet<Usuario> Usuarios => Set<Usuario>();
    public DbSet<EspacioFinanciero> EspaciosFinancieros => Set<EspacioFinanciero>();
    public DbSet<EspacioUsuario> EspaciosUsuarios => Set<EspacioUsuario>();
    
    public DbSet<Categoria> Categorias => Set<Categoria>();
    public DbSet<EntidadFinanciera> EntidadesFinancieras => Set<EntidadFinanciera>();
    public DbSet<Cuenta> Cuentas => Set<Cuenta>();
    public DbSet<Ingreso> Ingresos => Set<Ingreso>();
    public DbSet<GastoFijo> GastosFijos => Set<GastoFijo>();

    public DbSet<Gasto> Gastos => Set<Gasto>();
    public DbSet<Devolucion> Devoluciones => Set<Devolucion>();

    public DbSet<ReglaReparto> ReglasReparto => Set<ReglaReparto>();
    public DbSet<DistribucionGasto> DistribucionesGasto => Set<DistribucionGasto>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Usuario>()
            .HasIndex(x => x.Email)
            .IsUnique();

        modelBuilder.Entity<EspacioUsuario>()
            .HasIndex(x => new
            {
                x.EspacioFinancieroId,
                x.UsuarioId
            })
            .IsUnique();

        modelBuilder.Entity<EspacioFinanciero>()
            .HasOne(x => x.CreadoPor)
            .WithMany()
            .HasForeignKey(x => x.CreadoPorId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<EspacioUsuario>()
            .HasOne(x => x.EspacioFinanciero)
            .WithMany(x => x.Usuarios)
            .HasForeignKey(x => x.EspacioFinancieroId);

        modelBuilder.Entity<EspacioUsuario>()
            .HasOne(x => x.Usuario)
            .WithMany(x => x.Espacios)
            .HasForeignKey(x => x.UsuarioId);
        
       
        modelBuilder.Entity<Categoria>()
            .HasIndex(x => new
            {
                x.EspacioFinancieroId,
                x.Nombre,
                x.Tipo
            })
            .IsUnique();

        modelBuilder.Entity<Ingreso>()
            .Property(x => x.Valor)
            .HasPrecision(12, 2);

        modelBuilder.Entity<GastoFijo>()
            .Property(x => x.ValorEstimado)
            .HasPrecision(12, 2);

        modelBuilder.Entity<GastoFijo>()
            .HasOne(x => x.Responsable)
            .WithMany()
            .HasForeignKey(x => x.ResponsableId)
            .OnDelete(DeleteBehavior.Restrict);

        
        modelBuilder.Entity<Gasto>()
            .Property(x => x.Valor)
            .HasPrecision(12, 2);

        modelBuilder.Entity<Devolucion>()
            .Property(x => x.Valor)
            .HasPrecision(12, 2);

        modelBuilder.Entity<Devolucion>()
            .Property(x => x.ValorPagado)
            .HasPrecision(12, 2);

        modelBuilder.Entity<Gasto>()
            .HasOne(x => x.RegistradoPor)
            .WithMany()
            .HasForeignKey(x => x.RegistradoPorId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Gasto>()
            .HasOne(x => x.PagadoPor)
            .WithMany()
            .HasForeignKey(x => x.PagadoPorId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Devolucion>()
            .HasOne(x => x.Gasto)
            .WithMany(x => x.Devoluciones)
            .HasForeignKey(x => x.GastoId);

        modelBuilder.Entity<Devolucion>()
            .HasOne(x => x.DebeUsuario)
            .WithMany()
            .HasForeignKey(x => x.DebeUsuarioId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Devolucion>()
            .HasOne(x => x.RecibeUsuario)
            .WithMany()
            .HasForeignKey(x => x.RecibeUsuarioId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Devolucion>()
            .HasOne(x => x.RecibeCuenta)
            .WithMany()
            .HasForeignKey(x => x.RecibeCuentaId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<ReglaReparto>()
            .Property(x => x.Porcentaje)
            .HasPrecision(5, 2);

        modelBuilder.Entity<DistribucionGasto>()
            .Property(x => x.Porcentaje)
            .HasPrecision(5, 2);

        modelBuilder.Entity<DistribucionGasto>()
            .Property(x => x.Valor)
            .HasPrecision(12, 2);

        modelBuilder.Entity<ReglaReparto>()
            .HasIndex(x => new
            {
                x.EspacioFinancieroId,
                x.UsuarioId
            })
            .IsUnique();

        modelBuilder.Entity<ReglaReparto>()
            .HasOne(x => x.EspacioFinanciero)
            .WithMany()
            .HasForeignKey(x => x.EspacioFinancieroId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<ReglaReparto>()
            .HasOne(x => x.Usuario)
            .WithMany()
            .HasForeignKey(x => x.UsuarioId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<DistribucionGasto>()
            .HasOne(x => x.Usuario)
            .WithMany()
            .HasForeignKey(x => x.UsuarioId)
            .OnDelete(DeleteBehavior.Restrict);
        
        modelBuilder.Entity<DistribucionGasto>()
            .HasIndex(x => new
            {
                x.GastoId,
                x.UsuarioId
            })
            .IsUnique();

        modelBuilder.Entity<DistribucionGasto>()
            .HasOne(x => x.Gasto)
            .WithMany(x => x.Distribuciones)
            .HasForeignKey(x => x.GastoId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
