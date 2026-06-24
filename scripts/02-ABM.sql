/*******************************************************************************
Fecha: 24/06/2026
Integrantes: [Nicolás Kugel, Facundo Gargiulo, Valentin Martinez]
Descripción: Procedimientos Almacenados para operaciones ABM de todas las tablas.
             Incluye la lógica de validación acumulativa de condiciones de negocio.
             Tablas cubiertas: Parques.Parque, Personal.Guia, Concesiones.Concesion,
             Ventas.TipoVisitante, Parques.Entrada, Concesiones.Empresa,
             Personal.GuardaParque, Personal.AsignacionGuardaParque,
             Parques.Atraccion, Ventas.Visitante, Personal.AtraccionGuia (U/D)
             y Concesiones.PagoConcesion (U/D).
*******************************************************************************/

USE TPBDG5;
GO

-- ==========================================
-- ABM: PARQUE
-- ==========================================
CREATE OR ALTER PROCEDURE sp_ABM_Parque
    @Accion        CHAR(1),
    @id            INT           = NULL,
    @Codigo        VARCHAR(20)   = NULL,
    @nombre        VARCHAR(100)  = NULL,
    @ubicacion     VARCHAR(200)  = NULL,
    @superficie_ha DECIMAL(12,2) = NULL,
    @tipo_parque   CHAR(2)       = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(MAX) = '';

    IF @Accion IN ('I', 'U')
    BEGIN
        IF ISNULL(@nombre, '') = ''
            SET @Errores = @Errores + 'ERROR: El nombre del parque es un campo obligatorio.' + CHAR(13);

        IF ISNULL(@Codigo, '') = ''
            SET @Errores = @Errores + 'ERROR: El código del parque es un campo obligatorio.' + CHAR(13);

        IF ISNULL(@superficie_ha, 0) <= 0
            SET @Errores = @Errores + 'ERROR: La superficie del parque debe ser mayor a 0 hectáreas.' + CHAR(13);
    END

    IF LEN(@Errores) > 0
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    IF @Accion = 'I'
        INSERT INTO Parques.Parque (Codigo, nombre, ubicacion, tipo_parque, superficie_ha)
        VALUES (@Codigo, @nombre, @ubicacion, @tipo_parque, @superficie_ha);
    ELSE IF @Accion = 'U'
        UPDATE Parques.Parque
        SET Codigo = @Codigo, nombre = @nombre, ubicacion = @ubicacion,
            tipo_parque = @tipo_parque, superficie_ha = @superficie_ha
        WHERE id = @id;
    ELSE IF @Accion = 'D'
        DELETE FROM Parques.Parque WHERE id = @id;
END;
GO

-- ==========================================
-- ABM: GUIA
-- ==========================================
CREATE OR ALTER PROCEDURE sp_ABM_Guia
    @Accion            CHAR(1),
    @id                INT          = NULL,
    @nombre            VARCHAR(100) = NULL,
    @apellido          VARCHAR(100) = NULL,
    @dni               VARCHAR(15)  = NULL,
    @titulo            VARCHAR(150) = NULL,
    @tipo_habilitacion VARCHAR(100) = NULL,
    @especialidad      VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(MAX) = '';

    IF @Accion IN ('I', 'U')
    BEGIN
        IF ISNULL(@nombre, '') = '' OR ISNULL(@apellido, '') = ''
            SET @Errores = @Errores + 'ERROR: Nombre y Apellido del guía son campos obligatorios.' + CHAR(13);

        IF LEN(ISNULL(@dni, '')) < 6
            SET @Errores = @Errores + 'ERROR: El DNI proporcionado no tiene una longitud válida (mínimo 6 caracteres).' + CHAR(13);
    END

    IF LEN(@Errores) > 0
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    IF @Accion = 'I'
        INSERT INTO Personal.Guia (nombre, apellido, dni, titulo, tipo_habilitacion, especialidad)
        VALUES (@nombre, @apellido, @dni, @titulo, @tipo_habilitacion, @especialidad);
    ELSE IF @Accion = 'U'
        UPDATE Personal.Guia
        SET nombre = @nombre, apellido = @apellido, dni = @dni, titulo = @titulo,
            tipo_habilitacion = @tipo_habilitacion, especialidad = @especialidad
        WHERE id = @id;
    ELSE IF @Accion = 'D'
        DELETE FROM Personal.Guia WHERE id = @id;
END;
GO

