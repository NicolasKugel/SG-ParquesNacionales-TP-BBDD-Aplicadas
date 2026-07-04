/*******************************************************************************
Fecha: 22/06/2026
Integrantes: [Nicolás Kugel, Facundo Gargiulo, Valentin Martinez]
Descripción: Entrega 7 - Reportes. Procedimientos Almacenados de reporting:
             visitas, ingresos, deudores, matriz de visitas y parques/concesiones.
*******************************************************************************/

USE TPBDG5;
GO

-- ==========================================
-- REPORTE 1: VISITAS POR SEMANA, MES Y AÑO, POR PARQUE
-- ==========================================
CREATE OR ALTER PROCEDURE usp_Reporte_VisitasPorParque
    @TipoPeriodo CHAR(1), -- 'S' Semana, 'M' Mes, 'A' Año
    @Anio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    WITH VentaParque AS (
        SELECT
            COALESCE(EN.parque_id, AT.parque_id) AS parque_id,
            LV.cantidad,
            LV.fecha_acceso
        FROM Ventas.LineaVenta LV
        LEFT JOIN Parques.Entrada  EN ON LV.entrada_id   = EN.id
        LEFT JOIN Parques.Atraccion AT ON LV.atraccion_id = AT.id
    )
    SELECT
        P.id   AS parque_id,
        P.nombre AS parque,
        DATEPART(YEAR, VP.fecha_acceso) AS anio,
        CASE WHEN @TipoPeriodo = 'M' THEN DATEPART(MONTH,    VP.fecha_acceso) END AS mes,
        CASE WHEN @TipoPeriodo = 'S' THEN DATEPART(ISO_WEEK, VP.fecha_acceso) END AS semana,
        SUM(VP.cantidad) AS total_visitas
    FROM VentaParque VP
    INNER JOIN Parques.Parque P ON P.id = VP.parque_id
    WHERE (@Anio IS NULL OR DATEPART(YEAR, VP.fecha_acceso) = @Anio)
    GROUP BY
        P.id, P.nombre, DATEPART(YEAR, VP.fecha_acceso),
        CASE WHEN @TipoPeriodo = 'M' THEN DATEPART(MONTH,    VP.fecha_acceso) END,
        CASE WHEN @TipoPeriodo = 'S' THEN DATEPART(ISO_WEEK, VP.fecha_acceso) END
    ORDER BY parque, anio, mes, semana;
END;
GO

-- ==========================================
-- REPORTE 2: INGRESOS POR PARQUE POR SEMANA, MES Y AÑO
-- ==========================================
CREATE OR ALTER PROCEDURE usp_Reporte_IngresosPorParque
    @TipoPeriodo CHAR(1), -- 'S' Semana, 'M' Mes, 'A' Año
    @Anio INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    WITH Ingresos AS (
        SELECT
            COALESCE(EN.parque_id, AT.parque_id) AS parque_id,
            DATEPART(YEAR, LV.fecha_acceso) AS anio,
            CASE WHEN @TipoPeriodo = 'M' THEN DATEPART(MONTH,    LV.fecha_acceso) END AS mes,
            CASE WHEN @TipoPeriodo = 'S' THEN DATEPART(ISO_WEEK, LV.fecha_acceso) END AS semana,
            CASE WHEN LV.entrada_id IS NOT NULL THEN 'ENTRADA' ELSE 'ATRACCION' END AS concepto,
            LV.subtotal AS monto
        FROM Ventas.LineaVenta LV
        LEFT JOIN Parques.Entrada   EN ON LV.entrada_id   = EN.id
        LEFT JOIN Parques.Atraccion AT ON LV.atraccion_id = AT.id

        UNION ALL

        SELECT
            C.parque_id,
            DATEPART(YEAR, PC.fecha_pago) AS anio,
            CASE WHEN @TipoPeriodo = 'M' THEN DATEPART(MONTH,    PC.fecha_pago) END AS mes,
            CASE WHEN @TipoPeriodo = 'S' THEN DATEPART(ISO_WEEK, PC.fecha_pago) END AS semana,
            'CONCESION' AS concepto,
            PC.total AS monto
        FROM Concesiones.PagoConcesion PC
        INNER JOIN Concesiones.Concesion C ON C.id = PC.concesion_id
        WHERE PC.fecha_pago IS NOT NULL
    )
    SELECT
        P.id AS parque_id,
        P.nombre AS parque,
        I.anio,
        I.mes,
        I.semana,
        SUM(CASE WHEN I.concepto = 'ENTRADA'   THEN I.monto ELSE 0 END) AS ingresos_entradas,
        SUM(CASE WHEN I.concepto = 'ATRACCION' THEN I.monto ELSE 0 END) AS ingresos_atracciones,
        SUM(CASE WHEN I.concepto = 'CONCESION' THEN I.monto ELSE 0 END) AS ingresos_concesiones,
        SUM(I.monto) AS ingreso_total
    FROM Ingresos I
    INNER JOIN Parques.Parque P ON P.id = I.parque_id
    WHERE (@Anio IS NULL OR I.anio = @Anio)
    GROUP BY P.id, P.nombre, I.anio, I.mes, I.semana
    ORDER BY parque, anio, mes, semana;
