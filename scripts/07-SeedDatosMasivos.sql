/*******************************************************************************
                       UNIVERSIDAD NACIONAL DE LA MATANZA
Fecha: 01/07/2026
Integrantes: [Nicolás Kugel, Facundo Gargiulo, Valentin Martinez]
Descripción: Seed de datos masivo. Carga un volumen grande de datos de ejemplo
             en todas las tablas del sistema, exclusivamente a través de los
             Procedimientos Almacenados de ABM (02-ABM.sql) y de Lógica de
             Negocio (03-logicaNegocio.sql). No se realiza ningún INSERT directo.

             Requiere haber ejecutado previamente, en orden:
               00-CreaBDySCHEMAS.sql -> 01-CreaTablas.sql -> 02-ABM.sql -> 03-logicaNegocio.sql

             IMPORTANTE: Este script está pensado para correr sobre una base
             recién creada (sin los datos de 04-testIntegracion.sql ni de
             06-testReportes.sql), ya que es una alternativa con mucho más
             volumen a esos scripts de prueba. Todos los DNI/CUIT usados aquí
             son distintos a los de esos archivos para evitar violaciones de
             las restricciones UNIQUE si igualmente se ejecuta a continuación
             de ellos.

             NOTA SOBRE FECHAS DE VENTA: usp_ProcesarVentaTicket graba
             Venta.fecha y LineaVenta.fecha_acceso con GETDATE() (no son
             parámetros del SP), por lo que todas las ventas generadas acá
             quedarán fechadas el día en que se ejecute este script. Los
             reportes de visitas/ingresos por semana o mes por lo tanto van
             a mostrar un único período para esas ventas; el reporte de
             concesiones sí muestra variedad histórica porque
             usp_RegistrarPagoConcesion recibe la fecha por parámetro.
*******************************************************************************/

USE TPBDG5;
GO

SET NOCOUNT ON;

PRINT '=============================================================';
PRINT 'INICIO DE CARGA MASIVA DE DATOS DE EJEMPLO';
PRINT '=============================================================';

-- =============================================================================
-- 1. PARQUES
-- =============================================================================
EXEC usp_ABM_Parque 'I', NULL, 'PNI', 'Parque Nacional Iguazú',           'Misiones',            67620.00,  'PN';
EXEC usp_ABM_Parque 'I', NULL, 'PNH', 'Parque Nacional Nahuel Huapi',     'Río Negro/Neuquén',  717261.00,  'PN';
EXEC usp_ABM_Parque 'I', NULL, 'PNG', 'Parque Nacional Los Glaciares',    'Santa Cruz',         726927.00,  'PN';
EXEC usp_ABM_Parque 'I', NULL, 'PNT', 'Parque Nacional Talampaya',        'La Rioja',           215000.00,  'PN';
EXEC usp_ABM_Parque 'I', NULL, 'PNL', 'Parque Nacional Lanín',            'Neuquén',            412013.00,  'PN';
EXEC usp_ABM_Parque 'I', NULL, 'PNA', 'Parque Nacional Los Alerces',      'Chubut',             259570.00,  'PN';
EXEC usp_ABM_Parque 'I', NULL, 'PNF', 'Parque Nacional Tierra del Fuego', 'Tierra del Fuego',    68909.00,  'PN';
EXEC usp_ABM_Parque 'I', NULL, 'PNC', 'Parque Nacional Calilegua',        'Jujuy',               76306.00,  'PN';

DECLARE @Parques TABLE (rn INT IDENTITY(1,1), id INT, Codigo VARCHAR(20));
INSERT INTO @Parques (id, Codigo)
SELECT id, Codigo FROM (SELECT TOP (8) id, Codigo FROM Parques.Parque ORDER BY id DESC) X ORDER BY id ASC;

-- NOTA: EXEC no admite subconsultas "(SELECT ...)" como argumento directo,
-- por eso cada id se vuelca antes a una variable escalar y se reutiliza.
DECLARE @Parque1 INT = (SELECT id FROM @Parques WHERE rn = 1);
DECLARE @Parque2 INT = (SELECT id FROM @Parques WHERE rn = 2);
DECLARE @Parque3 INT = (SELECT id FROM @Parques WHERE rn = 3);
DECLARE @Parque4 INT = (SELECT id FROM @Parques WHERE rn = 4);
DECLARE @Parque5 INT = (SELECT id FROM @Parques WHERE rn = 5);
DECLARE @Parque6 INT = (SELECT id FROM @Parques WHERE rn = 6);
DECLARE @Parque7 INT = (SELECT id FROM @Parques WHERE rn = 7);
DECLARE @Parque8 INT = (SELECT id FROM @Parques WHERE rn = 8);

-- =============================================================================
-- 2. EMPRESAS CONCESIONARIAS
-- =============================================================================
EXEC usp_ABM_Empresa 'I', NULL, 'Sabores del Iguazú S.A.',    '33-11111111-1', 'Gastronomía';
EXEC usp_ABM_Empresa 'I', NULL, 'Patagonia Turismo S.R.L.',   '33-22222222-2', 'Transporte';
EXEC usp_ABM_Empresa 'I', NULL, 'Hostería Cauquenes Sur S.A.','33-33333333-3', 'Alojamiento';
EXEC usp_ABM_Empresa 'I', NULL, 'Andes Aventura S.A.',        '33-44444444-4', 'Turismo Aventura';
EXEC usp_ABM_Empresa 'I', NULL, 'Norte Nativo S.R.L.',        '33-55555555-5', 'Gastronomía';
EXEC usp_ABM_Empresa 'I', NULL, 'Cataratas Tour S.A.',        '33-66666666-6', 'Transporte';

