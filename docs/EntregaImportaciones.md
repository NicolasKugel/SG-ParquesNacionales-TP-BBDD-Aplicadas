# Entrega Importaciones Masivas y APIs

## Objetivo

El modulo agregado permite importar informacion externa desde archivos CSV mediante Stored Procedures, aplicar validaciones, registrar errores por fila, importar parcialmente los registros validos y evitar duplicados con logica de upsert.

Tambien incorpora Stored Procedures para consumir APIs por URL y registrar la respuesta en la base de datos.

## Archivos Procesados

### Areas protegidas por jurisdiccion

- Archivo: `importaciones/aprn_g_ap_juris_2025.csv`
- Formato: CSV separado por `;`
- Fuente: dataset publico sobre areas protegidas por jurisdiccion.
- Procedimiento: `Importacion.sp_ImportarAreasProtegidasCSV`
- Tabla destino: `Importacion.AreaProtegidaJurisdiccion`
- Clave de upsert: `jurisdiccion`
- Regla especial: la fila `Total` se registra como error no importable porque es un agregado del dataset, no una jurisdiccion individual.

### Visitas residentes y no residentes

- Archivo: `importaciones/visitas-residentes-y-no-residentes.csv`
- Formato: CSV separado por `,`
- Fuente: dataset publico turistico sobre visitas historicas de residentes y no residentes.
- Procedimiento: `Importacion.sp_ImportarVisitasTuristicasCSV`
- Tabla destino: `Importacion.VisitaTuristicaHistorica`
- Clave de upsert: `indice_tiempo + origen_visitantes`
- Regla historica: se mantiene un registro por periodo y origen. Al reimportar el mismo periodo se actualiza, no se duplica.

## Objetos Creados

El script `scripts/04-Importaciones.sql` crea el schema `Importacion` y los siguientes objetos:

- `Importacion.LoteImportacion`: cabecera de cada ejecucion de importacion.
- `Importacion.ErrorImportacion`: errores de formato, datos faltantes o filas no importables.
- `Importacion.StageAreaProtegidaJurisdiccion`: tabla temporal persistente para carga cruda del CSV de areas protegidas.
- `Importacion.AreaProtegidaJurisdiccion`: tabla final normalizada.
- `Importacion.StageVisitaTuristica`: tabla temporal persistente para carga cruda del CSV de visitas.
- `Importacion.VisitaTuristicaHistorica`: tabla final historica.
- `Importacion.ApiConsulta`: registro de llamadas a APIs y respuesta cruda.
- `Importacion.ApiCotizacion`: cotizaciones parseadas desde APIs JSON compatibles.
- `Importacion.sp_RegistrarErrorImportacion`: alta centralizada de errores.
- `Importacion.sp_ImportarAreasProtegidasCSV`: importacion y upsert del dataset de areas protegidas.
- `Importacion.sp_ImportarVisitasTuristicasCSV`: importacion y upsert del dataset de visitas turisticas.
- `Importacion.sp_ConsumirApi`: consumo generico de API por URL.
- `Importacion.sp_RegistrarCotizacionDesdeApi`: consumo de API y parseo de cotizaciones desde JSON con nodo `results`.

## Validaciones

Los procedimientos no abortan toda la importacion ante errores de datos. Primero cargan el archivo crudo a staging, luego registran errores y finalmente importan solo las filas validas.

Validaciones de areas protegidas:

- `jurisdicciones` obligatorio.
- La fila `Total` no se importa por ser agregada.
- Campos de cantidad deben convertir a entero.
- Campos de hectareas y porcentaje deben convertir a decimal.
- Cantidades, superficies y porcentajes no pueden ser negativos.
- El valor `-` se interpreta como dato no informado y se guarda como `NULL`.

Validaciones de visitas turisticas:

- `indice_tiempo` debe convertir a fecha.
- `origen_visitantes` debe ser `residentes`, `no residentes` o `total`.
- `visitas` debe ser entero mayor o igual a cero.

## Ejecucion

Orden sugerido:

```sql
:r scripts/00-CreaBDySCHEMAS.sql
:r scripts/01-CreaTablas.sql
:r scripts/02-ABM.sql
:r scripts/03-logicaNegocio.sql
:r scripts/04-Importaciones.sql
:r scripts/testImportaciones.sql
```

El archivo `scripts/testImportaciones.sql` usa SQLCMD mode y define la variable `RutaImportaciones` con la ruta local de la carpeta `importaciones`.

## Requisitos Para BULK INSERT

Los SP de importacion reciben `@NombreArchivo` y `@RutaArchivo`. La ruta debe ser accesible para el servicio de SQL Server, no solo para el usuario de Windows que ejecuta SSMS.

Si SQL Server no puede leer la ruta por permisos, OneDrive, espacios o acentos, hay dos alternativas:

- Dar permisos de lectura sobre la carpeta al usuario del servicio SQL Server.
- Usar una ruta local simple accesible por SQL Server y pasar esa ruta como parametro.

Los archivos CSV no deben editarse antes de importarlos.

## Consumo De APIs

El procedimiento `Importacion.sp_ConsumirApi` recibe la URL como parametro. Se documentan dos APIs consumibles desde el modulo:

- API de feriados de Argentina Datos: permite consultar feriados nacionales por anio para aplicar reglas de negocio o reportes por dias especiales.
- API BCRA de estadisticas monetarias: permite consultar variables monetarias y cotizaciones para conversiones de moneda.

Ejemplo de consumo de feriados:

```sql
DECLARE @ApiConsultaId int;

EXEC Importacion.sp_ConsumirApi
    @UrlApi = 'https://api.argentinadatos.com/v1/feriados/2026',
    @Metodo = 'GET',
    @ApiConsultaId = @ApiConsultaId OUTPUT;
```

Ejemplo de consumo de BCRA con registro de cotizaciones:

```sql
DECLARE @ApiConsultaId int;

EXEC Importacion.sp_RegistrarCotizacionDesdeApi
    @UrlApi = 'https://api.bcra.gob.ar/estadisticas/v4.0/DatosVariable/4/2026-06-01/2026-06-30',
    @Moneda = 'USD',
    @ApiConsultaId = @ApiConsultaId OUTPUT;
```

Este procedimiento espera una respuesta con un arreglo `results` y campos `fecha` y `valor`.

## Requisitos Para sp_OA

El consumo HTTP desde SQL Server usa `sp_OACreate`, `sp_OAMethod` y `sp_OAGetProperty`. Para ejecutarlo, el servidor debe tener habilitado `Ole Automation Procedures`.

Configuracion habitual, a ejecutar con permisos de administrador:

```sql
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE;
```

Si la opcion no esta habilitada, los SP de importacion de archivos siguen funcionando, pero los SP de API registraran error o fallaran al intentar invocar `sp_OA*`.

## Evidencias Esperadas

Luego de ejecutar `scripts/testImportaciones.sql` se puede verificar:

- `Importacion.LoteImportacion`: cada importacion con cantidades leidas, validas, insertadas, actualizadas y errores.
- `Importacion.ErrorImportacion`: filas rechazadas y motivo.
- `Importacion.AreaProtegidaJurisdiccion`: registros importados sin duplicados por jurisdiccion.
- `Importacion.VisitaTuristicaHistorica`: historico sin duplicados por periodo y origen.
- `Importacion.ApiConsulta`: respuesta cruda y estado de cada API consumida.
- `Importacion.ApiCotizacion`: cotizaciones parseadas cuando la respuesta JSON sea compatible.
