Columna de vw_FactVentas |   Qué es
SalesOrderID, SalesOrderDetailID    |	Orden y línea (cada fila es una línea de venta)
Fecha |	Fecha de la venta
CustomerID, ProductID, TerritoryID, SalesPersonID | Llaves hacia las dimensiones (0 = sin vendedor, ventas online)
Canal |	Online o Tienda
Cantidad, PrecioUnitario |	Unidades y precio de lista de la línea
VentaBruta, Descuento, VentaNeta |	Venta sin descuento, descuento y venta neta (≈ bruta − descuento)
CostoUnitario, CostoTotal |	Costo estándar vigente en la fecha de venta (vacío si no hay)
VentaConCosto |	Venta neta de las líneas con costo; es la base del margen


