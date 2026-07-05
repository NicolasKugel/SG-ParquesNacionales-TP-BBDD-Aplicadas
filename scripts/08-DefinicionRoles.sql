/*******************************************************************************
Fecha: 24/06/2026
Integrantes: [Nicolás Kugel, Facundo Gargiulo, Valentin Martinez]
Descripción: Entrega 8 - Implementación de Roles Organizacionales Reales.
             Crea perfiles para DBA, Desarrolladores, Aplicación Operativa y Consultas.
*******************************************************************************/

USE TPBDG5;
GO

PRINT '=========================================================';
PRINT '1. CREACIÓN DE ROLES PROFESIONALES';
PRINT '=========================================================';

-- 1. El Administrador (Infraestructura y Seguridad)
IF DATABASE_PRINCIPAL_ID('Rol_DBA') IS NULL CREATE ROLE Rol_DBA;

-- 2. El Desarrollador (Crea código, tablas y SPs)
IF DATABASE_PRINCIPAL_ID('Rol_DB_Developer') IS NULL CREATE ROLE Rol_DB_Developer;

-- 3. La Aplicación/Operador (El software que ejecuta las ventas y ABMs)
IF DATABASE_PRINCIPAL_ID('Rol_Aplicacion_Boleteria') IS NULL CREATE ROLE Rol_Aplicacion_Boleteria;

-- 4. El Consultor (Personal analítico o PowerBI)
IF DATABASE_PRINCIPAL_ID('Rol_Consultas') IS NULL CREATE ROLE Rol_Consultas;
GO


PRINT '=========================================================';
PRINT '2. ASIGNACIÓN DE PERMISOS GRANULARES';
PRINT '=========================================================';

-- PERMISOS: ROL DBA
GRANT CONTROL TO Rol_DBA;
GRANT CONTROL ON CERTIFICATE::CertificadoSeguridadTP TO Rol_DBA; -- Custodio de la llave

-- PERMISOS: ROL DB DEVELOPER
GRANT ALTER, CREATE TABLE, CREATE PROCEDURE, VIEW DEFINITION TO Rol_DB_Developer;
GRANT SELECT, INSERT, UPDATE, DELETE TO Rol_DB_Developer; -- Permiso para probar datos en desarrollo

-- PERMISOS: ROL APLICACIÓN BOLETERÍA (La clave de la abstracción)
-- No le damos SELECT ni INSERT directo a ninguna tabla.
-- Le damos permiso estricto de EJECUCIÓN sobre la capa de procedimientos.
GRANT EXECUTE TO Rol_Aplicacion_Boleteria; 
-- Al darle GRANT EXECUTE general, la app puede correr los ABM y la Lógica de negocio,
-- pero sus usuarios jamás podrán tocar las tablas por fuera del sistema.

-- PERMISOS: ROL CONSULTAS
GRANT SELECT ON SCHEMA::Ventas TO Rol_Consultas;
GRANT SELECT ON SCHEMA::Parques TO Rol_Consultas;
GRANT SELECT ON SCHEMA::Concesiones TO Rol_Consultas;
GRANT SELECT ON SCHEMA::Personal TO Rol_Consultas;
-- Le bloqueamos explícitamente el acceso al certificado para que no puedan ver DNI reales
DENY CONTROL ON CERTIFICATE::CertificadoSeguridadTP TO Rol_Consultas;
GO

PRINT 'Matriz corporativa de roles y permisos granulares aplicada.';
GO

-- ==========================================
-- COMPONENTE DE AUDITORÍA: CONSULTA DE CÁNONES REALES
-- ==========================================
IF OBJECT_ID('dbo.usp_Reporte_Canones_Directivos', 'P') IS NOT NULL 
    DROP PROCEDURE dbo.usp_Reporte_Canones_Directivos;
GO

CREATE PROCEDURE usp_Reporte_Canones_Directivos
AS
BEGIN
    SET NOCOUNT ON;

    -- Abrimos la clave unificada para procesar la información en la memoria del servidor
    OPEN SYMMETRIC KEY ClaveSimetricaDNI DECRYPTION BY CERTIFICATE CertificadoSeguridadTP;

    SELECT 
        C.id AS Concesion_ID,
        E.razon_social AS Empresa,
        P.nombre AS Parque,
        C.fecha_inicio AS Inicio_Contrato,
        C.fecha_fin AS Fin_Contrato,
        -- Desencriptamos los bytes, los pasamos a texto y finalmente al formato numérico DECIMAL
        CONVERT(DECIMAL(18,2), CONVERT(VARCHAR(30), DECRYPTBYKEY(C.canon_cifrado))) AS Canon_Mensual_Real
    FROM Concesiones.Concesion C
    INNER JOIN Concesiones.Empresa E ON C.empresa_id = E.id
    INNER JOIN Parques.Parque P ON C.parque_id = P.id;

    -- Cerramos inmediatamente el canal criptográfico
    CLOSE SYMMETRIC KEY ClaveSimetricaDNI;
END;
GO

-- ==========================================
-- ASIGNACIÓN DE PRIVILEGIO AL ROL DE CONSULTAS
-- ==========================================
-- Autorizamos al rol gerencial a ejecutar EXCLUSIVAMENTE este reporte comercial descifrado
GRANT EXECUTE ON dbo.usp_Reporte_Canones_Directivos TO Rol_Consultas;
GO