DECLARE @Empresas TABLE (rn INT IDENTITY(1,1), id INT);
INSERT INTO @Empresas (id)
SELECT id FROM (SELECT TOP (6) id FROM Concesiones.Empresa ORDER BY id DESC) X ORDER BY id ASC;

DECLARE @Empresa1 INT = (SELECT id FROM @Empresas WHERE rn = 1);
DECLARE @Empresa2 INT = (SELECT id FROM @Empresas WHERE rn = 2);
DECLARE @Empresa3 INT = (SELECT id FROM @Empresas WHERE rn = 3);
DECLARE @Empresa4 INT = (SELECT id FROM @Empresas WHERE rn = 4);
DECLARE @Empresa5 INT = (SELECT id FROM @Empresas WHERE rn = 5);
DECLARE @Empresa6 INT = (SELECT id FROM @Empresas WHERE rn = 6);

-- =============================================================================
-- 3. TIPOS DE VISITANTE
-- =============================================================================
EXEC usp_ABM_TipoVisitante 'I', NULL, 'Residente Nacional',    50;
EXEC usp_ABM_TipoVisitante 'I', NULL, 'Residente Provincial',  30;
EXEC usp_ABM_TipoVisitante 'I', NULL, 'Turista Extranjero',     0;
EXEC usp_ABM_TipoVisitante 'I', NULL, 'Jubilado',              60;
EXEC usp_ABM_TipoVisitante 'I', NULL, 'Menor de 12 años',      80;
EXEC usp_ABM_TipoVisitante 'I', NULL, 'Estudiante',            40;

DECLARE @TiposVisitante TABLE (rn INT IDENTITY(1,1), id INT);
INSERT INTO @TiposVisitante (id)
SELECT id FROM (SELECT TOP (6) id FROM Ventas.TipoVisitante ORDER BY id DESC) X ORDER BY id ASC;

-- =============================================================================
-- 4. ENTRADAS (con historial de precio en 3 parques)
-- =============================================================================
EXEC usp_ABM_Entrada 'I', NULL, 4000.00, @Parque1, '2024-01-01'; -- Iguazú
EXEC usp_ABM_Entrada 'I', NULL, 5000.00, @Parque1, '2025-06-01'; -- Iguazú (aumento)
EXEC usp_ABM_Entrada 'I', NULL, 3000.00, @Parque2, '2024-01-01'; -- Nahuel Huapi
EXEC usp_ABM_Entrada 'I', NULL, 4500.00, @Parque3, '2024-01-01'; -- Los Glaciares
EXEC usp_ABM_Entrada 'I', NULL, 6000.00, @Parque3, '2025-06-01'; -- Los Glaciares (aumento)
EXEC usp_ABM_Entrada 'I', NULL, 3500.00, @Parque4, '2024-01-01'; -- Talampaya
EXEC usp_ABM_Entrada 'I', NULL, 2500.00, @Parque5, '2024-01-01'; -- Lanín
EXEC usp_ABM_Entrada 'I', NULL, 3000.00, @Parque6, '2024-01-01'; -- Los Alerces
EXEC usp_ABM_Entrada 'I', NULL, 3800.00, @Parque7, '2024-01-01'; -- Tierra del Fuego
EXEC usp_ABM_Entrada 'I', NULL, 4800.00, @Parque7, '2025-06-01'; -- Tierra del Fuego (aumento)
EXEC usp_ABM_Entrada 'I', NULL, 2000.00, @Parque8, '2024-01-01'; -- Calilegua

-- Entrada vigente (la de mayor id, es decir la más reciente) por cada parque
DECLARE @EntradaVigente TABLE (parque_id INT, entrada_id INT);
INSERT INTO @EntradaVigente (parque_id, entrada_id)
SELECT parque_id, MAX(id) FROM Parques.Entrada GROUP BY parque_id;

