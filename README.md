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

## EstadoGasto

| Valor | Descripción |
| ----: | ----------- |
|     1 | Pendiente   |
|     2 | Pagado      |
|     3 | Anulado     |

## TipoRepartoGasto

| Valor | Descripción     |
| ----: | --------------- |
|     1 | Regla del hogar |
|     2 | Individual      |
|     3 | Personalizado   |

## EstadoDevolucion

| Valor | Descripción |
| ----: | ----------- |
|     1 | Pendiente   |
|     2 | Parcial     |
|     3 | Pagada      |

## EstadoIngreso

| Valor | Descripción |
| ----: | ----------- |
|     1 | Activo      |
|     2 | Anulado     |

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

---

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

---

## Cuentas

Las cuentas pertenecen a un espacio financiero.

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

# Reparto de gastos

Los gastos de un hogar pueden distribuirse de tres formas.

### Regla del hogar

Utiliza la regla general configurada para los miembros.

Ejemplo:

```text
Sandra → 30%
Andres → 70%
```

Un gasto de $300 genera:

```text
Sandra → $90
Andres → $210
```

### Individual

El gasto corresponde completamente a una sola persona.

Ejemplo:

```text
Garage = $50
Responsable: Andres

Andres → 100% = $50
```

### Personalizado

Permite indicar porcentajes específicos para un gasto.

Ejemplo:

```text
Compra especial = $100

Sandra → 20% = $20
Andres → 80% = $80
```

La distribución aplicada se guarda históricamente en `DistribucionGasto`.

Si posteriormente cambia la regla general del hogar, los gastos anteriores conservan el reparto con el que fueron creados.

---

# Autenticación

La API utiliza JWT Bearer.

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

# Reglas de reparto

Permiten configurar el porcentaje general de participación de los miembros de un hogar.

```text
GET /api/ReglasReparto/espacio/{espacioId}
PUT /api/ReglasReparto/espacio/{espacioId}
```

Ejemplo:

```json
{
  "distribuciones": [
    {
      "usuarioId": 1,
      "porcentaje": 30
    },
    {
      "usuarioId": 2,
      "porcentaje": 70
    }
  ]
}
```

Los porcentajes deben sumar exactamente `100%`.

---

# Ingresos

```text
GET   /api/Ingresos/espacio/{espacioId}
POST  /api/Ingresos
PUT   /api/Ingresos/{id}
PATCH /api/Ingresos/{id}/anular
```

Los ingresos pueden asociarse a:

* Usuario.
* Categoría.
* Cuenta.
* Fecha.
* Observación.

Los ingresos anulados se mantienen como histórico, pero no deben contabilizarse en los totales mensuales.

---

# Gastos fijos

Un gasto fijo funciona como una plantilla recurrente.

Ejemplos:

* Arriendo.
* Internet.
* Garage.
* Servicios básicos.

Endpoints:

```text
GET   /api/GastosFijos/espacio/{espacioId}
POST  /api/GastosFijos
PUT   /api/GastosFijos/{id}
PATCH /api/GastosFijos/{id}/estado
POST  /api/GastosFijos/{id}/generar
```

Generar un gasto fijo crea una ocurrencia mensual en estado **Pendiente**.

La distribución del gasto se copia en ese momento para conservar el histórico.

No se permite generar dos veces el mismo gasto fijo para el mismo mes.

---

# Gastos

Los gastos pueden ser:

* Fijos.
* Variables.
* Pendientes.
* Pagados.
* Anulados.

Endpoints principales:

```text
GET   /api/Gastos/espacio/{espacioId}
POST  /api/Gastos/variable
PATCH /api/Gastos/{id}/pagar
PATCH /api/Gastos/{id}/anular
```

La consulta de gastos permite filtros opcionales:

```text
anio
mes
estado
tipo
```

Ejemplo:

```text
GET /api/Gastos/espacio/2?anio=2026&mes=8&estado=2&tipo=2
```

---

# Pago de gastos

Un gasto generado puede permanecer pendiente hasta que se registre su pago.

Al pagar se registra:

* Persona que pagó.
* Cuenta opcional.
* Fecha de pago.
* Estado Pagado.

Ejemplo:

```text
PATCH /api/Gastos/{id}/pagar
```

```json
{
  "pagadoPorId": 1,
  "cuentaId": null,
  "fechaPago": "2026-08-24"
}
```

