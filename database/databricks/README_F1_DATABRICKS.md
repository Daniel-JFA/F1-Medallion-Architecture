# Databricks SQL

Esta carpeta contiene la version canonica del proyecto.

## Archivos Activos

1. `F1_databricks_schema.sql`
2. `F1_databricks_load.sql`
3. `F1_databricks_constraints.sql`
4. `F1_databricks_silver.sql`
5. `F1_databricks_gold.sql`
6. `F1_databricks_gold_star.sql`
7. `F1_databricks_control.sql`

`F1_databricks_hive_metastore.sql` queda como alternativa para workspaces sin Unity Catalog.

## Gold

`F1_databricks_gold.sql` crea:

- marts ejecutivos: `mart_*`
- catalogo y snapshot de KPIs
- vistas `vw_dashboard_*`

## Gold Star

`F1_databricks_gold_star.sql` crea el esquema separado `f1_gold_star` con tablas dimensionales fisicas para BI:

- `dim_*`
- `fact_*`

Se alimenta desde `f1_gold`, no desde `f1_silver`.

## Ejecucion Rapida

Si la capa base `f1` ya existe:

```bash
export DATABRICKS_TOKEN='...'
python tools/run_databricks_sql.py
unset DATABRICKS_TOKEN
```

Si necesitas cargar desde cero, primero ejecuta `schema`, `load` y opcionalmente `constraints`.