-- =============================================================================
-- 5. ATRACCIONES (2 o 3 por parque)
-- =============================================================================
EXEC usp_ABM_Atraccion 'I', NULL, 'Garganta del Diablo',           'Paseo en pasarelas sobre la Garganta del Diablo', '02:00:00', 60, 1500.00, @Parque1;
EXEC usp_ABM_Atraccion 'I', NULL, 'Senda Macuco',                  'Caminata guiada en la selva paranaense',          '03:00:00', 30, 2500.00, @Parque1;
EXEC usp_ABM_Atraccion 'I', NULL, 'Gran Aventura en Lancha',       'Navegación de alta velocidad bajo los saltos',    '01:30:00', 40, 4000.00, @Parque1;
EXEC usp_ABM_Atraccion 'I', NULL, 'Circuito Chico en Bicicleta',   'Recorrido panorámico en bicicleta',               '04:00:00', 20, 3000.00, @Parque2;
EXEC usp_ABM_Atraccion 'I', NULL, 'Navegación Isla Victoria',      'Excursión lacustre a Isla Victoria y Arrayanes',  '03:00:00', 50, 5500.00, @Parque2;
EXEC usp_ABM_Atraccion 'I', NULL, 'Minitrekking Perito Moreno',    'Caminata sobre el hielo del glaciar',             '04:00:00', 25, 8000.00, @Parque3;
EXEC usp_ABM_Atraccion 'I', NULL, 'Trekking Fitz Roy',             'Ascenso al mirador del Cerro Fitz Roy',           '06:00:00', 15, 3000.00, @Parque3;
EXEC usp_ABM_Atraccion 'I', NULL, 'Recorrido en Camión 4x4',       'Ingreso al cañón en vehículo todoterreno',        '03:00:00', 35, 4500.00, @Parque4;
EXEC usp_ABM_Atraccion 'I', NULL, 'Cañón del Eclipse en Bicicleta','Recorrido en bicicleta por formaciones rocosas',  '02:00:00', 20, 3000.00, @Parque4;
EXEC usp_ABM_Atraccion 'I', NULL, 'Ascenso al Volcán Lanín',       'Trekking técnico de altura',                      '08:00:00', 12, 6000.00, @Parque5;
EXEC usp_ABM_Atraccion 'I', NULL, 'Paseo Lacustre Huechulafquen',  'Navegación por el lago Huechulafquen',            '02:00:00', 30, 2800.00, @Parque5;
EXEC usp_ABM_Atraccion 'I', NULL, 'Navegación Lago Futalaufquen',  'Paseo en catamarán por el lago',                  '02:30:00', 40, 3200.00, @Parque6;
EXEC usp_ABM_Atraccion 'I', NULL, 'Sendero Alerzal Milenario',     'Caminata entre alerces centenarios',              '03:00:00', 25, 2200.00, @Parque6;
EXEC usp_ABM_Atraccion 'I', NULL, 'Tren del Fin del Mundo',        'Recorrido histórico en tren a vapor',             '01:00:00', 80, 4000.00, @Parque7;
EXEC usp_ABM_Atraccion 'I', NULL, 'Trekking Bahía Ensenada',       'Caminata costera por el Canal de Beagle',         '03:00:00', 20, 2500.00, @Parque7;
EXEC usp_ABM_Atraccion 'I', NULL, 'Sendero Las Lanzas',            'Caminata en la selva de yungas',                  '02:00:00', 20, 1800.00, @Parque8;
EXEC usp_ABM_Atraccion 'I', NULL, 'Avistaje de Aves',              'Recorrido guiado de avistaje ornitológico',       '03:00:00', 15, 2200.00, @Parque8;

DECLARE @Atracciones TABLE (rn INT IDENTITY(1,1), id INT, parque_id INT);
INSERT INTO @Atracciones (id, parque_id)
SELECT id, parque_id FROM (SELECT TOP (17) id, parque_id FROM Parques.Atraccion ORDER BY id DESC) X ORDER BY id ASC;

DECLARE @Atraccion1  INT = (SELECT id FROM @Atracciones WHERE rn = 1);
DECLARE @Atraccion2  INT = (SELECT id FROM @Atracciones WHERE rn = 2);
DECLARE @Atraccion3  INT = (SELECT id FROM @Atracciones WHERE rn = 3);
DECLARE @Atraccion4  INT = (SELECT id FROM @Atracciones WHERE rn = 4);
DECLARE @Atraccion5  INT = (SELECT id FROM @Atracciones WHERE rn = 5);
DECLARE @Atraccion6  INT = (SELECT id FROM @Atracciones WHERE rn = 6);
DECLARE @Atraccion7  INT = (SELECT id FROM @Atracciones WHERE rn = 7);
DECLARE @Atraccion8  INT = (SELECT id FROM @Atracciones WHERE rn = 8);
DECLARE @Atraccion9  INT = (SELECT id FROM @Atracciones WHERE rn = 9);
DECLARE @Atraccion10 INT = (SELECT id FROM @Atracciones WHERE rn = 10);
DECLARE @Atraccion11 INT = (SELECT id FROM @Atracciones WHERE rn = 11);
DECLARE @Atraccion12 INT = (SELECT id FROM @Atracciones WHERE rn = 12);
DECLARE @Atraccion13 INT = (SELECT id FROM @Atracciones WHERE rn = 13);
DECLARE @Atraccion14 INT = (SELECT id FROM @Atracciones WHERE rn = 14);
DECLARE @Atraccion15 INT = (SELECT id FROM @Atracciones WHERE rn = 15);
DECLARE @Atraccion16 INT = (SELECT id FROM @Atracciones WHERE rn = 16);
DECLARE @Atraccion17 INT = (SELECT id FROM @Atracciones WHERE rn = 17);

-- =============================================================================
-- 6. GUARDAPARQUES
-- =============================================================================
EXEC usp_ABM_GuardaParque 'I', NULL, 'Marta',     'Fernández', '46123456', 1;
EXEC usp_ABM_GuardaParque 'I', NULL, 'Diego',     'Ibarra',    '46234567', 1;
EXEC usp_ABM_GuardaParque 'I', NULL, 'Lucía',     'Paredes',   '46345678', 1;
EXEC usp_ABM_GuardaParque 'I', NULL, 'Martín',    'Ríos',      '46456789', 1;
EXEC usp_ABM_GuardaParque 'I', NULL, 'Carla',     'Sosa',      '46567890', 1;
EXEC usp_ABM_GuardaParque 'I', NULL, 'Hernán',    'Molina',    '46678901', 1;
EXEC usp_ABM_GuardaParque 'I', NULL, 'Valeria',   'Acosta',    '46789012', 1;
EXEC usp_ABM_GuardaParque 'I', NULL, 'Fernando',  'Duarte',    '46890123', 1;
EXEC usp_ABM_GuardaParque 'I', NULL, 'Sabrina',   'Ortiz',     '46901234', 1;
EXEC usp_ABM_GuardaParque 'I', NULL, 'Gastón',    'Benítez',   '47012345', 1;
EXEC usp_ABM_GuardaParque 'I', NULL, 'Rocío',     'Villalba',  '47123456', 0; -- Inactiva (asignación cerrada)
EXEC usp_ABM_GuardaParque 'I', NULL, 'Pablo',     'Medina',    '47234567', 1;
EXEC usp_ABM_GuardaParque 'I', NULL, 'Antonella', 'Rojas',     '47345678', 1;
EXEC usp_ABM_GuardaParque 'I', NULL, 'Ezequiel',  'Torres',    '47456789', 1;
EXEC usp_ABM_GuardaParque 'I', NULL, 'Nahuel',    'Aráoz',     '47567890', 0; -- Inactivo (asignación cerrada)

