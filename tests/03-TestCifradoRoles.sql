/*******************************************************************************
Fecha: 24/06/2026
Integrantes: [Nicolás Kugel, Facundo Gargiulo, Valentin Martinez]
Descripción: Script de Testing 1:1 para la Entrega 8 (Seguridad y Cifrado).
             Prueba el comportamiento del enmascaramiento, la denegación de llaves
             y el acceso seguro mediante Stored Procedures.
*******************************************************************************/

USE TPBDG5;
GO

-- Creamos dos usuarios de prueba sin login para simular los roles en el test
IF DATABASE_PRINCIPAL_ID('User_Admin_Test') IS NULL
    CREATE USER User_Admin_Test WITHOUT LOGIN;

IF DATABASE_PRINCIPAL_ID('User_Consultas_Test') IS NULL
    CREATE USER User_Consultas_Test WITHOUT LOGIN;
GO

-- Los asignamos a sus respectivos roles corporativos
ALTER ROLE Rol_DBA ADD MEMBER User_Admin_Test;
ALTER ROLE Rol_Consultas ADD MEMBER User_Consultas_Test;
GO

USE TPBDG5;
GO

PRINT '=========================================================';
PRINT 'ESCENARIO 1: EJECUCIÓN CON PRIVILEGIOS DE ADMINISTRADOR (DBA)';
PRINT '=========================================================';

-- Suplantamos la identidad del usuario Administrador
EXECUTE AS USER = 'User_Admin_Test';
PRINT '--> Identidad actual: ' + USER_NAME();
GO

-- 1. El Admin puede abrir la clave simétrica unificada y ver los DNI reales sin problemas
OPEN SYMMETRIC KEY ClaveSimetricaDNI DECRYPTION BY CERTIFICATE CertificadoSeguridadTP;

PRINT '--> [ÉXITO] El Administrador consulta los DNI reales desencriptados al vuelo:';
SELECT 
    id, 
    nombre, 
    apellido, 
    CONVERT(VARCHAR(15), DECRYPTBYKEY(dni_cifrado)) AS DNI_Real_Descifrado
FROM Ventas.Visitante;

CLOSE SYMMETRIC KEY ClaveSimetricaDNI;
GO

-- Volvemos al contexto original del script
REVERT;
GO


PRINT '=========================================================';
PRINT 'ESCENARIO 2: EJECUCIÓN CON PRIVILEGIOS DE CONSULTAS (RESTRICCIÓN)';
PRINT '=========================================================';

-- Suplantamos la identidad del usuario de Consultas / PowerBI
EXECUTE AS USER = 'User_Consultas_Test';
PRINT '--> Identidad actual: ' + USER_NAME();
GO

-- 1. Intentamos leer la tabla de visitantes directamente
PRINT '--> [EVIDENCIA 1] El Consultor hace SELECT directo. Solo ve los asteriscos de la máscara:';
SELECT id, nombre, apellido, dni AS DNI_En_Tabla FROM Ventas.Visitante;

-- 2. Intentamos leer la tabla de concesiones directamente
PRINT '--> [EVIDENCIA 2] El Consultor hace SELECT directo a Concesiones. El canon figura en cero (ofuscado):';
SELECT id, fecha_inicio, canon_mensual AS Canon_Ofuscado FROM Concesiones.Concesion;

-- 3. PRUEBA DE VIOLACIÓN DE SEGURIDAD: El Consultor intenta abrir la clave criptográfica a la fuerza
PRINT '--> [EVIDENCIA 3] Intentando forzar la apertura de la Clave Simétrica (Debe fallar por permisos)...';
BEGIN TRY
    OPEN SYMMETRIC KEY ClaveSimetricaDNI DECRYPTION BY CERTIFICATE CertificadoSeguridadTP;
    
    -- Si por algún error entrara, intentamos leer
    SELECT CONVERT(VARCHAR(15), DECRYPTBYKEY(dni_cifrado)) FROM Ventas.Visitante;
    
    CLOSE SYMMETRIC KEY ClaveSimetricaDNI;
END TRY
BEGIN CATCH
    PRINT '!!! BLOQUEO EXITOSO: SQL Server denegó el acceso a la infraestructura criptográfica.';
    PRINT 'Mensaje capturado: ' + ERROR_MESSAGE();
END CATCH
GO

-- 4. ACCESO CONTROLADO POR NEGOCIO: El consultor ejecuta el SP de reportes autorizado por el DBA
PRINT '--> [EVIDENCIA 4] El Consultor ejecuta el SP de reportes gerencial autorizado. Puede ver los cánones reales:';
BEGIN TRY
    EXEC dbo.usp_Reporte_Canones_Directivos;
END TRY
BEGIN CATCH
    PRINT 'Error inesperado al ejecutar el reporte: ' + ERROR_MESSAGE();
END CATCH
GO

-- Volvemos al contexto original y cerramos las pruebas
REVERT;
PRINT '--> Script de testing finalizado. Identidad restaurada a: ' + USER_NAME();
GO