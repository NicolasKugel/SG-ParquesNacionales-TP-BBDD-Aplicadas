/*******************************************************************************
Fecha: 22/06/2026
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

-- 2. Ejecutar Upsert de Importación Externa para dar de alta parques oficiales públicos
EXEC sp_ImportarDatosParqueUpsert 'Parque Nacional Iguazú', 'Misiones', 5000.00, 67720.00, 'PN';

EXEC sp_ABM_Entrada 'I', NULL, 5000.00, 1;

-- 3. Cargar un Visitante apto para el negocio
INSERT INTO Visitante (nombre, apellido, dni)
VALUES ('Juan', 'Pérez', '35123456');

-- [EVIDENCIA 1]: Verificar el estado actual del Parque y el Visitante insertados
SELECT * FROM Parque WHERE nombre = 'Parque Nacional Iguazú';
SELECT * FROM Entrada WHERE parque_id = 1;
SELECT * FROM Visitante WHERE dni = '35123456';

-- 4. Ejecutar el Proceso Complejo Transaccional de Venta de Entradas
EXEC sp_ProcesarVentaTicket
    @punto_venta = 10, @numero = 9991,
    @forma_pago = 'Tarjeta de Débito', @visitante_id = 1,
    @tipo_visitante_id = 1, @entrada_id = 1, @atraccion_id = NULL, @cantidad = 2;

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
PRINT 'TEST DE ERROR 2: Asignación de Guía Inexistente a una Atracción';
PRINT '---------------------------------------------------------';

INSERT INTO Guia (nombre, apellido, dni, titulo, tipo_habilitacion, especialidad)
VALUES ('Carlos', 'Gómez', '22987654', 'Lic. Biología', 'Provincial', 'Aves');

-- Insertamos una atracción de prueba vinculada al parque creado en el escenario A
INSERT INTO Atraccion (parque_id, nombre, descripcion, duracion, cupo_maximo, costo)
VALUES (1, 'Garganta del Diablo', 'Paseo en pasarelas superiores', '02:00:00', 50, 1500.00);

BEGIN TRY
    EXEC sp_AsignarGuiaAtraccion
        @atraccion_id = 1,
        @guia_id = 9999,
        @fecha_asignacion = '2026-06-22',
        @turno = 'Mañana';
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;
GO
