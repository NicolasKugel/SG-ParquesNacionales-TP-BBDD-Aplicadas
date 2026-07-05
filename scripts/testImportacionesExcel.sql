/*******************************************************************************
Fecha: 30/06/2026
Integrantes: [Nicolas Kugel, Facundo Gargiulo, Valentin Martinez]
Descripcion: Pruebas del modulo de importacion Excel por Stored Procedures.
             Requiere ejecutar antes: 00, 01, 02, 03 y 04-Importaciones.sql.

IMPORTANTE: el archivo XLSX debe estar disponible para SQL Server en:
             C:\SQLImports\TP-BBDD-Aplicadas\tests\testImportacionesExcel.xlsx
*******************************************************************************/
USE TPBDG5;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST E-01: Importacion XLSX de parques';
PRINT '---------------------------------------------------------';

DECLARE @RutaImportaciones varchar(255) = 'C:\SQLImports\TP-BBDD-Aplicadas\tests\';
DECLARE @NombreArchivo varchar(255) = 'testImportacionesExcel.xlsx';
DECLARE @RutaArchivoCompleta varchar(510) = @RutaImportaciones + @NombreArchivo;

INSERT INTO Importacion.LoteImportacion (dataset, nombre_archivo, ruta_archivo)
VALUES ('Parque', @NombreArchivo, @RutaArchivoCompleta);

DECLARE @LoteParque int = SCOPE_IDENTITY();

EXEC Importacion.usp_ImportarParqueArchivo
    @LoteId = @LoteParque,
    @RutaArchivo = @RutaArchivoCompleta,
    @MapeoColumnas = '{"Codigo":1,"nombre":2,"ubicacion":3,"tipo_parque":4,"superficie_ha":5}',
    @NombreArchivo = @NombreArchivo,
    @TipoArchivo = 'XLSX',
    @NombreHoja = 'parques',
    @PrimeraFilaDatos = 2,
    @RangoExcel = 'A:E';

SELECT * FROM Parques.Parque WHERE Codigo IN ('PNE', 'PNF');
SELECT * FROM Importacion.LoteImportacion WHERE id = @LoteParque;
SELECT * FROM Importacion.ErrorImportacion WHERE lote_id = @LoteParque;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST E-02: Importacion XLSX de visitantes';
PRINT '---------------------------------------------------------';

DECLARE @RutaImportaciones varchar(255) = 'C:\SQLImports\TP-BBDD-Aplicadas\tests\';
DECLARE @NombreArchivo varchar(255) = 'testImportacionesExcel.xlsx';
DECLARE @RutaArchivoCompleta varchar(510) = @RutaImportaciones + @NombreArchivo;

INSERT INTO Importacion.LoteImportacion (dataset, nombre_archivo, ruta_archivo)
VALUES ('Visitante', @NombreArchivo, @RutaArchivoCompleta);

DECLARE @LoteVisitante int = SCOPE_IDENTITY();

EXEC Importacion.usp_ImportarVisitanteArchivo
    @LoteId = @LoteVisitante,
    @RutaArchivo = @RutaArchivoCompleta,
    @MapeoColumnas = '{"nombre":1,"apellido":2,"dni":3}',
    @NombreArchivo = @NombreArchivo,
    @TipoArchivo = 'XLSX',
    @NombreHoja = 'visitantes',
    @RangoExcel = 'A:C';

SELECT * FROM Ventas.Visitante WHERE dni IN ('33123456', '44123456');
SELECT * FROM Importacion.LoteImportacion WHERE id = @LoteVisitante;
SELECT * FROM Importacion.ErrorImportacion WHERE lote_id = @LoteVisitante;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST E-03: Importacion XLSX de atracciones';
PRINT '---------------------------------------------------------';

DECLARE @RutaImportaciones varchar(255) = 'C:\SQLImports\TP-BBDD-Aplicadas\tests\';
DECLARE @NombreArchivo varchar(255) = 'testImportacionesExcel.xlsx';
DECLARE @RutaArchivoCompleta varchar(510) = @RutaImportaciones + @NombreArchivo;

