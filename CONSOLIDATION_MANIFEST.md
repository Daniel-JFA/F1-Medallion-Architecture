# Consolidation Manifest

El proyecto local quedo reducido a los artefactos necesarios para operar contra Databricks.

## Conservado

- `database/databricks/F1_databricks_schema.sql`
- `database/databricks/F1_databricks_load.sql`
- `database/databricks/F1_databricks_constraints.sql`
- `database/databricks/F1_databricks_silver.sql`
- `database/databricks/F1_databricks_gold.sql`
- `database/databricks/F1_databricks_gold_star.sql`
- `database/databricks/F1_databricks_control.sql`
- `database/databricks/F1_databricks_hive_metastore.sql`
- `tools/run_databricks_sql.py`
- `app.py`
- `requirements.txt`
- `.streamlit/config.toml`
- scripts `run_*` y `stop_*`
- `assets/F1.png`

## Removido Del Repo

- dumps MySQL portables
- CSV fuente locales
- pipeline MySQL local
- SQL Databricks monoliticos generados con inserts
- documentacion historica duplicada
- caches Python, logs y entorno virtual local

## Nota

La fuente de verdad operativa es Databricks. `F1_databricks_gold.sql` contiene los marts ejecutivos, KPIs y vistas de presentacion en `f1_gold`.

`F1_databricks_gold_star.sql` contiene el modelo estrella fisico separado en `f1_gold_star`.
