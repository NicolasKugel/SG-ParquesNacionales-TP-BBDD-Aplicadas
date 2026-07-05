/*******************************************************************************
Fecha: 30/06/2026
Integrantes: [Nicolas Kugel, Facundo Gargiulo, Valentin Martinez]
Descripcion: Pruebas del modulo de importacion CSV por Stored Procedures.
             Requiere ejecutar antes: 00, 01, 02, 03 y 04-Importaciones.sql.

IMPORTANTE: los archivos CSV deben estar disponibles para SQL Server en:
             C:\SQLImports\TP-BBDD-Aplicadas\
*******************************************************************************/
USE TPBDG5;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST I-01: Importacion CSV de parques';
PRINT '---------------------------------------------------------';

DECLARE @RutaImportaciones varchar(255) = 'C:\SQLImports\TP-BBDD-Aplicadas\tests\';
DECLARE @NombreArchivo varchar(255) = 'parques.csv';
DECLARE @RutaArchivoCompleta varchar(510) = @RutaImportaciones + @NombreArchivo;

INSERT INTO Importacion.LoteImportacion (dataset, nombre_archivo, ruta_archivo)
VALUES ('Parque', @NombreArchivo, @RutaArchivoCompleta);

DECLARE @LoteParque int = SCOPE_IDENTITY();

EXEC Importacion.usp_ImportarParqueArchivo
    @LoteId = @LoteParque,
    @RutaArchivo = @RutaArchivoCompleta,
    @MapeoColumnas = '{"Codigo":1,"nombre":2,"ubicacion":3,"tipo_parque":4,"superficie_ha":5}',
    @NombreArchivo = @NombreArchivo;

SELECT * FROM Parques.Parque WHERE Codigo IN ('PNI', 'PNN');
SELECT * FROM Importacion.LoteImportacion WHERE id = @LoteParque;
SELECT * FROM Importacion.ErrorImportacion WHERE lote_id = @LoteParque;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST I-02: Importacion CSV de visitantes';
PRINT '---------------------------------------------------------';

DECLARE @RutaImportaciones varchar(255) = 'C:\SQLImports\TP-BBDD-Aplicadas\tests\';
DECLARE @NombreArchivo varchar(255) = 'visitantes.csv';
DECLARE @RutaArchivoCompleta varchar(510) = @RutaImportaciones + @NombreArchivo;

INSERT INTO Importacion.LoteImportacion (dataset, nombre_archivo, ruta_archivo)
VALUES ('Visitante', @NombreArchivo, @RutaArchivoCompleta);

DECLARE @LoteVisitante int = SCOPE_IDENTITY();

EXEC Importacion.usp_ImportarVisitanteArchivo
    @LoteId = @LoteVisitante,
    @RutaArchivo = @RutaArchivoCompleta,
    @MapeoColumnas = '{"nombre":1,"apellido":2,"dni":3}',
    @NombreArchivo = @NombreArchivo;

SELECT * FROM Ventas.Visitante WHERE dni IN ('35123456', '42123456');
SELECT * FROM Importacion.LoteImportacion WHERE id = @LoteVisitante;
SELECT * FROM Importacion.ErrorImportacion WHERE lote_id = @LoteVisitante;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST I-03: Importacion CSV de atracciones';
PRINT '---------------------------------------------------------';

DECLARE @RutaImportaciones varchar(255) = 'C:\SQLImports\TP-BBDD-Aplicadas\tests\';
DECLARE @NombreArchivo varchar(255) = 'atracciones.csv';
DECLARE @RutaArchivoCompleta varchar(510) = @RutaImportaciones + @NombreArchivo;

INSERT INTO Importacion.LoteImportacion (dataset, nombre_archivo, ruta_archivo)
VALUES ('Atraccion', @NombreArchivo, @RutaArchivoCompleta);

DECLARE @LoteAtraccion int = SCOPE_IDENTITY();

EXEC Importacion.usp_ImportarAtraccionArchivo
    @LoteId = @LoteAtraccion,
    @RutaArchivo = @RutaArchivoCompleta,
    @MapeoColumnas = '{"nombre":1,"descripcion":2,"duracion":3,"cupo_maximo":4,"costo":5,"CodigoParque":6}',
    @NombreArchivo = @NombreArchivo;

SELECT A.*
FROM Parques.Atraccion A
INNER JOIN Parques.Parque P ON P.id = A.parque_id
WHERE A.nombre = 'Garganta del Diablo' AND P.Codigo = 'PNI';
SELECT * FROM Importacion.LoteImportacion WHERE id = @LoteAtraccion;
SELECT * FROM Importacion.ErrorImportacion WHERE lote_id = @LoteAtraccion;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST I-04: Importacion CSV de guias';
PRINT '---------------------------------------------------------';

DECLARE @RutaImportaciones varchar(255) = 'C:\SQLImports\TP-BBDD-Aplicadas\tests\';
DECLARE @NombreArchivo varchar(255) = 'guias.csv';
DECLARE @RutaArchivoCompleta varchar(510) = @RutaImportaciones + @NombreArchivo;

INSERT INTO Importacion.LoteImportacion (dataset, nombre_archivo, ruta_archivo)
VALUES ('Guia', @NombreArchivo, @RutaArchivoCompleta);

DECLARE @LoteGuia int = SCOPE_IDENTITY();

EXEC Importacion.usp_ImportarGuiaArchivo
    @LoteId = @LoteGuia,
    @RutaArchivo = @RutaArchivoCompleta,
    @MapeoColumnas = '{"nombre":1,"apellido":2,"dni":3,"titulo":4,"tipo_habilitacion":5,"especialidad":6}',
    @NombreArchivo = @NombreArchivo;

SELECT * FROM Personal.Guia WHERE dni IN ('30111222', '30222333');
SELECT * FROM Importacion.LoteImportacion WHERE id = @LoteGuia;
SELECT * FROM Importacion.ErrorImportacion WHERE lote_id = @LoteGuia;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST I-05: Importacion CSV de guardaparques';
PRINT '---------------------------------------------------------';

DECLARE @RutaImportaciones varchar(255) = 'C:\SQLImports\TP-BBDD-Aplicadas\tests\';
DECLARE @NombreArchivo varchar(255) = 'guardaparques.csv';
DECLARE @RutaArchivoCompleta varchar(510) = @RutaImportaciones + @NombreArchivo;

INSERT INTO Importacion.LoteImportacion (dataset, nombre_archivo, ruta_archivo)
VALUES ('GuardaParque', @NombreArchivo, @RutaArchivoCompleta);

DECLARE @LoteGuardaParque int = SCOPE_IDENTITY();

EXEC Importacion.usp_ImportarGuardaParqueArchivo
    @LoteId = @LoteGuardaParque,
    @RutaArchivo = @RutaArchivoCompleta,
    @MapeoColumnas = '{"nombre":1,"apellido":2,"dni":3,"estado":4}',
    @NombreArchivo = @NombreArchivo;

SELECT * FROM Personal.GuardaParque WHERE dni IN ('28765432', '29876543');
SELECT * FROM Importacion.LoteImportacion WHERE id = @LoteGuardaParque;
SELECT * FROM Importacion.ErrorImportacion WHERE lote_id = @LoteGuardaParque;
GO
