/*******************************************************************************
Fecha: 30/06/2026
Integrantes: [Nicolas Kugel, Facundo Gargiulo, Valentin Martinez]
Descripcion: Modulo de importacion masiva desde archivos externos y consumo de API.
             Incluye staging, control de lotes, errores, upsert y registro de API.
*******************************************************************************/

USE TPBDG5;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Importacion')
BEGIN
    EXEC('CREATE SCHEMA Importacion');
END;
GO

IF OBJECT_ID('Importacion.ErrorImportacion', 'U') IS NOT NULL DROP TABLE Importacion.ErrorImportacion;
IF OBJECT_ID('Importacion.ApiCotizacion', 'U') IS NOT NULL DROP TABLE Importacion.ApiCotizacion;
IF OBJECT_ID('Importacion.ApiConsulta', 'U') IS NOT NULL DROP TABLE Importacion.ApiConsulta;
IF OBJECT_ID('Importacion.VisitaTuristicaHistorica', 'U') IS NOT NULL DROP TABLE Importacion.VisitaTuristicaHistorica;
IF OBJECT_ID('Importacion.AreaProtegidaJurisdiccion', 'U') IS NOT NULL DROP TABLE Importacion.AreaProtegidaJurisdiccion;
IF OBJECT_ID('Importacion.StageVisitaTuristica', 'U') IS NOT NULL DROP TABLE Importacion.StageVisitaTuristica;
IF OBJECT_ID('Importacion.StageAreaProtegidaJurisdiccion', 'U') IS NOT NULL DROP TABLE Importacion.StageAreaProtegidaJurisdiccion;
IF OBJECT_ID('Importacion.LoteImportacion', 'U') IS NOT NULL DROP TABLE Importacion.LoteImportacion;
GO

CREATE TABLE Importacion.LoteImportacion (
    id int IDENTITY(1,1) PRIMARY KEY,
    dataset varchar(100) NOT NULL,
    nombre_archivo varchar(260) NOT NULL,
    ruta_archivo varchar(1000) NULL,
    fecha_inicio datetime2(0) NOT NULL DEFAULT SYSDATETIME(),
    fecha_fin datetime2(0) NULL,
    estado varchar(20) NOT NULL DEFAULT 'Iniciado',
    registros_leidos int NOT NULL DEFAULT 0,
    registros_validos int NOT NULL DEFAULT 0,
    registros_insertados int NOT NULL DEFAULT 0,
    registros_actualizados int NOT NULL DEFAULT 0,
    registros_error int NOT NULL DEFAULT 0,
    mensaje nvarchar(4000) NULL
);
GO

CREATE TABLE Importacion.ErrorImportacion (
    id int IDENTITY(1,1) PRIMARY KEY,
    lote_id int NOT NULL,
    fila int NULL,
    campo varchar(100) NULL,
    valor nvarchar(4000) NULL,
    mensaje nvarchar(4000) NOT NULL,
    fecha_error datetime2(0) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_ErrorImportacion_Lote FOREIGN KEY (lote_id) REFERENCES Importacion.LoteImportacion(id)
);
GO

CREATE TABLE Importacion.StageAreaProtegidaJurisdiccion (
    jurisdicciones nvarchar(200) NULL,
    total_cantidad nvarchar(50) NULL,
    ap_nac nvarchar(50) NULL,
    ap_prov nvarchar(50) NULL,
    ap_desig_inter nvarchar(50) NULL,
    total_ha nvarchar(50) NULL,
    terrestre_ha nvarchar(50) NULL,
    marino_ha nvarchar(50) NULL,
    porcentaje_terrestre_protegido nvarchar(50) NULL
);
GO

