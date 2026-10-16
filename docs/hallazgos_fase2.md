--Paso 1: Mirar las tablas clave

USE AdventureWorks2025;

SELECT TOP 5 * FROM Sales.SalesOrderHeader;
SELECT TOP 5 * FROM Sales.SalesOrderDetail;
SELECT TOP 5 * FROM Production.Product;
SELECT TOP 5 * FROM Production.ProductSubcategory;
SELECT TOP 5 * FROM Production.ProductCategory;
SELECT TOP 5 * FROM Production.ProductCostHistory;
SELECT TOP 5 * FROM Sales.Customer;
SELECT TOP 5 * FROM Sales.Store;
SELECT TOP 5 * FROM Sales.SalesTerritory;
SELECT TOP 5 * FROM Sales.SalesPerson;


--Paso 2: Cómo se conectan

SalesOrderHeader --SalesOrderID--> SalesOrderDetail
SalesOrderDetail --ProductID--> Product --ProductSubcategoryID--> ProductSubcategory --ProductCategoryID--> ProductCategory
Product --ProductID--> ProductCostHistory (costo por rango de fechas)
SalesOrderHeader --CustomerID--> Customer --StoreID--> Store
                                          --PersonID--> Person
SalesOrderHeader --TerritoryID--> SalesTerritory
SalesOrderHeader --SalesPersonID--> SalesPerson

--Paso 3: Canal y tipo de cliente

SELECT h.OnlineOrderFlag,
       CASE WHEN c.StoreID IS NULL THEN 'Retail' ELSE 'Store' END AS TipoCliente,
       COUNT(*) AS Ordenes,
       SUM(h.SubTotal) AS Ventas
FROM Sales.SalesOrderHeader h
JOIN Sales.Customer c ON h.CustomerID = c.CustomerID
GROUP BY h.OnlineOrderFlag,
         CASE WHEN c.StoreID IS NULL THEN 'Retail' ELSE 'Store' END;

--RESULTADOS:
OnlineOrderFlag	TipoCliente	Ordenes	Ventas
0	Store	3806	80487704,1832
1	Retail	27659	29358677,2207

--Paso 4: Canal por mes (el salto de julio 2024)

SELECT YEAR(OrderDate) AS Anio,
	MONTH(OrderDate) AS Mes,
	OnlineOrderFlag,
	COUNT(*) AS Ordenes,
	SUM(SubTotal) AS Ventas,
	SUM(Subtotal)/COUNT(*) AS TicketPromedio
FROM Sales.SalesOrderHeader

WHERE OrderDate >= '20240101'
GROUP BY YEAR(OrderDate), MONTH(OrderDate), OnlineOrderFlag
ORDER BY Anio, Mes, OnlineOrderFlag;

--RESULTADOS:
Anio	Mes	OnlineOrderFlag	Ordenes	Ventas	TicketPromedio
2024	1	0	106	1563955,0808	14754,2932
2024	1	1	294	523917,3815	1782,0319
2024	2	0	74	1865278,434	25206,4653
2024	2	1	264	477981,7995	1810,5371
2024	3	0	134	2880752,6805	21498,1543
2024	3	1	309	526284,7311	1703,1868
2024	4	0	102	1987872,7063	19488,9481
2024	4	1	324	545184,7045	1682,6688
2024	5	0	95	2667423,4773	28078,1418
2024	5	1	341	590917,6534	1732,8963
2024	6	0	186	4220928,0019	22693,1613
2024	6	1	555	842870,38	1518,6853
2024	7	0	176	4049215,0886	23006,9039
2024	7	1	1579	869365,10	550,5795
2024	8	0	99	2284056,6777	23071,2795
2024	8	1	1686	1041239,42	617,5797
2024	9	0	179	3486885,9354	19479,8096
2024	9	1	1617	1052943,06	651,1707
2024	10	0	176	3511220,3598	19950,1156
2024	10	1	1795	1309504,97	729,5292
2024	11	0	96	1668952,4657	17384,9215
2024	11	1	2004	1622285,82	809,5238
2024	12	0	175	2703810,8157	15450,3475
2024	12	1	1878	1379042,76	734,3145
2025	1	0	175	2738752,3914	15650,0136
2025	1	1	1961	1537675,33	784,1281
2025	2	0	94	2207772,4933	23486,9414
2025	2	1	1763	1358106,83	770,3385
2025	3	0	180	3321810,3343	18454,5018
2025	3	1	2124	1666091,20	784,412
2025	4	0	181	3416763,8623	18877,1484
2025	4	1	2098	1805994,88	860,8173
2025	5	1	2218	1908059,49	860,2612
2025	6	1	905	47491,55	52,4768


