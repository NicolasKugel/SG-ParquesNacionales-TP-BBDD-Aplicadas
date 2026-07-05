/*******************************************************************************
Fecha: 24/06/2026
Integrantes: [Nicolás Kugel, Facundo Gargiulo, Valentin Martinez]
Descripción: Batería de Pruebas Funcionales (Testing Unitario e Integración).
             Cubre flujos de éxito con evidencia y flujos erróneos de validación
             para todos los SPs definidos en ABM.sql y logicaNegocio.sql.
             Requiere haber ejecutado previamente:
               00-CreaBDySCHEMAS.sql → 01-CreaTablas.sql → ABM.sql → logicaNegocio.sql
*******************************************************************************/

USE TPBDG5;
GO

-- =============================================================================
-- ESCENARIO DE TESTING A: FLUJOS EXITOSOS (HAPPY PATH) CON EVIDENCIA DIRECTA
-- =============================================================================

-- 1. Insertar TipoVisitante
EXEC usp_ABM_TipoVisitante 'I', NULL, 'Residente Nacional', 50; -- 50% Bonificación

-- 2. Importar parque via Upsert
EXEC usp_ImportarDatosParqueUpsert
    @nombre        = 'Parque Nacional Iguazú',
    @Codigo        = 'PNI',
    @ubicacion     = 'Misiones',
    @superficie_ha = 67720.00,
    @tipo_parque   = 'PN';

-- 3. Alta de Entrada con fecha de vigencia
EXEC usp_ABM_Entrada 'I', NULL, 5000.00, 1, '2026-01-01';

-- 4. Alta de Visitante via SP
EXEC usp_ABM_Visitante 'I', NULL, 'Juan', 'Pérez', '35123456';

-- [EVIDENCIA 1]: Estado del Parque, Entrada y Visitante
SELECT * FROM Parques.Parque   WHERE nombre = 'Parque Nacional Iguazú';
SELECT * FROM Parques.Entrada  WHERE parque_id = 1;
SELECT * FROM Ventas.Visitante WHERE dni = '35123456';

-- 5. Procesar Venta Transaccional
EXEC usp_ProcesarVentaTicket
    @punto_venta = 10, @numero = 9991,
    @forma_pago = 'Tarjeta de débito', @visitante_id = 1,
    @tipo_visitante_id = 1, @entrada_id = 1, @atraccion_id = NULL, @cantidad = 2;

-- [EVIDENCIA 2]: Venta e impacto financiero
SELECT * FROM Ventas.Venta;
SELECT * FROM Ventas.LineaVenta;
GO


-- =============================================================================
-- ESCENARIO DE TESTING B: COMPORTAMIENTO ANTE VALIDACIONES NO CUMPLIDAS
-- =============================================================================

PRINT '---------------------------------------------------------';
PRINT 'TEST DE ERROR 1: Violación unificada de Parque';
PRINT '---------------------------------------------------------';
BEGIN TRY
    EXEC usp_ABM_Parque
        @Accion = 'I', @Codigo = '', @nombre = '',
        @ubicacion = 'Destino Prueba', @superficie_ha = 0.00, @tipo_parque = 'RE';
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST DE ERROR 2: Asignación de Guía Inexistente a una Atracción';
PRINT '---------------------------------------------------------';

EXEC usp_ABM_Guia 'I', NULL, 'Carlos', 'Gómez', '22987654', 'Lic. Biología', 'Provincial', 'Aves';

EXEC usp_ABM_Atraccion 'I', NULL, 'Garganta del Diablo', 'Paseo en pasarelas superiores',
    '02:00:00', 50, 1500.00, 1;

BEGIN TRY
    EXEC usp_AsignarGuiaAtraccion
        @atraccion_id = 1, @guia_id = 9999,
        @fecha_asignacion = '2026-06-22', @turno = 'Mañana';
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;
GO


-- =============================================================================
-- ESCENARIO DE TESTING C: GUARDAPARQUE Y ASIGNACION
-- =============================================================================

PRINT '---------------------------------------------------------';
PRINT 'TEST C-01 (ÉXITO): Alta de GuardaParque activo';
PRINT '---------------------------------------------------------';

EXEC usp_ABM_GuardaParque 'I', NULL, 'Roberto', 'Cáceres', '28765432', 1;

SELECT id, nombre, apellido, dni, estado FROM Personal.GuardaParque WHERE dni = '28765432';
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST C-02 (ÉXITO): Baja lógica del guardaparque (estado = 0)';
PRINT '---------------------------------------------------------';

DECLARE @idGP INT = (SELECT id FROM Personal.GuardaParque WHERE dni = '28765432');
EXEC usp_ABM_GuardaParque 'U', @idGP, 'Roberto', 'Cáceres', '28765432', 0;

