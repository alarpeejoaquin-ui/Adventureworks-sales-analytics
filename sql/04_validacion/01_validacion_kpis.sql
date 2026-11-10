-- =====================================================================
-- Fase 7 - Validacion cruzada (SQL vs Power BI)
-- Fuente: dbo.vw_FactVentas (AdventureWorks2025)
-- Ejecutar cada bloque por separado (seleccionar y F5)
-- =====================================================================

-- 7.1 KPI por anio (la fila con Anio = NULL es el Total)
SELECT
    YEAR(Fecha) AS Anio,
    SUM(VentaNeta) AS VentaNeta,
    SUM(VentaBruta) AS VentaBruta,
    SUM(Descuento) AS Descuento,
    CAST(SUM(Descuento) AS FLOAT) / SUM(VentaBruta) AS TasaDescuento,
    COUNT(*) AS Lineas,
    COUNT(DISTINCT SalesOrderID) AS Ordenes,
    SUM(Cantidad) AS Unidades,
    SUM(VentaNeta) / COUNT(DISTINCT SalesOrderID) AS Ticket,
    COUNT(DISTINCT CustomerID) AS Clientes,
    COUNT(DISTINCT CASE WHEN Canal = 'Online' THEN CustomerID END) AS ClientesOnline,
    COUNT(DISTINCT CASE WHEN Canal = 'Tienda' THEN CustomerID END) AS ClientesTienda,
    CAST(SUM(CASE WHEN Canal = 'Online' THEN VentaNeta ELSE 0 END) AS FLOAT) / SUM(VentaNeta) AS ParticipacionOnline,
    SUM(CostoTotal) AS Costo,
    SUM(VentaConCosto) AS VentaConCosto,
    SUM(VentaConCosto) - SUM(CostoTotal) AS Utilidad,
    CAST(SUM(VentaConCosto) - SUM(CostoTotal) AS FLOAT) / SUM(VentaConCosto) AS Margen,
    CAST(SUM(VentaConCosto) AS FLOAT) / SUM(VentaNeta) AS Cobertura,
    SUM(VentaNeta) - SUM(VentaConCosto) AS VentaSinCosto
FROM dbo.vw_FactVentas
GROUP BY ROLLUP(YEAR(Fecha))
ORDER BY Anio;

-- 7.2a Por categoria
SELECT ISNULL(p.Categoria, 'SIN COINCIDENCIA') AS Categoria,
       SUM(v.VentaNeta) AS VentaNeta,
       COUNT(DISTINCT v.SalesOrderID) AS Ordenes,
       CAST(SUM(v.VentaConCosto) - SUM(v.CostoTotal) AS FLOAT) / SUM(v.VentaConCosto) AS Margen
FROM dbo.vw_FactVentas v
LEFT JOIN dbo.vw_DimProducto p ON p.ProductID = v.ProductID
GROUP BY p.Categoria
ORDER BY VentaNeta DESC;

-- 7.2b Por tipo de cliente
SELECT ISNULL(c.TipoCliente, 'SIN COINCIDENCIA') AS TipoCliente,
       SUM(v.VentaNeta) AS VentaNeta,
       COUNT(DISTINCT v.SalesOrderID) AS Ordenes
FROM dbo.vw_FactVentas v
LEFT JOIN dbo.vw_DimCliente c ON c.CustomerID = v.CustomerID
GROUP BY c.TipoCliente
ORDER BY VentaNeta DESC;

-- 7.2c Por grupo de territorio
SELECT ISNULL(t.GrupoTerritorio, 'SIN COINCIDENCIA') AS GrupoTerritorio,
       SUM(v.VentaNeta) AS VentaNeta,
       COUNT(DISTINCT v.SalesOrderID) AS Ordenes
FROM dbo.vw_FactVentas v
LEFT JOIN dbo.vw_DimTerritorio t ON t.TerritoryID = v.TerritoryID
GROUP BY t.GrupoTerritorio
ORDER BY VentaNeta DESC;

-- 7.2d Por vendedor
SELECT ISNULL(s.Vendedor, 'SIN COINCIDENCIA') AS Vendedor,
       SUM(v.VentaNeta) AS VentaNeta,
       COUNT(DISTINCT v.SalesOrderID) AS Ordenes
FROM dbo.vw_FactVentas v
LEFT JOIN dbo.vw_DimVendedor s ON s.SalesPersonID = v.SalesPersonID
GROUP BY s.Vendedor
ORDER BY VentaNeta DESC;

-- 7.3 Puentes producto y cliente (seleccionar TODO el bloque; cambiar fechas por anio)
DECLARE @Ini0 DATE = '2023-01-01', @Fin0 DATE = '2023-12-31';  -- periodo anterior
DECLARE @Ini1 DATE = '2024-01-01', @Fin1 DATE = '2024-12-31';  -- periodo actual