--Paso 5: Categorías por mes en 2025

SELECT YEAR(h.OrderDate) AS Anio,
       MONTH(h.OrderDate) AS Mes,
       pc.Name AS Categoria,
       SUM(d.LineTotal) AS Ventas,
       SUM(d.OrderQty) AS Unidades
FROM Sales.SalesOrderHeader h
JOIN Sales.SalesOrderDetail d ON h.SalesOrderID = d.SalesOrderID
JOIN Production.Product p ON d.ProductID = p.ProductID
JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE h.OrderDate >= '20250101'
GROUP BY YEAR(h.OrderDate), MONTH(h.OrderDate), pc.Name
ORDER BY Anio, Mes, Categoria;

--RESULTADOS: 
Anio	Mes	Categoria	Ventas	Unidades
2025	1	Accessories	79007.490580	3879
2025	1	Bikes	3879589.620999	3663
2025	1	Clothing	84263.617374	2703
2025	1	Components	233566.992000	1219
2025	2	Accessories	82302.503188	3988
2025	2	Bikes	3063065.451419	2871
2025	2	Clothing	91893.799271	3112
2025	2	Components	328617.569392	1465
2025	3	Accessories	106383.082659	5005
2025	3	Bikes	4233511.437992	4116
2025	3	Clothing	118316.973765	3977
2025	3	Components	529690.039888	2344
2025	4	Accessories	106831.022716	4923
2025	4	Bikes	4423689.584414	4225
2025	4	Clothing	114385.784508	3836
2025	4	Components	577852.350700	2555
2025	5	Accessories	66024.120000	3471
2025	5	Bikes	1806581.360000	1160
2025	5	Clothing	35454.010000	952
2025	6	Accessories	31591.320000	1639
2025	6	Clothing	15900.230000	408

--Paso 6: Rango del historial de costos

SELECT MIN(StartDate) AS Desde,
       MAX(EndDate) AS Hasta,
       COUNT(*) AS Filas,
       COUNT(DISTINCT ProductID) AS Productos
FROM Production.ProductCostHistory;

--RESULTADOS:
Desde	Hasta	Filas	Productos
2022-05-30 00:00:00.000	2024-05-28 00:00:00.000	395	293

--Paso 7: Perfilado básico

-- a) Estados de las órdenes (¿hay canceladas?)
SELECT Status, COUNT(*) AS Ordenes
FROM Sales.SalesOrderHeader
GROUP BY Status;

--RESULTADOS:
Status	Ordenes
5	31465

-- b) Órdenes sin territorio o sin vendedor
SELECT COUNT(*) AS Total,
       COUNT(*) - COUNT(TerritoryID) AS SinTerritorio,
       COUNT(*) - COUNT(SalesPersonID) AS SinVendedor
FROM Sales.SalesOrderHeader;

Total	SinTerritorio	SinVendedor
31465	0	27659

-- c) Órdenes sin líneas de detalle
SELECT COUNT(*) AS OrdenesSinDetalle
FROM Sales.SalesOrderHeader h
LEFT JOIN Sales.SalesOrderDetail d ON h.SalesOrderID = d.SalesOrderID
WHERE d.SalesOrderID IS NULL;

--RESULTADOS:

OrdenesSinDetalle
0