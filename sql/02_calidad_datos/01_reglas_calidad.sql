--Parte A: ¿Los datos son coherentes?

--Regla 1: el total de cada orden debe ser igual a la suma de sus líneas.

USE AdventureWorks2025;

SELECT h.SalesOrderID, h.SubTotal, SUM(d.LineTotal) AS TotalDetalle
FROM Sales.SalesOrderHeader h
JOIN Sales.SalesOrderDetail d ON h.SalesOrderID = d.SalesOrderID
GROUP BY h.SalesOrderID, h.SubTotal
HAVING ABS(h.SubTotal - SUM(d.LineTotal)) > 0.01;

--RESULTADOS: 
SalesOrderID	SubTotal	TotalDetalle

--NOTA: Un resultado de 0, significa que todo está bien

-- Regla 2: las fechas deben tener sentido (no enviar ni vencer antes de pedir).

SELECT COUNT(*) AS FechasIncoherentes
FROM Sales.SalesOrderHeader
WHERE ShipDate < OrderDate OR DueDate < OrderDate;

--RESULTADOS:
FechasIncoherentes
0

--Regla 3: cantidades, precios y descuentos válidos.

SELECT COUNT(*) AS LineasInvalidas
FROM Sales.SalesOrderDetail
WHERE OrderQty <= 0 OR UnitPrice < 0
   OR UnitPriceDiscount < 0 OR UnitPriceDiscount > 1;

--RESULTADOS:

LineasInvalidas
0

--Regla 4 (referencia): tasa de descuento de 2025

SELECT SUM(d.UnitPrice * d.OrderQty) AS VentaBruta,
       SUM(d.UnitPrice * d.UnitPriceDiscount * d.OrderQty) AS Descuento,
       ROUND(100.0 * SUM(d.UnitPrice * d.UnitPriceDiscount * d.OrderQty)
             / SUM(d.UnitPrice * d.OrderQty), 2) AS PctDescuento
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h ON d.SalesOrderID = h.SalesOrderID
WHERE h.OrderDate >= '20250101';

--RESULTADOS:
VentaBruta	Descuento	PctDescuento
20045419,0535	36900,7241	0.180000000000000

--Parte B: Costos históricos (base de la rentabilidad)

--5a: ¿Cómo está el historial?
SELECT COUNT(*) AS Filas,
       COUNT(*) - COUNT(EndDate) AS Vigentes,
       MIN(StartDate) AS PrimerInicio,
       MAX(StartDate) AS UltimoInicio,
       SUM(CASE WHEN StandardCost <= 0 THEN 1 ELSE 0 END) AS CostosInvalidos
FROM Production.ProductCostHistory;

--RESULTADOS:
Filas	Vigentes	PrimerInicio	UltimoInicio	CostosInvalidos
395	195	2022-05-30 00:00:00.000	2024-05-29 00:00:00.000	0

--5b: ¿Hay rangos que se traslapan? Si los hubiera, una venta se contaría dos veces.

SELECT COUNT(*) AS Traslapes
FROM Production.ProductCostHistory a
JOIN Production.ProductCostHistory b
  ON a.ProductID = b.ProductID
 AND a.StartDate < b.StartDate
 AND (a.EndDate IS NULL OR a.EndDate >= b.StartDate);

 --RESULTADOS:
Traslapes
0

--5c: cobertura de costos por año
SELECT YEAR(h.OrderDate) AS Anio,
       COUNT(*) AS Lineas,
       SUM(d.LineTotal) AS Ventas,
       SUM(CASE WHEN c.ProductID IS NULL THEN d.LineTotal ELSE 0 END) AS VentasSinCosto,
       ROUND(100.0 * SUM(CASE WHEN c.ProductID IS NULL THEN 0 ELSE d.LineTotal END)
             / SUM(d.LineTotal), 2) AS PctCobertura
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h ON d.SalesOrderID = h.SalesOrderID
LEFT JOIN Production.ProductCostHistory c
       ON c.ProductID = d.ProductID
      AND h.OrderDate >= c.StartDate
      AND (c.EndDate IS NULL OR h.OrderDate <= c.EndDate)
GROUP BY YEAR(h.OrderDate)
ORDER BY Anio;

--RESULTADOS:
Anio	Lineas	Ventas	VentasSinCosto	PctCobertura
2022	6588	14561051.591512	0.000000	100.000000
2023	20817	31604921.945876	0.000000	100.000000
2024	56721	43671889.501635	28222.619000	99.940000
2025	37191	20008518.360865	8884.603000	99.960000