DECLARE @GuardaParques TABLE (rn INT IDENTITY(1,1), id INT);
INSERT INTO @GuardaParques (id)
SELECT id FROM (SELECT TOP (15) id FROM Personal.GuardaParque ORDER BY id DESC) X ORDER BY id ASC;

DECLARE @GuardaParque1  INT = (SELECT id FROM @GuardaParques WHERE rn = 1);
DECLARE @GuardaParque2  INT = (SELECT id FROM @GuardaParques WHERE rn = 2);
DECLARE @GuardaParque3  INT = (SELECT id FROM @GuardaParques WHERE rn = 3);
DECLARE @GuardaParque4  INT = (SELECT id FROM @GuardaParques WHERE rn = 4);
DECLARE @GuardaParque5  INT = (SELECT id FROM @GuardaParques WHERE rn = 5);
DECLARE @GuardaParque6  INT = (SELECT id FROM @GuardaParques WHERE rn = 6);
DECLARE @GuardaParque7  INT = (SELECT id FROM @GuardaParques WHERE rn = 7);
DECLARE @GuardaParque8  INT = (SELECT id FROM @GuardaParques WHERE rn = 8);
DECLARE @GuardaParque9  INT = (SELECT id FROM @GuardaParques WHERE rn = 9);
DECLARE @GuardaParque10 INT = (SELECT id FROM @GuardaParques WHERE rn = 10);
DECLARE @GuardaParque11 INT = (SELECT id FROM @GuardaParques WHERE rn = 11);
DECLARE @GuardaParque12 INT = (SELECT id FROM @GuardaParques WHERE rn = 12);
DECLARE @GuardaParque13 INT = (SELECT id FROM @GuardaParques WHERE rn = 13);
DECLARE @GuardaParque14 INT = (SELECT id FROM @GuardaParques WHERE rn = 14);
DECLARE @GuardaParque15 INT = (SELECT id FROM @GuardaParques WHERE rn = 15);

-- =============================================================================
-- 7. ASIGNACIONES DE GUARDAPARQUE A PARQUE
-- =============================================================================
EXEC usp_ABM_AsignacionGuardaParque 'I', NULL, '2023-01-10', NULL,         NULL,                     @GuardaParque1,  @Parque1;
EXEC usp_ABM_AsignacionGuardaParque 'I', NULL, '2023-03-01', NULL,         NULL,                     @GuardaParque2,  @Parque1;
EXEC usp_ABM_AsignacionGuardaParque 'I', NULL, '2023-01-15', NULL,         NULL,                     @GuardaParque3,  @Parque2;
EXEC usp_ABM_AsignacionGuardaParque 'I', NULL, '2023-02-01', NULL,         NULL,                     @GuardaParque4,  @Parque2;
EXEC usp_ABM_AsignacionGuardaParque 'I', NULL, '2023-01-20', NULL,         NULL,                     @GuardaParque5,  @Parque3;
EXEC usp_ABM_AsignacionGuardaParque 'I', NULL, '2023-04-01', NULL,         NULL,                     @GuardaParque6,  @Parque3;
EXEC usp_ABM_AsignacionGuardaParque 'I', NULL, '2023-01-05', NULL,         NULL,                     @GuardaParque7,  @Parque4;
EXEC usp_ABM_AsignacionGuardaParque 'I', NULL, '2023-05-01', NULL,         NULL,                     @GuardaParque8,  @Parque4;
EXEC usp_ABM_AsignacionGuardaParque 'I', NULL, '2023-01-12', NULL,         NULL,                     @GuardaParque9,  @Parque5;
EXEC usp_ABM_AsignacionGuardaParque 'I', NULL, '2023-06-01', NULL,         NULL,                     @GuardaParque10, @Parque5;
EXEC usp_ABM_AsignacionGuardaParque 'I', NULL, '2022-11-01', '2024-03-15', 'Renuncia',                @GuardaParque11, @Parque6;
EXEC usp_ABM_AsignacionGuardaParque 'I', NULL, '2024-03-20', NULL,         NULL,                     @GuardaParque12, @Parque6;
EXEC usp_ABM_AsignacionGuardaParque 'I', NULL, '2023-02-10', NULL,         NULL,                     @GuardaParque13, @Parque7;
EXEC usp_ABM_AsignacionGuardaParque 'I', NULL, '2023-07-01', NULL,         NULL,                     @GuardaParque14, @Parque7;
EXEC usp_ABM_AsignacionGuardaParque 'I', NULL, '2022-09-01', '2023-12-31', 'Traslado a otra unidad',  @GuardaParque15, @Parque8;
EXEC usp_ABM_AsignacionGuardaParque 'I', NULL, '2024-01-15', NULL,         NULL,                     @GuardaParque8,  @Parque8;
EXEC usp_ABM_AsignacionGuardaParque 'I', NULL, '2023-09-01', '2024-01-05', 'Licencia prolongada',     @GuardaParque3,  @Parque6;
EXEC usp_ABM_AsignacionGuardaParque 'I', NULL, '2023-11-01', NULL,         NULL,                     @GuardaParque6,  @Parque5;

