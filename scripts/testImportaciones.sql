/*******************************************************************************
Fecha: 30/06/2026
Integrantes: [Nicolas Kugel, Facundo Gargiulo, Valentin Martinez]
Descripcion: Pruebas del modulo de importacion CSV por Stored Procedures.
             Requiere ejecutar antes: 00, 01, 02, 03 y 04-Importaciones.sql.

IMPORTANTE: ejecutar en modo SQLCMD para usar la variable RutaImportaciones.
La ruta relativa .\importaciones se resuelve desde el contexto del servicio de
SQL Server. Si falla por permisos o archivo no encontrado, copiar los CSV a una
carpeta local simple y ajustar RutaImportaciones.
*******************************************************************************/

:setvar RutaImportaciones ".\importaciones"

USE TPBDG5;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST I-01: Importacion CSV de parques';
PRINT '---------------------------------------------------------';

INSERT INTO Importacion.LoteImportacion (dataset, nombre_archivo, ruta_archivo)
VALUES ('Parque', 'parques.csv', '$(RutaImportaciones)\parques.csv');

DECLARE @LoteParque int = SCOPE_IDENTITY();

EXEC Importacion.usp_ImportarParqueCSV
    @LoteId = @LoteParque,
    @RutaArchivo = '$(RutaImportaciones)\parques.csv',
    @MapeoColumnas = '{"Codigo":1,"nombre":2,"ubicacion":3,"tipo_parque":4,"superficie_ha":5}',
    @NombreArchivo = 'parques.csv';

SELECT * FROM Parques.Parque WHERE Codigo IN ('PNI', 'PNN');
SELECT * FROM Importacion.LoteImportacion WHERE id = @LoteParque;
SELECT * FROM Importacion.ErrorImportacion WHERE lote_id = @LoteParque;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST I-02: Importacion CSV de visitantes';
PRINT '---------------------------------------------------------';

INSERT INTO Importacion.LoteImportacion (dataset, nombre_archivo, ruta_archivo)
VALUES ('Visitante', 'visitantes.csv', '$(RutaImportaciones)\visitantes.csv');

DECLARE @LoteVisitante int = SCOPE_IDENTITY();

EXEC Importacion.usp_ImportarVisitanteCSV
    @LoteId = @LoteVisitante,
    @RutaArchivo = '$(RutaImportaciones)\visitantes.csv',
    @MapeoColumnas = '{"nombre":1,"apellido":2,"dni":3}',
    @NombreArchivo = 'visitantes.csv';

SELECT * FROM Ventas.Visitante WHERE dni IN ('35123456', '42123456');
SELECT * FROM Importacion.LoteImportacion WHERE id = @LoteVisitante;
SELECT * FROM Importacion.ErrorImportacion WHERE lote_id = @LoteVisitante;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST I-03: Importacion CSV de atracciones';
PRINT '---------------------------------------------------------';

INSERT INTO Importacion.LoteImportacion (dataset, nombre_archivo, ruta_archivo)
VALUES ('Atraccion', 'atracciones.csv', '$(RutaImportaciones)\atracciones.csv');

DECLARE @LoteAtraccion int = SCOPE_IDENTITY();

EXEC Importacion.usp_ImportarAtraccionCSV
    @LoteId = @LoteAtraccion,
    @RutaArchivo = '$(RutaImportaciones)\atracciones.csv',
    @MapeoColumnas = '{"nombre":1,"descripcion":2,"duracion":3,"cupo_maximo":4,"costo":5,"CodigoParque":6}',
    @NombreArchivo = 'atracciones.csv';

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

INSERT INTO Importacion.LoteImportacion (dataset, nombre_archivo, ruta_archivo)
VALUES ('Guia', 'guias.csv', '$(RutaImportaciones)\guias.csv');

DECLARE @LoteGuia int = SCOPE_IDENTITY();

EXEC Importacion.usp_ImportarGuiaCSV
    @LoteId = @LoteGuia,
    @RutaArchivo = '$(RutaImportaciones)\guias.csv',
    @MapeoColumnas = '{"nombre":1,"apellido":2,"dni":3,"titulo":4,"tipo_habilitacion":5,"especialidad":6}',
    @NombreArchivo = 'guias.csv';

SELECT * FROM Personal.Guia WHERE dni IN ('30111222', '30222333');
SELECT * FROM Importacion.LoteImportacion WHERE id = @LoteGuia;
SELECT * FROM Importacion.ErrorImportacion WHERE lote_id = @LoteGuia;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST I-05: Importacion CSV de guardaparques';
PRINT '---------------------------------------------------------';

INSERT INTO Importacion.LoteImportacion (dataset, nombre_archivo, ruta_archivo)
VALUES ('GuardaParque', 'guardaparques.csv', '$(RutaImportaciones)\guardaparques.csv');

DECLARE @LoteGuardaParque int = SCOPE_IDENTITY();

EXEC Importacion.usp_ImportarGuardaParqueCSV
    @LoteId = @LoteGuardaParque,
    @RutaArchivo = '$(RutaImportaciones)\guardaparques.csv',
    @MapeoColumnas = '{"nombre":1,"apellido":2,"dni":3,"estado":4}',
    @NombreArchivo = 'guardaparques.csv';

SELECT * FROM Personal.GuardaParque WHERE dni IN ('28765432', '29876543');
SELECT * FROM Importacion.LoteImportacion WHERE id = @LoteGuardaParque;
SELECT * FROM Importacion.ErrorImportacion WHERE lote_id = @LoteGuardaParque;
GO
