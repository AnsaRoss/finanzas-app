# Finanzas App

Aplicación para la gestión de finanzas personales y compartidas por hogar.

## Stack tecnológico

### Backend

* .NET 9
* ASP.NET Core Web API
* Entity Framework Core 9
* JWT
* Swagger / OpenAPI

### Base de datos

* MySQL 8

### Aplicación móvil

* Flutter / Dart *(pendiente)*

---

## Estructura

```text
finanzas-app/
├── backend/
│   └── Finanzas.Api/
└── mobile/
```

---

# Enums

## TipoEspacio

| Valor | Descripción |
| ----: | ----------- |
|     1 | Personal    |
|     2 | Hogar       |

## RolEspacio

| Valor | Descripción |
| ----: | ----------- |
|     1 | Propietario |
|     2 | Miembro     |

## TipoCategoria

| Valor | Descripción |
| ----: | ----------- |
|     1 | Ingreso     |
|     2 | Gasto       |

## TipoCuenta

| Valor | Descripción        |
| ----: | ------------------ |
|     1 | Efectivo           |
|     2 | Cuenta de ahorros  |
|     3 | Cuenta corriente   |
|     4 | Tarjeta de crédito |
|     5 | Otro               |

## TipoGasto

| Valor | Descripción |
| ----: | ----------- |
|     1 | Fijo        |
|     2 | Variable    |

## EstadoDevolucion

| Valor | Descripción |
| ----: | ----------- |
|     1 | Pendiente   |
|     2 | Parcial     |
|     3 | Pagada      |

---

# Conceptos principales

## Espacios financieros

Cada usuario tiene automáticamente un espacio financiero de tipo **Personal**.

Un usuario también puede crear o pertenecer a espacios de tipo **Hogar**, permitiendo compartir gastos y movimientos con otros usuarios.

Ejemplo:

```text
Sandra
├── Personal - Sandra
└── Hogar
    ├── Sandra (Propietario)
    └── Andres (Miembro)

Andres
├── Personal - Andres
└── Hogar
```

## Categorías

Las categorías pertenecen a un espacio financiero y pueden ser de:

* Ingreso
* Gasto

Ejemplos:

```text
Ingreso
└── Sueldo

Gasto
├── Arriendo casa
├── Garage
├── Alimentación
└── Servicios básicos
```

## Cuentas

Las cuentas también pertenecen a un espacio financiero.

Ejemplos:

```text
Banco Guayaquil
├── Cuenta de ahorros
└── TC Mastercard

Banco Pichincha
└── Cuenta corriente

Sin entidad financiera
└── Efectivo
```

Una cuenta puede tener un propietario dentro del espacio financiero.

---

# Autenticación

La API utiliza JWT Bearer.

Endpoints:

```text
POST /api/Auth/register
POST /api/Auth/login
```

Al registrar un usuario se crea automáticamente:

1. El usuario.
2. Su espacio financiero Personal.
3. Su membresía como Propietario del espacio.

Los endpoints protegidos requieren:

```text
Authorization: Bearer <token>
```

Swagger permite ingresar el JWT mediante el botón **Authorize**.

---

# Espacios

```text
GET  /api/Espacios
POST /api/Espacios/hogar
POST /api/Espacios/{id}/miembros
```

Solo el propietario de un Hogar puede agregar miembros.

---

# Categorías

```text
GET  /api/Categorias/espacio/{espacioId}
POST /api/Categorias
```

El usuario debe pertenecer al espacio financiero para consultar o crear categorías.

---

# Entidades financieras

```text
GET  /api/EntidadesFinancieras
POST /api/EntidadesFinancieras
```

Ejemplos:

* Banco Guayaquil
* Banco Pichincha
* Produbanco

---

# Cuentas

```text
GET  /api/Cuentas/espacio/{espacioId}
POST /api/Cuentas
```

Una cuenta puede estar asociada opcionalmente a:

* Una entidad financiera.
* Un propietario.

Para efectivo no es necesario especificar una entidad financiera.

---

# Modelo financiero previsto

La aplicación manejará:

* Ingresos.
* Gastos fijos.
* Gastos variables.
* Cuentas y tarjetas.
* Devoluciones entre personas.
* Devoluciones hacia cuentas/tarjetas.
* Porcentaje de aporte sobre ingresos.
* Libro diario.
* Reportería mensual.
* Finanzas personales.
* Finanzas compartidas por hogar.

---

# Base de datos

La base de datos utilizada es:

```text
finanzas_app
```

Las modificaciones del esquema se gestionan mediante Entity Framework Core Migrations.

Crear una migración:

```bash
dotnet ef migrations add NombreMigracion
```

Aplicarla:

```bash
dotnet ef database update
```

---

# Configuración local

Las credenciales de MySQL y la clave JWT **no deben almacenarse en Git**.

Se utiliza .NET User Secrets para desarrollo.

Ejemplo:

```bash
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "<connection-string>"
dotnet user-secrets set "Jwt:Key" "<jwt-key>"
dotnet user-secrets set "Jwt:Issuer" "Finanzas.Api"
dotnet user-secrets set "Jwt:Audience" "Finanzas.Mobile"
```

---

# Estado actual

Implementado:

* [x] Proyecto ASP.NET Core Web API
* [x] MySQL + Entity Framework Core
* [x] Migraciones
* [x] Registro de usuarios
* [x] Login con JWT
* [x] Espacio personal automático
* [x] Creación de hogares
* [x] Miembros de hogares
* [x] Categorías
* [x] Entidades financieras
* [x] Cuentas
* [x] Swagger con JWT

Pendiente:

* [ ] Ingresos
* [ ] Gastos fijos
* [ ] Gastos variables
* [ ] Devoluciones
* [ ] Reportería
* [ ] Libro diario
* [ ] Dashboard
* [ ] Detección de conceptos similares
* [ ] Aplicación Flutter
