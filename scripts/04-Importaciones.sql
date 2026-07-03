/*******************************************************************************
Fecha: 30/06/2026
Integrantes: [Nicolas Kugel, Facundo Gargiulo, Valentin Martinez]
Descripcion: Modulo de importacion CSV.
             Usa lineas crudas, mapeo JSON, control de lotes, errores por fila
             y upsert por entidad. El SQL dinamico queda acotado al BULK INSERT.
*******************************************************************************/

USE TPBDG5;
GO

DROP PROCEDURE IF EXISTS Importacion.usp_ImportarParqueCSV;
DROP PROCEDURE IF EXISTS Importacion.usp_ImportarVisitanteCSV;
DROP PROCEDURE IF EXISTS Importacion.usp_ImportarAtraccionCSV;
DROP PROCEDURE IF EXISTS Importacion.usp_ImportarGuiaCSV;
DROP PROCEDURE IF EXISTS Importacion.usp_ImportarGuardaParqueCSV;

DROP PROCEDURE IF EXISTS Importacion.usp_CargarCsvLineasDesdeArchivo;
DROP PROCEDURE IF EXISTS Importacion.usp_CargarExcelLineasDesdeArchivo;
DROP FUNCTION IF EXISTS Importacion.fn_CantidadColumnasCsvLinea;

DROP FUNCTION IF EXISTS Importacion.fn_ValorCsvLinea;
DROP FUNCTION IF EXISTS Importacion.fn_ValorCsvGenerico;

DROP PROCEDURE IF EXISTS Importacion.usp_ValidarLoteImportacionCSV;
DROP PROCEDURE IF EXISTS Importacion.usp_FinalizarLoteImportacionCSV;
DROP PROCEDURE IF EXISTS Importacion.usp_RegistrarErrorImportacion;
GO

IF OBJECT_ID('Importacion.ErrorImportacion', 'U') IS NOT NULL DROP TABLE Importacion.ErrorImportacion;
IF OBJECT_ID('Importacion.CsvLinea', 'U') IS NOT NULL DROP TABLE Importacion.CsvLinea;
IF OBJECT_ID('Importacion.CsvLineaTrabajo', 'U') IS NOT NULL DROP TABLE Importacion.CsvLineaTrabajo;
IF OBJECT_ID('Importacion.CsvGenerico', 'U') IS NOT NULL DROP TABLE Importacion.CsvGenerico;
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
    mensaje nvarchar(500) NULL
);
GO

CREATE TABLE Importacion.CsvLineaTrabajo (
    fila int IDENTITY(1,1) PRIMARY KEY,
    linea nvarchar(1000) NOT NULL
);
GO

CREATE TABLE Importacion.CsvLinea (
    lote_id int NOT NULL,
    fila int NOT NULL,
    linea nvarchar(1000) NOT NULL,
    CONSTRAINT PK_CsvLinea PRIMARY KEY (lote_id, fila),
    CONSTRAINT FK_CsvLinea_Lote FOREIGN KEY (lote_id) REFERENCES Importacion.LoteImportacion(id)
);
GO

CREATE TABLE Importacion.ErrorImportacion (
    id int IDENTITY(1,1) PRIMARY KEY,
    lote_id int NOT NULL,
    fila int NULL,
    campo varchar(100) NULL,
    valor nvarchar(500) NULL,
    mensaje nvarchar(500) NOT NULL,
    fecha_error datetime2(0) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_ErrorImportacion_Lote FOREIGN KEY (lote_id) REFERENCES Importacion.LoteImportacion(id)
);
GO

CREATE OR ALTER FUNCTION Importacion.fn_ValorCsvLinea (
    @linea nvarchar(1000),
    @separador varchar(5),
    @numero_columna int
)
RETURNS nvarchar(500)
AS
BEGIN
    DECLARE @json nvarchar(1000);
    DECLARE @valor nvarchar(500);

    IF @linea IS NULL OR @separador IS NULL OR @numero_columna IS NULL OR @numero_columna < 1
        RETURN NULL;

    --- Arma el JSON a partir de la línea y el separador, se pone N para que sea unicode, por eso @json es varchar
    SET @json = N'["' + REPLACE(STRING_ESCAPE(@linea, 'json'), @separador, N'","') + N'"]';

    --- Elimina espacios en blanco alrededor de los valores y convierte el valor (que devuelve OPENJSON) a nvarchar(500)
    SELECT @valor = LTRIM(RTRIM(CONVERT(nvarchar(500), value)))
    FROM OPENJSON(@json)
    WHERE CONVERT(int, [key]) = @numero_columna - 1;

    RETURN NULLIF(@valor, '');
END;
GO

CREATE OR ALTER FUNCTION Importacion.fn_CantidadColumnasCsvLinea (
    @linea nvarchar(1000),
    @separador varchar(5)
)
RETURNS int
AS
BEGIN
    DECLARE @json nvarchar(1000);
    DECLARE @cantidad int;

    IF @linea IS NULL OR @separador IS NULL
        RETURN 0;

    SET @json =  N'["' + REPLACE(STRING_ESCAPE(@linea, 'json'), @separador, N'","') + N'"]';

    SELECT @cantidad = COUNT(*)
    FROM OPENJSON(@json);

    RETURN ISNULL(@cantidad, 0);
END;
GO

CREATE OR ALTER PROCEDURE Importacion.usp_RegistrarErrorImportacion
    @lote_id int,
    @fila int = NULL,
    @campo varchar(100) = NULL,
    @valor nvarchar(500) = NULL,
    @mensaje nvarchar(500)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Importacion.ErrorImportacion (lote_id, fila, campo, valor, mensaje)
    VALUES (@lote_id, @fila, @campo, @valor, @mensaje);
END;
GO