-- =============================================================================
-- 8. GUÍAS
-- =============================================================================
EXEC usp_ABM_Guia 'I', NULL, 'Florencia', 'Núñez',    '44123456', 'Guía Universitario de Turismo',  'Nacional',   'Trekking';
EXEC usp_ABM_Guia 'I', NULL, 'Matías',    'Herrera',   '44234567', 'Técnico en Turismo',             'Provincial', 'Fauna y Flora';
EXEC usp_ABM_Guia 'I', NULL, 'Julieta',   'Campos',    '44345678', NULL,                              'Nacional',   'Kayak';
EXEC usp_ABM_Guia 'I', NULL, 'Nicolás',   'Ferreyra',  '44456789', 'Lic. en Ciencias Naturales',      'Nacional',   'Glaciares';
EXEC usp_ABM_Guia 'I', NULL, 'Camila',    'Suárez',    '44567890', 'Guía de Montaña',                 'Provincial', 'Montañismo';
EXEC usp_ABM_Guia 'I', NULL, 'Tomás',     'Aguirre',   '44678901', NULL,                              'Provincial', 'Avistaje de Aves';
EXEC usp_ABM_Guia 'I', NULL, 'Agustina',  'Leiva',     '44789012', 'Lic. en Turismo',                 'Nacional',   'Historia Natural';
EXEC usp_ABM_Guia 'I', NULL, 'Ramiro',    'Godoy',     '44890123', 'Guía Baqueano',                   'Provincial', 'Cabalgatas';
EXEC usp_ABM_Guia 'I', NULL, 'Milagros',  'Vera',      '44901234', NULL,                              'Nacional',   'Buceo y Snorkel';
EXEC usp_ABM_Guia 'I', NULL, 'Bruno',     'Escobar',   '45012345', 'Técnico en Guía de Turismo',      'Provincial', 'Ciclismo de Montaña';
EXEC usp_ABM_Guia 'I', NULL, 'Micaela',   'Funes',     '45123456', 'Lic. en Biología',                'Nacional',   'Fauna Marina';
EXEC usp_ABM_Guia 'I', NULL, 'Rodrigo',   'Paz',       '45234567', 'Guía Bilingüe',                   'Nacional',   'Interpretación Ambiental';

DECLARE @Guias TABLE (rn INT IDENTITY(1,1), id INT);
INSERT INTO @Guias (id)
SELECT id FROM (SELECT TOP (12) id FROM Personal.Guia ORDER BY id DESC) X ORDER BY id ASC;

DECLARE @Guia1  INT = (SELECT id FROM @Guias WHERE rn = 1);
DECLARE @Guia2  INT = (SELECT id FROM @Guias WHERE rn = 2);
DECLARE @Guia3  INT = (SELECT id FROM @Guias WHERE rn = 3);
DECLARE @Guia4  INT = (SELECT id FROM @Guias WHERE rn = 4);
DECLARE @Guia5  INT = (SELECT id FROM @Guias WHERE rn = 5);
DECLARE @Guia6  INT = (SELECT id FROM @Guias WHERE rn = 6);
DECLARE @Guia7  INT = (SELECT id FROM @Guias WHERE rn = 7);
DECLARE @Guia8  INT = (SELECT id FROM @Guias WHERE rn = 8);
DECLARE @Guia9  INT = (SELECT id FROM @Guias WHERE rn = 9);
DECLARE @Guia10 INT = (SELECT id FROM @Guias WHERE rn = 10);
DECLARE @Guia11 INT = (SELECT id FROM @Guias WHERE rn = 11);
DECLARE @Guia12 INT = (SELECT id FROM @Guias WHERE rn = 12);

