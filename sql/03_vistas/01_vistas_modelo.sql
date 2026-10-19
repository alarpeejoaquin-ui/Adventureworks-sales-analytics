--Paso 1: Crear las vistas
USE AdventureWorks2025;
GO

-- 1) Tabla de hechos: una fila por linea de venta
CREATE VIEW dbo.vw_FactVentas AS
SELECT d.SalesOrderID,
       d.SalesOrderDetailID,
       CAST(h.OrderDate AS DATE) AS Fecha,
       h.CustomerID,
       d.ProductID,
       h.TerritoryID,
       ISNULL(h.SalesPersonID, 0) AS SalesPersonID,
       CASE WHEN h.OnlineOrderFlag = 1 THEN 'Online' ELSE 'Tienda' END AS Canal,
       d.OrderQty AS Cantidad,
       d.UnitPrice AS PrecioUnitario,
       d.UnitPrice * d.OrderQty AS VentaBruta,
       d.UnitPrice * d.UnitPriceDiscount * d.OrderQty AS Descuento,
       d.LineTotal AS VentaNeta,
       c.StandardCost AS CostoUnitario,
       c.StandardCost * d.OrderQty AS CostoTotal,
       CASE WHEN c.ProductID IS NULL THEN 0 ELSE d.LineTotal END AS VentaConCosto
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h ON d.SalesOrderID = h.SalesOrderID
LEFT JOIN Production.ProductCostHistory c
       ON c.ProductID = d.ProductID
      AND h.OrderDate >= c.StartDate
      AND (c.EndDate IS NULL OR h.OrderDate <= c.EndDate);
GO

-- 2) Dimension producto
CREATE VIEW dbo.vw_DimProducto AS
SELECT p.ProductID,
       p.Name AS Producto,
       ISNULL(ps.Name, 'Sin subcategoria') AS Subcategoria,
       ISNULL(pc.Name, 'Sin categoria') AS Categoria
FROM Production.Product p
LEFT JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
LEFT JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID;
GO

-- 3) Dimension cliente (incluye la fecha de su primera compra)
CREATE VIEW dbo.vw_DimCliente AS
SELECT c.CustomerID,
       CASE WHEN c.StoreID IS NULL THEN 'Retail' ELSE 'Store' END AS TipoCliente,
       CASE WHEN c.StoreID IS NULL THEN p.FirstName + ' ' + p.LastName
            ELSE s.Name END AS NombreCliente,
       o.FechaPrimeraCompra
FROM Sales.Customer c
LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN (SELECT CustomerID,
                  MIN(CAST(OrderDate AS DATE)) AS FechaPrimeraCompra
           FROM Sales.SalesOrderHeader
           GROUP BY CustomerID) o
       ON c.CustomerID = o.CustomerID;
GO

-- 4) Dimension territorio
CREATE VIEW dbo.vw_DimTerritorio AS
SELECT t.TerritoryID,
       t.Name AS Territorio,
       cr.Name AS Pais,
       t.[Group] AS GrupoTerritorio
FROM Sales.SalesTerritory t
LEFT JOIN Person.CountryRegion cr ON t.CountryRegionCode = cr.CountryRegionCode;
GO

-- 5) Dimension vendedor (0 = ventas online, que no tienen vendedor)
CREATE VIEW dbo.vw_DimVendedor AS
SELECT sp.BusinessEntityID AS SalesPersonID,
       p.FirstName + ' ' + p.LastName AS Vendedor
FROM Sales.SalesPerson sp
JOIN Person.Person p ON sp.BusinessEntityID = p.BusinessEntityID
UNION ALL
SELECT 0, 'Sin vendedor (Online)';
GO

--Paso 2: Verificar
--a) Totales de la tabla de hechos
SELECT COUNT(*) AS Lineas,
       SUM(VentaNeta) AS VentaNeta,
       SUM(VentaNeta) - SUM(VentaConCosto) AS VentaSinCosto,
       MIN(Fecha) AS Desde,
       MAX(Fecha) AS Hasta
FROM dbo.vw_FactVentas;

--RESULTADOS: 
Lineas	VentaNeta	VentaSinCosto	Desde	Hasta
121317	109846381.399888	37107.222000	2022-05-30	2025-06-29

b) Integridad: ninguna venta debe quedar huérfana ni duplicarse
SELECT COUNT(*) AS Filas,
       SUM(CASE WHEN p.ProductID IS NULL THEN 1 ELSE 0 END) AS SinProducto,
       SUM(CASE WHEN c.CustomerID IS NULL THEN 1 ELSE 0 END) AS SinCliente,
       SUM(CASE WHEN t.TerritoryID IS NULL THEN 1 ELSE 0 END) AS SinTerritorio,
       SUM(CASE WHEN v.SalesPersonID IS NULL THEN 1 ELSE 0 END) AS SinVendedor
FROM dbo.vw_FactVentas f
LEFT JOIN dbo.vw_DimProducto p ON f.ProductID = p.ProductID
LEFT JOIN dbo.vw_DimCliente c ON f.CustomerID = c.CustomerID
LEFT JOIN dbo.vw_DimTerritorio t ON f.TerritoryID = t.TerritoryID
LEFT JOIN dbo.vw_DimVendedor v ON f.SalesPersonID = v.SalesPersonID;

--RESULTADOS:
Filas	SinProducto	SinCliente	SinTerritorio	SinVendedor
121317	0	0	0	0


