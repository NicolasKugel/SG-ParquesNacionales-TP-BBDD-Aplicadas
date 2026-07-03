# Entrega Importaciones Masivas

## Objetivo

El modulo permite importar datos CSV y Excel de entidades relevantes mediante Stored Procedures. Cada SP recibe la ruta del archivo, carga sus lineas en una tabla intermedia, interpreta las columnas con un mapeo JSON, valida datos, registra errores por fila y aplica upsert sobre la entidad destino.

El uso de SQL dinamico queda acotado a los casos necesarios: `OPENROWSET(BULK...)` para CSV y `OPENROWSET` con ACE OLEDB para Excel requieren que la ruta del archivo sea parte de una sentencia dinamica.

## Objetos Principales

- `Importacion.LoteImportacion`: cabecera de cada importacion.
- `Importacion.CsvLineaTrabajo`: tabla tecnica usada por `BULK INSERT` para cargar lineas crudas.
- `Importacion.CsvLinea`: lineas crudas asociadas a un lote.
- `Importacion.ErrorImportacion`: errores detectados por lote y fila.
- `Importacion.fn_ValorCsvLinea`: obtiene el valor de una columna segun su posicion dentro de una linea.
- `Importacion.fn_CantidadColumnasCsvLinea`: cuenta columnas de una linea segun el separador.
- `Importacion.usp_CargarCsvLineasDesdeArchivo`: helper que carga el archivo en `CsvLinea`.
- `Importacion.usp_CargarExcelLineasDesdeArchivo`: helper que lee Excel con `Microsoft.ACE.OLEDB.16.0` y carga sus filas en `CsvLinea`.

## SPs De Importacion CSV

Todos los SP de entidad usan esta firma:

```sql
@LoteId int,
@RutaArchivo varchar(1000),
@MapeoColumnas nvarchar(max),
@NombreArchivo varchar(260) = NULL,
@Separador varchar(5) = ',',
@PrimeraFilaDatos int = 2,
@TipoArchivo varchar(10) = 'CSV',
@NombreHoja varchar(128) = NULL
```

SPs disponibles:

- `Importacion.usp_ImportarParqueCSV`
- `Importacion.usp_ImportarVisitanteCSV`
- `Importacion.usp_ImportarAtraccionCSV`
- `Importacion.usp_ImportarGuiaCSV`
- `Importacion.usp_ImportarGuardaParqueCSV`

## Flujo De Uso

1. Crear un lote en `Importacion.LoteImportacion`.
2. Ejecutar el SP de la entidad indicando `@RutaArchivo` y `@MapeoColumnas`.
3. El SP carga el archivo en `Importacion.CsvLinea` usando el helper CSV o Excel segun `@TipoArchivo`.
4. El SP valida, registra errores e importa los registros validos.
5. Consultar `Importacion.LoteImportacion` y `Importacion.ErrorImportacion`.

Ejemplo:

```sql
INSERT INTO Importacion.LoteImportacion (dataset, nombre_archivo, ruta_archivo)
VALUES ('Visitante', 'visitantes.csv', 'C:\SQLImports\visitantes.csv');

DECLARE @LoteId int = SCOPE_IDENTITY();

EXEC Importacion.usp_ImportarVisitanteCSV
    @LoteId = @LoteId,
    @RutaArchivo = 'C:\SQLImports\visitantes.csv',
    @MapeoColumnas = '{"nombre":1,"apellido":2,"dni":3}',
    @NombreArchivo = 'visitantes.csv',
    @Separador = ',',
    @PrimeraFilaDatos = 2;

SELECT *
FROM Importacion.LoteImportacion
WHERE id = @LoteId;

SELECT *
FROM Importacion.ErrorImportacion
WHERE lote_id = @LoteParque;

SELECT *
FROM Importacion.CsvLinea
WHERE lote_id = @LoteId
ORDER BY fila;

SELECT TOP 100 *
FROM <Tabla en donde impacto la importacion>;
```

Ejemplo Excel:

```sql
INSERT INTO Importacion.LoteImportacion (dataset, nombre_archivo, ruta_archivo)
VALUES ('Visitante', 'visitantes.xlsx', 'C:\SQLImports\visitantes.xlsx');

DECLARE @LoteId int = SCOPE_IDENTITY();

EXEC Importacion.usp_ImportarVisitanteCSV
    @LoteId = @LoteId,
    @RutaArchivo = 'C:\SQLImports\visitantes.xlsx',
    @MapeoColumnas = '{"nombre":1,"apellido":2,"dni":3}',
    @NombreArchivo = 'visitantes.xlsx',
    @Separador = ',',
    @PrimeraFilaDatos = 2,
    @TipoArchivo = 'XLSX',
    @NombreHoja = 'Hoja1';

SELECT *
FROM Importacion.LoteImportacion
WHERE id = @LoteId;

SELECT *
FROM Importacion.ErrorImportacion
WHERE lote_id = @LoteId;

SELECT *
FROM Importacion.CsvLinea
WHERE lote_id = @LoteId
ORDER BY fila;

SELECT TOP 100 *
FROM <Tabla en donde Impacta la importacion>;
```

