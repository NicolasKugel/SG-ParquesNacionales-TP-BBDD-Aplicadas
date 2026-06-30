/*******************************************************************************
Fecha: 30/06/2026
Integrantes: [Nicolas Kugel, Facundo Gargiulo, Valentin Martinez]
Descripcion: Pruebas del modulo de importaciones masivas y consumo de API.
             Requiere ejecutar antes: 00, 01, 02, 03 y 04-Importaciones.sql.

IMPORTANTE: ejecutar en modo SQLCMD para usar la variable RutaImportaciones.
*******************************************************************************/

:setvar RutaImportaciones "C:\Users\nicol\OneDrive\Documentos\Universidad\BBDD aplicadas\EntregaTPBBDDAplicadas\SG-ParquesNacionales-TP-BBDD-Aplicadas\importaciones"

USE TPBDG5;
GO

DECLARE @RutaAreas varchar(1000) = '$(RutaImportaciones)\aprn_g_ap_juris_2025.csv';
DECLARE @RutaVisitas varchar(1000) = '$(RutaImportaciones)\visitas-residentes-y-no-residentes.csv';

PRINT '---------------------------------------------------------';
PRINT 'TEST I-01: Importacion de areas protegidas por jurisdiccion';
PRINT '---------------------------------------------------------';

EXEC Importacion.sp_ImportarAreasProtegidasCSV
    @NombreArchivo = 'aprn_g_ap_juris_2025.csv',
    @RutaArchivo = @RutaAreas;

SELECT TOP 10 * FROM Importacion.AreaProtegidaJurisdiccion ORDER BY jurisdiccion;
SELECT TOP 5 * FROM Importacion.ErrorImportacion ORDER BY id DESC;
SELECT TOP 1 * FROM Importacion.LoteImportacion WHERE dataset = 'Areas protegidas por jurisdiccion' ORDER BY id DESC;
GO

DECLARE @RutaAreas varchar(1000) = '$(RutaImportaciones)\aprn_g_ap_juris_2025.csv';
DECLARE @CantidadAntes int = (SELECT COUNT(*) FROM Importacion.AreaProtegidaJurisdiccion);

PRINT '---------------------------------------------------------';
PRINT 'TEST I-02: Reimportacion de areas protegidas sin duplicados';
PRINT '---------------------------------------------------------';

EXEC Importacion.sp_ImportarAreasProtegidasCSV
    @NombreArchivo = 'aprn_g_ap_juris_2025.csv',
    @RutaArchivo = @RutaAreas;

SELECT @CantidadAntes AS cantidad_antes,
       COUNT(*) AS cantidad_despues
FROM Importacion.AreaProtegidaJurisdiccion;

SELECT TOP 1 registros_insertados, registros_actualizados, registros_error
FROM Importacion.LoteImportacion
WHERE dataset = 'Areas protegidas por jurisdiccion'
ORDER BY id DESC;
GO

DECLARE @RutaVisitas varchar(1000) = '$(RutaImportaciones)\visitas-residentes-y-no-residentes.csv';

PRINT '---------------------------------------------------------';
PRINT 'TEST I-03: Importacion de visitas turisticas historicas';
PRINT '---------------------------------------------------------';

EXEC Importacion.sp_ImportarVisitasTuristicasCSV
    @NombreArchivo = 'visitas-residentes-y-no-residentes.csv',
    @RutaArchivo = @RutaVisitas;

SELECT TOP 10 * FROM Importacion.VisitaTuristicaHistorica ORDER BY indice_tiempo, origen_visitantes;
SELECT TOP 1 * FROM Importacion.LoteImportacion WHERE dataset = 'Visitas residentes y no residentes' ORDER BY id DESC;
GO

DECLARE @RutaVisitas varchar(1000) = '$(RutaImportaciones)\visitas-residentes-y-no-residentes.csv';
DECLARE @CantidadAntes int = (SELECT COUNT(*) FROM Importacion.VisitaTuristicaHistorica);

PRINT '---------------------------------------------------------';
PRINT 'TEST I-04: Reimportacion de visitas sin duplicados';
PRINT '---------------------------------------------------------';

EXEC Importacion.sp_ImportarVisitasTuristicasCSV
    @NombreArchivo = 'visitas-residentes-y-no-residentes.csv',
    @RutaArchivo = @RutaVisitas;

SELECT @CantidadAntes AS cantidad_antes,
       COUNT(*) AS cantidad_despues
FROM Importacion.VisitaTuristicaHistorica;

SELECT TOP 1 registros_insertados, registros_actualizados, registros_error
FROM Importacion.LoteImportacion
WHERE dataset = 'Visitas residentes y no residentes'
ORDER BY id DESC;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST I-05: Consumo de API de feriados por URL';
PRINT '---------------------------------------------------------';

DECLARE @ApiConsultaId int;

EXEC Importacion.sp_ConsumirApi
    @UrlApi = 'https://api.argentinadatos.com/v1/feriados/2026',
    @Metodo = 'GET',
    @ApiConsultaId = @ApiConsultaId OUTPUT;

SELECT id, url, metodo, fecha_consulta, estado, codigo_http, LEFT(respuesta, 500) AS respuesta_muestra, mensaje_error
FROM Importacion.ApiConsulta
WHERE id = @ApiConsultaId;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST I-06: Registro de cotizacion desde API BCRA';
PRINT '---------------------------------------------------------';

DECLARE @ApiConsultaId int;

EXEC Importacion.sp_RegistrarCotizacionDesdeApi
    @UrlApi = 'https://api.bcra.gob.ar/estadisticas/v4.0/DatosVariable/4/2026-06-01/2026-06-30',
    @Moneda = 'USD',
    @ApiConsultaId = @ApiConsultaId OUTPUT;

SELECT * FROM Importacion.ApiConsulta WHERE id = @ApiConsultaId;
SELECT TOP 10 * FROM Importacion.ApiCotizacion WHERE api_consulta_id = @ApiConsultaId ORDER BY fecha DESC;
GO
