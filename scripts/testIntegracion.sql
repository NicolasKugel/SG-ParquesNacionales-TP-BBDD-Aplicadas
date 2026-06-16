/*******************************************************************************
Fecha: 15/06/2026
Integrantes: [Nicolás Kugel, Facundo Gargiulo, Valentin Martinez]
Descripción: Script 4/4 - Batería de Pruebas Funcionales (Testing Unitario e Integración).
             Cubre flujos de éxito con evidencia y flujos erróneos de validación.
*******************************************************************************/

USE TPBDG5;
GO

-- =============================================================================
-- ESCENARIO DE TESTING A: FLUJOS EXITOSOS (HAPPY PATH) CON EVIDENCIA DIRECTA
-- =============================================================================

-- 1. Insertar Datos Maestros Iniciales mediante SPs parametrizados
EXEC sp_ABM_TipoVisitante 'I', NULL, 'Residente Nacional', 50; -- 50% Bonificación
EXEC sp_ABM_Moneda 'I', NULL, 'Peso Argentino', 'ARS', 1.0000;

-- 2. Ejecutar Upsert de Importación Externa para dar de alta parques oficiales públicos
EXEC sp_ImportarDatosParqueUpsert 'P-NAL-001', 'Parque Nacional Iguazú', 'Misiones', 5000.00, 67720.00, 'PN';

-- 3. Cargar un Visitante apto para el negocio
INSERT INTO Visitante (tipo_visitante_id, nombre, apellido, dni)
VALUES (1, 'Juan', 'Pérez', '35123456');

-- [EVIDENCIA 1]: Verificar el estado actual del Parque y el Visitante insertados
SELECT * FROM Parque WHERE codigo_oficial = 'P-NAL-001';
SELECT * FROM Visitante WHERE dni = '35123456';

-- 4. Ejecutar el Proceso Complejo Transaccional de Venta de Entradas
-- Compra 2 entradas generales para el parque ID 1 (Iguazú), usando moneda 1
EXEC sp_ProcesarVentaTicket
    @moneda_id = 1, @punto_venta = 10, @numero = 9991,
    @forma_pago = 'Tarjeta de Débito', @visitante_id = 1,
    @parque_id = 1, @atraccion_id = NULL, @cantidad = 2;

-- [EVIDENCIA 2]: Comprobación del impacto financiero integrado de la transacción
SELECT * FROM Venta;
SELECT * FROM LineaVenta;
GO


-- =============================================================================
-- ESCENARIO DE TESTING B: COMPORTAMIENTO ANTE VALIDACIONES NO CUMPLIDAS
-- =============================================================================

PRINT '---------------------------------------------------------';
PRINT 'TEST DE ERROR 1: Violación unificada de Parque (Precio Negativo y Superficie Cero)';
PRINT '---------------------------------------------------------';
BEGIN TRY
    -- Se fuerzan parámetros inválidos para detonar las validaciones acumuladas 1 y 2
    EXEC sp_ABM_Parque
        @Accion = 'I',
        @codigo_oficial = 'ERR-01',
        @nombre = '', -- Detonará error de campo obligatorio
        @ubicacion = 'Destino Prueba',
        @precio_entrada = -150.00, -- Detonará error de precio
        @superficie_ha = 0.00,     -- Detonará error de hectáreas
        @tipo_parque = 'RE';
END TRY
BEGIN CATCH
    -- El bloque catch captura el mensaje consolidado de la excepción
    PRINT ERROR_MESSAGE();
END CATCH;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST DE ERROR 2: Asignación de Guía con Credencial Habilitante Vencida';
PRINT '---------------------------------------------------------';

-- Insertamos un guía cuya autorización expiró en el pasado
INSERT INTO Guia (nombre, apellido, dni, titulo, tipo_habilitacion, especialidad, fecha_vigencia)
VALUES ('Carlos', 'Gómez', '22987654', 'Lic. Biología', 'Provincial', 'Aves', '2025-01-01');

-- Insertamos una atracción de prueba vinculada al parque creado en el escenario A
INSERT INTO Atraccion (parque_id, nombre, descripcion, duracion, cupo_maximo, costo)
VALUES (1, 'Garganta del Diablo', 'Paseo en pasarelas superiores', 120, 50, 1500.00);

BEGIN TRY
    -- Intentamos agendar al guía en una fecha del año 2026 (cuando su vigencia ya expiró en 2025)
    EXEC sp_AsignarGuiaAtraccion
        @atraccion_id = 1,
        @guia_id = 1,
        @fecha_asignacion = '2026-06-15',
        @turno = 'Mañana';
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;
GO
