/*******************************************************************************
Fecha: 22/06/2026
Integrantes: [Nicolás Kugel, Facundo Gargiulo, Valentin Martinez]
Descripción: Script 2/4 - Procedimientos Almacenados para operaciones ABM.
             Incluye la lógica de validación acumulativa de condiciones de negocio.
*******************************************************************************/

USE TPBDG5;
GO

-- ==========================================
-- ABM: PARQUE
-- ==========================================
CREATE OR ALTER PROCEDURE sp_ABM_Parque
    @Accion CHAR(1), -- 'I' (Insert), 'U' (Update), 'D' (Delete)
    @id INT = NULL,
    @nombre VARCHAR(255) = NULL,
    @ubicacion VARCHAR(255) = NULL,
    @precio_entrada DECIMAL(18,2) = NULL,
    @superficie_ha DECIMAL(12,2) = NULL,
    @tipo_parque CHAR(2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(255) = '';

    IF @Accion IN ('I', 'U')
    BEGIN
        -- Validación: El precio de entrada no puede ser negativo
        IF @precio_entrada < 0
            SET @Errores = @Errores + 'ERROR: El precio de entrada no puede ser un valor negativo.' + CHAR(13);

        -- Validación: La superficie medida en hectáreas debe ser estrictamente mayor a cero
        IF @superficie_ha <= 0
            SET @Errores = @Errores + 'ERROR: La superficie del parque debe ser mayor a 0 hectáreas.' + CHAR(13);

        -- Validación: Campos de texto obligatorios vacíos
        IF ISNULL(@nombre, '') = ''
            SET @Errores = @Errores + 'ERROR: El nombre del parque es un campo obligatorio.' + CHAR(13);
    END

    -- Despacho unificado de errores si existen
    IF LEN(@Errores) > 0
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    -- Ejecución de la operación si pasó las validaciones
    IF @Accion = 'I'
    BEGIN
        INSERT INTO Parque (nombre, ubicacion, precio_entrada, superficie_ha, tipo_parque)
        VALUES (@nombre, @ubicacion, @precio_entrada, @superficie_ha, @tipo_parque);
    END
    ELSE IF @Accion = 'U'
    BEGIN
        UPDATE Parque
        SET nombre = @nombre, ubicacion = @ubicacion,
            precio_entrada = @precio_entrada, superficie_ha = @superficie_ha, tipo_parque = @tipo_parque
        WHERE id = @id;
    END
    ELSE IF @Accion = 'D'
    BEGIN
        DELETE FROM Parque WHERE id = @id;
    END
END;
GO

-- ==========================================
-- ABM: GUIA
-- ==========================================
CREATE OR ALTER PROCEDURE sp_ABM_Guia
    @Accion CHAR(1),
    @id INT = NULL,
    @nombre VARCHAR(255) = NULL,
    @apellido VARCHAR(255) = NULL,
    @dni VARCHAR(50) = NULL,
    @titulo VARCHAR(255) = NULL,
    @tipo_habilitacion VARCHAR(255) = NULL,
    @especialidad VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(255) = '';

    IF @Accion IN ('I', 'U')
    BEGIN
        -- Validación: Nombre y apellido del personal no pueden ser nulos
        IF ISNULL(@nombre, '') = '' OR ISNULL(@apellido, '') = ''
            SET @Errores = @Errores + 'ERROR: Nombre y Apellido del guía son campos obligatorios.' + CHAR(13);

        -- Validación: Longitud mínima del DNI para evitar registros basura
        IF LEN(ISNULL(@dni, '')) < 6
            SET @Errores = @Errores + 'ERROR: El DNI proporcionado no tiene una longitud válida (mínimo 6 caracteres).' + CHAR(13);
    END

    IF LEN(@Errores) > 0
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    IF @Accion = 'I'
    BEGIN
        INSERT INTO Guia(nombre, apellido, dni, titulo, tipo_habilitacion, especialidad)
        VALUES (@nombre, @apellido, @dni, @titulo, @tipo_habilitacion, @especialidad);
    END
    ELSE IF @Accion = 'U'
    BEGIN
        UPDATE Guia
        SET nombre = @nombre, apellido = @apellido, dni = @dni, titulo = @titulo,
            tipo_habilitacion = @tipo_habilitacion, especialidad = @especialidad
        WHERE id = @id;
    END
    ELSE IF @Accion = 'D'
    BEGIN
        DELETE FROM Guia WHERE id = @id;
    END
END;
GO

-- ==========================================
-- ABM: CONCESION
-- ==========================================
CREATE OR ALTER PROCEDURE sp_ABM_Concesion
    @Accion CHAR(1),
    @id INT = NULL,
    @fecha_inicio DATE = NULL,
    @fecha_fin DATE = NULL,
    @canon_mensual DECIMAL(18,2) = NULL,
    @empresa_id INT = NULL,
    @parque_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(255) = '';

    IF @Accion IN ('I', 'U')
    BEGIN
        -- Validación: La fecha de finalización contractual debe ser posterior a la fecha de inicio
        IF @fecha_fin <= @fecha_inicio
            SET @Errores = @Errores + 'ERROR: La fecha de fin del contrato de concesión debe ser estrictamente posterior a la de inicio.' + CHAR(13);

        -- Validación: El canon mensual a cobrar debe ser positivo
        IF @canon_mensual <= 0
            SET @Errores = @Errores + 'ERROR: El monto del canon mensual debe ser un valor mayor a cero.' + CHAR(13);

        -- Validación: Integridad relacional previa de entidades existentes
        IF NOT EXISTS (SELECT 1 FROM Empresa WHERE id = @empresa_id)
            SET @Errores = @Errores + 'ERROR: La Empresa asociada no existe en los registros del sistema.' + CHAR(13);

        IF NOT EXISTS (SELECT 1 FROM Parque WHERE id = @parque_id)
            SET @Errores = @Errores + 'ERROR: El Parque destino asignado no existe.' + CHAR(13);
    END

    IF LEN(@Errores) > 0
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    IF @Accion = 'I'
    BEGIN
        INSERT INTO Concesion(fecha_inicio, fecha_fin, canon_mensual, empresa_id, parque_id)
        VALUES (@fecha_inicio, @fecha_fin, @canon_mensual, @empresa_id, @parque_id);
    END
    ELSE IF @Accion = 'U'
    BEGIN
        UPDATE Concesion
        SET fecha_inicio = @fecha_inicio, fecha_fin = @fecha_fin, canon_mensual = @canon_mensual,
            empresa_id = @empresa_id, parque_id = @parque_id
        WHERE id = @id;
    END
    ELSE IF @Accion = 'D'
    BEGIN
        DELETE FROM Concesion WHERE id = @id;
    END
END;
GO

-- ==========================================
-- ABM: TIPO VISITANTE
-- ==========================================
CREATE OR ALTER PROCEDURE sp_ABM_TipoVisitante
    @Accion CHAR(1), @id INT = NULL, @descripcion VARCHAR(255) = NULL, @descuento INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    -- Validación: Descuento acotado de manera porcentual realista (0% a 100%)
    IF @Accion IN ('I', 'U') AND (@descuento < 0 OR @descuento > 100)
    BEGIN
        RAISERROR('ERROR: El porcentaje de descuento asignado debe encontrarse en el rango de 0 a 100.', 16, 1);
        RETURN;
    END

    IF @Accion = 'I' INSERT INTO TipoVisitante(descripcion, descuento) VALUES (@descripcion, @descuento);
    IF @Accion = 'U' UPDATE TipoVisitante SET descripcion = @descripcion, descuento = @descuento WHERE id = @id;
    IF @Accion = 'D' DELETE FROM TipoVisitante WHERE id = @id;
END;
GO

CREATE OR ALTER PROCEDURE sp_ABM_Entrada
    @Accion CHAR(1), @id INT = NULL, @precio_entrada DECIMAL(18,2) = NULL, @parque_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(255) = '';

    IF @Accion IN ('I', 'U')
    BEGIN
        IF @precio_entrada < 0
            SET @Errores = @Errores + 'ERROR: El precio de la entrada no puede ser un valor negativo.' + CHAR(13);

        IF NOT EXISTS (SELECT 1 FROM Parque WHERE id = @parque_id)
            SET @Errores = @Errores + 'ERROR: El Parque asociado a la entrada no existe.' + CHAR(13);
    END

    IF LEN(@Errores) > 0
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    IF @Accion = 'I' INSERT INTO Entrada(precio_entrada, parque_id) VALUES (@precio_entrada, @parque_id);
    IF @Accion = 'U' UPDATE Entrada SET precio_entrada = @precio_entrada, parque_id = @parque_id WHERE id = @id;
    IF @Accion = 'D' DELETE FROM Entrada WHERE id = @id;
END;
GO

CREATE OR ALTER PROCEDURE sp_ABM_Empresa
    @Accion CHAR(1), @id INT = NULL, @razon_social VARCHAR(255) = NULL, @cuit VARCHAR(255) = NULL, @tipo_actividad VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(255) = '';

    IF @Accion IN ('I', 'U')
    BEGIN
        IF ISNULL(@razon_social, '') = '' OR ISNULL(@cuit, '') = ''
            SET @Errores = @Errores + 'ERROR: La Razón Social y el CUIT son campos obligatorios.' + CHAR(13);

        IF LEN(ISNULL(@cuit, '')) < 11
            SET @Errores = @Errores + 'ERROR: El CUIT proporcionado no tiene una longitud válida (mínimo 11 caracteres).' + CHAR(13);
    END

    IF LEN(@Errores) > 0
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    IF @Accion = 'I' INSERT INTO Empresa(razon_social, cuit, tipo_actividad) VALUES (@razon_social, @cuit, @tipo_actividad);
    IF @Accion = 'U' UPDATE Empresa SET razon_social = @razon_social, cuit = @cuit, tipo_actividad = @tipo_actividad WHERE id = @id;
    IF @Accion = 'D' DELETE FROM Empresa WHERE id = @id;
END;
GO
