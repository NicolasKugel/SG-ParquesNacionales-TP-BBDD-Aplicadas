/*******************************************************************************
Fecha: 24/06/2026
Integrantes: [Nicolás Kugel, Facundo Gargiulo, Valentin Martinez]
Descripción: Entrega 8 - Implementación de Cifrado Simétrico para Datos Sensibles.
             Crea Master Key, Certificado, Clave Simétrica y adapta la estructura 
             de Ventas.Visitante junto con su SP ABM Seguro.
*******************************************************************************/

USE TPBDG5;
GO

-- =============================================================================
-- 1. INFRAESTRUCTURA DE CIFRADO DE SQL SERVER
-- =============================================================================

-- Creamos la Clave Maestra de la Base de Datos con su contraseña (si no existe)
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Unlam_Super_Password_2026!';
END
GO

-- Creamos el Certificado de Seguridad protegido por la Master Key
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'CertificadoSeguridadTP')
BEGIN
    CREATE CERTIFICATE CertificadoSeguridadTP WITH SUBJECT = 'Proteccion de Datos Sensibles TPBDG5';
END
GO

-- Creamos la Clave Simétrica vinculada y protegida por el Certificado
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = 'ClaveSimetricaDNI')
BEGIN
    CREATE SYMMETRIC KEY ClaveSimetricaDNI
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE CertificadoSeguridadTP;
END
GO

-- =============================================================================
-- 2. MODIFICACIÓN DE TABLA Y ELIMINACIÓN DE RESTRICCIÓN UNIQUE
-- =============================================================================

-- Agregamos la columna varbinary para el DNI Cifrado (si no existe)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Ventas.Visitante') AND name = 'dni_cifrado')
BEGIN
    ALTER TABLE Ventas.Visitante ADD dni_cifrado VARBINARY(256) NULL;
END
GO

-- Buscamos el nombre dinámico de la Unique Key del DNI original y la eliminamos
-- para permitir que convivan múltiples filas ofuscadas con el texto '********'
DECLARE @ConstraintName NVARCHAR(200);
SELECT @ConstraintName = name 
FROM sys.key_constraints 
WHERE type = 'UQ' AND parent_object_id = OBJECT_ID('Ventas.Visitante');

IF @ConstraintName IS NOT NULL
BEGIN
    EXEC('ALTER TABLE Ventas.Visitante DROP CONSTRAINT ' + @ConstraintName);
END
GO

-- =============================================================================
-- 3. PROCESO ALMACENADO ABM SEGURO (Maneja el cifrado de forma transparente)
-- =============================================================================
IF OBJECT_ID('dbo.sp_ABM_Visitante_Seguro', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ABM_Visitante_Seguro;
GO

CREATE PROCEDURE sp_ABM_Visitante_Seguro
    @Accion   CHAR(1),
    @id       INT          = NULL,
    @nombre   VARCHAR(100) = NULL,
    @apellido VARCHAR(100) = NULL,
    @dni      VARCHAR(15)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Abrimos la clave para la sesión de ejecución del procedimiento
    OPEN SYMMETRIC KEY ClaveSimetricaDNI DECRYPTION BY CERTIFICATE CertificadoSeguridadTP;

    IF @Accion = 'I'
    BEGIN
        INSERT INTO Ventas.Visitante (nombre, apellido, dni, dni_cifrado) 
        VALUES (@nombre, @apellido, '********', EncryptByKey(Key_GUID('ClaveSimetricaDNI'), @dni));
    END
    ELSE IF @Accion = 'U'
    BEGIN
        UPDATE Ventas.Visitante 
        SET nombre = @nombre, 
            apellido = @apellido, 
            dni_cifrado = EncryptByKey(Key_GUID('ClaveSimetricaDNI'), @dni)
        WHERE id = @id;
    END
    ELSE IF @Accion = 'D'
    BEGIN
        DELETE FROM Ventas.Visitante WHERE id = @id;
    END

    -- Cerramos el canal criptográfico
    CLOSE SYMMETRIC KEY ClaveSimetricaDNI;
END;
GO

-- =============================================================================
-- 4. CIFRADO RETROACTIVO DE DATOS PREEXISTENTES
-- =============================================================================
OPEN SYMMETRIC KEY ClaveSimetricaDNI DECRYPTION BY CERTIFICATE CertificadoSeguridadTP;

-- Ciframos a los visitantes históricos que aún tengan la columna dni_cifrado como NULL
UPDATE Ventas.Visitante
SET dni_cifrado = EncryptByKey(Key_GUID('ClaveSimetricaDNI'), dni),
    dni = '********'
WHERE dni_cifrado IS NULL;

CLOSE SYMMETRIC KEY ClaveSimetricaDNI;
GO

-- =============================================================================
-- 5. VERIFICACIÓN Y DEMOSTRACIÓN DE DESENCRIPCIÓN (EVIDENCIA)
-- =============================================================================
PRINT '---------------------------------------------------------';
PRINT 'VISTA DE LA TABLA EN DISCO (DATOS OFUSCADOS Y EN BYTES)';
PRINT '---------------------------------------------------------';
SELECT id, nombre, apellido, dni AS DNI_En_Tabla, dni_cifrado FROM Ventas.Visitante;

PRINT '---------------------------------------------------------';
PRINT 'DESENCRIPCIÓN AL VUELO AUTORIZADA MEDIANTE LA LLAVE';
PRINT '---------------------------------------------------------';
OPEN SYMMETRIC KEY ClaveSimetricaDNI DECRYPTION BY CERTIFICATE CertificadoSeguridadTP;

SELECT 
    id, 
    nombre, 
    apellido, 
    CONVERT(VARCHAR(15), DECRYPTBYKEY(dni_cifrado)) AS DNI_Descifrado
FROM Ventas.Visitante;

CLOSE SYMMETRIC KEY ClaveSimetricaDNI;
GO