-- ==========================================
-- ABM: CONCESION
-- ==========================================
CREATE OR ALTER PROCEDURE sp_ABM_Concesion
    @Accion        CHAR(1),
    @id            INT           = NULL,
    @fecha_inicio  DATE          = NULL,
    @fecha_fin     DATE          = NULL,
    @canon_mensual DECIMAL(18,2) = NULL,
    @empresa_id    INT           = NULL,
    @parque_id     INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(MAX) = '';

    IF @Accion IN ('I', 'U')
    BEGIN
        IF @fecha_fin <= @fecha_inicio
            SET @Errores = @Errores + 'ERROR: La fecha de fin del contrato de concesión debe ser estrictamente posterior a la de inicio.' + CHAR(13);

        IF @canon_mensual <= 0
            SET @Errores = @Errores + 'ERROR: El monto del canon mensual debe ser un valor mayor a cero.' + CHAR(13);

        IF NOT EXISTS (SELECT 1 FROM Concesiones.Empresa WHERE id = @empresa_id)
            SET @Errores = @Errores + 'ERROR: La Empresa asociada no existe en los registros del sistema.' + CHAR(13);

        IF NOT EXISTS (SELECT 1 FROM Parques.Parque WHERE id = @parque_id)
            SET @Errores = @Errores + 'ERROR: El Parque destino asignado no existe.' + CHAR(13);
    END

    IF LEN(@Errores) > 0
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    IF @Accion = 'I'
        INSERT INTO Concesiones.Concesion (fecha_inicio, fecha_fin, canon_mensual, empresa_id, parque_id)
        VALUES (@fecha_inicio, @fecha_fin, @canon_mensual, @empresa_id, @parque_id);
    ELSE IF @Accion = 'U'
        UPDATE Concesiones.Concesion
        SET fecha_inicio = @fecha_inicio, fecha_fin = @fecha_fin, canon_mensual = @canon_mensual,
            empresa_id = @empresa_id, parque_id = @parque_id
        WHERE id = @id;
    ELSE IF @Accion = 'D'
        DELETE FROM Concesiones.Concesion WHERE id = @id;
END;
GO

-- ==========================================
-- ABM: TIPO VISITANTE
-- ==========================================
CREATE OR ALTER PROCEDURE sp_ABM_TipoVisitante
    @Accion      CHAR(1),
    @id          INT          = NULL,
    @descripcion VARCHAR(100) = NULL,
    @descuento   INT          = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @Accion IN ('I', 'U') AND (@descuento < 0 OR @descuento > 100)
    BEGIN
        RAISERROR('ERROR: El porcentaje de descuento asignado debe encontrarse en el rango de 0 a 100.', 16, 1);
        RETURN;
    END

    IF @Accion = 'I' INSERT INTO Ventas.TipoVisitante (descripcion, descuento) VALUES (@descripcion, @descuento);
    IF @Accion = 'U' UPDATE Ventas.TipoVisitante SET descripcion = @descripcion, descuento = @descuento WHERE id = @id;
    IF @Accion = 'D' DELETE FROM Ventas.TipoVisitante WHERE id = @id;
END;
GO

-- ==========================================
-- ABM: ENTRADA
-- ==========================================
CREATE OR ALTER PROCEDURE sp_ABM_Entrada
    @Accion         CHAR(1),
    @id             INT           = NULL,
    @precio_entrada DECIMAL(18,2) = NULL,
    @parque_id      INT           = NULL,
    @fecha_desde    DATE          = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(MAX) = '';

    IF @Accion IN ('I', 'U')
    BEGIN
        IF ISNULL(@precio_entrada, -1) < 0
            SET @Errores = @Errores + 'ERROR: El precio de la entrada no puede ser un valor negativo.' + CHAR(13);

        IF NOT EXISTS (SELECT 1 FROM Parques.Parque WHERE id = @parque_id)
            SET @Errores = @Errores + 'ERROR: El Parque asociado a la entrada no existe.' + CHAR(13);

        IF @fecha_desde IS NULL
            SET @Errores = @Errores + 'ERROR: La fecha de vigencia de la entrada es obligatoria.' + CHAR(13);
    END

    IF LEN(@Errores) > 0
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    IF @Accion = 'I'
        INSERT INTO Parques.Entrada (precio_entrada, parque_id, fecha_desde)
        VALUES (@precio_entrada, @parque_id, @fecha_desde);
    IF @Accion = 'U'
        UPDATE Parques.Entrada
        SET precio_entrada = @precio_entrada, parque_id = @parque_id, fecha_desde = @fecha_desde
        WHERE id = @id;
    IF @Accion = 'D'
        DELETE FROM Parques.Entrada WHERE id = @id;
