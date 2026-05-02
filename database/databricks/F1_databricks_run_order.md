# Ejecución de F1 en Databricks desde DBeaver

Usa la conexión de Databricks ya guardada en DBeaver:

- `dbc-27294608-e1ce.cloud.databricks.com`
- catálogo esperado: `workspace`
- esquema base: `f1`

## Opción recomendada

Si quieres ejecutar todo desde un único archivo, usa:

- [`F1_databricks_full_rebuild.sql`](/home/djfa/Dev/DBs%20BackUps/F1_databricks_full_rebuild.sql)

Ese archivo ya consolida:

- esquema base
- carga de CSV
- constraints opcionales
- capa `Silver`
- capa `Gold`

No incluye `Control`, porque esa capa es opcional y se deja aparte para no bloquear la reconstrucción principal en DBeaver.

## Orden de ejecución

1. [`F1_databricks_schema.sql`](/home/djfa/Dev/DBs%20BackUps/F1_databricks_schema.sql)
2. [`F1_databricks_load.sql`](/home/djfa/Dev/DBs%20BackUps/F1_databricks_load.sql)
3. [`F1_databricks_constraints.sql`](/home/djfa/Dev/DBs%20BackUps/F1_databricks_constraints.sql)
   Usa este paso solo si tu entorno soporta constraints informativas en Unity Catalog.
4. [`F1_databricks_silver.sql`](/home/djfa/Dev/DBs%20BackUps/F1_databricks_silver.sql)
5. [`F1_databricks_gold.sql`](/home/djfa/Dev/DBs%20BackUps/F1_databricks_gold.sql)
6. [`F1_databricks_control.sql`](/home/djfa/Dev/DBs%20BackUps/F1_databricks_control.sql)
   Este paso es opcional. Solo sirve para guardar snapshots de KPIs.

## Qué crea cada archivo

- `F1_databricks_schema.sql`
  - crea la capa `f1`
  - define las tablas base
- `F1_databricks_load.sql`
  - carga los CSV en las tablas base
- `F1_databricks_silver.sql`
  - crea `f1_silver`
  - incluye `dim_seasons`, `fact_constructor_results`, `fact_race_entries`
- `F1_databricks_gold.sql`
  - crea `f1_gold`
  - materializa marts, KPIs y vistas ejecutivas
- `F1_databricks_control.sql`
  - crea `f1_control`
  - guarda snapshots de KPIs

## Validación mínima esperada

Después de ejecutar `Silver`:

```sql
SELECT * FROM f1_silver.vw_silver_summary;
SELECT * FROM f1_silver.vw_data_quality_checks;
```

Después de ejecutar `Gold`:

```sql
SELECT * FROM f1_gold.vw_dashboard_kpi_cards;
SELECT COUNT(*) AS mart_driver_season_rows FROM f1_gold.mart_driver_season;
SELECT COUNT(*) AS mart_constructor_season_rows FROM f1_gold.mart_constructor_season;
SELECT COUNT(*) AS mart_race_weekend_rows FROM f1_gold.mart_race_weekend;
```

## Nota importante

En `F1_databricks_load.sql` debes revisar la ruta de los CSV antes de correrlo, porque Databricks no va a leer tu ruta local de Linux directamente. Debe apuntar a un volumen o ubicación accesible desde Databricks.