-- =============================================================================
-- 9. ASIGNACIÓN DE GUÍAS A ATRACCIONES (usp_AsignarGuiaAtraccion - lógica de negocio)
-- =============================================================================
EXEC usp_AsignarGuiaAtraccion @atraccion_id = @Atraccion1,  @guia_id = @Guia1,  @fecha_asignacion = '2026-01-05', @turno = 'Mañana';
EXEC usp_AsignarGuiaAtraccion @atraccion_id = @Atraccion1,  @guia_id = @Guia2,  @fecha_asignacion = '2026-01-05', @turno = 'Tarde';
EXEC usp_AsignarGuiaAtraccion @atraccion_id = @Atraccion2,  @guia_id = @Guia3,  @fecha_asignacion = '2026-01-06', @turno = 'Mañana';
EXEC usp_AsignarGuiaAtraccion @atraccion_id = @Atraccion3,  @guia_id = @Guia4,  @fecha_asignacion = '2026-01-07', @turno = 'Tarde';
EXEC usp_AsignarGuiaAtraccion @atraccion_id = @Atraccion4,  @guia_id = @Guia5,  @fecha_asignacion = '2026-01-08', @turno = 'Mañana';
EXEC usp_AsignarGuiaAtraccion @atraccion_id = @Atraccion5,  @guia_id = @Guia6,  @fecha_asignacion = '2026-01-09', @turno = 'Tarde';
EXEC usp_AsignarGuiaAtraccion @atraccion_id = @Atraccion6,  @guia_id = @Guia7,  @fecha_asignacion = '2026-01-10', @turno = 'Mañana';
EXEC usp_AsignarGuiaAtraccion @atraccion_id = @Atraccion7,  @guia_id = @Guia6,  @fecha_asignacion = '2026-01-11', @turno = 'Tarde';
EXEC usp_AsignarGuiaAtraccion @atraccion_id = @Atraccion8,  @guia_id = @Guia8,  @fecha_asignacion = '2026-01-12', @turno = 'Mañana';
EXEC usp_AsignarGuiaAtraccion @atraccion_id = @Atraccion9,  @guia_id = @Guia9,  @fecha_asignacion = '2026-01-13', @turno = 'Tarde';
EXEC usp_AsignarGuiaAtraccion @atraccion_id = @Atraccion10, @guia_id = @Guia9,  @fecha_asignacion = '2026-01-14', @turno = 'Mañana';
EXEC usp_AsignarGuiaAtraccion @atraccion_id = @Atraccion11, @guia_id = @Guia10, @fecha_asignacion = '2026-01-15', @turno = 'Tarde';
EXEC usp_AsignarGuiaAtraccion @atraccion_id = @Atraccion12, @guia_id = @Guia11, @fecha_asignacion = '2026-01-16', @turno = 'Mañana';
EXEC usp_AsignarGuiaAtraccion @atraccion_id = @Atraccion13, @guia_id = @Guia11, @fecha_asignacion = '2026-01-17', @turno = 'Noche';
EXEC usp_AsignarGuiaAtraccion @atraccion_id = @Atraccion14, @guia_id = @Guia12, @fecha_asignacion = '2026-01-18', @turno = 'Tarde';
EXEC usp_AsignarGuiaAtraccion @atraccion_id = @Atraccion15, @guia_id = @Guia1,  @fecha_asignacion = '2026-01-19', @turno = 'Mañana';
EXEC usp_AsignarGuiaAtraccion @atraccion_id = @Atraccion16, @guia_id = @Guia2,  @fecha_asignacion = '2026-01-20', @turno = 'Tarde';
EXEC usp_AsignarGuiaAtraccion @atraccion_id = @Atraccion17, @guia_id = @Guia3,  @fecha_asignacion = '2026-01-21', @turno = 'Noche';
EXEC usp_AsignarGuiaAtraccion @atraccion_id = @Atraccion2,  @guia_id = @Guia4,  @fecha_asignacion = '2026-01-22', @turno = 'Noche';
EXEC usp_AsignarGuiaAtraccion @atraccion_id = @Atraccion9,  @guia_id = @Guia5,  @fecha_asignacion = '2026-01-23', @turno = 'Mañana';

-- =============================================================================
-- 10. CONCESIONES
-- =============================================================================
EXEC usp_ABM_Concesion 'I', NULL, '2023-01-01', '2027-01-01', 150000.00, @Empresa1, @Parque1;
EXEC usp_ABM_Concesion 'I', NULL, '2023-06-01', '2026-06-01', 180000.00, @Empresa1, @Parque3;
EXEC usp_ABM_Concesion 'I', NULL, '2022-01-01', '2025-12-31', 120000.00, @Empresa2, @Parque2;
EXEC usp_ABM_Concesion 'I', NULL, '2024-01-01', '2028-01-01',  90000.00, @Empresa2, @Parque6;
EXEC usp_ABM_Concesion 'I', NULL, '2021-03-01', '2026-03-01', 250000.00, @Empresa3, @Parque2;
EXEC usp_ABM_Concesion 'I', NULL, '2023-09-01', '2026-09-01',  80000.00, @Empresa4, @Parque5;
EXEC usp_ABM_Concesion 'I', NULL, '2024-02-01', '2027-02-01',  95000.00, @Empresa4, @Parque4;
EXEC usp_ABM_Concesion 'I', NULL, '2023-04-01', '2026-04-01', 110000.00, @Empresa5, @Parque7;
EXEC usp_ABM_Concesion 'I', NULL, '2022-10-01', '2025-10-01', 200000.00, @Empresa6, @Parque1;
EXEC usp_ABM_Concesion 'I', NULL, '2024-05-01', '2027-05-01',  60000.00, @Empresa5, @Parque8;

DECLARE @Concesiones TABLE (rn INT IDENTITY(1,1), id INT, canon_mensual DECIMAL(18,2), fecha_inicio DATE, fecha_fin DATE);
INSERT INTO @Concesiones (id, canon_mensual, fecha_inicio, fecha_fin)
SELECT id, canon_mensual, fecha_inicio, fecha_fin
FROM (SELECT TOP (10) id, canon_mensual, fecha_inicio, fecha_fin FROM Concesiones.Concesion ORDER BY id DESC) X
ORDER BY id ASC;