END;
GO

-- ==========================================
-- ABM: EMPRESA
-- ==========================================
CREATE OR ALTER PROCEDURE sp_ABM_Empresa
    @Accion         CHAR(1),
    @id             INT          = NULL,
    @razon_social   VARCHAR(150) = NULL,
    @cuit           VARCHAR(13)  = NULL,
    @tipo_actividad VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(MAX) = '';

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

    IF @Accion = 'I' INSERT INTO Concesiones.Empresa (razon_social, cuit, tipo_actividad) VALUES (@razon_social, @cuit, @tipo_actividad);
    IF @Accion = 'U' UPDATE Concesiones.Empresa SET razon_social = @razon_social, cuit = @cuit, tipo_actividad = @tipo_actividad WHERE id = @id;
    IF @Accion = 'D' DELETE FROM Concesiones.Empresa WHERE id = @id;
END;
GO

-- ==========================================
-- ABM: GUARDA PARQUE
-- ==========================================
CREATE OR ALTER PROCEDURE sp_ABM_GuardaParque
    @Accion   CHAR(1),
    @id       INT          = NULL,
    @nombre   VARCHAR(100) = NULL,
    @apellido VARCHAR(100) = NULL,
    @dni      VARCHAR(15)  = NULL,
    @estado   INT          = NULL  -- 1: Activo, 0: Inactivo
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(MAX) = '';

    IF @Accion IN ('I', 'U')
    BEGIN
        IF ISNULL(@nombre, '') = '' OR ISNULL(@apellido, '') = ''
            SET @Errores = @Errores + 'ERROR: Nombre y Apellido del guardaparque son obligatorios.' + CHAR(13);

        IF LEN(ISNULL(@dni, '')) < 6
            SET @Errores = @Errores + 'ERROR: El DNI debe tener al menos 6 caracteres.' + CHAR(13);

        IF @estado NOT IN (0, 1)
            SET @Errores = @Errores + 'ERROR: El estado debe ser 0 (Inactivo) o 1 (Activo).' + CHAR(13);

        IF @Accion = 'I' AND EXISTS (SELECT 1 FROM Personal.GuardaParque WHERE dni = @dni)
            SET @Errores = @Errores + 'ERROR: Ya existe un guardaparque registrado con ese DNI.' + CHAR(13);
    END

    IF LEN(@Errores) > 0
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    IF @Accion = 'I'
        INSERT INTO Personal.GuardaParque (nombre, apellido, dni, estado)
        VALUES (@nombre, @apellido, @dni, @estado);
    ELSE IF @Accion = 'U'
        UPDATE Personal.GuardaParque
        SET nombre = @nombre, apellido = @apellido, dni = @dni, estado = @estado
        WHERE id = @id;
    ELSE IF @Accion = 'D'
        DELETE FROM Personal.GuardaParque WHERE id = @id;
END;
GO

-- ==========================================
-- ABM: ASIGNACION GUARDA PARQUE
-- ==========================================
CREATE OR ALTER PROCEDURE sp_ABM_AsignacionGuardaParque
    @Accion           CHAR(1),
    @id               INT          = NULL,
    @fecha_inicio     DATE         = NULL,
    @fecha_fin        DATE         = NULL,
    @motivo_egreso    VARCHAR(200) = NULL,
    @guarda_parque_id INT          = NULL,
    @parque_id        INT          = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(MAX) = '';

    IF @Accion IN ('I', 'U')
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM Personal.GuardaParque WHERE id = @guarda_parque_id)
            SET @Errores = @Errores + 'ERROR: El guardaparque indicado no existe en el sistema.' + CHAR(13);

        IF NOT EXISTS (SELECT 1 FROM Parques.Parque WHERE id = @parque_id)
            SET @Errores = @Errores + 'ERROR: El parque indicado no existe en el sistema.' + CHAR(13);

        IF @fecha_fin IS NOT NULL AND @fecha_fin < @fecha_inicio
            SET @Errores = @Errores + 'ERROR: La fecha de fin no puede ser anterior a la fecha de inicio.' + CHAR(13);

        IF @fecha_fin IS NOT NULL AND ISNULL(@motivo_egreso, '') = ''
            SET @Errores = @Errores + 'ERROR: Se debe indicar el motivo de egreso cuando se registra una fecha de fin.' + CHAR(13);
    END

    IF LEN(@Errores) > 0
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    IF @Accion = 'I'
        INSERT INTO Personal.AsignacionGuardaParque (fecha_inicio, fecha_fin, motivo_egreso, guarda_parque_id, parque_id)
        VALUES (@fecha_inicio, @fecha_fin, @motivo_egreso, @guarda_parque_id, @parque_id);
    ELSE IF @Accion = 'U'
        UPDATE Personal.AsignacionGuardaParque
        SET fecha_inicio = @fecha_inicio, fecha_fin = @fecha_fin,
            motivo_egreso = @motivo_egreso, guarda_parque_id = @guarda_parque_id, parque_id = @parque_id
        WHERE id = @id;
    ELSE IF @Accion = 'D'
        DELETE FROM Personal.AsignacionGuardaParque WHERE id = @id;