INSERT INTO Importacion.LoteImportacion (dataset, nombre_archivo, ruta_archivo)
VALUES ('Atraccion', @NombreArchivo, @RutaArchivoCompleta);

DECLARE @LoteAtraccion int = SCOPE_IDENTITY();

EXEC Importacion.usp_ImportarAtraccionArchivo
    @LoteId = @LoteAtraccion,
    @RutaArchivo = @RutaArchivoCompleta,
    @MapeoColumnas = '{"nombre":1,"descripcion":2,"duracion":3,"cupo_maximo":4,"costo":5,"CodigoParque":6}',
    @NombreArchivo = @NombreArchivo,
    @TipoArchivo = 'XLSX',
    @NombreHoja = 'atracciones',
    @RangoExcel = 'A:F';

SELECT A.*
FROM Parques.Atraccion A
INNER JOIN Parques.Parque P ON P.id = A.parque_id
WHERE A.nombre = 'Sendero Excel' AND P.Codigo = 'PNE';
SELECT * FROM Importacion.LoteImportacion WHERE id = @LoteAtraccion;
SELECT * FROM Importacion.ErrorImportacion WHERE lote_id = @LoteAtraccion;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST E-04: Importacion XLSX de guias';
PRINT '---------------------------------------------------------';

DECLARE @RutaImportaciones varchar(255) = 'C:\SQLImports\TP-BBDD-Aplicadas\tests\';
DECLARE @NombreArchivo varchar(255) = 'testImportacionesExcel.xlsx';
DECLARE @RutaArchivoCompleta varchar(510) = @RutaImportaciones + @NombreArchivo;

INSERT INTO Importacion.LoteImportacion (dataset, nombre_archivo, ruta_archivo)
VALUES ('Guia', @NombreArchivo, @RutaArchivoCompleta);

DECLARE @LoteGuia int = SCOPE_IDENTITY();

EXEC Importacion.usp_ImportarGuiaArchivo
    @LoteId = @LoteGuia,
    @RutaArchivo = @RutaArchivoCompleta,
    @MapeoColumnas = '{"nombre":1,"apellido":2,"dni":3,"titulo":4,"tipo_habilitacion":5,"especialidad":6}',
    @NombreArchivo = @NombreArchivo,
    @TipoArchivo = 'XLSX',
    @NombreHoja = 'guias',
    @RangoExcel = 'A:F';

SELECT * FROM Personal.Guia WHERE dni IN ('31111222', '31222333');
SELECT * FROM Importacion.LoteImportacion WHERE id = @LoteGuia;
SELECT * FROM Importacion.ErrorImportacion WHERE lote_id = @LoteGuia;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST E-05: Importacion XLSX de guardaparques';
PRINT '---------------------------------------------------------';

DECLARE @RutaImportaciones varchar(255) = 'C:\SQLImports\TP-BBDD-Aplicadas\tests\';
DECLARE @NombreArchivo varchar(255) = 'testImportacionesExcel.xlsx';
DECLARE @RutaArchivoCompleta varchar(510) = @RutaImportaciones + @NombreArchivo;

INSERT INTO Importacion.LoteImportacion (dataset, nombre_archivo, ruta_archivo)
VALUES ('GuardaParque', @NombreArchivo, @RutaArchivoCompleta);

DECLARE @LoteGuardaParque int = SCOPE_IDENTITY();

EXEC Importacion.usp_ImportarGuardaParqueArchivo
    @LoteId = @LoteGuardaParque,
    @RutaArchivo = @RutaArchivoCompleta,
    @MapeoColumnas = '{"nombre":1,"apellido":2,"dni":3,"estado":4}',
    @NombreArchivo = @NombreArchivo,
    @TipoArchivo = 'XLSX',
    @NombreHoja = 'guardaparques',
    @RangoExcel = 'A:D';

SELECT * FROM Personal.GuardaParque WHERE dni IN ('29765432', '30876543');
SELECT * FROM Importacion.LoteImportacion WHERE id = @LoteGuardaParque;
SELECT * FROM Importacion.ErrorImportacion WHERE lote_id = @LoteGuardaParque;
GO