El pago y la generación de devoluciones se ejecutan de forma transaccional.

---

# Devoluciones

Cuando una persona paga más de lo que le corresponde según la distribución del gasto, se generan devoluciones automáticamente.

Ejemplo:

```text
Supermercado = $100

Sandra debe asumir 30% = $30
Andres debe asumir 70% = $70

Sandra paga los $100

→ Andres debe devolver $70 a Sandra
```

Endpoints:

```text
GET   /api/Devoluciones/espacio/{espacioId}
PATCH /api/Devoluciones/{id}/pagar
```

Las devoluciones admiten pagos parciales.

Ejemplo:

```text
Deuda:      $210
Pago:       $100
Pendiente:  $110
Estado:     Parcial
```

Después de completar el saldo:

```text
Pendiente: $0
Estado: Pagada
```

---

# Reportería

## Resumen mensual

```text
GET /api/Reportes/resumen
```

Parámetros:

```text
espacioId
anio
mes
```

Incluye:

* Total de ingresos.
* Total de gastos.
* Saldo.
* Gastos pagados.
* Gastos pendientes.
* Gastos fijos.
* Gastos variables.
* Devoluciones pendientes.

Los gastos anulados y los ingresos anulados no deben afectar los totales.

---

## Libro diario

```text
GET /api/Reportes/libro-diario
```

Agrupa cronológicamente:

* Ingresos.
* Gastos fijos.
* Gastos variables.

Los movimientos anulados pueden permanecer visibles para mantener trazabilidad, pero no afectan los totales.

Ejemplo:

```text
24/08 | Sueldo mensual | INGRESO        | +1200
24/08 | Arriendo casa  | GASTO_FIJO     | -300
24/08 | Supermercado   | GASTO_VARIABLE | -100
```

---

## Reporte de devoluciones

```text
GET /api/Reportes/devoluciones
```

Permite consultar resumen y detalle de las devoluciones.

Ejemplo:

```text
Andres debe a Sandra: $150
```

Detalle:

```text
Supermercado     $70
Compra especial  $80
```

Las devoluciones ya pagadas permanecen en el detalle histórico, pero no suman al pendiente.

---

# Detección de conceptos similares

La API incluye búsqueda de conceptos similares para evitar registros duplicados con nombres diferentes.

Ejemplo:

```text
Pierna de chancho
Chancho pierna
```

Endpoint:

```text
POST /api/Conceptos/similares
```

La comparación normaliza:

* Mayúsculas/minúsculas.
* Tildes.
* Signos.
* Orden y coincidencia de palabras.

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

Consultar migraciones:

```bash
dotnet ef migrations list
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

## Implementado

* [x] Proyecto ASP.NET Core Web API
* [x] MySQL + Entity Framework Core
* [x] Migraciones
* [x] Registro de usuarios
* [x] Login con JWT
* [x] Swagger con JWT
* [x] Espacio personal automático
* [x] Creación de hogares
* [x] Miembros y roles
* [x] Categorías
* [x] Entidades financieras
* [x] Cuentas
* [x] Ingresos
* [x] Gastos fijos
* [x] Gastos variables
* [x] Estado pendiente / pagado / anulado
* [x] Reglas generales de reparto
* [x] Reparto individual
* [x] Reparto personalizado
* [x] Distribución histórica de gastos
* [x] Pago de gastos
* [x] Devoluciones automáticas
* [x] Pagos parciales de devoluciones
* [x] Anulación de gastos
* [x] Filtros por año, mes, estado y tipo
* [x] Resumen mensual
* [x] Libro diario
* [x] Reporte de devoluciones
* [x] Servicio centralizado para lógica de gastos/reparto
* [x] Operaciones críticas transaccionales
* [x] Detección de conceptos similares

## Pendiente de validación

* [ ] Probar edición de ingresos
* [ ] Probar anulación de ingresos
* [ ] Confirmar que ingresos anulados no afecten el resumen mensual
* [ ] Probar detección de conceptos similares
* [ ] Ejecutar regresión general de endpoints
* [ ] Confirmar `dotnet build` sin errores ni warnings

## Pendiente de desarrollo

* [ ] Dashboard móvil
* [ ] Aplicación Flutter
* [ ] Integración Flutter ↔ API
* [ ] Mejoras visuales y experiencia de usuario
* [ ] Pruebas finales del flujo completo
