/*******************************************************************************
Fecha: 04/07/2026
Integrantes: [Nicolás Kugel, Facundo Gargiulo, Valentin Martinez]
Descripción: Entrega 8 - VERSIÓN UNIFICADA INTEGRAL (Cifrado y Ofuscación).
             Crea la infraestructura criptográfica y aplica el cifrado en todas
             las tablas del sistema (Ventas, Personal, Concesiones).
*******************************************************************************/

USE TPBDG5;
GO

-- =============================================================================
-- 1. INFRAESTRUCTURA DE CIFRADO DE SQL SERVER
-- =============================================================================

-- Creamos la Clave Maestra de la Base de Datos
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'mandioca';
END
GO

-- Creamos el Certificado de Seguridad
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'CertificadoSeguridadTP')
BEGIN
    CREATE CERTIFICATE CertificadoSeguridadTP WITH SUBJECT = 'Proteccion de Datos Sensibles TPBDG5';
END
GO

-- Usamos el nombre unificado del grupo: 'ClaveSimetricaDNI' para todo el parque
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = 'ClaveSimetricaDNI')
BEGIN
    CREATE SYMMETRIC KEY ClaveSimetricaDNI
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE CertificadoSeguridadTP;
END
GO


PRINT '=========================================================';
PRINT '2. MODIFICACIÓN DE ESTRUCTURAS DE TABLAS (ALTERS)';
PRINT '=========================================================';

-- Extensión de Ventas.Visitante (DNI)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Ventas.Visitante') AND name = 'dni_cifrado')
    ALTER TABLE Ventas.Visitante ADD dni_cifrado VARBINARY(256) NULL;

-- Removemos el UNIQUE viejo del DNI
DECLARE @UQ_Visitante NVARCHAR(200) = (SELECT name FROM sys.key_constraints WHERE type = 'UQ' AND parent_object_id = OBJECT_ID('Ventas.Visitante'));
IF @UQ_Visitante IS NOT NULL EXEC('ALTER TABLE Ventas.Visitante DROP CONSTRAINT ' + @UQ_Visitante);
GO

-- Volamos el CHECK viejo de la forma de pago
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Venta_FormaPago')
    ALTER TABLE Ventas.Venta DROP CONSTRAINT CK_Venta_FormaPago;
GO

-- Extensión de Ventas.Venta (Forma de Pago)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Ventas.Venta') AND name = 'forma_pago_cifrado')
    ALTER TABLE Ventas.Venta ADD forma_pago_cifrado VARBINARY(256) NULL;
GO

-- Extensión de Personal.GuardaParque (DNI)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Personal.GuardaParque') AND name = 'dni_cifrado')
    ALTER TABLE Personal.GuardaParque ADD dni_cifrado VARBINARY(256) NULL;

DECLARE @UQ_GuardaParque NVARCHAR(200) = (SELECT name FROM sys.key_constraints WHERE type = 'UQ' AND parent_object_id = OBJECT_ID('Personal.GuardaParque'));
IF @UQ_GuardaParque IS NOT NULL EXEC('ALTER TABLE Personal.GuardaParque DROP CONSTRAINT ' + @UQ_GuardaParque);
GO

-- Extensión de Personal.Guia (DNI)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Personal.Guia') AND name = 'dni_cifrado')
    ALTER TABLE Personal.Guia ADD dni_cifrado VARBINARY(256) NULL;

DECLARE @UQ_Guia NVARCHAR(200) = (SELECT name FROM sys.key_constraints WHERE type = 'UQ' AND parent_object_id = OBJECT_ID('Personal.Guia'));
IF @UQ_Guia IS NOT NULL EXEC('ALTER TABLE Personal.Guia DROP CONSTRAINT ' + @UQ_Guia);
GO

-- Extensión de Concesiones.Empresa (CUIT)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Concesiones.Empresa') AND name = 'cuit_cifrado')
    ALTER TABLE Concesiones.Empresa ADD cuit_cifrado VARBINARY(256) NULL;

DECLARE @UQ_Empresa NVARCHAR(200) = (SELECT name FROM sys.key_constraints WHERE type = 'UQ' AND parent_object_id = OBJECT_ID('Concesiones.Empresa'));
IF @UQ_Empresa IS NOT NULL EXEC('ALTER TABLE Concesiones.Empresa DROP CONSTRAINT ' + @UQ_Empresa);
GO

-- Extensión de Concesiones.Concesion (Canon Mensual)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Concesiones.Concesion') AND name = 'canon_cifrado')
    ALTER TABLE Concesiones.Concesion ADD canon_cifrado VARBINARY(256) NULL;
GO


PRINT '=========================================================';
PRINT '3. CIFRADO RETROACTIVO EN TABLAS';
PRINT '=========================================================';

OPEN SYMMETRIC KEY ClaveSimetricaDNI DECRYPTION BY CERTIFICATE CertificadoSeguridadTP;

-- Cifrado en Ventas
UPDATE Ventas.Visitante SET dni_cifrado = EncryptByKey(Key_GUID('ClaveSimetricaDNI'), dni), dni = '********' WHERE dni_cifrado IS NULL;
UPDATE Ventas.Venta SET forma_pago_cifrado = EncryptByKey(Key_GUID('ClaveSimetricaDNI'), forma_pago), forma_pago = 'CONFIDENCIAL' WHERE forma_pago_cifrado IS NULL;

-- Cifrado en Personal
UPDATE Personal.GuardaParque SET dni_cifrado = EncryptByKey(Key_GUID('ClaveSimetricaDNI'), dni), dni = '********' WHERE dni_cifrado IS NULL;
UPDATE Personal.Guia SET dni_cifrado = EncryptByKey(Key_GUID('ClaveSimetricaDNI'), dni), dni = '********' WHERE dni_cifrado IS NULL;

