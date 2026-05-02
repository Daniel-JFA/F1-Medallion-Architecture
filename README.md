# F1 Databricks Gold

Proyecto de analitica historica de Formula 1 consolidado para Databricks.

La fuente operativa actual vive en Databricks. El repositorio local queda como paquete de scripts, dashboard y documentacion minima para reconstruir o exponer las capas.

```text
Databricks f1 -> f1_silver -> f1_gold -> f1_control
```

## Estructura

- `database/databricks/F1_databricks_schema.sql`: crea las tablas base en `f1`.
- `database/databricks/F1_databricks_load.sql`: carga CSV desde un volumen Databricks.
- `database/databricks/F1_databricks_constraints.sql`: constraints informativas para Unity Catalog.
- `database/databricks/F1_databricks_silver.sql`: capa curada.
- `database/databricks/F1_databricks_gold.sql`: marts, KPIs y vistas ejecutivas.
- `database/databricks/F1_databricks_gold_star.sql`: modelo estrella fisico en `f1_gold_star`.
- `database/databricks/F1_databricks_control.sql`: snapshots historicos de KPIs.
- `tools/run_databricks_sql.py`: ejecutor JDBC para correr Silver, Gold y Control.
- `app.py`: dashboard Streamlit legado.
- `assets/F1.png`: recurso visual del proyecto.

## Gold

`F1_databricks_gold.sql` mantiene solo objetos de consumo final:

- `mart_driver_season`
- `mart_constructor_season`
- `mart_circuit_risk`
- `mart_qualifying_effect_season`
- `mart_race_weekend`
- `mart_kpi_snapshot`
- `kpi_catalog`

## Gold Star

`F1_databricks_gold_star.sql` crea el esquema `f1_gold_star`, separado de `f1_gold`.

Contiene dimensiones y hechos fisicos para BI:

- `dim_season`
- `dim_driver`
- `dim_constructor`
- `dim_circuit`
- `dim_kpi`
- `fact_driver_season`
- `fact_constructor_season`
- `fact_circuit_risk`
- `fact_qualifying_season`
- `fact_race_weekend`
- `fact_kpi_snapshot`

Documentacion completa:

- `docs/F1_gold_star_documentacion.md`

Y vistas de dashboard:

- `vw_dashboard_kpi_cards`
- `vw_dashboard_top_drivers`
- `vw_dashboard_top_constructors`
- `vw_dashboard_circuit_risk`
- `vw_dashboard_qualifying_effect_recent`
- `vw_dashboard_latest_driver_championship`
- `vw_dashboard_latest_constructor_championship`
- `vw_dashboard_recent_race_highlights`

## Orden Recomendado En Databricks

Si la capa base `f1` ya esta cargada, ejecutar:

```bash
export DATABRICKS_TOKEN='...'
python tools/run_databricks_sql.py
unset DATABRICKS_TOKEN
```

El script corre por defecto:

1. `F1_databricks_silver.sql`
2. `F1_databricks_gold.sql`
3. `F1_databricks_control.sql`

Si necesitas reconstruir desde cero:

1. Ejecuta `F1_databricks_schema.sql`.
2. Sube los CSV al volumen Databricks esperado por `F1_databricks_load.sql`.
3. Ajusta la ruta `COPY INTO` si tu volumen no es `/Volumes/workspace/default/f1_raw/`.
4. Ejecuta `F1_databricks_load.sql`.
5. Ejecuta `F1_databricks_constraints.sql` solo si estas usando Unity Catalog.
6. Ejecuta `F1_databricks_silver.sql`.
7. Ejecuta `F1_databricks_gold.sql`.
8. Ejecuta `F1_databricks_gold_star.sql`.
9. Ejecuta `F1_databricks_control.sql`.

## Variables

- `DATABRICKS_TOKEN`: token de acceso. Obligatorio para `tools/run_databricks_sql.py`.
- `DATABRICKS_SERVER_HOSTNAME`: hostname del workspace para el dashboard Streamlit.
- `DATABRICKS_HTTP_PATH`: HTTP path del SQL Warehouse para el dashboard Streamlit.
- `DATABRICKS_JDBC_URL`: URL JDBC opcional si cambia el warehouse.
- `DATABRICKS_JDBC_DRIVER`: ruta al JAR JDBC si no esta en la ruta detectada por defecto.
- `DATABRICKS_CATALOG`: catalogo objetivo. Por defecto: `f1`.
- `DATABRICKS_SQL_FILE`: lista separada por comas para `tools/run_databricks_sql.py`.

## Validacion Rapida

Despues de Gold:

```sql
SELECT COUNT(*) AS mart_driver_season_rows FROM f1_gold.mart_driver_season;
SELECT COUNT(*) AS mart_race_weekend_rows FROM f1_gold.mart_race_weekend;
SELECT * FROM f1_gold.vw_dashboard_kpi_cards;
```

Despues de Gold Star:

```sql
SELECT COUNT(*) AS dim_driver_rows FROM f1_gold_star.dim_driver;
SELECT COUNT(*) AS fact_driver_season_rows FROM f1_gold_star.fact_driver_season;
SELECT COUNT(*) AS fact_race_weekend_rows FROM f1_gold_star.fact_race_weekend;
```

Despues de Control:

```sql
SELECT snapshot_label, source_schema, COUNT(*) AS kpis
FROM f1_control.f1_gold_kpi_snapshot_history
GROUP BY snapshot_label, source_schema;
```