WITH Prod AS (
    SELECT
        ProductID,
        CAST(SUM(CASE WHEN Fecha BETWEEN @Ini0 AND @Fin0 THEN Cantidad ELSE 0 END) AS FLOAT) AS U0,
        CAST(SUM(CASE WHEN Fecha BETWEEN @Ini0 AND @Fin0 THEN VentaNeta ELSE 0 END) AS FLOAT) AS V0,
        CAST(SUM(CASE WHEN Fecha BETWEEN @Ini1 AND @Fin1 THEN Cantidad ELSE 0 END) AS FLOAT) AS U1,
        CAST(SUM(CASE WHEN Fecha BETWEEN @Ini1 AND @Fin1 THEN VentaNeta ELSE 0 END) AS FLOAT) AS V1
    FROM dbo.vw_FactVentas
    GROUP BY ProductID
),
Tot AS (
    SELECT SUM(U0) AS TU0, SUM(U1) AS TU1, SUM(V0) AS TV0
    FROM Prod
    WHERE U0 > 0 AND U1 > 0
)
SELECT
    SUM(p.V1) - SUM(p.V0) AS VarTotal,
    MAX((t.TU1 - t.TU0) * t.TV0 / t.TU0) AS Volumen,
    SUM(CASE WHEN p.U0 > 0 AND p.U1 > 0 THEN (p.U1 - t.TU1 * p.U0 / t.TU0) * p.V0 / p.U0 ELSE 0 END) AS Mix,
    SUM(CASE WHEN p.U0 > 0 AND p.U1 > 0 THEN p.V1 - p.U1 * p.V0 / p.U0 ELSE 0 END) AS Precio,
    SUM(CASE WHEN p.U0 = 0 AND p.U1 > 0 THEN p.V1 ELSE 0 END) AS Nuevos,
    -SUM(CASE WHEN p.U1 = 0 AND p.U0 > 0 THEN p.V0 ELSE 0 END) AS Descontinuados
FROM Prod p
CROSS JOIN Tot t;

WITH Cli AS (
    SELECT
        CustomerID,
        SUM(CASE WHEN Fecha BETWEEN @Ini0 AND @Fin0 THEN VentaNeta ELSE 0 END) AS V0,
        SUM(CASE WHEN Fecha BETWEEN @Ini1 AND @Fin1 THEN VentaNeta ELSE 0 END) AS V1
    FROM dbo.vw_FactVentas
    GROUP BY CustomerID
)
SELECT
    SUM(V1) - SUM(V0) AS VarTotal,
    SUM(CASE WHEN V0 = 0 AND V1 > 0 THEN V1 ELSE 0 END) AS Nuevos,
    -SUM(CASE WHEN V1 = 0 AND V0 > 0 THEN V0 ELSE 0 END) AS Perdidos,
    SUM(CASE WHEN V0 > 0 AND V1 > V0 THEN V1 - V0 ELSE 0 END) AS Expansion,
    SUM(CASE WHEN V0 > 0 AND V1 > 0 AND V1 < V0 THEN V1 - V0 ELSE 0 END) AS Contraccion
FROM Cli;

-- 7.4 Ventas Online de Accessories por anio (explica la prueba vacia)
SELECT
    YEAR(v.Fecha) AS Anio,
    MIN(v.Fecha) AS PrimeraVenta,
    MAX(v.Fecha) AS UltimaVenta,
    SUM(v.VentaNeta) AS VentaNeta
FROM dbo.vw_FactVentas v
JOIN dbo.vw_DimProducto p ON p.ProductID = v.ProductID
WHERE v.Canal = 'Online' AND p.Categoria = 'Accessories'
GROUP BY YEAR(v.Fecha)
ORDER BY Anio;

-- 7.5 Prueba del YoY del dashboard original
SELECT
    Corte,
    CAST(V1 AS FLOAT) / V0 - 1 AS CrecVentas,
    CAST(O1 AS FLOAT) / O0 - 1 AS CrecOrdenes,
    (CAST(V1 AS FLOAT) / O1) / (CAST(V0 AS FLOAT) / O0) - 1 AS CrecTicket
FROM (
    SELECT
        '2024 hasta 30-jun' AS Corte,
        SUM(CASE WHEN Fecha BETWEEN '2025-01-01' AND '2025-06-30' THEN VentaNeta END) AS V1,
        SUM(CASE WHEN Fecha BETWEEN '2024-01-01' AND '2024-06-30' THEN VentaNeta END) AS V0,
        COUNT(DISTINCT CASE WHEN Fecha BETWEEN '2025-01-01' AND '2025-06-30' THEN SalesOrderID END) AS O1,
        COUNT(DISTINCT CASE WHEN Fecha BETWEEN '2024-01-01' AND '2024-06-30' THEN SalesOrderID END) AS O0
    FROM dbo.vw_FactVentas
    UNION ALL
    SELECT
        '2024 hasta 29-jun',
        SUM(CASE WHEN Fecha BETWEEN '2025-01-01' AND '2025-06-30' THEN VentaNeta END),
        SUM(CASE WHEN Fecha BETWEEN '2024-01-01' AND '2024-06-29' THEN VentaNeta END),
        COUNT(DISTINCT CASE WHEN Fecha BETWEEN '2025-01-01' AND '2025-06-30' THEN SalesOrderID END),
        COUNT(DISTINCT CASE WHEN Fecha BETWEEN '2024-01-01' AND '2024-06-29' THEN SalesOrderID END)
    FROM dbo.vw_FactVentas
) x;