## Mapeos Esperados (La numeración de las columnas puede variar)
El atributo que quede mapeado con el número de columna se va a intentar importar, esto implica que la importación falle
por validaciones definidas en la tabla para el atributo.

Parque:

```json
{"Codigo":1,"nombre":2,"ubicacion":3,"tipo_parque":4,"superficie_ha":5}
```

Visitante:

```json
{"nombre":1,"apellido":2,"dni":3}
```

Atraccion:

```json
{"nombre":1,"descripcion":2,"duracion":3,"cupo_maximo":4,"costo":5,"CodigoParque":6}
```

Guia:

```json
{"nombre":1,"apellido":2,"dni":3,"titulo":4,"tipo_habilitacion":5,"especialidad":6}
```

GuardaParque:

```json
{"nombre":1,"apellido":2,"dni":3,"estado":4}
```

## Reglas De Upsert

- Parque: `Codigo`.
- Visitante: `dni`.
- Guia: `dni`.
- GuardaParque: `dni`.
- Atraccion: `nombre + parque_id`, resolviendo `parque_id` por `CodigoParque`.

## Validaciones

- Si falta un atributo obligatorio en el mapeo JSON, el lote queda en error.
- Si una fila no cumple las reglas de la entidad, se registra en `Importacion.ErrorImportacion`.
- Si el archivo o una fila tiene una sola columna, se registra error porque no puede mapearse a una entidad.
- Las filas validas se importan aunque otras filas tengan errores.

## Limitaciones Del Parser CSV

El parser implementado es simple y adecuado para el alcance academico del TP. Soporta separadores simples como `,` o `;` y remueve comillas dobles comunes.

No soporta correctamente separadores dentro de campos entrecomillados, por ejemplo:

```csv
"Juan, Carlos",Perez,35123456
```

Para CSVs complejos de produccion se recomienda usar herramientas especializadas como SSIS, Import Wizard avanzado, format files o procesos ETL externos.

## Importacion Excel

La importacion Excel usa `Microsoft.ACE.OLEDB.16.0` con `HDR=NO`. Esto significa que la primera fila del Excel se lee como una fila normal, igual que en CSV. Por eso `@PrimeraFilaDatos = 2` saltea encabezados y el mapeo JSON sigue siendo por posicion.

El helper lee el rango `A:AD`, equivalente a un maximo de 30 columnas. Si se necesita importar un Excel con mas columnas, se debe ampliar ese rango en `Importacion.usp_CargarExcelLineasDesdeArchivo`.

Requisitos para Excel:

- Driver `Microsoft.ACE.OLEDB.16.0` instalado y visible desde SQL Server.
- `Ad Hoc Distributed Queries` habilitado.
- Permisos de lectura para la cuenta del servicio SQL Server sobre la carpeta del archivo.
- Indicar `@NombreHoja` sin el signo `$`, por ejemplo `Hoja1`.

## Anotaciones sobre como configure el driver Microsoft.ACE.OLEDB.16.0 y Microsoft.ACE.OLEDB.12.0

1. Ver si tengo instalado el driver:
	1. EXEC master.dbo.sp_enum_oledb_providers;
2. Nombre del driver: Microsoft.ACE.OLEDB.12.0
3. Si no se tiene el driver hay que descargarlo desde esta pagina de microsoft:`https://www.microsoft.com/en-us/download/details.aspx?id=54920`
4. instalado el driver, reiniciar SSMS.
5. Ejecutar esta query:
```sql
SELECT * FROM OPENROWSET(
	    'Microsoft.ACE.OLEDB.16.0',
	    'Excel 12.0;Database=C:\SQLImports\TP-BBDD-Aplicadas\telefonia_fija_accesos_provincias.xlsx;HDR=YES',
	    'SELECT * FROM [hoja1$]'
	  )
```
Si se genera este error:
```
Mens. 15281, Nivel 16, Estado 1, Línea 41
SQL Server blocked access to STATEMENT 'OpenRowset/OpenDatasource' of component 'Ad Hoc Distributed Queries' because this component is turned off as part of the security configuration for this server. A system administrator can enable the use of 'Ad Hoc Distributed Queries' by using sp_configure. For more information about enabling 'Ad Hoc Distributed Queries', search for 'Ad Hoc Distributed Queries' in SQL Server Books Online.
Hora de finalización: 2026-07-03T01:13:09.2013092-03:00
```
Hay que ejecutar estas queries:
```sql
EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1; RECONFIGURE;
```
Si sigue fallando:
```
1. Vamos al menú izquierdo (Explorador de objetos)
2. Objetos de servidor -> Servidores Vinculados -> Proveedores -> Entramos a los drivers y habilitamos en inprocess.
3. Reiniciar SMSS.
```
## Rutas Y Permisos

SQL Server lee archivos desde el servicio de SQL Server, no desde SSMS. Por eso `@RutaArchivo` debe apuntar a una ruta existente y accesible por el usuario del servicio SQL Server.

Recomendacion practica:

- Mantener los archivos originales en la carpeta `importaciones/` del repositorio.
- Para ejecutar en SQL Server local, copiar los archivos a una carpeta simple, por ejemplo `C:\SQLImports\TP-BBDD-Aplicadas`.
- Usar esa ruta absoluta en `@RutaArchivo`.