CREATE OR ALTER PROCEDURE Importacion.usp_ValidarLoteImportacionCSV
    @LoteId int,
    @RutaArchivo varchar(1000),
    @NombreArchivo varchar(260) = NULL,
    @Dataset varchar(100)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Importacion.LoteImportacion WHERE id = @LoteId)
    BEGIN
        RAISERROR('ERROR: El lote indicado no existe en Importacion.LoteImportacion.', 16, 1);
        RETURN;
    END;

    UPDATE Importacion.LoteImportacion
    SET dataset = @Dataset,
        nombre_archivo = COALESCE(@NombreArchivo, nombre_archivo, @RutaArchivo),
        ruta_archivo = @RutaArchivo,
        estado = 'En proceso',
        fecha_fin = NULL,
        mensaje = NULL,
        registros_leidos = 0,
        registros_validos = 0,
        registros_insertados = 0,
        registros_actualizados = 0,
        registros_error = 0
    WHERE id = @LoteId;

    DELETE FROM Importacion.ErrorImportacion WHERE lote_id = @LoteId;
END;
GO

CREATE OR ALTER PROCEDURE Importacion.usp_FinalizarLoteImportacionCSV
    @LoteId int,
    @RegistrosValidos int,
    @RegistrosInsertados int,
    @RegistrosActualizados int,
    @Mensaje nvarchar(500)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Importacion.LoteImportacion
    SET fecha_fin = SYSDATETIME(),
        estado = CASE WHEN EXISTS (SELECT 1 FROM Importacion.ErrorImportacion WHERE lote_id = @LoteId) THEN 'Con errores' ELSE 'Finalizado' END,
        registros_validos = @RegistrosValidos,
        registros_insertados = @RegistrosInsertados,
        registros_actualizados = @RegistrosActualizados,
        registros_error = (SELECT COUNT(*) FROM Importacion.ErrorImportacion WHERE lote_id = @LoteId),
        mensaje = @Mensaje
    WHERE id = @LoteId;
END;
GO