-- =============================================================================
-- 11. PAGOS DE CONCESIÓN (usp_RegistrarPagoConcesion - lógica de negocio)
-- Genera hasta 12 pagos mensuales (últimos 12 meses hasta 2026-06-01) por cada
-- concesión, recortando en la fecha_fin del contrato cuando corresponde.
-- Aproximadamente 1 de cada 5 pagos queda "Atrasado" (monto parcial).
-- =============================================================================
DECLARE @FechaCorte    DATE = '2026-06-01';
DECLARE @VentanaInicio DATE = DATEADD(MONTH, -11, @FechaCorte); -- 2025-07-01

DECLARE @ci INT = 1;
DECLARE @TotalConcesiones INT = (SELECT COUNT(*) FROM @Concesiones);
WHILE @ci <= @TotalConcesiones
BEGIN
    DECLARE @ConcesionId  INT = (SELECT id            FROM @Concesiones WHERE rn = @ci);
    DECLARE @Canon        DECIMAL(18,2) = (SELECT canon_mensual FROM @Concesiones WHERE rn = @ci);
    DECLARE @FInicio      DATE = (SELECT fecha_inicio FROM @Concesiones WHERE rn = @ci);
    DECLARE @FFin         DATE = (SELECT fecha_fin    FROM @Concesiones WHERE rn = @ci);
    DECLARE @PrimerPeriodo DATE = CASE WHEN @FInicio > @VentanaInicio THEN @FInicio ELSE @VentanaInicio END;

    DECLARE @mes INT = 0;
    WHILE @mes < 12
    BEGIN
        DECLARE @Periodo DATE = DATEADD(MONTH, @mes, @PrimerPeriodo);
        IF @Periodo <= @FFin AND @Periodo <= @FechaCorte
        BEGIN
            DECLARE @FechaPago DATE = DATEADD(DAY, 5 + (@mes % 10), @Periodo);
            DECLARE @Monto DECIMAL(18,2) = CASE WHEN @mes % 5 = 3 THEN @Canon * 0.6 ELSE @Canon END;

            EXEC usp_RegistrarPagoConcesion @ConcesionId, @FechaPago, @Periodo, @Monto;
        END
        SET @mes = @mes + 1;
    END

    SET @ci = @ci + 1;
END

-- =============================================================================
-- 12. VISITANTES
-- =============================================================================
EXEC usp_ABM_Visitante 'I', NULL, 'Juan',       'Pérez',      '48000001';
EXEC usp_ABM_Visitante 'I', NULL, 'María',      'González',   '48000002';
EXEC usp_ABM_Visitante 'I', NULL, 'Pedro',      'Sosa',       '48000003';
EXEC usp_ABM_Visitante 'I', NULL, 'Lucía',      'Fernández',  '48000004';
EXEC usp_ABM_Visitante 'I', NULL, 'Diego',      'Martínez',   '48000005';
EXEC usp_ABM_Visitante 'I', NULL, 'Valentina',  'López',      '48000006';
EXEC usp_ABM_Visitante 'I', NULL, 'Federico',   'Díaz',       '48000007';
EXEC usp_ABM_Visitante 'I', NULL, 'Camila',     'Torres',     '48000008';
EXEC usp_ABM_Visitante 'I', NULL, 'Santiago',   'Romero',     '48000009';
EXEC usp_ABM_Visitante 'I', NULL, 'Sofía',      'Álvarez',    '48000010';
EXEC usp_ABM_Visitante 'I', NULL, 'Nicolás',    'Castro',     '48000011';
EXEC usp_ABM_Visitante 'I', NULL, 'Agustina',   'Rojas',      '48000012';
EXEC usp_ABM_Visitante 'I', NULL, 'Matías',     'Molina',     '48000013';
EXEC usp_ABM_Visitante 'I', NULL, 'Florencia',  'Ortiz',      '48000014';
EXEC usp_ABM_Visitante 'I', NULL, 'Joaquín',    'Vega',       '48000015';
EXEC usp_ABM_Visitante 'I', NULL, 'Martina',    'Silva',      '48000016';
EXEC usp_ABM_Visitante 'I', NULL, 'Tomás',      'Ibáñez',     '48000017';
EXEC usp_ABM_Visitante 'I', NULL, 'Julieta',    'Acosta',     '48000018';
EXEC usp_ABM_Visitante 'I', NULL, 'Franco',     'Núñez',      '48000019';
EXEC usp_ABM_Visitante 'I', NULL, 'Milagros',   'Paz',        '48000020';
EXEC usp_ABM_Visitante 'I', NULL, 'Ignacio',    'Herrera',    '48000021';
EXEC usp_ABM_Visitante 'I', NULL, 'Renata',     'Suárez',     '48000022';
EXEC usp_ABM_Visitante 'I', NULL, 'Bruno',      'Aguirre',    '48000023';
EXEC usp_ABM_Visitante 'I', NULL, 'Antonella',  'Ramos',      '48000024';
EXEC usp_ABM_Visitante 'I', NULL, 'Ezequiel',   'Cabrera',    '48000025';
EXEC usp_ABM_Visitante 'I', NULL, 'Delfina',    'Medina',     '48000026';
EXEC usp_ABM_Visitante 'I', NULL, 'Lautaro',    'Ferreyra',   '48000027';
EXEC usp_ABM_Visitante 'I', NULL, 'Guadalupe',  'Vargas',     '48000028';
EXEC usp_ABM_Visitante 'I', NULL, 'Emiliano',   'Duarte',     '48000029';
EXEC usp_ABM_Visitante 'I', NULL, 'Catalina',   'Benítez',    '48000030';
EXEC usp_ABM_Visitante 'I', NULL, 'Thiago',     'Villalba',   '48000031';
EXEC usp_ABM_Visitante 'I', NULL, 'Isabella',   'Godoy',      '48000032';
EXEC usp_ABM_Visitante 'I', NULL, 'Benjamín',   'Funes',      '48000033';
EXEC usp_ABM_Visitante 'I', NULL, 'Victoria',   'Campos',     '48000034';
EXEC usp_ABM_Visitante 'I', NULL, 'Gael',       'Escobar',    '48000035';