END;
GO

-- ==========================================
-- ABM: ATRACCION
-- ==========================================
CREATE OR ALTER PROCEDURE sp_ABM_Atraccion
    @Accion      CHAR(1),
    @id          INT           = NULL,
    @nombre      VARCHAR(100)  = NULL,
    @descripcion VARCHAR(500)  = NULL,
    @duracion    TIME          = NULL,
    @cupo_maximo INT           = NULL,
    @costo       DECIMAL(18,2) = NULL,
    @parque_id   INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(MAX) = '';

    IF @Accion IN ('I', 'U')
    BEGIN
        IF ISNULL(@nombre, '') = ''
            SET @Errores = @Errores + 'ERROR: El nombre de la atracción es un campo obligatorio.' + CHAR(13);

        IF ISNULL(@cupo_maximo, 0) <= 0
            SET @Errores = @Errores + 'ERROR: El cupo máximo debe ser un número entero positivo.' + CHAR(13);

        IF ISNULL(@costo, -1) < 0
            SET @Errores = @Errores + 'ERROR: El costo de la atracción no puede ser un valor negativo.' + CHAR(13);

        IF NOT EXISTS (SELECT 1 FROM Parques.Parque WHERE id = @parque_id)
            SET @Errores = @Errores + 'ERROR: El parque asociado a la atracción no existe en el sistema.' + CHAR(13);
    END

    IF LEN(@Errores) > 0
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    IF @Accion = 'I'
        INSERT INTO Parques.Atraccion (nombre, descripcion, duracion, cupo_maximo, costo, parque_id)
        VALUES (@nombre, @descripcion, @duracion, @cupo_maximo, @costo, @parque_id);
    ELSE IF @Accion = 'U'
        UPDATE Parques.Atraccion
        SET nombre = @nombre, descripcion = @descripcion, duracion = @duracion,
            cupo_maximo = @cupo_maximo, costo = @costo, parque_id = @parque_id
        WHERE id = @id;
    ELSE IF @Accion = 'D'
        DELETE FROM Parques.Atraccion WHERE id = @id;
END;
GO

-- ==========================================
-- ABM: VISITANTE
-- ==========================================
CREATE OR ALTER PROCEDURE sp_ABM_Visitante
    @Accion   CHAR(1),
    @id       INT          = NULL,
    @nombre   VARCHAR(100) = NULL,
    @apellido VARCHAR(100) = NULL,
    @dni      VARCHAR(15)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(MAX) = '';

    IF @Accion IN ('I', 'U')
    BEGIN
        IF ISNULL(@nombre, '') = '' OR ISNULL(@apellido, '') = ''
            SET @Errores = @Errores + 'ERROR: Nombre y Apellido del visitante son campos obligatorios.' + CHAR(13);

        IF LEN(ISNULL(@dni, '')) < 6
            SET @Errores = @Errores + 'ERROR: El DNI del visitante debe tener al menos 6 caracteres.' + CHAR(13);

        IF @Accion = 'I' AND EXISTS (SELECT 1 FROM Ventas.Visitante WHERE dni = @dni)
            SET @Errores = @Errores + 'ERROR: Ya existe un visitante registrado con ese DNI.' + CHAR(13);
    END

    IF LEN(@Errores) > 0
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    IF @Accion = 'I'
        INSERT INTO Ventas.Visitante (nombre, apellido, dni) VALUES (@nombre, @apellido, @dni);
    ELSE IF @Accion = 'U'
        UPDATE Ventas.Visitante SET nombre = @nombre, apellido = @apellido, dni = @dni WHERE id = @id;
    ELSE IF @Accion = 'D'
        DELETE FROM Ventas.Visitante WHERE id = @id;
END;
GO

