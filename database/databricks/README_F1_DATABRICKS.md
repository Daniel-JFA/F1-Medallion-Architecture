# F1 para Databricks

No ejecutes archivos de MySQL en Databricks.

Especialmente, no ejecutes:

- `sql_exports/F1_full_project_2026_05_02_portable.sql`
- `F1.sql`
- `F1_relationships.sql`
- `database/mysql/*.sql`

Esos archivos usan sintaxis MySQL/MariaDB, por ejemplo:

```sql
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
```

Databricks SQL/Spark SQL no entiende esa sintaxis y devuelve errores como:

```text
[PARSE_SYNTAX_ERROR] Syntax error at or near end of input
```

## Opcion Recomendada Desde DBeaver

Si estas conectado a Databricks desde DBeaver y quieres cargar todo en una sola ejecucion, sin depender de volumenes externos ni archivos separados, ejecuta este archivo:

```text
database/databricks/F1_databricks_one_sql_with_inserts.sql
```

Ese archivo ya incluye:

- creacion de tablas base en `f1`
- carga de datos con `INSERT`
- construccion de `f1_silver`
- construccion de `f1_gold`
- construccion de `f1_control`
- consultas de validacion

No requiere subir CSV a Databricks.

El archivo anterior `F1_databricks_full_rebuild_inserts.sql` se mantiene por compatibilidad, pero no incluye `f1_control`. Para el equipo, el archivo recomendado es `F1_databricks_one_sql_with_inserts.sql`.

Usa estos archivos en este orden:

1. `F1_databricks_schema.sql`
2. `F1_databricks_load.sql`
3. `F1_databricks_constraints.sql` solo si tus tablas viven en Unity Catalog
4. `F1_databricks_silver.sql`
5. `F1_databricks_gold.sql`
6. `F1_databricks_control.sql` opcional si quieres versionar snapshots de KPIs

Ese orden separado requiere que `F1_databricks_load.sql` apunte a una ruta de CSV accesible por Databricks. Si no tienes esa ruta configurada, usa mejor `F1_databricks_one_sql_with_inserts.sql`.

## Flujo recomendado

1. Ejecuta `F1_databricks_schema.sql`.
2. Sube los CSV de `DB F1` a un volumen de Unity Catalog o a una ubicacion externa accesible desde Databricks.
3. En `F1_databricks_load.sql`, cambia la ruta `/Volumes/main/default/f1_raw/` por tu ruta real.
4. Ejecuta `F1_databricks_load.sql`.
5. Si no usas `hive_metastore`, ejecuta `F1_databricks_constraints.sql`.
6. Ejecuta `F1_databricks_silver.sql` para construir la capa curada.
7. Ejecuta `F1_databricks_gold.sql` para materializar marts, KPIs y vistas ejecutivas.
8. Si quieres historial de KPIs, ejecuta `F1_databricks_control.sql`.

## Archivos fuente esperados

- `circuits.csv`
- `constructors.csv`
- `drivers.csv`
- `seasons.csv`
- `status.csv`
- `races.csv`
- `constructor_results.csv`
- `constructor_standings.csv`
- `driver_standings.csv`
- `results.csv`
- `sprint_results.csv`
- `qualifying.csv`
- `lap_times.csv`
- `pit_stops.csv`

## Notas

- Las columnas de hora se guardan como `STRING` para evitar incompatibilidades entre MySQL y Databricks.
- `COPY INTO` ya es idempotente: si vuelves a ejecutar el script de carga, Databricks omite archivos que ya cargo.
- Las llaves primarias y foraneas en Databricks son informativas y requieren Unity Catalog.
- `F1_databricks_silver.sql` ya incluye la version ampliada de `Silver` equivalente a la capa local:
  - `dim_seasons`
  - `fact_constructor_results`
  - `fact_race_entries`
- `F1_databricks_gold.sql` crea la capa de consumo en `f1_gold` con:
  - `kpi_catalog`
  - `mart_kpi_snapshot`
  - `mart_driver_season`
  - `mart_constructor_season`
  - `mart_circuit_risk`
  - `mart_qualifying_effect_season`
  - `mart_race_weekend`
  - vistas `vw_dashboard_*`