END;
GO

-- ==========================================
-- REPORTE 3: DEUDORES (CONCESIONES ATRASADAS) - XML
-- ==========================================
CREATE OR ALTER PROCEDURE usp_Reporte_Deudores
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        E.id            AS '@id',
        E.razon_social  AS '@razon_social',
        E.cuit          AS '@cuit',
        (
            SELECT
                C.id            AS '@id',
                P.nombre        AS '@parque',
                C.canon_mensual AS '@canon_mensual',
                (
                    SELECT
                        PC.periodo              AS '@periodo',
                        PC.fecha_pago           AS '@fecha_pago',
                        PC.total                AS '@monto_pagado',
                        (C.canon_mensual - PC.total) AS '@monto_adeudado'
                    FROM Concesiones.PagoConcesion PC
                    WHERE PC.concesion_id = C.id AND PC.estado = 'Atrasado'
                    FOR XML PATH('PagoAtrasado'), TYPE
                ) AS Pagos
            FROM Concesiones.Concesion C
            INNER JOIN Parques.Parque P ON P.id = C.parque_id
            WHERE C.empresa_id = E.id
              AND EXISTS (SELECT 1 FROM Concesiones.PagoConcesion PC2
                          WHERE PC2.concesion_id = C.id AND PC2.estado = 'Atrasado')
            FOR XML PATH('Concesion'), TYPE
        ) AS Concesiones
    FROM Concesiones.Empresa E
    WHERE EXISTS (
        SELECT 1
        FROM Concesiones.Concesion C2
        INNER JOIN Concesiones.PagoConcesion PC3 ON PC3.concesion_id = C2.id
        WHERE C2.empresa_id = E.id AND PC3.estado = 'Atrasado'
    )
    FOR XML PATH('Deudor'), ROOT('Deudores');
END;
GO

-- ==========================================
-- REPORTE 4: MATRIZ DE VISITAS (PIVOT POR MES Y PARQUE)
-- ==========================================
CREATE OR ALTER PROCEDURE usp_Reporte_MatrizVisitas
    @Anio INT
AS
BEGIN
    SET NOCOUNT ON;

    WITH VentaParque AS (
        SELECT
            COALESCE(EN.parque_id, AT.parque_id) AS parque_id,
            LV.cantidad,
            DATEPART(MONTH, LV.fecha_acceso) AS mes
        FROM Ventas.LineaVenta LV
        LEFT JOIN Parques.Entrada   EN ON LV.entrada_id   = EN.id
        LEFT JOIN Parques.Atraccion AT ON LV.atraccion_id = AT.id
        WHERE DATEPART(YEAR, LV.fecha_acceso) = @Anio
    )
    SELECT Parque,
           ISNULL([1],  0) AS Ene, ISNULL([2],  0) AS Feb, ISNULL([3],  0) AS Mar,
           ISNULL([4],  0) AS Abr, ISNULL([5],  0) AS May, ISNULL([6],  0) AS Jun,
           ISNULL([7],  0) AS Jul, ISNULL([8],  0) AS Ago, ISNULL([9],  0) AS Sep,
           ISNULL([10], 0) AS Oct, ISNULL([11], 0) AS Nov, ISNULL([12], 0) AS Dic
    FROM (
        SELECT Parque, [1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12]
        FROM (
            SELECT P.nombre AS Parque, VP.mes, VP.cantidad
            FROM Parques.Parque P
            LEFT JOIN VentaParque VP ON VP.parque_id = P.id
        ) AS Origen
        PIVOT (
            SUM(cantidad) FOR mes IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12])
        ) AS Pvt
    ) AS PvtConCeros
    ORDER BY Parque;
END;
GO

-- ==========================================
-- REPORTE 5: PARQUES Y CONCESIONES - XML
-- ==========================================
CREATE OR ALTER PROCEDURE usp_Reporte_ParquesConcesiones
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        P.id        AS '@id',
        P.nombre    AS '@nombre',
        P.ubicacion AS '@ubicacion',
        (
            SELECT
                C.fecha_inicio      AS '@fecha_inicio',
                C.fecha_fin         AS '@fecha_fin',
                EM.razon_social     AS '@titular',
                EM.tipo_actividad   AS '@servicio_prestado',
                C.canon_mensual     AS '@canon_mensual'
            FROM Concesiones.Concesion C
            INNER JOIN Concesiones.Empresa EM ON EM.id = C.empresa_id
            WHERE C.parque_id = P.id
            FOR XML PATH('Concesion'), TYPE
        ) AS Concesiones
    FROM Parques.Parque P
    FOR XML PATH('Parque'), ROOT('ParquesYConcesiones');
END;
GO