-- ==========================================
-- ABM: ATRACCION GUIA — Modificación y Baja
-- La asignación inicial (Alta) se realiza a través de sp_AsignarGuiaAtraccion
-- en logicaNegocio.sql, que aplica las validaciones de negocio correspondientes.
-- ==========================================
CREATE OR ALTER PROCEDURE sp_ABM_AtraccionGuia
    @Accion           CHAR(1),           -- 'U' Actualizar | 'D' Eliminar
    @id               INT          = NULL,
    @fecha_asignacion DATE         = NULL,
    @turno            VARCHAR(10)  = NULL,
    @atraccion_id     INT          = NULL,
    @guia_id          INT          = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(MAX) = '';

    IF @Accion = 'U'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM Personal.AtraccionGuia WHERE id = @id)
            SET @Errores = @Errores + 'ERROR: La asignación guía-atracción indicada no existe en el sistema.' + CHAR(13);

        IF ISNULL(@turno, '') NOT IN ('Mañana', 'Tarde', 'Noche')
            SET @Errores = @Errores + 'ERROR: El turno debe ser Mañana, Tarde o Noche.' + CHAR(13);

        IF NOT EXISTS (SELECT 1 FROM Parques.Atraccion WHERE id = @atraccion_id)
            SET @Errores = @Errores + 'ERROR: La atracción indicada no existe en el sistema.' + CHAR(13);

        IF NOT EXISTS (SELECT 1 FROM Personal.Guia WHERE id = @guia_id)
            SET @Errores = @Errores + 'ERROR: El guía indicado no existe en el sistema.' + CHAR(13);
    END

    IF @Accion = 'D' AND NOT EXISTS (SELECT 1 FROM Personal.AtraccionGuia WHERE id = @id)
        SET @Errores = @Errores + 'ERROR: La asignación que se intenta eliminar no existe en el sistema.' + CHAR(13);

    IF LEN(@Errores) > 0
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    IF @Accion = 'U'
        UPDATE Personal.AtraccionGuia
        SET fecha_asignacion = @fecha_asignacion, turno = @turno,
            atraccion_id = @atraccion_id, guia_id = @guia_id
        WHERE id = @id;
    ELSE IF @Accion = 'D'
        DELETE FROM Personal.AtraccionGuia WHERE id = @id;
END;
GO

-- ==========================================
-- ABM: PAGO CONCESION — Modificación y Baja
-- La carga inicial (Alta) se gestiona a través de sp_RegistrarPagoConcesion
-- en logicaNegocio.sql, que aplica la lógica de negocio del canon mensual.
-- ==========================================
CREATE OR ALTER PROCEDURE sp_ABM_PagoConcesion
    @Accion       CHAR(1),
    @id           INT           = NULL,
    @fecha_pago   DATE          = NULL,
    @periodo      DATE          = NULL,
    @estado       VARCHAR(10)   = NULL,   -- 'Pagado' | 'Atrasado' | 'Pendiente'
    @total        DECIMAL(18,2) = NULL,
    @concesion_id INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(MAX) = '';

    IF @Accion = 'U'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM Concesiones.PagoConcesion WHERE id = @id)
            SET @Errores = @Errores + 'ERROR: El pago de concesión indicado no existe en el sistema.' + CHAR(13);

        IF ISNULL(@estado, '') NOT IN ('Pagado', 'Atrasado', 'Pendiente')
            SET @Errores = @Errores + 'ERROR: El estado del pago debe ser Pagado, Atrasado o Pendiente.' + CHAR(13);

        IF ISNULL(@total, -1) < 0
            SET @Errores = @Errores + 'ERROR: El monto del pago no puede ser un valor negativo.' + CHAR(13);

        IF NOT EXISTS (SELECT 1 FROM Concesiones.Concesion WHERE id = @concesion_id)
            SET @Errores = @Errores + 'ERROR: La concesión indicada no existe en el sistema.' + CHAR(13);
    END

    IF @Accion = 'D' AND NOT EXISTS (SELECT 1 FROM Concesiones.PagoConcesion WHERE id = @id)
        SET @Errores = @Errores + 'ERROR: El pago de concesión que se intenta eliminar no existe.' + CHAR(13);

    IF LEN(@Errores) > 0
    BEGIN
        RAISERROR(@Errores, 16, 1);
        RETURN;
    END

    IF @Accion = 'U'
        UPDATE Concesiones.PagoConcesion
        SET fecha_pago = @fecha_pago, periodo = @periodo, estado = @estado,
            total = @total, concesion_id = @concesion_id
        WHERE id = @id;
    ELSE IF @Accion = 'D'
        DELETE FROM Concesiones.PagoConcesion WHERE id = @id;
END;
GO
