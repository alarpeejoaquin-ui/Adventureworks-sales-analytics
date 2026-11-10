# Validación cruzada – Fase 7

**Proyecto:** Análisis Comercial y Financiero – AdventureWorks2025 (SQL Server + Power BI)
**Autor:** JOA · **Fecha:** 10-nov-2026
**Consultas usadas:** `sql/04_validacion/01_validacion_kpis.sql`

## 1. Resultado general

| Prueba | Qué valida | Resultado |
|---|---|---|
| 7.1 | 18 indicadores por año y total (SQL vs Power BI) | ✅ Coinciden |
| 7.2 | Relaciones del modelo: categoría, tipo de cliente, territorio, vendedor | ✅ Coinciden, sin filas en blanco |
| 7.3 | Puentes de crecimiento (producto y cliente) 2023, 2024 y 2025 | ✅ Coinciden |
| 7.4 | Controles de los puentes bajo filtros de canal y categoría | ✅ Controles en $0 |
| 7.5 | Diferencia entre nuestro YoY y el del dashboard original | ✅ Explicada y reproducida |

## 2. Método

- **Fuente de verdad:** la vista `dbo.vw_FactVentas` de SQL Server, consultada directamente en SSMS.
- **Comparación:** cada cifra de Power BI se contrasta con la consulta SQL equivalente.
- **Tolerancia:** solo el redondeo de visualización (±$1 en montos; 2 decimales en porcentajes).
- **Datos:** AdventureWorks es una empresa ficticia con datos simulados. Los resultados demuestran la metodología, no describen un mercado real.

## 3. Prueba 7.1 – KPI por año

Valores de SQL; Power BI muestra los mismos redondeados.

| Indicador | 2022 | 2023 | 2024 | 2025 | Total |
|---|---:|---:|---:|---:|---:|
| Venta neta | 14.561.051,59 | 31.604.921,95 | 43.671.889,50 | 20.008.518,36 | 109.846.381,40 |
| Venta bruta | 14.565.499,15 | 31.791.509,95 | 43.971.461,16 | 20.045.419,05 | 110.373.889,31 |
| Descuento | 4.447,57 | 186.588,02 | 299.571,63 | 36.900,72 | 527.507,94 |
| Tasa de descuento | 0,03% | 0,59% | 0,68% | 0,18% | 0,48% |
| Líneas de venta | 6.588 | 20.817 | 56.721 | 37.191 | 121.317 |
| Órdenes | 1.692 | 3.830 | 14.244 | 11.699 | 31.465 |
| Unidades | 15.026 | 66.441 | 131.936 | 61.511 | 274.914 |
| Ticket promedio | 8.605,82 | 8.251,94 | 3.065,98 | 1.710,28 | 3.491,07 |
| Clientes activos | 1.412 | 3.155 | 11.145 | 10.303 | 19.119 |
| Clientes online | 1.207 | 2.737 | 10.591 | 9.847 | 18.484 |
| Clientes tienda | 205 | 418 | 554 | 456 | 635 |
| Participación online | 26,66% | 20,16% | 24,69% | 41,60% | 26,73% |
| Costo estándar histórico | 12.579.881,21 | 28.657.049,85 | 39.441.787,22 | 16.579.189,67 | 97.257.907,95 |
| Venta con costo | 14.561.051,59 | 31.604.921,95 | 43.643.666,88 | 19.999.633,76 | 109.809.274,18 |
| Utilidad bruta | 1.981.170,38 | 2.947.872,09 | 4.201.879,66 | 3.420.444,09 | 12.551.366,22 |
| Margen bruto | 13,61% | 9,33% | 9,63% | 17,10% | 11,43% |
| Cobertura de costos | 100,00% | 100,00% | 99,94% | 99,96% | 99,97% |
| Venta sin costo | 0,00 | 0,00 | 28.222,62 | 8.884,60 | 37.107,22 |

**Chequeos internos**
- Las cuatro filas anuales suman el total en venta neta, líneas, órdenes, unidades y costo.
- Los clientes únicos del total (19.119) no suman las filas anuales, porque un mismo cliente compra en varios años. Es lo esperado.
- `Venta bruta − Descuento` difiere de `Venta neta` en unos 3 centavos por año, porque `LineTotal` viene redondeado desde AdventureWorks. No afecta ningún resultado.

## 4. Prueba 7.2 – Relaciones del modelo

Se usó `LEFT JOIN` desde la tabla de hechos a cada dimensión. Ninguna venta quedó sin pareja ("SIN COINCIDENCIA" no apareció) y Power BI no muestra filas "(En blanco)".

| Dimensión | Valor | Venta neta (SQL) | Órdenes |
|---|---|---:|---:|
| Categoría | Bikes | 94.651.172,70 | 18.368 |
| | Components | 11.802.593,29 | 2.650 |
| | Clothing | 2.120.542,52 | 9.877 |
| | Accessories | 1.272.072,88 | 19.524 |
| Tipo de cliente | Store | 80.487.704,18 | 3.806 |
| | Retail | 29.358.677,22 | 27.659 |
| Grupo de territorio | North America | 79.353.361,16 | 16.108 |
| | Europe | 19.837.684,28 | 8.514 |
| | Pacific | 10.655.335,96 | 6.843 |