SELECT id, nombre, estado FROM Personal.GuardaParque WHERE dni = '28765432';
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST C-03 (ERROR): Nombre vacío, DNI corto, estado inválido';
PRINT '---------------------------------------------------------';
BEGIN TRY
    EXEC usp_ABM_GuardaParque 'I', NULL, '', '', '123', 9;
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST C-04 (ERROR): DNI duplicado en GuardaParque';
PRINT '---------------------------------------------------------';
BEGIN TRY
    EXEC usp_ABM_GuardaParque 'I', NULL, 'Ana', 'Ríos', '28765432', 1;
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST C-05 (ÉXITO): Asignación activa de guardaparque al parque';
PRINT '---------------------------------------------------------';

DECLARE @idGP INT = (SELECT id FROM Personal.GuardaParque WHERE dni = '28765432');
EXEC usp_ABM_AsignacionGuardaParque 'I', NULL, '2026-01-15', NULL, NULL, @idGP, 1;

SELECT a.id, g.nombre, a.fecha_inicio, a.fecha_fin, a.motivo_egreso
FROM Personal.AsignacionGuardaParque a
INNER JOIN Personal.GuardaParque g ON g.id = a.guarda_parque_id
WHERE a.guarda_parque_id = @idGP;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST C-06 (ÉXITO): Cierre de asignación con fecha y motivo';
PRINT '---------------------------------------------------------';

DECLARE @idGP   INT = (SELECT id FROM Personal.GuardaParque WHERE dni = '28765432');
DECLARE @idAsig INT = (SELECT TOP 1 id FROM Personal.AsignacionGuardaParque
                       WHERE guarda_parque_id = @idGP ORDER BY id DESC);
EXEC usp_ABM_AsignacionGuardaParque 'U', @idAsig, '2026-01-15', '2026-06-20',
    'Traslado a otra unidad', @idGP, 1;

SELECT id, fecha_inicio, fecha_fin, motivo_egreso
FROM Personal.AsignacionGuardaParque WHERE id = @idAsig;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST C-07 (ERROR): Guardaparque/parque inexistente + fecha fin anterior a inicio';
PRINT '---------------------------------------------------------';
BEGIN TRY
    EXEC usp_ABM_AsignacionGuardaParque 'I', NULL, '2026-06-01', '2026-05-01',
        NULL, 9999, 9999;
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;
GO


-- =============================================================================
-- ESCENARIO DE TESTING D: ATRACCION
-- =============================================================================

PRINT '---------------------------------------------------------';
PRINT 'TEST D-01 (ÉXITO): Alta de Atraccion en parque existente';
PRINT '---------------------------------------------------------';

EXEC usp_ABM_Atraccion 'I', NULL, 'Senda Macuco',
    'Caminata guiada en selva paranaense', '03:00:00', 30, 2500.00, 1;

SELECT id, nombre, cupo_maximo, costo, parque_id
FROM Parques.Atraccion WHERE nombre = 'Senda Macuco';
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST D-02 (ÉXITO): Ajuste de precio de Atraccion';
PRINT '---------------------------------------------------------';

DECLARE @idATR INT = (SELECT id FROM Parques.Atraccion WHERE nombre = 'Senda Macuco');
EXEC usp_ABM_Atraccion 'U', @idATR, 'Senda Macuco',
    'Caminata guiada en selva paranaense', '03:00:00', 30, 3000.00, 1;

SELECT id, nombre, costo FROM Parques.Atraccion WHERE nombre = 'Senda Macuco';
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST D-03 (ERROR): Nombre vacío, cupo 0, costo negativo, parque inexistente';
PRINT '---------------------------------------------------------';
BEGIN TRY
    EXEC usp_ABM_Atraccion 'I', NULL, '', NULL, '01:00:00', 0, -200.00, 9999;
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;
GO


-- =============================================================================
-- ESCENARIO DE TESTING E: VISITANTE
-- =============================================================================

PRINT '---------------------------------------------------------';
PRINT 'TEST E-01 (ÉXITO): Alta de Visitante';
PRINT '---------------------------------------------------------';

EXEC usp_ABM_Visitante 'I', NULL, 'María', 'González', '41987654';

SELECT id, nombre, apellido, dni FROM Ventas.Visitante WHERE dni = '41987654';
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST E-02 (ÉXITO): Modificación de nombre de Visitante';
PRINT '---------------------------------------------------------';

DECLARE @idVIS INT = (SELECT id FROM Ventas.Visitante WHERE dni = '41987654');
EXEC usp_ABM_Visitante 'U', @idVIS, 'María Laura', 'González', '41987654';

SELECT id, nombre, apellido FROM Ventas.Visitante WHERE dni = '41987654';
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST E-03 (ERROR): Nombre vacío y DNI corto';
PRINT '---------------------------------------------------------';
BEGIN TRY
    EXEC usp_ABM_Visitante 'I', NULL, '', '', '12';
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST E-04 (ERROR): DNI duplicado en Visitante';
PRINT '---------------------------------------------------------';
BEGIN TRY
    EXEC usp_ABM_Visitante 'I', NULL, 'Pedro', 'Sosa', '41987654';
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;
GO


-- =============================================================================
-- ESCENARIO DE TESTING F: ATRACCION GUIA (Update / Delete)
-- =============================================================================