-- Cifrado en Concesiones
UPDATE Concesiones.Empresa SET cuit_cifrado = EncryptByKey(Key_GUID('ClaveSimetricaDNI'), cuit), cuit = '********' WHERE cuit_cifrado IS NULL;
UPDATE Concesiones.Concesion SET canon_cifrado = EncryptByKey(Key_GUID('ClaveSimetricaDNI'), CONVERT(VARCHAR(30), canon_mensual)), canon_mensual = 0.00 WHERE canon_cifrado IS NULL;

CLOSE SYMMETRIC KEY ClaveSimetricaDNI;
GO


PRINT '=========================================================';
PRINT '4. RE-COMPILACIÓN DE COMPONENTES DEL SISTEMA AFECTADOS';
PRINT '=========================================================';

-- Modificación del ABM de Visitante
IF OBJECT_ID('dbo.usp_ABM_Visitante_Seguro', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_ABM_Visitante_Seguro;
GO
CREATE PROCEDURE usp_ABM_Visitante_Seguro
    @Accion   CHAR(1),
    @id       INT          = NULL,
    @nombre   VARCHAR(100) = NULL,
    @apellido VARCHAR(100) = NULL,
    @dni      VARCHAR(15)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(MAX) = '';
    IF @Accion IN ('I', 'U') BEGIN
        IF ISNULL(@nombre, '') = '' OR ISNULL(@apellido, '') = '' SET @Errores = @Errores + 'ERROR: Nombre y Apellido son obligatorios.' + CHAR(13);
        IF LEN(ISNULL(@dni, '')) < 6 SET @Errores = @Errores + 'ERROR: DNI inválido.' + CHAR(13);
    END
    IF LEN(@Errores) > 0 BEGIN RAISERROR(@Errores, 16, 1); RETURN; END

    OPEN SYMMETRIC KEY ClaveSimetricaDNI DECRYPTION BY CERTIFICATE CertificadoSeguridadTP;

    IF @Accion = 'I'
        INSERT INTO Ventas.Visitante (nombre, apellido, dni, dni_cifrado) 
        VALUES (@nombre, @apellido, '********', EncryptByKey(Key_GUID('ClaveSimetricaDNI'), @dni));
    ELSE IF @Accion = 'U'
        UPDATE Ventas.Visitante 
        SET nombre = @nombre, apellido = @apellido, 
            dni_cifrado = EncryptByKey(Key_GUID('ClaveSimetricaDNI'), @dni) 
        WHERE id = @id;
    ELSE IF @Accion = 'D'
        DELETE FROM Ventas.Visitante WHERE id = @id;

    CLOSE SYMMETRIC KEY ClaveSimetricaDNI;
END;
GO

-- Modificación del SP Transaccional de Venta de Tickets
IF OBJECT_ID('dbo.sp_ProcesarVentaTicket', 'P') IS NOT NULL 
    DROP PROCEDURE dbo.sp_ProcesarVentaTicket;
GO

CREATE PROCEDURE sp_ProcesarVentaTicket
    @punto_venta       INT,
    @numero            INT,
    @forma_pago        VARCHAR(50),
    @visitante_id      INT,
    @tipo_visitante_id INT,
    @entrada_id        INT = NULL,
    @atraccion_id      INT = NULL,
    @cantidad          INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @forma_pago NOT IN ('Efectivo', 'Tarjeta de débito', 'Tarjeta de crédito', 'Transferencia')
        BEGIN
            RAISERROR('ERROR: La forma de pago debe ser Efectivo, Tarjeta de débito, Tarjeta de crédito o Transferencia.', 16, 1);
            RETURN;
        END

        BEGIN TRANSACTION;
        
        DECLARE @PrecioBase DECIMAL(18,2) = 0, @DescuentoPorcentaje INT = 0, @PrecioFinalUnitario DECIMAL(18,2) = 0;

        IF @entrada_id IS NOT NULL SELECT @PrecioBase = precio_entrada FROM Parques.Entrada WHERE id = @entrada_id;
        ELSE SELECT @PrecioBase = costo FROM Parques.Atraccion WHERE id = @atraccion_id;

        SELECT @DescuentoPorcentaje = descuento FROM Ventas.TipoVisitante WHERE id = @tipo_visitante_id;
        SET @PrecioFinalUnitario = @PrecioBase * (1.0 - (@DescuentoPorcentaje / 100.0));
        DECLARE @SubtotalCalculado DECIMAL(18,2) = @PrecioFinalUnitario * @cantidad;

        OPEN SYMMETRIC KEY ClaveSimetricaDNI DECRYPTION BY CERTIFICATE CertificadoSeguridadTP;

        INSERT INTO Ventas.Venta (punto_venta, numero, fecha, forma_pago, forma_pago_cifrado, total, visitante_id)
        VALUES (@punto_venta, @numero, GETDATE(), 'CONFIDENCIAL', EncryptByKey(Key_GUID('ClaveSimetricaDNI'), @forma_pago), @SubtotalCalculado, @visitante_id);

        DECLARE @NuevaVentaId INT = SCOPE_IDENTITY();
        INSERT INTO Ventas.LineaVenta (venta_id, tipo_visitante_id, entrada_id, atraccion_id, cantidad, precio_unitario, subtotal, fecha_acceso)
        VALUES (@NuevaVentaId, @tipo_visitante_id, @entrada_id, @atraccion_id, @cantidad, @PrecioFinalUnitario, @SubtotalCalculado, GETDATE());

        CLOSE SYMMETRIC KEY ClaveSimetricaDNI;
        COMMIT TRANSACTION;
        
        PRINT 'Venta cifrada procesada de forma exitosa.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO