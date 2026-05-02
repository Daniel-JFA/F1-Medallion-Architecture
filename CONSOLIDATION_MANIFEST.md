# Consolidation Manifest

This project now contains the operational F1 dashboard package plus the main database artifacts needed to run, restore, rebuild, document, and share the project without relying on `/home/djfa/Dev/DBs BackUps`.

## Runtime Dashboard

- `app.py`
- `requirements.txt`
- `.streamlit/config.toml`
- `run_streamlit.sh`
- `stop_streamlit.sh`
- `run_public_tunnel.sh`
- `stop_public_tunnel.sh`

## Portable Database Dump

- `sql_exports/F1_full_project_2026_05_02_portable.sql`
- `sql_exports/F1_full_project_2026_05_02_portable.sql.sha256`

This is the recommended path for the team. Restoring this dump creates:

- `F1`
- `F1_silver`
- `F1_gold`
- `F1_control`

## MySQL Pipeline

- `database/mysql/F1_relationships.sql`
- `database/mysql/F1_mysql_silver.sql`
- `database/mysql/F1_mysql_gold.sql`
- `database/mysql/F1_gold_kpi_history.sql`
- `database/mysql/F1_refresh_layers.sh`
- `database/mysql/F1_freeze_kpis.sh`

The shell scripts in this folder use paths relative to their own location.

## Source CSV

- `database/source_csv/import_f1.py`
- `database/source_csv/DB F1/*.csv`

These are the original CSV inputs and the Python loader for rebuilding the relational `F1` database from source files.

## Databricks Artifacts

- `database/databricks/F1_databricks_*.sql`
- `database/databricks/F1_databricks_run_order.md`
- `database/databricks/README_F1_DATABRICKS.md`
- `database/databricks/generate_databricks_insert_dump.py`

## Documentation

- `docs/F1_diccionario_relacional.md`
- `docs/F1_documentacion_hacia_gold.md`
- `docs/F1_documentacion_silver_presentacion.md`
- `docs/F1_documentacion_gold_presentacion.md`
- `docs/F1_informe_avance.md`
- `docs/F1_entrega_corregida.md`
- `docs/F1_entrega_databricks.md`
- `docs/F1_gold_presentacion.md`
- `docs/F1_taller_consultas_corregidas.sql`

## Assets

- `assets/F1.png`

## What Can Be Cleaned From `DBs BackUps`

After confirming this repository has been pushed and backed up, the F1-specific duplicates in `/home/djfa/Dev/DBs BackUps` can be archived or removed from that folder. Keep unrelated database backups there if they belong to other projects.

Do not delete anything from `DBs BackUps` until the repository has been pushed successfully and another clone has verified:

1. The dump restores correctly.
2. The dashboard runs.
3. The MySQL rebuild scripts are present.
4. The source CSV files are present.