CREATE OR ALTER PROCEDURE Importacion.usp_CargarCsvLineasDesdeArchivo
    @LoteId int,
    @RutaArchivo varchar(1000),
    @Separador varchar(5) = ',',
    @PrimeraFilaDatos int = 2
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DELETE FROM Importacion.CsvLinea WHERE lote_id = @LoteId;
        TRUNCATE TABLE Importacion.CsvLineaTrabajo;

        CREATE TABLE #CsvArchivo (
            contenido nvarchar(max) NOT NULL
        );

        DECLARE @Sql nvarchar(max) = N'
            INSERT INTO #CsvArchivo (contenido)
            SELECT CONVERT(nvarchar(max), BulkColumn)
            FROM OPENROWSET(
                BULK ''' + REPLACE(@RutaArchivo, '''', '''''') + N''',
                SINGLE_CLOB,
                CODEPAGE = ''65001''
            ) AS Archivo;';
        ---- El valor 65001 corresponde a la codificación UTF-8
        EXEC sp_executesql @Sql;

        DECLARE @Contenido nvarchar(max);
        DECLARE @JsonLineas nvarchar(max);

        SELECT @Contenido = REPLACE(contenido, CHAR(13), '') --- Eliminamos carriage return, \r (Windows)
        FROM #CsvArchivo;

        SET @JsonLineas = N'["' + REPLACE(STRING_ESCAPE(@Contenido, 'json'), '\n', N'", "') + N'"]';

        INSERT INTO Importacion.CsvLinea (lote_id, fila, linea)
        SELECT @LoteId, CONVERT(int, [key]) + 1, LTRIM(RTRIM(CONVERT(nvarchar(max), value)))
        FROM OPENJSON(@JsonLineas)
        --- Evaluamos si value es vacio, retornamos NULL, sino retornamos value normalizado sin espacios.
        WHERE NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max), value))), '') IS NOT NULL;

        UPDATE Importacion.LoteImportacion
        SET registros_leidos = (SELECT COUNT(*) FROM Importacion.CsvLinea WHERE lote_id = @LoteId AND fila >= @PrimeraFilaDatos)
        WHERE id = @LoteId;

        INSERT INTO Importacion.ErrorImportacion (lote_id, fila, campo, valor, mensaje)
        SELECT @LoteId, fila, 'archivo', LEFT(linea, 500), 'No se pueden importar archivos o filas con una sola columna.'
        FROM Importacion.CsvLinea
        WHERE lote_id = @LoteId
          AND fila >= @PrimeraFilaDatos
          AND Importacion.fn_CantidadColumnasCsvLinea(linea, @Separador) <= 1;

        IF NOT EXISTS (
            SELECT 1
            FROM Importacion.CsvLinea
            WHERE lote_id = @LoteId
              AND fila >= @PrimeraFilaDatos
              AND Importacion.fn_CantidadColumnasCsvLinea(linea, @Separador) > 1
        )
        BEGIN
            RAISERROR('ERROR: No se pueden importar archivos con una sola columna.', 16, 1);
        END;
    END TRY
    BEGIN CATCH
        UPDATE Importacion.LoteImportacion
        SET fecha_fin = SYSDATETIME(), estado = 'Error', mensaje = ERROR_MESSAGE(),
            registros_error = (SELECT COUNT(*) FROM Importacion.ErrorImportacion WHERE lote_id = @LoteId)
        WHERE id = @LoteId;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Importacion.usp_CargarExcelLineasDesdeArchivo
    @LoteId int,
    @RutaArchivo varchar(1000),
    @NombreHoja varchar(128),
    @Separador varchar(5) = ',',
    @PrimeraFilaDatos int = 2
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NULLIF(LTRIM(RTRIM(@NombreHoja)), '') IS NULL
        BEGIN
            RAISERROR('ERROR: Para importar Excel se debe indicar @NombreHoja sin el signo $.', 16, 1);
            RETURN;
        END;

        DELETE FROM Importacion.CsvLinea WHERE lote_id = @LoteId;
        TRUNCATE TABLE Importacion.CsvLineaTrabajo;

        DECLARE @Sql nvarchar(max);
        DECLARE @HojaRango varchar(300) = REPLACE(@NombreHoja, '''', '''''') + '$A:AD';

        SET @Sql = N'
            INSERT INTO Importacion.CsvLinea (lote_id, fila, linea)
            SELECT @LoteId,
                   ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS fila,
                   LTRIM(RTRIM(
                       ISNULL(CONVERT(nvarchar(500), F1), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F2), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F3), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F4), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F5), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F6), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F7), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F8), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F9), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F10), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F11), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F12), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F13), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F14), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F15), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F16), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F17), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F18), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F19), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F20), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F21), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F22), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F23), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F24), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F25), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F26), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F27), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F28), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F29), '''') + @Separador +
                       ISNULL(CONVERT(nvarchar(500), F30), '''')
                   )) AS linea
            FROM OPENROWSET(
                ''Microsoft.ACE.OLEDB.16.0'',
                ''Excel 12.0;Database=' + REPLACE(@RutaArchivo, '''', '''''') + ';HDR=NO;IMEX=1'',
                ''SELECT * FROM [' + @HojaRango + ']''
            ) AS ExcelFilas
            WHERE COALESCE(
                CONVERT(nvarchar(500), F1), CONVERT(nvarchar(500), F2), CONVERT(nvarchar(500), F3),
                CONVERT(nvarchar(500), F4), CONVERT(nvarchar(500), F5), CONVERT(nvarchar(500), F6),
                CONVERT(nvarchar(500), F7), CONVERT(nvarchar(500), F8), CONVERT(nvarchar(500), F9),
                CONVERT(nvarchar(500), F10), CONVERT(nvarchar(500), F11), CONVERT(nvarchar(500), F12),
                CONVERT(nvarchar(500), F13), CONVERT(nvarchar(500), F14), CONVERT(nvarchar(500), F15),
                CONVERT(nvarchar(500), F16), CONVERT(nvarchar(500), F17), CONVERT(nvarchar(500), F18),
                CONVERT(nvarchar(500), F19), CONVERT(nvarchar(500), F20), CONVERT(nvarchar(500), F21),
                CONVERT(nvarchar(500), F22), CONVERT(nvarchar(500), F23), CONVERT(nvarchar(500), F24),
                CONVERT(nvarchar(500), F25), CONVERT(nvarchar(500), F26), CONVERT(nvarchar(500), F27),
                CONVERT(nvarchar(500), F28), CONVERT(nvarchar(500), F29), CONVERT(nvarchar(500), F30)
            ) IS NOT NULL;';

        EXEC sp_executesql @Sql, N'@LoteId int, @Separador varchar(5)', @LoteId = @LoteId, @Separador = @Separador;

        UPDATE Importacion.LoteImportacion
        SET registros_leidos = (SELECT COUNT(*) FROM Importacion.CsvLinea WHERE lote_id = @LoteId AND fila >= @PrimeraFilaDatos)
        WHERE id = @LoteId;

        INSERT INTO Importacion.ErrorImportacion (lote_id, fila, campo, valor, mensaje)
        SELECT @LoteId, fila, 'archivo', LEFT(linea, 500), 'No se pueden importar archivos o filas con una sola columna.'
        FROM Importacion.CsvLinea
        WHERE lote_id = @LoteId
          AND fila >= @PrimeraFilaDatos
          AND Importacion.fn_CantidadColumnasCsvLinea(linea, @Separador) <= 1;

        IF NOT EXISTS (
            SELECT 1
            FROM Importacion.CsvLinea
            WHERE lote_id = @LoteId
              AND fila >= @PrimeraFilaDatos
              AND Importacion.fn_CantidadColumnasCsvLinea(linea, @Separador) > 1
        )
        BEGIN
            RAISERROR('ERROR: No se pueden importar archivos con una sola columna.', 16, 1);
        END;
    END TRY
    BEGIN CATCH
        UPDATE Importacion.LoteImportacion
        SET fecha_fin = SYSDATETIME(), estado = 'Error', mensaje = ERROR_MESSAGE(),
            registros_error = (SELECT COUNT(*) FROM Importacion.ErrorImportacion WHERE lote_id = @LoteId)
        WHERE id = @LoteId;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Importacion.usp_ImportarParqueCSV
    @LoteId int,
    @RutaArchivo varchar(1000),
    @MapeoColumnas nvarchar(max),
    @NombreArchivo varchar(260) = NULL,
    @Separador varchar(5) = ',',
    @PrimeraFilaDatos int = 2,
    @TipoArchivo varchar(10) = 'CSV',
    @NombreHoja varchar(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        EXEC Importacion.usp_ValidarLoteImportacionCSV @LoteId, @RutaArchivo, @NombreArchivo, 'Parque';
        IF UPPER(@TipoArchivo) IN ('XLS', 'XLSX')
            EXEC Importacion.usp_CargarExcelLineasDesdeArchivo @LoteId, @RutaArchivo, @NombreHoja, @Separador, @PrimeraFilaDatos;
        ELSE
            EXEC Importacion.usp_CargarCsvLineasDesdeArchivo @LoteId, @RutaArchivo, @Separador, @PrimeraFilaDatos;

        DECLARE @ColCodigo int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.Codigo'));
        DECLARE @ColNombre int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.nombre'));
        DECLARE @ColUbicacion int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.ubicacion'));
        DECLARE @ColTipoParque int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.tipo_parque'));
        DECLARE @ColSuperficie int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.superficie_ha'));

        IF @ColCodigo IS NULL EXEC Importacion.usp_RegistrarErrorImportacion @LoteId, NULL, 'Codigo', NULL, 'Falta mapear Codigo.';
        IF @ColNombre IS NULL EXEC Importacion.usp_RegistrarErrorImportacion @LoteId, NULL, 'nombre', NULL, 'Falta mapear nombre.';
        IF @ColUbicacion IS NULL EXEC Importacion.usp_RegistrarErrorImportacion @LoteId, NULL, 'ubicacion', NULL, 'Falta mapear ubicacion.';
        IF @ColTipoParque IS NULL EXEC Importacion.usp_RegistrarErrorImportacion @LoteId, NULL, 'tipo_parque', NULL, 'Falta mapear tipo_parque.';
        IF @ColSuperficie IS NULL EXEC Importacion.usp_RegistrarErrorImportacion @LoteId, NULL, 'superficie_ha', NULL, 'Falta mapear superficie_ha.';
        IF EXISTS (SELECT 1 FROM Importacion.ErrorImportacion WHERE lote_id = @LoteId AND fila IS NULL) RAISERROR('ERROR: El mapeo de columnas esta incompleto.', 16, 1);

        ;WITH Datos AS (
            SELECT fila,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColCodigo) AS Codigo,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColNombre) AS nombre,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColUbicacion) AS ubicacion,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColTipoParque) AS tipo_parque,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColSuperficie) AS superficie_ha
            FROM Importacion.CsvLinea
            WHERE lote_id = @LoteId AND fila >= @PrimeraFilaDatos
        ), Errores AS (
            SELECT fila, 'Codigo' AS campo, Codigo AS valor, 'Codigo obligatorio.' AS mensaje FROM Datos WHERE ISNULL(Codigo, '') = ''
            UNION ALL SELECT fila, 'nombre', nombre, 'Nombre obligatorio.' FROM Datos WHERE ISNULL(nombre, '') = ''
            UNION ALL SELECT fila, 'ubicacion', ubicacion, 'Ubicacion obligatoria.' FROM Datos WHERE ISNULL(ubicacion, '') = ''
            UNION ALL SELECT fila, 'tipo_parque', tipo_parque, 'tipo_parque debe tener 2 caracteres.' FROM Datos WHERE LEN(ISNULL(tipo_parque, '')) <> 2
            UNION ALL SELECT fila, 'superficie_ha', superficie_ha, 'superficie_ha debe ser mayor a 0.' FROM Datos WHERE TRY_CONVERT(decimal(12,2), superficie_ha) IS NULL OR TRY_CONVERT(decimal(12,2), superficie_ha) <= 0
        )
        INSERT INTO Importacion.ErrorImportacion (lote_id, fila, campo, valor, mensaje)
        SELECT @LoteId, fila, campo, valor, mensaje FROM Errores;

        DECLARE @Cambios TABLE (accion varchar(10));

        ;WITH Datos AS (
            SELECT fila,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColCodigo) AS Codigo,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColNombre) AS nombre,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColUbicacion) AS ubicacion,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColTipoParque) AS tipo_parque,
                TRY_CONVERT(decimal(12,2), Importacion.fn_ValorCsvLinea(linea, @Separador, @ColSuperficie)) AS superficie_ha
            FROM Importacion.CsvLinea
            WHERE lote_id = @LoteId AND fila >= @PrimeraFilaDatos
        ), Validado AS (
            SELECT * FROM Datos D WHERE NOT EXISTS (SELECT 1 FROM Importacion.ErrorImportacion E WHERE E.lote_id = @LoteId AND E.fila = D.fila)
        )
        MERGE Parques.Parque AS Target
        USING Validado AS Source
        ON Target.Codigo = Source.Codigo
        WHEN MATCHED THEN UPDATE SET nombre = Source.nombre, ubicacion = Source.ubicacion, tipo_parque = Source.tipo_parque, superficie_ha = Source.superficie_ha
        WHEN NOT MATCHED THEN INSERT (Codigo, nombre, ubicacion, tipo_parque, superficie_ha) VALUES (Source.Codigo, Source.nombre, Source.ubicacion, Source.tipo_parque, Source.superficie_ha)
        OUTPUT $action INTO @Cambios;

        DECLARE @RegistrosValidos int = (SELECT COUNT(*) FROM @Cambios);
        DECLARE @RegistrosInsertados int = (SELECT COUNT(*) FROM @Cambios WHERE accion = 'INSERT');
        DECLARE @RegistrosActualizados int = (SELECT COUNT(*) FROM @Cambios WHERE accion = 'UPDATE');

        EXEC Importacion.usp_FinalizarLoteImportacionCSV @LoteId, @RegistrosValidos, @RegistrosInsertados, @RegistrosActualizados, 'Importacion CSV de parques finalizada.';
    END TRY
    BEGIN CATCH
        UPDATE Importacion.LoteImportacion SET fecha_fin = SYSDATETIME(), estado = 'Error', mensaje = ERROR_MESSAGE(), registros_error = (SELECT COUNT(*) FROM Importacion.ErrorImportacion WHERE lote_id = @LoteId) WHERE id = @LoteId;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Importacion.usp_ImportarVisitanteCSV
    @LoteId int,
    @RutaArchivo varchar(1000),
    @MapeoColumnas nvarchar(max),
    @NombreArchivo varchar(260) = NULL,
    @Separador varchar(5) = ',',
    @PrimeraFilaDatos int = 2,
    @TipoArchivo varchar(10) = 'CSV',
    @NombreHoja varchar(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        EXEC Importacion.usp_ValidarLoteImportacionCSV @LoteId, @RutaArchivo, @NombreArchivo, 'Visitante';
        IF UPPER(@TipoArchivo) IN ('XLS', 'XLSX')
            EXEC Importacion.usp_CargarExcelLineasDesdeArchivo @LoteId, @RutaArchivo, @NombreHoja, @Separador, @PrimeraFilaDatos;
        ELSE
            EXEC Importacion.usp_CargarCsvLineasDesdeArchivo @LoteId, @RutaArchivo, @Separador, @PrimeraFilaDatos;

        DECLARE @ColNombre int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.nombre'));
        DECLARE @ColApellido int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.apellido'));
        DECLARE @ColDni int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.dni'));

        IF @ColNombre IS NULL EXEC Importacion.usp_RegistrarErrorImportacion @LoteId, NULL, 'nombre', NULL, 'Falta mapear nombre.';
        IF @ColApellido IS NULL EXEC Importacion.usp_RegistrarErrorImportacion @LoteId, NULL, 'apellido', NULL, 'Falta mapear apellido.';
        IF @ColDni IS NULL EXEC Importacion.usp_RegistrarErrorImportacion @LoteId, NULL, 'dni', NULL, 'Falta mapear dni.';
        IF EXISTS (SELECT 1 FROM Importacion.ErrorImportacion WHERE lote_id = @LoteId AND fila IS NULL) RAISERROR('ERROR: El mapeo de columnas esta incompleto.', 16, 1);

        ;WITH Datos AS (
            SELECT fila,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColNombre) AS nombre,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColApellido) AS apellido,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColDni) AS dni
            FROM Importacion.CsvLinea
            WHERE lote_id = @LoteId AND fila >= @PrimeraFilaDatos
        ), Errores AS (
            SELECT fila, 'nombre' AS campo, nombre AS valor, 'Nombre obligatorio.' AS mensaje FROM Datos WHERE ISNULL(nombre, '') = ''
            UNION ALL SELECT fila, 'apellido', apellido, 'Apellido obligatorio.' FROM Datos WHERE ISNULL(apellido, '') = ''
            UNION ALL SELECT fila, 'dni', dni, 'DNI obligatorio con longitud minima 6.' FROM Datos WHERE LEN(ISNULL(dni, '')) < 6
        )
        INSERT INTO Importacion.ErrorImportacion (lote_id, fila, campo, valor, mensaje)
        SELECT @LoteId, fila, campo, valor, mensaje FROM Errores;

        DECLARE @Cambios TABLE (accion varchar(10));

        ;WITH Datos AS (
            SELECT fila,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColNombre) AS nombre,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColApellido) AS apellido,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColDni) AS dni
            FROM Importacion.CsvLinea
            WHERE lote_id = @LoteId AND fila >= @PrimeraFilaDatos
        ), Validado AS (
            SELECT * FROM Datos D WHERE NOT EXISTS (SELECT 1 FROM Importacion.ErrorImportacion E WHERE E.lote_id = @LoteId AND E.fila = D.fila)
        )
        MERGE Ventas.Visitante AS Target
        USING Validado AS Source
        ON Target.dni = Source.dni
        WHEN MATCHED THEN UPDATE SET nombre = Source.nombre, apellido = Source.apellido
        WHEN NOT MATCHED THEN INSERT (nombre, apellido, dni) VALUES (Source.nombre, Source.apellido, Source.dni)
        OUTPUT $action INTO @Cambios;

        DECLARE @RegistrosValidos int = (SELECT COUNT(*) FROM @Cambios);
        DECLARE @RegistrosInsertados int = (SELECT COUNT(*) FROM @Cambios WHERE accion = 'INSERT');
        DECLARE @RegistrosActualizados int = (SELECT COUNT(*) FROM @Cambios WHERE accion = 'UPDATE');

        EXEC Importacion.usp_FinalizarLoteImportacionCSV @LoteId, @RegistrosValidos, @RegistrosInsertados, @RegistrosActualizados, 'Importacion CSV de visitantes finalizada.';
    END TRY
    BEGIN CATCH
        UPDATE Importacion.LoteImportacion SET fecha_fin = SYSDATETIME(), estado = 'Error', mensaje = ERROR_MESSAGE(), registros_error = (SELECT COUNT(*) FROM Importacion.ErrorImportacion WHERE lote_id = @LoteId) WHERE id = @LoteId;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Importacion.usp_ImportarGuiaCSV
    @LoteId int,
    @RutaArchivo varchar(1000),
    @MapeoColumnas nvarchar(max),
    @NombreArchivo varchar(260) = NULL,
    @Separador varchar(5) = ',',
    @PrimeraFilaDatos int = 2,
    @TipoArchivo varchar(10) = 'CSV',
    @NombreHoja varchar(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        EXEC Importacion.usp_ValidarLoteImportacionCSV @LoteId, @RutaArchivo, @NombreArchivo, 'Guia';
        IF UPPER(@TipoArchivo) IN ('XLS', 'XLSX')
            EXEC Importacion.usp_CargarExcelLineasDesdeArchivo @LoteId, @RutaArchivo, @NombreHoja, @Separador, @PrimeraFilaDatos;
        ELSE
            EXEC Importacion.usp_CargarCsvLineasDesdeArchivo @LoteId, @RutaArchivo, @Separador, @PrimeraFilaDatos;

        DECLARE @ColNombre int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.nombre'));
        DECLARE @ColApellido int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.apellido'));
        DECLARE @ColDni int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.dni'));
        DECLARE @ColTitulo int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.titulo'));
        DECLARE @ColTipoHabilitacion int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.tipo_habilitacion'));
        DECLARE @ColEspecialidad int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.especialidad'));

        IF @ColNombre IS NULL EXEC Importacion.usp_RegistrarErrorImportacion @LoteId, NULL, 'nombre', NULL, 'Falta mapear nombre.';
        IF @ColApellido IS NULL EXEC Importacion.usp_RegistrarErrorImportacion @LoteId, NULL, 'apellido', NULL, 'Falta mapear apellido.';
        IF @ColDni IS NULL EXEC Importacion.usp_RegistrarErrorImportacion @LoteId, NULL, 'dni', NULL, 'Falta mapear dni.';
        IF @ColEspecialidad IS NULL EXEC Importacion.usp_RegistrarErrorImportacion @LoteId, NULL, 'especialidad', NULL, 'Falta mapear especialidad.';
        IF EXISTS (SELECT 1 FROM Importacion.ErrorImportacion WHERE lote_id = @LoteId AND fila IS NULL) RAISERROR('ERROR: El mapeo de columnas esta incompleto.', 16, 1);

        ;WITH Datos AS (
            SELECT fila,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColNombre) AS nombre,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColApellido) AS apellido,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColDni) AS dni,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColTitulo) AS titulo,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColTipoHabilitacion) AS tipo_habilitacion,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColEspecialidad) AS especialidad
            FROM Importacion.CsvLinea
            WHERE lote_id = @LoteId AND fila >= @PrimeraFilaDatos
        ), Errores AS (
            SELECT fila, 'nombre' AS campo, nombre AS valor, 'Nombre obligatorio.' AS mensaje FROM Datos WHERE ISNULL(nombre, '') = ''
            UNION ALL SELECT fila, 'apellido', apellido, 'Apellido obligatorio.' FROM Datos WHERE ISNULL(apellido, '') = ''
            UNION ALL SELECT fila, 'dni', dni, 'DNI obligatorio con longitud minima 6.' FROM Datos WHERE LEN(ISNULL(dni, '')) < 6
            UNION ALL SELECT fila, 'especialidad', especialidad, 'Especialidad obligatoria.' FROM Datos WHERE ISNULL(especialidad, '') = ''
        )
        INSERT INTO Importacion.ErrorImportacion (lote_id, fila, campo, valor, mensaje)
        SELECT @LoteId, fila, campo, valor, mensaje FROM Errores;

        DECLARE @Cambios TABLE (accion varchar(10));

        ;WITH Datos AS (
            SELECT fila,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColNombre) AS nombre,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColApellido) AS apellido,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColDni) AS dni,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColTitulo) AS titulo,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColTipoHabilitacion) AS tipo_habilitacion,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColEspecialidad) AS especialidad
            FROM Importacion.CsvLinea
            WHERE lote_id = @LoteId AND fila >= @PrimeraFilaDatos
        ), Validado AS (
            SELECT * FROM Datos D WHERE NOT EXISTS (SELECT 1 FROM Importacion.ErrorImportacion E WHERE E.lote_id = @LoteId AND E.fila = D.fila)
        )
        MERGE Personal.Guia AS Target
        USING Validado AS Source
        ON Target.dni = Source.dni
        WHEN MATCHED THEN UPDATE SET nombre = Source.nombre, apellido = Source.apellido, titulo = Source.titulo, tipo_habilitacion = Source.tipo_habilitacion, especialidad = Source.especialidad
        WHEN NOT MATCHED THEN INSERT (nombre, apellido, dni, titulo, tipo_habilitacion, especialidad) VALUES (Source.nombre, Source.apellido, Source.dni, Source.titulo, Source.tipo_habilitacion, Source.especialidad)
        OUTPUT $action INTO @Cambios;

        DECLARE @RegistrosValidos int = (SELECT COUNT(*) FROM @Cambios);
        DECLARE @RegistrosInsertados int = (SELECT COUNT(*) FROM @Cambios WHERE accion = 'INSERT');
        DECLARE @RegistrosActualizados int = (SELECT COUNT(*) FROM @Cambios WHERE accion = 'UPDATE');

        EXEC Importacion.usp_FinalizarLoteImportacionCSV @LoteId, @RegistrosValidos, @RegistrosInsertados, @RegistrosActualizados, 'Importacion CSV de guias finalizada.';
    END TRY
    BEGIN CATCH
        UPDATE Importacion.LoteImportacion SET fecha_fin = SYSDATETIME(), estado = 'Error', mensaje = ERROR_MESSAGE(), registros_error = (SELECT COUNT(*) FROM Importacion.ErrorImportacion WHERE lote_id = @LoteId) WHERE id = @LoteId;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Importacion.usp_ImportarGuardaParqueCSV
    @LoteId int,
    @RutaArchivo varchar(1000),
    @MapeoColumnas nvarchar(max),
    @NombreArchivo varchar(260) = NULL,
    @Separador varchar(5) = ',',
    @PrimeraFilaDatos int = 2,
    @TipoArchivo varchar(10) = 'CSV',
    @NombreHoja varchar(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        EXEC Importacion.usp_ValidarLoteImportacionCSV @LoteId, @RutaArchivo, @NombreArchivo, 'GuardaParque';
        IF UPPER(@TipoArchivo) IN ('XLS', 'XLSX')
            EXEC Importacion.usp_CargarExcelLineasDesdeArchivo @LoteId, @RutaArchivo, @NombreHoja, @Separador, @PrimeraFilaDatos;
        ELSE
            EXEC Importacion.usp_CargarCsvLineasDesdeArchivo @LoteId, @RutaArchivo, @Separador, @PrimeraFilaDatos;

        DECLARE @ColNombre int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.nombre'));
        DECLARE @ColApellido int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.apellido'));
        DECLARE @ColDni int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.dni'));
        DECLARE @ColEstado int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.estado'));

        IF @ColNombre IS NULL EXEC Importacion.usp_RegistrarErrorImportacion @LoteId, NULL, 'nombre', NULL, 'Falta mapear nombre.';
        IF @ColApellido IS NULL EXEC Importacion.usp_RegistrarErrorImportacion @LoteId, NULL, 'apellido', NULL, 'Falta mapear apellido.';
        IF @ColDni IS NULL EXEC Importacion.usp_RegistrarErrorImportacion @LoteId, NULL, 'dni', NULL, 'Falta mapear dni.';
        IF @ColEstado IS NULL EXEC Importacion.usp_RegistrarErrorImportacion @LoteId, NULL, 'estado', NULL, 'Falta mapear estado.';
        IF EXISTS (SELECT 1 FROM Importacion.ErrorImportacion WHERE lote_id = @LoteId AND fila IS NULL) RAISERROR('ERROR: El mapeo de columnas esta incompleto.', 16, 1);

        ;WITH Datos AS (
            SELECT fila,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColNombre) AS nombre,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColApellido) AS apellido,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColDni) AS dni,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColEstado) AS estado
            FROM Importacion.CsvLinea
            WHERE lote_id = @LoteId AND fila >= @PrimeraFilaDatos
        ), Errores AS (
            SELECT fila, 'nombre' AS campo, nombre AS valor, 'Nombre obligatorio.' AS mensaje FROM Datos WHERE ISNULL(nombre, '') = ''
            UNION ALL SELECT fila, 'apellido', apellido, 'Apellido obligatorio.' FROM Datos WHERE ISNULL(apellido, '') = ''
            UNION ALL SELECT fila, 'dni', dni, 'DNI obligatorio con longitud minima 6.' FROM Datos WHERE LEN(ISNULL(dni, '')) < 6
            UNION ALL SELECT fila, 'estado', estado, 'Estado debe ser 0 o 1.' FROM Datos WHERE TRY_CONVERT(int, estado) IS NULL OR TRY_CONVERT(int, estado) NOT IN (0, 1)
        )
        INSERT INTO Importacion.ErrorImportacion (lote_id, fila, campo, valor, mensaje)
        SELECT @LoteId, fila, campo, valor, mensaje FROM Errores;

        DECLARE @Cambios TABLE (accion varchar(10));

        ;WITH Datos AS (
            SELECT fila,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColNombre) AS nombre,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColApellido) AS apellido,
                Importacion.fn_ValorCsvLinea(linea, @Separador, @ColDni) AS dni,
                TRY_CONVERT(int, Importacion.fn_ValorCsvLinea(linea, @Separador, @ColEstado)) AS estado
            FROM Importacion.CsvLinea
            WHERE lote_id = @LoteId AND fila >= @PrimeraFilaDatos
        ), Validado AS (
            SELECT * FROM Datos D WHERE NOT EXISTS (SELECT 1 FROM Importacion.ErrorImportacion E WHERE E.lote_id = @LoteId AND E.fila = D.fila)
        )
        MERGE Personal.GuardaParque AS Target
        USING Validado AS Source
        ON Target.dni = Source.dni
        WHEN MATCHED THEN UPDATE SET nombre = Source.nombre, apellido = Source.apellido, estado = Source.estado
        WHEN NOT MATCHED THEN INSERT (nombre, apellido, dni, estado) VALUES (Source.nombre, Source.apellido, Source.dni, Source.estado)
        OUTPUT $action INTO @Cambios;

        DECLARE @RegistrosValidos int = (SELECT COUNT(*) FROM @Cambios);
        DECLARE @RegistrosInsertados int = (SELECT COUNT(*) FROM @Cambios WHERE accion = 'INSERT');
        DECLARE @RegistrosActualizados int = (SELECT COUNT(*) FROM @Cambios WHERE accion = 'UPDATE');

        EXEC Importacion.usp_FinalizarLoteImportacionCSV @LoteId, @RegistrosValidos, @RegistrosInsertados, @RegistrosActualizados, 'Importacion CSV de guardaparques finalizada.';
    END TRY
    BEGIN CATCH
        UPDATE Importacion.LoteImportacion SET fecha_fin = SYSDATETIME(), estado = 'Error', mensaje = ERROR_MESSAGE(), registros_error = (SELECT COUNT(*) FROM Importacion.ErrorImportacion WHERE lote_id = @LoteId) WHERE id = @LoteId;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE Importacion.usp_ImportarAtraccionCSV
    @LoteId int,
    @RutaArchivo varchar(1000),
    @MapeoColumnas nvarchar(max),
    @NombreArchivo varchar(260) = NULL,
    @Separador varchar(5) = ',',
    @PrimeraFilaDatos int = 2,
    @TipoArchivo varchar(10) = 'CSV',
    @NombreHoja varchar(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        EXEC Importacion.usp_ValidarLoteImportacionCSV @LoteId, @RutaArchivo, @NombreArchivo, 'Atraccion';
        IF UPPER(@TipoArchivo) IN ('XLS', 'XLSX')
            EXEC Importacion.usp_CargarExcelLineasDesdeArchivo @LoteId, @RutaArchivo, @NombreHoja, @Separador, @PrimeraFilaDatos;
        ELSE
            EXEC Importacion.usp_CargarCsvLineasDesdeArchivo @LoteId, @RutaArchivo, @Separador, @PrimeraFilaDatos;

        DECLARE @ColNombre int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.nombre'));
        DECLARE @ColDescripcion int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.descripcion'));
        DECLARE @ColDuracion int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.duracion'));
        DECLARE @ColCupo int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.cupo_maximo'));
        DECLARE @ColCosto int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.costo'));
        DECLARE @ColCodigoParque int = TRY_CONVERT(int, JSON_VALUE(@MapeoColumnas, '$.CodigoParque'));

        IF @ColNombre IS NULL EXEC Importacion.usp_RegistrarErrorImportacion @LoteId, NULL, 'nombre', NULL, 'Falta mapear nombre.';
        IF @ColDuracion IS NULL EXEC Importacion.usp_RegistrarErrorImportacion @LoteId, NULL, 'duracion', NULL, 'Falta mapear duracion.';
        IF @ColCupo IS NULL EXEC Importacion.usp_RegistrarErrorImportacion @LoteId, NULL, 'cupo_maximo', NULL, 'Falta mapear cupo_maximo.';
        IF @ColCosto IS NULL EXEC Importacion.usp_RegistrarErrorImportacion @LoteId, NULL, 'costo', NULL, 'Falta mapear costo.';
        IF @ColCodigoParque IS NULL EXEC Importacion.usp_RegistrarErrorImportacion @LoteId, NULL, 'CodigoParque', NULL, 'Falta mapear CodigoParque.';
        IF EXISTS (SELECT 1 FROM Importacion.ErrorImportacion WHERE lote_id = @LoteId AND fila IS NULL) RAISERROR('ERROR: El mapeo de columnas esta incompleto.', 16, 1);

        ;WITH Datos AS (
            SELECT C.fila,
                Importacion.fn_ValorCsvLinea(C.linea, @Separador, @ColNombre) AS nombre,
                Importacion.fn_ValorCsvLinea(C.linea, @Separador, @ColDescripcion) AS descripcion,
                Importacion.fn_ValorCsvLinea(C.linea, @Separador, @ColDuracion) AS duracion,
                Importacion.fn_ValorCsvLinea(C.linea, @Separador, @ColCupo) AS cupo_maximo,
                Importacion.fn_ValorCsvLinea(C.linea, @Separador, @ColCosto) AS costo,
                Importacion.fn_ValorCsvLinea(C.linea, @Separador, @ColCodigoParque) AS CodigoParque,
                P.id AS parque_id
            FROM Importacion.CsvLinea C
            LEFT JOIN Parques.Parque P ON P.Codigo = Importacion.fn_ValorCsvLinea(C.linea, @Separador, @ColCodigoParque)
            WHERE C.lote_id = @LoteId AND C.fila >= @PrimeraFilaDatos
        ), Errores AS (
            SELECT fila, 'nombre' AS campo, nombre AS valor, 'Nombre obligatorio.' AS mensaje FROM Datos WHERE ISNULL(nombre, '') = ''
            UNION ALL SELECT fila, 'duracion', duracion, 'Duracion debe ser un valor TIME valido.' FROM Datos WHERE TRY_CONVERT(time, duracion) IS NULL
            UNION ALL SELECT fila, 'cupo_maximo', cupo_maximo, 'cupo_maximo debe ser mayor a 0.' FROM Datos WHERE TRY_CONVERT(int, cupo_maximo) IS NULL OR TRY_CONVERT(int, cupo_maximo) <= 0
            UNION ALL SELECT fila, 'costo', costo, 'costo debe ser mayor o igual a 0.' FROM Datos WHERE TRY_CONVERT(decimal(18,2), costo) IS NULL OR TRY_CONVERT(decimal(18,2), costo) < 0
            UNION ALL SELECT fila, 'CodigoParque', CodigoParque, 'CodigoParque no existe en Parques.Parque.' FROM Datos WHERE parque_id IS NULL
        )
        INSERT INTO Importacion.ErrorImportacion (lote_id, fila, campo, valor, mensaje)
        SELECT @LoteId, fila, campo, valor, mensaje FROM Errores;

        DECLARE @Cambios TABLE (accion varchar(10));

        ;WITH Datos AS (
            SELECT C.fila,
                Importacion.fn_ValorCsvLinea(C.linea, @Separador, @ColNombre) AS nombre,
                Importacion.fn_ValorCsvLinea(C.linea, @Separador, @ColDescripcion) AS descripcion,
                TRY_CONVERT(time, Importacion.fn_ValorCsvLinea(C.linea, @Separador, @ColDuracion)) AS duracion,
                TRY_CONVERT(int, Importacion.fn_ValorCsvLinea(C.linea, @Separador, @ColCupo)) AS cupo_maximo,
                TRY_CONVERT(decimal(18,2), Importacion.fn_ValorCsvLinea(C.linea, @Separador, @ColCosto)) AS costo,
                P.id AS parque_id
            FROM Importacion.CsvLinea C
            LEFT JOIN Parques.Parque P ON P.Codigo = Importacion.fn_ValorCsvLinea(C.linea, @Separador, @ColCodigoParque)
            WHERE C.lote_id = @LoteId AND C.fila >= @PrimeraFilaDatos
        ), Validado AS (
            SELECT * FROM Datos D WHERE NOT EXISTS (SELECT 1 FROM Importacion.ErrorImportacion E WHERE E.lote_id = @LoteId AND E.fila = D.fila)
        )
        MERGE Parques.Atraccion AS Target
        USING Validado AS Source
        ON Target.nombre = Source.nombre AND Target.parque_id = Source.parque_id
        WHEN MATCHED THEN UPDATE SET descripcion = Source.descripcion, duracion = Source.duracion, cupo_maximo = Source.cupo_maximo, costo = Source.costo
        WHEN NOT MATCHED THEN INSERT (nombre, descripcion, duracion, cupo_maximo, costo, parque_id) VALUES (Source.nombre, Source.descripcion, Source.duracion, Source.cupo_maximo, Source.costo, Source.parque_id)
        OUTPUT $action INTO @Cambios;

        DECLARE @RegistrosValidos int = (SELECT COUNT(*) FROM @Cambios);
        DECLARE @RegistrosInsertados int = (SELECT COUNT(*) FROM @Cambios WHERE accion = 'INSERT');
        DECLARE @RegistrosActualizados int = (SELECT COUNT(*) FROM @Cambios WHERE accion = 'UPDATE');

        EXEC Importacion.usp_FinalizarLoteImportacionCSV @LoteId, @RegistrosValidos, @RegistrosInsertados, @RegistrosActualizados, 'Importacion CSV de atracciones finalizada.';
    END TRY
    BEGIN CATCH
        UPDATE Importacion.LoteImportacion SET fecha_fin = SYSDATETIME(), estado = 'Error', mensaje = ERROR_MESSAGE(), registros_error = (SELECT COUNT(*) FROM Importacion.ErrorImportacion WHERE lote_id = @LoteId) WHERE id = @LoteId;
        THROW;
    END CATCH;
END;
GO