CREATE TABLE Importacion.AreaProtegidaJurisdiccion (
    id int IDENTITY(1,1) PRIMARY KEY,
    jurisdiccion varchar(200) NOT NULL UNIQUE,
    total_cantidad int NULL,
    ap_nac int NULL,
    ap_prov int NULL,
    ap_desig_inter int NULL,
    total_ha decimal(18,2) NULL,
    terrestre_ha decimal(18,2) NULL,
    marino_ha decimal(18,2) NULL,
    porcentaje_terrestre_protegido decimal(9,2) NULL,
    nombre_archivo varchar(260) NOT NULL,
    fecha_ultima_importacion datetime2(0) NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE TABLE Importacion.StageVisitaTuristica (
    indice_tiempo nvarchar(50) NULL,
    origen_visitantes nvarchar(50) NULL,
    visitas nvarchar(50) NULL,
    observaciones nvarchar(4000) NULL
);
GO

CREATE TABLE Importacion.VisitaTuristicaHistorica (
    id int IDENTITY(1,1) PRIMARY KEY,
    indice_tiempo date NOT NULL,
    origen_visitantes varchar(30) NOT NULL,
    visitas int NOT NULL,
    observaciones varchar(4000) NULL,
    nombre_archivo varchar(260) NOT NULL,
    fecha_ultima_importacion datetime2(0) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT UQ_VisitaTuristicaHistorica UNIQUE (indice_tiempo, origen_visitantes)
);
GO

CREATE TABLE Importacion.ApiConsulta (
    id int IDENTITY(1,1) PRIMARY KEY,
    url varchar(1000) NOT NULL,
    metodo varchar(10) NOT NULL DEFAULT 'GET',
    fecha_consulta datetime2(0) NOT NULL DEFAULT SYSDATETIME(),
    estado varchar(20) NOT NULL,
    codigo_http int NULL,
    respuesta nvarchar(max) NULL,
    mensaje_error nvarchar(4000) NULL
);
GO

CREATE TABLE Importacion.ApiCotizacion (
    id int IDENTITY(1,1) PRIMARY KEY,
    api_consulta_id int NOT NULL,
    moneda varchar(20) NOT NULL,
    fecha date NOT NULL,
    valor decimal(18,6) NOT NULL,
    fecha_registro datetime2(0) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT UQ_ApiCotizacion UNIQUE (moneda, fecha),
    CONSTRAINT FK_ApiCotizacion_ApiConsulta FOREIGN KEY (api_consulta_id) REFERENCES Importacion.ApiConsulta(id)
);
GO

CREATE OR ALTER PROCEDURE Importacion.sp_RegistrarErrorImportacion
    @lote_id int,
    @fila int = NULL,
    @campo varchar(100) = NULL,
    @valor nvarchar(4000) = NULL,
    @mensaje nvarchar(4000)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Importacion.ErrorImportacion (lote_id, fila, campo, valor, mensaje)
    VALUES (@lote_id, @fila, @campo, @valor, @mensaje);
END;
GO

CREATE OR ALTER PROCEDURE Importacion.sp_ImportarAreasProtegidasCSV
    @NombreArchivo varchar(260),
    @RutaArchivo varchar(1000)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LoteId int;
    INSERT INTO Importacion.LoteImportacion (dataset, nombre_archivo, ruta_archivo)
    VALUES ('Areas protegidas por jurisdiccion', @NombreArchivo, @RutaArchivo);
    SET @LoteId = SCOPE_IDENTITY();

    BEGIN TRY
        TRUNCATE TABLE Importacion.StageAreaProtegidaJurisdiccion;

        DECLARE @Sql nvarchar(max) = N'
            BULK INSERT Importacion.StageAreaProtegidaJurisdiccion
            FROM ''' + REPLACE(@RutaArchivo, '''', '''''') + N'''
            WITH (
                FORMAT = ''CSV'',
                FIRSTROW = 2,
                FIELDTERMINATOR = '';'',
                FIELDQUOTE = ''"'',
                ROWTERMINATOR = ''0x0a'',
                CODEPAGE = ''65001'',
                MAXERRORS = 1000,
                TABLOCK
            );';

        EXEC sp_executesql @Sql;

        UPDATE Importacion.LoteImportacion
        SET registros_leidos = (SELECT COUNT(*) FROM Importacion.StageAreaProtegidaJurisdiccion)
        WHERE id = @LoteId;

        ;WITH Normalizado AS (
            SELECT
                ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS id,
                LTRIM(RTRIM(REPLACE(jurisdicciones, NCHAR(160), ' '))) AS jurisdiccion,
                NULLIF(LTRIM(RTRIM(total_cantidad)), '-') AS total_cantidad,
                NULLIF(LTRIM(RTRIM(ap_nac)), '-') AS ap_nac,
                NULLIF(LTRIM(RTRIM(ap_prov)), '-') AS ap_prov,
                NULLIF(LTRIM(RTRIM(ap_desig_inter)), '-') AS ap_desig_inter,
                NULLIF(LTRIM(RTRIM(total_ha)), '-') AS total_ha,
                NULLIF(LTRIM(RTRIM(terrestre_ha)), '-') AS terrestre_ha,
                NULLIF(LTRIM(RTRIM(marino_ha)), '-') AS marino_ha,
                NULLIF(LTRIM(RTRIM(porcentaje_terrestre_protegido)), '-') AS porcentaje
            FROM Importacion.StageAreaProtegidaJurisdiccion
        ), Errores AS (
            SELECT id, 'jurisdicciones' AS campo, jurisdiccion AS valor, 'Jurisdiccion obligatoria o fila agregada no importable.' AS mensaje
            FROM Normalizado
            WHERE ISNULL(jurisdiccion, '') = '' OR jurisdiccion = 'Total'
            UNION ALL
            SELECT id, 'total_cantidad', total_cantidad, 'total_cantidad debe ser numerico mayor o igual a cero.' FROM Normalizado WHERE total_cantidad IS NOT NULL AND (TRY_CONVERT(int, total_cantidad) IS NULL OR TRY_CONVERT(int, total_cantidad) < 0)
            UNION ALL
            SELECT id, 'ap_nac', ap_nac, 'ap_nac debe ser numerico mayor o igual a cero.' FROM Normalizado WHERE ap_nac IS NOT NULL AND (TRY_CONVERT(int, ap_nac) IS NULL OR TRY_CONVERT(int, ap_nac) < 0)
            UNION ALL
            SELECT id, 'ap_prov', ap_prov, 'ap_prov debe ser numerico mayor o igual a cero.' FROM Normalizado WHERE ap_prov IS NOT NULL AND (TRY_CONVERT(int, ap_prov) IS NULL OR TRY_CONVERT(int, ap_prov) < 0)
            UNION ALL
            SELECT id, 'ap_desig_inter', ap_desig_inter, 'ap_desig_inter debe ser numerico mayor o igual a cero.' FROM Normalizado WHERE ap_desig_inter IS NOT NULL AND (TRY_CONVERT(int, ap_desig_inter) IS NULL OR TRY_CONVERT(int, ap_desig_inter) < 0)
            UNION ALL
            SELECT id, 'total_ha', total_ha, 'total_ha debe ser numerico mayor o igual a cero.' FROM Normalizado WHERE total_ha IS NOT NULL AND (TRY_CONVERT(decimal(18,2), total_ha) IS NULL OR TRY_CONVERT(decimal(18,2), total_ha) < 0)
            UNION ALL
            SELECT id, 'terrestre_ha', terrestre_ha, 'terrestre_ha debe ser numerico mayor o igual a cero.' FROM Normalizado WHERE terrestre_ha IS NOT NULL AND (TRY_CONVERT(decimal(18,2), terrestre_ha) IS NULL OR TRY_CONVERT(decimal(18,2), terrestre_ha) < 0)
            UNION ALL
            SELECT id, 'marino_ha', marino_ha, 'marino_ha debe ser numerico mayor o igual a cero.' FROM Normalizado WHERE marino_ha IS NOT NULL AND (TRY_CONVERT(decimal(18,2), marino_ha) IS NULL OR TRY_CONVERT(decimal(18,2), marino_ha) < 0)
            UNION ALL
            SELECT id, 'porcentaje_terrestre_protegido', porcentaje, 'porcentaje_terrestre_protegido debe ser numerico mayor o igual a cero.' FROM Normalizado WHERE porcentaje IS NOT NULL AND (TRY_CONVERT(decimal(9,2), porcentaje) IS NULL OR TRY_CONVERT(decimal(9,2), porcentaje) < 0)
        )
        INSERT INTO Importacion.ErrorImportacion (lote_id, fila, campo, valor, mensaje)
        SELECT @LoteId, id, campo, valor, mensaje
        FROM Errores;

        DECLARE @Cambios TABLE (accion varchar(10));

        ;WITH Normalizado AS (
            SELECT
                ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS id,
                LTRIM(RTRIM(REPLACE(jurisdicciones, NCHAR(160), ' '))) AS jurisdiccion,
                NULLIF(LTRIM(RTRIM(total_cantidad)), '-') AS total_cantidad,
                NULLIF(LTRIM(RTRIM(ap_nac)), '-') AS ap_nac,
                NULLIF(LTRIM(RTRIM(ap_prov)), '-') AS ap_prov,
                NULLIF(LTRIM(RTRIM(ap_desig_inter)), '-') AS ap_desig_inter,
                NULLIF(LTRIM(RTRIM(total_ha)), '-') AS total_ha,
                NULLIF(LTRIM(RTRIM(terrestre_ha)), '-') AS terrestre_ha,
                NULLIF(LTRIM(RTRIM(marino_ha)), '-') AS marino_ha,
                NULLIF(LTRIM(RTRIM(porcentaje_terrestre_protegido)), '-') AS porcentaje
            FROM Importacion.StageAreaProtegidaJurisdiccion
        ), Validado AS (
            SELECT *
            FROM Normalizado N
            WHERE ISNULL(jurisdiccion, '') <> ''
              AND jurisdiccion <> 'Total'
              AND (total_cantidad IS NULL OR TRY_CONVERT(int, total_cantidad) >= 0)
              AND (ap_nac IS NULL OR TRY_CONVERT(int, ap_nac) >= 0)
              AND (ap_prov IS NULL OR TRY_CONVERT(int, ap_prov) >= 0)
              AND (ap_desig_inter IS NULL OR TRY_CONVERT(int, ap_desig_inter) >= 0)
              AND (total_ha IS NULL OR TRY_CONVERT(decimal(18,2), total_ha) >= 0)
              AND (terrestre_ha IS NULL OR TRY_CONVERT(decimal(18,2), terrestre_ha) >= 0)
              AND (marino_ha IS NULL OR TRY_CONVERT(decimal(18,2), marino_ha) >= 0)
              AND (porcentaje IS NULL OR TRY_CONVERT(decimal(9,2), porcentaje) >= 0)
        )
        MERGE Importacion.AreaProtegidaJurisdiccion AS Target
        USING Validado AS Source
        ON Target.jurisdiccion = Source.jurisdiccion
        WHEN MATCHED THEN
            UPDATE SET
                total_cantidad = TRY_CONVERT(int, Source.total_cantidad),
                ap_nac = TRY_CONVERT(int, Source.ap_nac),
                ap_prov = TRY_CONVERT(int, Source.ap_prov),
                ap_desig_inter = TRY_CONVERT(int, Source.ap_desig_inter),
                total_ha = TRY_CONVERT(decimal(18,2), Source.total_ha),
                terrestre_ha = TRY_CONVERT(decimal(18,2), Source.terrestre_ha),
                marino_ha = TRY_CONVERT(decimal(18,2), Source.marino_ha),
                porcentaje_terrestre_protegido = TRY_CONVERT(decimal(9,2), Source.porcentaje),
                nombre_archivo = @NombreArchivo,
                fecha_ultima_importacion = SYSDATETIME()
        WHEN NOT MATCHED THEN
            INSERT (jurisdiccion, total_cantidad, ap_nac, ap_prov, ap_desig_inter, total_ha, terrestre_ha, marino_ha, porcentaje_terrestre_protegido, nombre_archivo)
            VALUES (Source.jurisdiccion, TRY_CONVERT(int, Source.total_cantidad), TRY_CONVERT(int, Source.ap_nac), TRY_CONVERT(int, Source.ap_prov), TRY_CONVERT(int, Source.ap_desig_inter), TRY_CONVERT(decimal(18,2), Source.total_ha), TRY_CONVERT(decimal(18,2), Source.terrestre_ha), TRY_CONVERT(decimal(18,2), Source.marino_ha), TRY_CONVERT(decimal(9,2), Source.porcentaje), @NombreArchivo)
        OUTPUT $action INTO @Cambios;

        UPDATE Importacion.LoteImportacion
        SET fecha_fin = SYSDATETIME(),
            estado = 'Finalizado',
            registros_validos = (SELECT COUNT(*) FROM @Cambios),
            registros_insertados = (SELECT COUNT(*) FROM @Cambios WHERE accion = 'INSERT'),
            registros_actualizados = (SELECT COUNT(*) FROM @Cambios WHERE accion = 'UPDATE'),
            registros_error = (SELECT COUNT(*) FROM Importacion.ErrorImportacion WHERE lote_id = @LoteId),
            mensaje = 'Importacion de areas protegidas finalizada.'
        WHERE id = @LoteId;
    END TRY
    BEGIN CATCH
        UPDATE Importacion.LoteImportacion
        SET fecha_fin = SYSDATETIME(), estado = 'Error', mensaje = ERROR_MESSAGE()
        WHERE id = @LoteId;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Importacion.sp_ImportarVisitasTuristicasCSV
    @NombreArchivo varchar(260),
    @RutaArchivo varchar(1000)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LoteId int;
    INSERT INTO Importacion.LoteImportacion (dataset, nombre_archivo, ruta_archivo)
    VALUES ('Visitas residentes y no residentes', @NombreArchivo, @RutaArchivo);
    SET @LoteId = SCOPE_IDENTITY();

    BEGIN TRY
        TRUNCATE TABLE Importacion.StageVisitaTuristica;

        DECLARE @Sql nvarchar(max) = N'
            BULK INSERT Importacion.StageVisitaTuristica
            FROM ''' + REPLACE(@RutaArchivo, '''', '''''') + N'''
            WITH (
                FORMAT = ''CSV'',
                FIRSTROW = 2,
                FIELDTERMINATOR = '','',
                FIELDQUOTE = ''"'',
                ROWTERMINATOR = ''0x0a'',
                CODEPAGE = ''65001'',
                MAXERRORS = 1000,
                TABLOCK
            );';

        EXEC sp_executesql @Sql;

        UPDATE Importacion.LoteImportacion
        SET registros_leidos = (SELECT COUNT(*) FROM Importacion.StageVisitaTuristica)
        WHERE id = @LoteId;

        ;WITH Normalizado AS (
            SELECT
                ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS id,
                LTRIM(RTRIM(indice_tiempo)) AS indice_tiempo,
                LOWER(LTRIM(RTRIM(origen_visitantes))) AS origen_visitantes,
                LTRIM(RTRIM(visitas)) AS visitas
            FROM Importacion.StageVisitaTuristica
        ), Errores AS (
            SELECT id, 'indice_tiempo' AS campo, indice_tiempo AS valor, 'indice_tiempo debe ser una fecha valida.' AS mensaje
            FROM Normalizado WHERE TRY_CONVERT(date, indice_tiempo) IS NULL
            UNION ALL
            SELECT id, 'origen_visitantes', origen_visitantes, 'origen_visitantes debe ser residentes, no residentes o total.'
            FROM Normalizado WHERE ISNULL(origen_visitantes, '') NOT IN ('residentes', 'no residentes', 'total')
            UNION ALL
            SELECT id, 'visitas', visitas, 'visitas debe ser un entero mayor o igual a cero.'
            FROM Normalizado WHERE TRY_CONVERT(int, visitas) IS NULL OR TRY_CONVERT(int, visitas) < 0
        )
        INSERT INTO Importacion.ErrorImportacion (lote_id, fila, campo, valor, mensaje)
        SELECT @LoteId, id, campo, valor, mensaje
        FROM Errores;

        DECLARE @Cambios TABLE (accion varchar(10));

        ;WITH Normalizado AS (
            SELECT
                ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS id,
                TRY_CONVERT(date, LTRIM(RTRIM(indice_tiempo))) AS indice_tiempo,
                LOWER(LTRIM(RTRIM(origen_visitantes))) AS origen_visitantes,
                TRY_CONVERT(int, LTRIM(RTRIM(visitas))) AS visitas,
                NULLIF(LTRIM(RTRIM(observaciones)), '') AS observaciones
            FROM Importacion.StageVisitaTuristica
        ), Validado AS (
            SELECT *
            FROM Normalizado N
            WHERE indice_tiempo IS NOT NULL
              AND origen_visitantes IN ('residentes', 'no residentes', 'total')
              AND visitas IS NOT NULL
              AND visitas >= 0
        )
        MERGE Importacion.VisitaTuristicaHistorica AS Target
        USING Validado AS Source
        ON Target.indice_tiempo = Source.indice_tiempo
           AND Target.origen_visitantes = Source.origen_visitantes
        WHEN MATCHED THEN
            UPDATE SET
                visitas = Source.visitas,
                observaciones = Source.observaciones,
                nombre_archivo = @NombreArchivo,
                fecha_ultima_importacion = SYSDATETIME()
        WHEN NOT MATCHED THEN
            INSERT (indice_tiempo, origen_visitantes, visitas, observaciones, nombre_archivo)
            VALUES (Source.indice_tiempo, Source.origen_visitantes, Source.visitas, Source.observaciones, @NombreArchivo)
        OUTPUT $action INTO @Cambios;

        UPDATE Importacion.LoteImportacion
        SET fecha_fin = SYSDATETIME(),
            estado = 'Finalizado',
            registros_validos = (SELECT COUNT(*) FROM @Cambios),
            registros_insertados = (SELECT COUNT(*) FROM @Cambios WHERE accion = 'INSERT'),
            registros_actualizados = (SELECT COUNT(*) FROM @Cambios WHERE accion = 'UPDATE'),
            registros_error = (SELECT COUNT(*) FROM Importacion.ErrorImportacion WHERE lote_id = @LoteId),
            mensaje = 'Importacion de visitas turisticas finalizada.'
        WHERE id = @LoteId;
    END TRY
    BEGIN CATCH
        UPDATE Importacion.LoteImportacion
        SET fecha_fin = SYSDATETIME(), estado = 'Error', mensaje = ERROR_MESSAGE()
        WHERE id = @LoteId;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Importacion.sp_ConsumirApi
    @UrlApi varchar(1000),
    @Metodo varchar(10) = 'GET',
    @ApiConsultaId int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Object int;
    DECLARE @Status int;
    DECLARE @ResponseText nvarchar(max);

    INSERT INTO Importacion.ApiConsulta (url, metodo, estado)
    VALUES (@UrlApi, @Metodo, 'Iniciado');
    SET @ApiConsultaId = SCOPE_IDENTITY();

    BEGIN TRY
        EXEC sp_OACreate 'MSXML2.ServerXMLHTTP.6.0', @Object OUT;
        EXEC sp_OAMethod @Object, 'open', NULL, @Metodo, @UrlApi, false;
        EXEC sp_OAMethod @Object, 'send';
        EXEC sp_OAGetProperty @Object, 'status', @Status OUT;
        EXEC sp_OAGetProperty @Object, 'responseText', @ResponseText OUT;
        EXEC sp_OADestroy @Object;

        UPDATE Importacion.ApiConsulta
        SET estado = CASE WHEN @Status BETWEEN 200 AND 299 THEN 'Finalizado' ELSE 'Error' END,
            codigo_http = @Status,
            respuesta = @ResponseText,
            mensaje_error = CASE WHEN @Status BETWEEN 200 AND 299 THEN NULL ELSE 'La API respondio con estado HTTP no exitoso.' END
        WHERE id = @ApiConsultaId;
    END TRY
    BEGIN CATCH
        IF @Object IS NOT NULL EXEC sp_OADestroy @Object;

        UPDATE Importacion.ApiConsulta
        SET estado = 'Error', mensaje_error = ERROR_MESSAGE()
        WHERE id = @ApiConsultaId;

        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Importacion.sp_RegistrarCotizacionDesdeApi
    @UrlApi varchar(1000),
    @Moneda varchar(20),
    @ApiConsultaId int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    EXEC Importacion.sp_ConsumirApi
        @UrlApi = @UrlApi,
        @Metodo = 'GET',
        @ApiConsultaId = @ApiConsultaId OUTPUT;

    DECLARE @Respuesta nvarchar(max);
    SELECT @Respuesta = respuesta
    FROM Importacion.ApiConsulta
    WHERE id = @ApiConsultaId AND estado = 'Finalizado';

    IF @Respuesta IS NULL RETURN;

    ;WITH Datos AS (
        SELECT
            TRY_CONVERT(date, JSON_VALUE(value, '$.fecha')) AS fecha,
            TRY_CONVERT(decimal(18,6), JSON_VALUE(value, '$.valor')) AS valor
        FROM OPENJSON(@Respuesta, '$.results')
    ), Validado AS (
        SELECT fecha, valor
        FROM Datos
        WHERE fecha IS NOT NULL AND valor IS NOT NULL
    )
    MERGE Importacion.ApiCotizacion AS Target
    USING Validado AS Source
    ON Target.moneda = @Moneda AND Target.fecha = Source.fecha
    WHEN MATCHED THEN
        UPDATE SET valor = Source.valor, api_consulta_id = @ApiConsultaId, fecha_registro = SYSDATETIME()
    WHEN NOT MATCHED THEN
        INSERT (api_consulta_id, moneda, fecha, valor)
        VALUES (@ApiConsultaId, @Moneda, Source.fecha, Source.valor);
END;
GO