- Las categorías suman $109.846.381,39. Sus órdenes suman más de 31.465 porque una orden puede incluir productos de varias categorías; el total de Power BI usa conteo distinto y da 31.465.
- Los 17 vendedores coinciden uno por uno con SQL. Suman $80.487.705 y 3.806 órdenes, exactamente lo de Store. El resto (Online) es "Sin vendedor (Online)": $29.358.677 y 27.659 órdenes, igual que Retail.

## 5. Prueba 7.3 – Puentes de crecimiento

Valores de SQL. Cada fila de Power BI coincide con redondeo y su control (variación total menos suma de piezas) es $0.

**Puente por producto** (año vs año anterior; 2025 = ene-abr vs ene-abr 2024)

| Pieza | 2023 vs 2022 | 2024 vs 2023 | 2025 vs 2024 |
|---|---:|---:|---:|
| Variación total | 17.043.870,35 | 12.066.967,56 | 7.681.739,80 |
| Volumen | 14.548.453,85 | −1.584.332,84 | −434.550,96 |
| Mix | −14.397.474,91 | 855.100,68 | −239.366,56 |
| Precio | −168.208,81 | 2.930.038,42 | 1.292.953,37 |
| Productos nuevos | 17.061.100,22 | 17.461.659,58 | 10.070.755,78 |
| Productos descontinuados | 0,00 | −7.595.498,28 | −3.008.051,84 |

**Puente por cliente**

| Pieza | 2023 vs 2022 | 2024 vs 2023 | 2025 vs 2024 |
|---|---:|---:|---:|
| Clientes nuevos | 17.879.911,92 | 17.607.710,25 | 10.486.469,16 |
| Clientes perdidos | −3.884.805,15 | −4.372.106,42 | −2.580.275,90 |
| Retenidos que crecieron | 5.831.437,55 | 5.495.106,10 | 1.651.153,60 |
| Retenidos que cayeron | −2.782.673,96 | −6.663.742,37 | −1.875.607,06 |

## 6. Prueba 7.4 – Controles con filtros

| Filtro | Años probados | Controles |
|---|---|---|
| Canal = Online | 2023, 2024, 2025 | $0 |
| Canal = Tienda | 2023, 2024, 2025 | $0 |
| Categoría = Bikes | 2023, 2024, 2025 | $0 |
| Online + Bikes | 2023, 2024, 2025 | $0 |
| Online + Accessories | – | Sin resultados (esperado, ver abajo) |

**Comprobación cruzada (2025):** Online $4.294.500 + Tienda $3.387.240 = $7.681.740, igual a la variación sin filtro. En 2023 y 2024 también suman la variación total.

**Online + Accessories vacío:** Online vendió accesorios por primera vez el 29-may-2024 (2024: $354.557,53; 2025: $346.202,43; sin ventas en 2022 ni 2023). Sin ventas en el periodo anterior no hay base de comparación, y la variación queda en blanco por diseño.

## 7. Prueba 7.5 – La diferencia con el dashboard original

El dashboard original mostraba un crecimiento de ventas de +7,14% (ene-jun 2025). Nuestra primera comparación daba +7,04%.

| Comparación | Ventas | Órdenes | Ticket |
|---|---:|---:|---:|
| 2025 (ene-30 jun) vs 2024 (ene-30 jun) | +7,04% | +320,22% | −74,53% |
| 2025 (ene-30 jun) vs 2024 (ene-**29 jun**) | **+7,14%** | **+326,82%** | **−74,90%** |
| Dashboard original | +7,14% | +326,82% | −74,90% |

**Conclusión:** el original comparó ene-jun 2025 con ene-29 jun 2024, es decir, recortó el año anterior en la misma fecha de la última venta (29-jun). Reproducimos sus tres cifras exactas.

Ese +7,14% mezcla meses completos de 2024 con meses incompletos de 2025 (may-jun), por lo que subestima el crecimiento. Este proyecto compara solo el **periodo comparable** (hasta el 30-abr-2025): **+74,07%** en ventas.

## 8. Limitaciones conocidas

1. **2022 es un año parcial.** Los datos empiezan el 30-may-2022. La variación 2023 vs 2022 compara 12 meses contra unos 7, así que no debe leerse como crecimiento real.
2. **Fila Total de las medidas comparativas.** No es comparable (mezcla años sin año anterior); no se usa en el dashboard.
3. **Variación en blanco.** Si el periodo anterior no tiene ventas, la variación queda en blanco (sin base de comparación).
4. **"Producto nuevo".** Significa que no se vendió en el periodo anterior, no que sea un lanzamiento.
5. **Volumen y Mix** deben leerse juntos: en 2023 se compensan casi por completo (+14,5 M y −14,4 M).
6. **Margen:** se calcula solo sobre ventas con costo (cobertura 99,97%).
7. **Datos simulados:** los resultados demuestran la metodología, no un mercado real.
