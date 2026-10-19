# Análisis Comercial y Financiero – AdventureWorks (SQL Server + Power BI)

Solución de Business Intelligence de punta a punta: desde la base transaccional en SQL Server hasta un dashboard interactivo en Power BI, con una vista adicional de **calidad del crecimiento** (Precio – Volumen – Mix).

> 🚧 Proyecto en construcción.

## Preguntas de negocio
- ¿Cómo evolucionan las ventas frente al año anterior?
- ¿Qué territorios, productos y clientes aportan más ingresos y más margen?
- ¿De dónde viene el crecimiento: más volumen, mejor mix de productos, precio o nuevos clientes?
- ¿Qué tan confiables son los indicadores financieros (cobertura de costos)?

## Fuente de datos
- **AdventureWorks2025** (base de datos de ejemplo oficial de Microsoft).
- Descarga: [microsoft/sql-server-samples – AdventureWorks](https://github.com/Microsoft/sql-server-samples/releases/tag/adventureworks)
- ⚠️ AdventureWorks es una empresa **ficticia** con datos **simulados**. Los resultados demuestran la metodología, no describen un mercado real.

## Herramientas
SQL Server 2025 · SQL Server Management Studio (SSMS) · Power BI Desktop · Git y GitHub

## Estructura del repositorio
```
adventureworks-sales-analytics/
├── sql/
│   ├── 01_exploracion/     # Consultas para conocer los datos
│   ├── 02_calidad_datos/   # Reglas y validaciones de calidad
│   └── 03_vistas/          # Vistas limpias que usa Power BI
├── powerbi/                # Archivo .pbix del dashboard
├── docs/                   # Metodología, diccionario de datos, decisiones
├── imagenes/               # Capturas del dashboard
└── datos/                  # Archivos locales (NO se suben a GitHub)
```

## Avance
- [x] Fase 0 – Preparación
- [x] Fase 1 – Obtención y verificación
- [x] Fase 2 – Exploración en SQL
- [x] Fase 3 – Control de calidad
- [x] Fase 4 – Vistas en SQL
- [ ] Fase 5 – Modelado en Power BI
- [ ] Fase 6 – Medidas DAX
- [ ] Fase 7 – Validación cruzada
- [ ] Fase 8 – Diseño del dashboard
- [ ] Fase 9 – Extra opcional (pronóstico)
- [ ] Fase 10 – Publicación

## Autor
JOA
