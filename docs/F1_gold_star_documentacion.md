# Documentacion del Modelo Estrella `f1_gold_star`

## 1. Objetivo

`f1_gold_star` es el esquema dimensional de consumo del proyecto de Formula 1.

Su proposito es exponer un modelo estrella claro para herramientas BI, exploracion en DBeaver/Databricks y presentacion academica/profesional, sin contaminar la capa medallon `f1_gold`.

La separacion queda asi:

```text
f1
  Base historica cargada en Databricks

f1_silver
  Limpieza, normalizacion, hechos detallados y reglas analiticas

f1_gold
  Marts, KPIs y vistas ejecutivas

f1_gold_star
  Modelo estrella fisico para BI, construido desde f1_gold

f1_control
  Historico/versionamiento de snapshots KPI
```

## 2. Principio De Diseno

`f1_gold_star` no se construye desde Silver directamente.

El modelo estrella se alimenta desde objetos Gold:

- `f1_gold.mart_driver_season`
- `f1_gold.mart_constructor_season`
- `f1_gold.mart_circuit_risk`
- `f1_gold.mart_qualifying_effect_season`
- `f1_gold.mart_race_weekend`
- `f1_gold.mart_kpi_snapshot`
- `f1_gold.kpi_catalog`

Esto respeta la arquitectura medallon:

- Silver conserva el detalle tecnico y el enriquecimiento.
- Gold contiene objetos de valor para consumo.
- Gold Star organiza esos objetos de valor en una forma dimensional.

## 3. Tablas Del Modelo

### Dimensiones

| Tabla | Llave | Proposito |
| --- | --- | --- |
| `dim_season` | `season_year` | Describe temporadas disponibles para analisis |
| `dim_driver` | `driverId` | Describe pilotos presentes en marts Gold |
| `dim_constructor` | `constructorId` | Describe escuderias presentes en marts Gold |
| `dim_circuit` | `circuitId` | Describe circuitos con analisis de riesgo |
| `dim_kpi` | `kpi_code` | Describe KPIs oficiales de Gold |

### Hechos

| Tabla | Grano | Proposito |
| --- | --- | --- |
| `fact_driver_season` | piloto-temporada | Rendimiento anual de pilotos |
| `fact_constructor_season` | constructor-temporada | Rendimiento anual de escuderias |
| `fact_circuit_risk` | circuito | Riesgo historico por circuito |
| `fact_qualifying_season` | temporada | Impacto de clasificacion por temporada |
| `fact_race_weekend` | carrera | Resumen narrativo y operativo por GP |
| `fact_kpi_snapshot` | KPI actual | Valores actuales de KPIs Gold |

## 4. Relaciones Logicas

```text
dim_season 1 ── N fact_driver_season
dim_driver 1 ── N fact_driver_season
dim_constructor 1 ── N fact_driver_season

dim_season 1 ── N fact_constructor_season
dim_constructor 1 ── N fact_constructor_season

dim_circuit 1 ── 1 fact_circuit_risk

dim_season 1 ── 1 fact_qualifying_season

dim_season 1 ── N fact_race_weekend

dim_kpi 1 ── 1 fact_kpi_snapshot
```

En MySQL local estas relaciones se crean con foreign keys fisicas.

En Databricks las tablas se materializan como Delta tables. Las relaciones deben interpretarse como modelo dimensional para BI; Databricks no necesita enforcing fisico para que el modelo sea util en consumo.

## 5. Diccionario Resumido

### `dim_season`

Contiene una fila por temporada.

Columnas principales:

- `season_year`
- `season_total_races`
- `first_race_date`
- `last_race_date`
- `has_sprint_weekend`

### `dim_driver`

Contiene una fila por piloto presente en Gold.

Columnas principales:

- `driverId`
- `driver_name`
- `first_season`
- `last_season`
- `seasons_competed`

### `dim_constructor`

Contiene una fila por escuderia presente en Gold.

Columnas principales:

- `constructorId`
- `constructor_name`
- `first_season`
- `last_season`
- `seasons_present`

### `dim_circuit`

Contiene una fila por circuito con datos de riesgo.

Columnas principales:

- `circuitId`
- `circuit_name`
- `country`
- `first_season`
- `last_season`
- `race_weekends_hosted`

### `dim_kpi`

Catalogo oficial de KPIs.

Columnas principales:

- `kpi_code`
- `kpi_name`
- `business_question`
- `business_definition`
- `formula_definition`
- `unit_of_measure`
- `grain_level`
- `source_objects`

## 6. Uso Recomendado

Para BI:

- Usar `dim_*` como tablas descriptivas.
- Usar `fact_*` como tablas de metricas.
- Evitar consumir `f1_silver` desde dashboards ejecutivos.
- Usar `f1_gold` para vistas ejecutivas existentes.
- Usar `f1_gold_star` cuando se necesite un modelo dimensional visible.

Ejemplo:

```sql
SELECT
    s.season_year,
    d.driver_name,
    c.constructor_name,
    f.total_points,
    f.wins,
    f.podiums,
    f.championship_position
FROM f1_gold_star.fact_driver_season f
JOIN f1_gold_star.dim_season s
    ON f.season_year = s.season_year
JOIN f1_gold_star.dim_driver d
    ON f.driverId = d.driverId
LEFT JOIN f1_gold_star.dim_constructor c
    ON f.constructorId = c.constructorId
WHERE s.season_year >= 2020
ORDER BY s.season_year DESC, f.championship_position ASC;
```

## 7. Validacion Esperada

Conteos actuales validados:

| Tabla | Filas |
| --- | ---: |
| `dim_season` | 75 |
| `dim_driver` | 861 |
| `dim_constructor` | 211 |
| `dim_circuit` | 77 |
| `dim_kpi` | 10 |
| `fact_driver_season` | 3211 |
| `fact_constructor_season` | 1111 |
| `fact_circuit_risk` | 77 |
| `fact_qualifying_season` | 31 |
| `fact_race_weekend` | 1125 |
| `fact_kpi_snapshot` | 10 |

## 8. Orden De Refresco

El orden correcto es:

```text
f1_silver
f1_gold
f1_gold_star
f1_control
```

En Databricks:

```bash
export DATABRICKS_TOKEN='...'
DATABRICKS_SQL_FILE='database/databricks/F1_databricks_gold_star.sql' python tools/run_databricks_sql.py
unset DATABRICKS_TOKEN
```

## 9. Decision Arquitectonica

`f1_gold_star` existe separado de `f1_gold` para evitar mezclar dos responsabilidades:

- `f1_gold`: capa Gold medallon, orientada a productos de datos y dashboard.
- `f1_gold_star`: representacion dimensional fisica para BI/modelado.

Esta separacion permite defender mejor el ejercicio:

- no se duplica Silver,
- no se ensucia Gold,
- el dashboard sigue consumiendo marts/vistas ejecutivas,
- y el modelo estrella queda visible para herramientas de base de datos.