DECLARE @Visitantes TABLE (rn INT IDENTITY(1,1), id INT);
INSERT INTO @Visitantes (id)
SELECT id FROM (SELECT TOP (35) id FROM Ventas.Visitante ORDER BY id DESC) X ORDER BY id ASC;

-- =============================================================================
-- 13. VENTAS (usp_ProcesarVentaTicket - lógica de negocio)
-- Genera 150 ventas alternando entradas y accesos a atracciones, variando
-- visitante, tipo de visitante, forma de pago y cantidad.
-- =============================================================================
DECLARE @FormasPago TABLE (rn INT IDENTITY(1,1), forma VARCHAR(50));
INSERT INTO @FormasPago (forma) VALUES ('Efectivo'), ('Tarjeta de débito'), ('Tarjeta de crédito'), ('Transferencia');

DECLARE @NumVisitantes    INT = (SELECT COUNT(*) FROM @Visitantes);
DECLARE @NumTipos         INT = (SELECT COUNT(*) FROM @TiposVisitante);
DECLARE @NumParques       INT = (SELECT COUNT(*) FROM @Parques);
DECLARE @NumAtracciones   INT = (SELECT COUNT(*) FROM @Atracciones);
DECLARE @TotalVentas      INT = 150;

DECLARE @i INT = 1;
WHILE @i <= @TotalVentas
BEGIN
    DECLARE @VisitanteId     INT = (SELECT id FROM @Visitantes     WHERE rn = ((@i - 1) % @NumVisitantes) + 1);
    DECLARE @TipoVisitanteId INT = (SELECT id FROM @TiposVisitante WHERE rn = ((@i - 1) % @NumTipos) + 1);
    DECLARE @FormaPago       VARCHAR(50) = (SELECT forma FROM @FormasPago WHERE rn = ((@i - 1) % 4) + 1);
    DECLARE @Cantidad        INT = ((@i - 1) % 4) + 1;

    DECLARE @EntradaId  INT = NULL;
    DECLARE @AtraccionId INT = NULL;

    IF @i % 3 = 0
        SET @AtraccionId = (SELECT id FROM @Atracciones WHERE rn = ((@i - 1) % @NumAtracciones) + 1);
    ELSE
    BEGIN
        DECLARE @ParqueSel INT = (SELECT id FROM @Parques WHERE rn = ((@i - 1) % @NumParques) + 1);
        SET @EntradaId = (SELECT entrada_id FROM @EntradaVigente WHERE parque_id = @ParqueSel);
    END

    DECLARE @PuntoVenta  INT = @i % 5 + 1;
    DECLARE @NumeroVenta INT = 10000 + @i;

    EXEC usp_ProcesarVentaTicket
        @punto_venta       = @PuntoVenta,
        @numero            = @NumeroVenta,
        @forma_pago        = @FormaPago,
        @visitante_id      = @VisitanteId,
        @tipo_visitante_id = @TipoVisitanteId,
        @entrada_id        = @EntradaId,
        @atraccion_id      = @AtraccionId,
        @cantidad          = @Cantidad;

    SET @i = @i + 1;
END

-- =============================================================================
-- 14. RESUMEN DE DATOS CARGADOS (EVIDENCIA)
-- =============================================================================
PRINT '=============================================================';
PRINT 'RESUMEN DE FILAS CARGADAS POR TABLA';
PRINT '=============================================================';

SELECT 'Parques'                  AS Tabla, COUNT(*) AS Filas FROM Parques.Parque
UNION ALL SELECT 'Empresas',                 COUNT(*) FROM Concesiones.Empresa
UNION ALL SELECT 'Concesiones',              COUNT(*) FROM Concesiones.Concesion
UNION ALL SELECT 'PagosConcesion',           COUNT(*) FROM Concesiones.PagoConcesion
UNION ALL SELECT 'TiposVisitante',           COUNT(*) FROM Ventas.TipoVisitante
UNION ALL SELECT 'Entradas',                 COUNT(*) FROM Parques.Entrada
UNION ALL SELECT 'Atracciones',              COUNT(*) FROM Parques.Atraccion
UNION ALL SELECT 'GuardaParques',            COUNT(*) FROM Personal.GuardaParque
UNION ALL SELECT 'AsignacionesGuardaParque', COUNT(*) FROM Personal.AsignacionGuardaParque
UNION ALL SELECT 'Guias',                    COUNT(*) FROM Personal.Guia
UNION ALL SELECT 'AsignacionesGuiaAtraccion',COUNT(*) FROM Personal.AtraccionGuia
UNION ALL SELECT 'Visitantes',               COUNT(*) FROM Ventas.Visitante
UNION ALL SELECT 'Ventas',                   COUNT(*) FROM Ventas.Venta
UNION ALL SELECT 'LineasVenta',              COUNT(*) FROM Ventas.LineaVenta;

PRINT '=============================================================';
PRINT 'FIN DE CARGA MASIVA DE DATOS DE EJEMPLO';
PRINT '=============================================================';
GO
