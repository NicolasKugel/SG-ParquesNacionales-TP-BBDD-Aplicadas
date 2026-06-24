/*******************************************************************************
Fecha: 22/06/2026
Integrantes: [Nicolás Kugel, Facundo Gargiulo, Valentin Martinez]
Descripción: Procedimientos Complejos de Lógica de Negocio.
             Transacciones para Ventas, Guías, Concesiones e Importación Upsert.
*******************************************************************************/

USE TPBDG5;
GO

-- ==========================================
-- LÓGICA 1: REGISTRACIÓN DE VENTA DE ENTRADAS COMPLETA
-- ==========================================
CREATE OR ALTER PROCEDURE sp_ProcesarVentaTicket
    @punto_venta       INT,
    @numero            INT,
    @forma_pago        VARCHAR(255),
    @visitante_id      INT,
    @tipo_visitante_id INT,
    @entrada_id        INT = NULL,
    @atraccion_id      INT = NULL,
    @cantidad          INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @PrecioBase          DECIMAL(18,2) = 0;
        DECLARE @DescuentoPorcentaje INT           = 0;
        DECLARE @PrecioFinalUnitario DECIMAL(18,2) = 0;

        IF @entrada_id IS NOT NULL
            SELECT @PrecioBase = precio_entrada FROM Parques.Entrada WHERE id = @entrada_id;
        ELSE
            SELECT @PrecioBase = costo FROM Parques.Atraccion WHERE id = @atraccion_id;

        SELECT @DescuentoPorcentaje = descuento FROM Ventas.TipoVisitante WHERE id = @tipo_visitante_id;

        SET @PrecioFinalUnitario = @PrecioBase * (1.0 - (@DescuentoPorcentaje / 100.0));
        DECLARE @SubtotalCalculado DECIMAL(18,2) = @PrecioFinalUnitario * @cantidad;

        INSERT INTO Ventas.Venta (punto_venta, numero, fecha, forma_pago, total, visitante_id)
        VALUES (@punto_venta, @numero, GETDATE(), @forma_pago, @SubtotalCalculado, @visitante_id);

        DECLARE @NuevaVentaId INT = SCOPE_IDENTITY();

        INSERT INTO Ventas.LineaVenta (venta_id, tipo_visitante_id, entrada_id, atraccion_id, cantidad, precio_unitario, subtotal, fecha_acceso)
        VALUES (@NuevaVentaId, @tipo_visitante_id, @entrada_id, @atraccion_id, @cantidad, @PrecioFinalUnitario, @SubtotalCalculado, GETDATE());

        COMMIT TRANSACTION;
        PRINT 'Operación de venta procesada de forma exitosa.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH
END;
GO

-- ==========================================
-- LÓGICA 2: ASIGNACIÓN DE GUÍAS A ATRACCIONES
-- ==========================================
CREATE OR ALTER PROCEDURE sp_AsignarGuiaAtraccion
    @atraccion_id     INT,
    @guia_id          INT,
    @fecha_asignacion DATE,
    @turno            VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Personal.Guia WHERE id = @guia_id)
    BEGIN
        RAISERROR('ERROR: El guía indicado no existe en los registros del sistema.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Parques.Atraccion WHERE id = @atraccion_id)
    BEGIN
        RAISERROR('ERROR: La atracción indicada no existe en los registros del sistema.', 16, 1);
        RETURN;
    END

    INSERT INTO Personal.AtraccionGuia (atraccion_id, guia_id, fecha_asignacion, turno)
    VALUES (@atraccion_id, @guia_id, @fecha_asignacion, @turno);
    PRINT 'Guía asignado exitosamente al tour/atracción.';
END;
GO

-- ==========================================
-- LÓGICA 3: CONTROL Y PAGO DE CONCESIONES
-- ==========================================
CREATE OR ALTER PROCEDURE sp_RegistrarPagoConcesion
    @concesion_id  INT,
    @fecha_pago    DATE,
    @periodo       DATE,
    @monto_abonado DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CanonPautado DECIMAL(18,2);
        SELECT @CanonPautado = canon_mensual FROM Concesiones.Concesion WHERE id = @concesion_id;

        DECLARE @EstadoPago VARCHAR(50) = 'Pagado';
        IF @monto_abonado < @CanonPautado SET @EstadoPago = 'Atrasado';

        INSERT INTO Concesiones.PagoConcesion (fecha_pago, periodo, estado, total, concesion_id)
        VALUES (@fecha_pago, @periodo, @EstadoPago, @monto_abonado, @concesion_id);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ==========================================
-- LÓGICA 4: IMPORTACIÓN DE PARQUES DESDE ARCHIVOS EXTERNOS (UPSERT)
-- ==========================================
CREATE OR ALTER PROCEDURE sp_ImportarDatosParqueUpsert
    @nombre        VARCHAR(255),
    @Codigo        VARCHAR(20),
    @ubicacion     VARCHAR(255),
    @superficie_ha DECIMAL(12,2),
    @tipo_parque   CHAR(2)
AS
BEGIN
    SET NOCOUNT ON;

    MERGE Parques.Parque AS Target
    USING (SELECT @nombre AS nombre) AS Source
    ON (Target.nombre = Source.nombre)

    WHEN MATCHED THEN
        UPDATE SET
            Codigo        = @Codigo,
            ubicacion     = @ubicacion,
            superficie_ha = @superficie_ha,
            tipo_parque   = @tipo_parque

    WHEN NOT MATCHED THEN
        INSERT (Codigo, nombre, ubicacion, superficie_ha, tipo_parque)
        VALUES (@Codigo, Source.nombre, @ubicacion, @superficie_ha, @tipo_parque);

    PRINT 'Proceso de Upsert de datos públicos de parques ejecutado.';
END;
GO
