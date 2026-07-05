/*******************************************************************************
Fecha: 22/06/2026
Integrantes: [Nicolás Kugel, Facundo Gargiulo, Valentin Martinez]
Descripción: Entrega 7 - Pruebas de ejecución de los 5 reportes sobre los datos
             de ejemplo cargados por testIntegracion.sql.
             Requiere haber corrido antes, en orden: TABLAS.sql, ABM.sql,
             logicaNegocio.sql, testIntegracion.sql.
*******************************************************************************/

USE TPBDG5;
GO

-- Datos adicionales para poder mostrar el reporte de Deudores con contenido real
EXEC usp_ABM_Empresa
    @Accion = 'I',
    @razon_social = 'Concesiones del Sur S.A.',
    @cuit = '30-12345678e-9',
    @tipo_actividad = 'Gastronomía';

EXEC usp_ABM_Concesion
    @Accion = 'I',
    @fecha_inicio = '2026-01-01',
    @fecha_fin = '2027-01-01',
    @canon_mensual = 100000.00,
    @empresa_id = 1,
    @parque_id = 1;

EXEC usp_RegistrarPagoConcesion
    @concesion_id = 1,
    @fecha_pago = '2026-02-05',
    @periodo = '2026-01-01',
    @monto_abonado = 60000.00; -- Pago parcial: queda registrado como 'Atrasado'

GO

PRINT '---------------------------------------------------------';
PRINT 'REPORTE 1: Visitas por parque (mensual)';
PRINT '---------------------------------------------------------';
EXEC usp_Reporte_VisitasPorParque @TipoPeriodo = 'M', @Anio = NULL;

PRINT '---------------------------------------------------------';
PRINT 'REPORTE 2: Ingresos por parque (mensual)';
PRINT '---------------------------------------------------------';
EXEC usp_Reporte_IngresosPorParque @TipoPeriodo = 'M', @Anio = NULL;

PRINT '---------------------------------------------------------';
PRINT 'REPORTE 3: Deudores (XML)';
PRINT '---------------------------------------------------------';
EXEC usp_Reporte_Deudores;

PRINT '---------------------------------------------------------';
PRINT 'REPORTE 4: Matriz de visitas (Pivot mensual)';
PRINT '---------------------------------------------------------';
EXEC usp_Reporte_MatrizVisitas @Anio = 2026;

PRINT '---------------------------------------------------------';
PRINT 'REPORTE 5: Parques y concesiones (XML)';
PRINT '---------------------------------------------------------';
EXEC usp_Reporte_ParquesConcesiones;
GO