PRINT '---------------------------------------------------------';
PRINT 'TEST F-00 (SETUP): Crear atracción nueva y asignar guía';
PRINT '---------------------------------------------------------';

EXEC usp_ABM_Atraccion 'I', NULL, 'Tour Nocturno de Fauna',
    'Avistamiento nocturno de fauna silvestre', '02:00:00', 15, 3500.00, 1;

DECLARE @idAtrF INT = (SELECT id FROM Parques.Atraccion WHERE nombre = 'Tour Nocturno de Fauna');
DECLARE @idG1   INT = (SELECT TOP 1 id FROM Personal.Guia ORDER BY id);

EXEC usp_AsignarGuiaAtraccion
    @atraccion_id = @idAtrF, @guia_id = @idG1,
    @fecha_asignacion = '2026-07-01', @turno = 'Noche';

SELECT ag.id, g.nombre AS guia, a.nombre AS atraccion, ag.turno
FROM Personal.AtraccionGuia ag
INNER JOIN Personal.Guia     g ON g.id = ag.guia_id
INNER JOIN Parques.Atraccion a ON a.id = ag.atraccion_id
WHERE a.nombre = 'Tour Nocturno de Fauna';
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST F-01 (ÉXITO): Actualización de turno de AtraccionGuia';
PRINT '---------------------------------------------------------';

DECLARE @idAtrF INT = (SELECT id FROM Parques.Atraccion WHERE nombre = 'Tour Nocturno de Fauna');
DECLARE @idG1   INT = (SELECT TOP 1 id FROM Personal.Guia ORDER BY id);
DECLARE @idAG   INT = (SELECT TOP 1 id FROM Personal.AtraccionGuia
                       WHERE atraccion_id = @idAtrF ORDER BY id DESC);

EXEC usp_ABM_AtraccionGuia 'U', @idAG, '2026-07-01', 'Tarde', @idAtrF, @idG1;

SELECT id, turno FROM Personal.AtraccionGuia WHERE id = @idAG;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST F-02 (ERROR): id inexistente, turno vacío, referencias inválidas';
PRINT '---------------------------------------------------------';
BEGIN TRY
    EXEC usp_ABM_AtraccionGuia 'U', 9999, '2026-07-01', '', 9999, 9999;
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST F-03 (ÉXITO): Baja de asignación guía-atracción';
PRINT '---------------------------------------------------------';

DECLARE @idAtrF INT = (SELECT id FROM Parques.Atraccion WHERE nombre = 'Tour Nocturno de Fauna');
DECLARE @idAG   INT = (SELECT TOP 1 id FROM Personal.AtraccionGuia
                       WHERE atraccion_id = @idAtrF ORDER BY id DESC);

EXEC usp_ABM_AtraccionGuia 'D', @idAG;

SELECT COUNT(*) AS debe_ser_cero FROM Personal.AtraccionGuia WHERE id = @idAG;
GO


-- =============================================================================
-- ESCENARIO DE TESTING G: PAGO CONCESION (Update / Delete)
-- =============================================================================

PRINT '---------------------------------------------------------';
PRINT 'TEST G-00 (SETUP): Empresa, Concesión y pago parcial';
PRINT '---------------------------------------------------------';

EXEC usp_ABM_Empresa 'I', NULL, 'Concesiones del Sur S.A.', '30-12345678-9', 'Gastronomía';
EXEC usp_ABM_Concesion 'I', NULL, '2026-01-01', '2027-01-01', 100000.00, 1, 1;
EXEC usp_RegistrarPagoConcesion 1, '2026-02-05', '2026-01-01', 60000.00; -- queda Atrasado
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST G-01 (ÉXITO): Corrección de estado y monto del pago';
PRINT '---------------------------------------------------------';

-- [EVIDENCIA antes]: estado Atrasado
SELECT id, estado, total FROM Concesiones.PagoConcesion WHERE concesion_id = 1;

DECLARE @idPago INT = (SELECT TOP 1 id FROM Concesiones.PagoConcesion
                       WHERE concesion_id = 1 ORDER BY id);
EXEC usp_ABM_PagoConcesion 'U', @idPago, '2026-02-10', '2026-01-01', 'Pagado', 100000.00, 1;

-- [EVIDENCIA después]: estado Pagado, total 100000
SELECT id, estado, total, fecha_pago FROM Concesiones.PagoConcesion WHERE id = @idPago;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST G-02 (ERROR): Estado inválido, monto negativo, id/concesion inexistente';
PRINT '---------------------------------------------------------';
BEGIN TRY
    EXEC usp_ABM_PagoConcesion 'U', 9999, '2026-03-01', '2026-02-01', 'Rechazado', -500.00, 9999;
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;
GO

PRINT '---------------------------------------------------------';
PRINT 'TEST G-03 (ERROR): Baja de pago inexistente';
PRINT '---------------------------------------------------------';
BEGIN TRY
    EXEC usp_ABM_PagoConcesion 'D', 9999;
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;
GO