--5d: ¿Qué productos se venden sin costo?

SELECT d.ProductID, p.Name AS Producto,
       COUNT(*) AS Lineas,
       SUM(d.LineTotal) AS Ventas,
       MIN(h.OrderDate) AS PrimeraVenta,
       MAX(h.OrderDate) AS UltimaVenta
FROM Sales.SalesOrderDetail d
JOIN Sales.SalesOrderHeader h ON d.SalesOrderID = h.SalesOrderID
JOIN Production.Product p ON d.ProductID = p.ProductID
LEFT JOIN Production.ProductCostHistory c
       ON c.ProductID = d.ProductID
      AND h.OrderDate >= c.StartDate
      AND (c.EndDate IS NULL OR h.OrderDate <= c.EndDate)
WHERE c.ProductID IS NULL
GROUP BY d.ProductID, p.Name
ORDER BY Ventas DESC;

--RESULTADOS:
ProductID	Producto	Lineas	Ventas	PrimeraVenta	UltimaVenta
760	Road-650 Red, 60	4	6201.280800	2024-06-29 00:00:00.000	2025-03-29 00:00:00.000
762	Road-650 Red, 44	5	5637.528000	2024-06-29 00:00:00.000	2025-03-29 00:00:00.000
761	Road-650 Red, 62	5	5637.528000	2024-05-29 00:00:00.000	2025-03-29 00:00:00.000
790	Road-250 Red, 48	1	5277.636000	2024-11-29 00:00:00.000	2024-11-29 00:00:00.000
765	Road-650 Black, 58	5	3382.516800	2024-06-29 00:00:00.000	2025-03-29 00:00:00.000
770	Road-650 Black, 52	3	2818.764000	2024-06-29 00:00:00.000	2024-12-30 00:00:00.000
763	Road-650 Red, 48	2	1127.505600	2024-12-30 00:00:00.000	2025-03-29 00:00:00.000
852	Women's Tights, S	4	779.896000	2024-06-29 00:00:00.000	2025-04-29 00:00:00.000
824	ML Mountain Rear Wheel	1	698.634000	2024-07-30 00:00:00.000	2024-07-30 00:00:00.000
856	Men's Bib-Shorts, M	4	584.935000	2024-06-29 00:00:00.000	2025-04-29 00:00:00.000
769	Road-650 Black, 48	1	563.752800	2024-11-29 00:00:00.000	2024-11-29 00:00:00.000
854	Women's Tights, L	4	536.178500	2024-06-29 00:00:00.000	2025-03-29 00:00:00.000
828	HL Road Rear Wheel	1	528.448800	2024-05-29 00:00:00.000	2024-05-29 00:00:00.000
730	LL Road Frame - Red, 62	2	499.085600	2024-06-29 00:00:00.000	2025-03-29 00:00:00.000
726	LL Road Frame - Red, 48	2	499.085600	2024-08-29 00:00:00.000	2025-02-27 00:00:00.000
729	LL Road Frame - Red, 60	1	499.085600	2024-06-29 00:00:00.000	2024-06-29 00:00:00.000
819	ML Road Front Wheel	1	367.609800	2024-06-29 00:00:00.000	2024-06-29 00:00:00.000
863	Full-Finger Gloves, L	3	321.015500	2024-10-29 00:00:00.000	2025-04-29 00:00:00.000
832	ML Mountain Frame - Black, 48	1	258.082400	2024-07-30 00:00:00.000	2024-07-30 00:00:00.000
855	Men's Bib-Shorts, S	2	233.974000	2024-05-29 00:00:00.000	2025-02-27 00:00:00.000
862	Full-Finger Gloves, M	4	222.241500	2024-07-30 00:00:00.000	2025-04-29 00:00:00.000
861	Full-Finger Gloves, S	4	172.854500	2024-07-30 00:00:00.000	2025-04-29 00:00:00.000
826	LL Road Rear Wheel	2	166.596200	2024-06-29 00:00:00.000	2024-09-29 00:00:00.000
849	Men's Sports Shorts, M	1	77.987000	2024-07-30 00:00:00.000	2024-07-30 00:00:00.000
843	Cable Lock	1	15.000000	2024-09-29 00:00:00.000	2024-09-29 00:00:00.000