-- Gold layer for Databricks SQL.
--
-- Assumption:
-- - Schema f1_silver already exists and contains the curated Silver layer.
-- - This script creates the presentation and business-consumption layer in f1_gold.
--
-- Optional for Unity Catalog:
-- USE CATALOG workspace;

CREATE CATALOG IF NOT EXISTS f1;
USE CATALOG f1;

CREATE SCHEMA IF NOT EXISTS f1_gold;
USE f1_gold;

-- ============================================================
-- KPI catalog
-- ============================================================

CREATE OR REPLACE TABLE f1_gold.kpi_catalog
USING DELTA
AS
SELECT *
FROM VALUES
(
    'total_seasons',
    'Temporadas cubiertas',
    'Cuantas temporadas historicas cubre el proyecto',
    'Cuenta total de temporadas modeladas en la capa Silver.',
    'COUNT(*) sobre f1_silver.dim_seasons',
    'temporadas',
    'global',
    'f1_silver.dim_seasons'
),
(
    'total_races',
    'Carreras registradas',
    'Cuantas carreras contiene la base analitica',
    'Cantidad total de grandes premios modelados en la dimension de carreras.',
    'COUNT(*) sobre f1_silver.dim_races',
    'carreras',
    'global',
    'f1_silver.dim_races'
),
(
    'total_drivers',
    'Pilotos registrados',
    'Cuantos pilotos unicos forman parte del historico',
    'Cantidad total de pilotos unicos disponibles para analisis.',
    'COUNT(*) sobre f1_silver.dim_drivers',
    'pilotos',
    'global',
    'f1_silver.dim_drivers'
),
(
    'total_constructors',
    'Escuderias registradas',
    'Cuantas escuderias aparecen en el historico',
    'Cantidad total de constructores unicos disponibles para analisis.',
    'COUNT(*) sobre f1_silver.dim_constructors',
    'escuderias',
    'global',
    'f1_silver.dim_constructors'
),
(
    'classified_finish_rate_pct',
    'Tasa de clasificacion',
    'Que porcentaje de participaciones termina clasificada',
    'Porcentaje de entradas de carrera que terminan clasificadas, incluyendo vueltas perdidas pero registradas como clasificadas.',
    'SUM(is_classified_finish) / COUNT(*) * 100',
    'porcentaje',
    'global',
    'f1_silver.fact_race_entries'
),
(
    'dnf_rate_pct',
    'Tasa de no clasificacion',
    'Que porcentaje de participaciones termina sin clasificar',
    'Porcentaje de entradas de carrera que no terminan clasificadas.',
    '(COUNT(*) - SUM(is_classified_finish)) / COUNT(*) * 100',
    'porcentaje',
    'global',
    'f1_silver.fact_race_entries'
),
(
    'avg_points_per_entry',
    'Puntos promedio por entrada',
    'Cuantos puntos produce en promedio una participacion de carrera',
    'Promedio de puntos totales del evento por cada entrada de carrera.',
    'AVG(total_event_points)',
    'puntos',
    'global',
    'f1_silver.fact_race_entries'
),
(
    'pole_to_win_rate_pct',
    'Conversion pole a victoria',
    'Con que frecuencia una pole termina en victoria',
    'Porcentaje de victorias que fueron logradas por un piloto que salio desde la pole.',
    'SUM(CASE WHEN is_winner = TRUE AND started_from_pole = TRUE THEN 1 ELSE 0 END) / SUM(CASE WHEN is_winner = TRUE THEN 1 ELSE 0 END) * 100',
    'porcentaje',
    'global',
    'f1_silver.fact_race_entries'
),
(
    'sprint_weekend_share_pct',
    'Participacion de fines de semana sprint',
    'Que proporcion del calendario corresponde a fines de semana con sprint',
    'Porcentaje de carreras cuya configuracion de fin de semana incluye sprint.',
    'SUM(has_sprint_weekend) / COUNT(*) * 100',
    'porcentaje',
    'global',
    'f1_silver.dim_races'
),
(
    'shared_drive_entry_rate_pct',
    'Participaciones con shared drive',
    'Que porcentaje de entradas corresponden a casos historicos de shared drive',
    'Porcentaje de registros identificados como posibles shared drives o multiples entradas del mismo piloto en una carrera.',
    'SUM(shared_drive_candidate) / COUNT(*) * 100',
    'porcentaje',
    'global',
    'f1_silver.fact_race_entries'
)
AS t(
    kpi_code,
    kpi_name,
    business_question,
    business_definition,
    formula_definition,
    unit_of_measure,
    grain_level,
    source_objects
);

-- ============================================================
-- Business marts
-- ============================================================

CREATE OR REPLACE TABLE f1_gold.mart_driver_season
USING DELTA
AS
WITH primary_constructor_counts AS (
    SELECT
        season_year,
        driverId,
        constructorId,
        COUNT(*) AS race_entries,
        SUM(total_event_points) AS total_points
    FROM f1_silver.fact_race_entries
    GROUP BY season_year, driverId, constructorId
),
primary_constructor_ranked AS (
    SELECT
        season_year,
        driverId,
        constructorId,
        ROW_NUMBER() OVER (
            PARTITION BY season_year, driverId
            ORDER BY race_entries DESC, total_points DESC, constructorId
        ) AS rn
    FROM primary_constructor_counts
),
constructors_used AS (
    SELECT
        fre2.season_year,
        fre2.driverId,
        ARRAY_JOIN(SORT_ARRAY(COLLECT_SET(dc2.constructor_name)), ', ') AS constructors_used
    FROM f1_silver.fact_race_entries fre2
    JOIN f1_silver.dim_constructors dc2
        ON fre2.constructorId = dc2.constructorId
    GROUP BY fre2.season_year, fre2.driverId
),
final_driver_standings AS (
    SELECT
        season_year,
        driverId,
        position AS championship_position,
        points AS championship_points,
        wins AS championship_wins
    FROM (
        SELECT
            fds.*,
            dr.season_round,
            ROW_NUMBER() OVER (
                PARTITION BY fds.season_year, fds.driverId
                ORDER BY dr.season_round DESC, fds.raceId DESC, fds.driverStandingsId DESC
            ) AS rn
        FROM f1_silver.fact_driver_standings fds
        JOIN f1_silver.dim_races dr
            ON fds.raceId = dr.raceId
    ) ranked
    WHERE rn = 1
)
SELECT
    fre.season_year,
    fre.driverId,
    dd.driver_name,
    pcm.constructorId AS primary_constructorId,
    dc.constructor_name AS primary_constructor_name,
    cu.constructors_used,
    COUNT(*) AS race_entries,
    COUNT(DISTINCT fre.raceId) AS race_weekends,
    SUM(CASE WHEN fre.shared_drive_candidate THEN 1 ELSE 0 END) AS shared_drive_entries,
    SUM(CASE WHEN fre.is_winner THEN 1 ELSE 0 END) AS wins,
    SUM(CASE WHEN fre.is_podium THEN 1 ELSE 0 END) AS podiums,
    SUM(CASE WHEN fre.qualified_on_pole THEN 1 ELSE 0 END) AS poles,
    ROUND(SUM(fre.race_points), 1) AS race_points,
    ROUND(SUM(fre.sprint_points), 1) AS sprint_points,
    ROUND(SUM(fre.total_event_points), 1) AS total_points,
    ROUND(AVG(NULLIF(fre.starting_grid, 0)), 2) AS avg_starting_grid,
    ROUND(AVG(fre.finish_position), 2) AS avg_finish_position,
    ROUND(AVG(fre.positions_gained), 2) AS avg_positions_gained,
    ROUND(AVG(fre.qualifying_to_finish_delta), 2) AS avg_qualifying_delta,
    SUM(CASE WHEN fre.is_classified_finish THEN 1 ELSE 0 END) AS classified_finishes,
    COUNT(*) - SUM(CASE WHEN fre.is_classified_finish THEN 1 ELSE 0 END) AS non_classified_finishes,
    ROUND(
        (COUNT(*) - SUM(CASE WHEN fre.is_classified_finish THEN 1 ELSE 0 END)) * 100.0 / COUNT(*),
        2
    ) AS non_classified_rate_pct,
    ROUND(SUM(CASE WHEN fre.is_winner THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS win_rate_pct,
    ROUND(SUM(CASE WHEN fre.is_podium THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS podium_rate_pct,
    ROUND(SUM(CASE WHEN fre.qualified_on_pole THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pole_rate_pct,
    MAX(fre.total_event_points) AS best_event_points,
    MAX(fre.positions_gained) AS best_positions_gained,
    fs.championship_position,
    ROUND(fs.championship_points, 1) AS final_standings_points,
    fs.championship_wins
FROM f1_silver.fact_race_entries fre
JOIN f1_silver.dim_drivers dd
    ON fre.driverId = dd.driverId
LEFT JOIN primary_constructor_ranked pcm
    ON fre.season_year = pcm.season_year
   AND fre.driverId = pcm.driverId
   AND pcm.rn = 1
LEFT JOIN f1_silver.dim_constructors dc
    ON pcm.constructorId = dc.constructorId
LEFT JOIN constructors_used cu
    ON fre.season_year = cu.season_year
   AND fre.driverId = cu.driverId
LEFT JOIN final_driver_standings fs
    ON fre.season_year = fs.season_year
   AND fre.driverId = fs.driverId
GROUP BY
    fre.season_year,
    fre.driverId,
    dd.driver_name,
    pcm.constructorId,
    dc.constructor_name,
    cu.constructors_used,
    fs.championship_position,
    fs.championship_points,
    fs.championship_wins;

CREATE OR REPLACE TABLE f1_gold.mart_constructor_season
USING DELTA
AS
WITH constructor_result_points AS (
    SELECT
        season_year,
        constructorId,
        SUM(points) AS official_constructor_race_points
    FROM f1_silver.fact_constructor_results
    GROUP BY season_year, constructorId
),
final_constructor_standings AS (
    SELECT
        season_year,
        constructorId,
        position AS championship_position,
        points AS championship_points,
        wins AS championship_wins
    FROM (
        SELECT
            fcs.*,
            dr.season_round,
            ROW_NUMBER() OVER (
                PARTITION BY fcs.season_year, fcs.constructorId
                ORDER BY dr.season_round DESC, fcs.raceId DESC, fcs.constructorStandingsId DESC
            ) AS rn
        FROM f1_silver.fact_constructor_standings fcs
        JOIN f1_silver.dim_races dr
            ON fcs.raceId = dr.raceId
    ) ranked
    WHERE rn = 1
)
SELECT
    fre.season_year,
    fre.constructorId,
    dc.constructor_name,
    COUNT(*) AS race_entries,
    COUNT(DISTINCT fre.raceId) AS race_weekends,
    COUNT(DISTINCT fre.driverId) AS drivers_used,
    SUM(CASE WHEN fre.shared_drive_candidate THEN 1 ELSE 0 END) AS shared_drive_entries,
    SUM(CASE WHEN fre.is_winner THEN 1 ELSE 0 END) AS wins,
    SUM(CASE WHEN fre.is_podium THEN 1 ELSE 0 END) AS podiums,
    SUM(CASE WHEN fre.qualified_on_pole THEN 1 ELSE 0 END) AS poles,
    ROUND(SUM(fre.race_points), 1) AS race_points_from_entries,
    ROUND(SUM(fre.sprint_points), 1) AS sprint_points,
    ROUND(SUM(fre.total_event_points), 1) AS total_points,
    ROUND(COALESCE(cr.official_constructor_race_points, 0D), 1) AS official_constructor_race_points,
    ROUND(AVG(NULLIF(fre.starting_grid, 0)), 2) AS avg_starting_grid,
    ROUND(AVG(fre.finish_position), 2) AS avg_finish_position,
    ROUND(AVG(fre.positions_gained), 2) AS avg_positions_gained,
    SUM(CASE WHEN fre.is_classified_finish THEN 1 ELSE 0 END) AS classified_entries,
    COUNT(*) - SUM(CASE WHEN fre.is_classified_finish THEN 1 ELSE 0 END) AS non_classified_entries,
    ROUND(
        (COUNT(*) - SUM(CASE WHEN fre.is_classified_finish THEN 1 ELSE 0 END)) * 100.0 / COUNT(*),
        2
    ) AS non_classified_rate_pct,
    ROUND(SUM(CASE WHEN fre.is_winner THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS win_rate_pct,
    ROUND(SUM(CASE WHEN fre.is_podium THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS podium_rate_pct,
    cs.championship_position,
    ROUND(cs.championship_points, 1) AS final_standings_points,
    cs.championship_wins
FROM f1_silver.fact_race_entries fre
JOIN f1_silver.dim_constructors dc
    ON fre.constructorId = dc.constructorId
LEFT JOIN constructor_result_points cr
    ON fre.season_year = cr.season_year
   AND fre.constructorId = cr.constructorId
LEFT JOIN final_constructor_standings cs
    ON fre.season_year = cs.season_year
   AND fre.constructorId = cs.constructorId
GROUP BY
    fre.season_year,
    fre.constructorId,
    dc.constructor_name,
    cr.official_constructor_race_points,
    cs.championship_position,
    cs.championship_points,
    cs.championship_wins;

CREATE OR REPLACE TABLE f1_gold.mart_circuit_risk
USING DELTA
AS
SELECT
    fre.circuitId,
    dc.circuit_name,
    dc.country,
    COUNT(DISTINCT fre.raceId) AS race_weekends_hosted,
    MIN(fre.season_year) AS first_season,
    MAX(fre.season_year) AS last_season,
    COUNT(*) AS total_entries,
    COUNT(DISTINCT fre.driverId) AS unique_drivers,
    SUM(CASE WHEN fre.is_classified_finish THEN 1 ELSE 0 END) AS classified_entries,
    COUNT(*) - SUM(CASE WHEN fre.is_classified_finish THEN 1 ELSE 0 END) AS non_classified_entries,
    ROUND(
        (COUNT(*) - SUM(CASE WHEN fre.is_classified_finish THEN 1 ELSE 0 END)) * 100.0 / COUNT(*),
        2
    ) AS non_classified_rate_pct,
    SUM(CASE WHEN fre.status_category = 'mechanical' THEN 1 ELSE 0 END) AS mechanical_non_classified_entries,
    SUM(CASE WHEN fre.status_category = 'accident_incident' THEN 1 ELSE 0 END) AS accident_non_classified_entries,
    SUM(CASE WHEN fre.status_category = 'disqualified' THEN 1 ELSE 0 END) AS disqualified_entries,
    SUM(CASE WHEN fre.is_winner AND fre.started_from_pole THEN 1 ELSE 0 END) AS pole_to_win_occurrences,
    ROUND(
        SUM(CASE WHEN fre.is_winner AND fre.started_from_pole THEN 1 ELSE 0 END) * 100.0
        / NULLIF(SUM(CASE WHEN fre.is_winner THEN 1 ELSE 0 END), 0),
        2
    ) AS pole_to_win_rate_pct,
    ROUND(AVG(fre.positions_gained), 2) AS avg_positions_gained,
    ROUND(AVG(fre.total_event_points), 2) AS avg_points_per_entry
FROM f1_silver.fact_race_entries fre
JOIN f1_silver.dim_circuits dc
    ON fre.circuitId = dc.circuitId
GROUP BY
    fre.circuitId,
    dc.circuit_name,
    dc.country;

CREATE OR REPLACE TABLE f1_gold.mart_qualifying_effect_season
USING DELTA
AS
SELECT
    fre.season_year,
    COUNT(*) AS race_entries_analyzed,
    COUNT(DISTINCT fre.raceId) AS race_weekends,
    ROUND(AVG(fre.qualifying_position), 2) AS avg_qualifying_position,
    ROUND(AVG(fre.finish_position), 2) AS avg_finish_position,
    ROUND(AVG(fre.positions_gained), 2) AS avg_positions_gained,
    ROUND(AVG(fre.qualifying_to_finish_delta), 2) AS avg_qualifying_to_finish_delta,
    SUM(CASE WHEN fre.is_winner AND fre.qualified_on_pole THEN 1 ELSE 0 END) AS winners_from_pole,
    ROUND(
        SUM(CASE WHEN fre.is_winner AND fre.qualified_on_pole THEN 1 ELSE 0 END) * 100.0
        / NULLIF(SUM(CASE WHEN fre.is_winner THEN 1 ELSE 0 END), 0),
        2
    ) AS pole_to_win_rate_pct,
    SUM(CASE WHEN fre.qualifying_position <= 2 AND fre.is_podium THEN 1 ELSE 0 END) AS front_row_podium_entries,
    ROUND(
        SUM(CASE WHEN fre.qualifying_position <= 2 AND fre.is_podium THEN 1 ELSE 0 END) * 100.0
        / NULLIF(SUM(CASE WHEN fre.qualifying_position <= 2 THEN 1 ELSE 0 END), 0),
        2
    ) AS front_row_podium_rate_pct,
    ROUND(AVG(CASE WHEN fre.is_winner THEN fre.starting_grid END), 2) AS winner_avg_grid,
    ROUND(AVG(CASE WHEN fre.is_winner THEN fre.qualifying_position END), 2) AS winner_avg_qualifying_position
FROM f1_silver.fact_race_entries fre
WHERE fre.qualifying_position IS NOT NULL
GROUP BY fre.season_year;

CREATE OR REPLACE TABLE f1_gold.mart_race_weekend
USING DELTA
AS
WITH winners AS (
    SELECT
        frew.raceId,
        ARRAY_JOIN(SORT_ARRAY(COLLECT_SET(dd.driver_name)), ' | ') AS winner_driver_name,
        ARRAY_JOIN(SORT_ARRAY(COLLECT_SET(dco.constructor_name)), ' | ') AS winner_constructor_name,
        ARRAY_JOIN(
            TRANSFORM(SORT_ARRAY(COLLECT_SET(CAST(frew.starting_grid AS INT))), x -> CAST(x AS STRING)),
            ' | '
        ) AS winner_starting_grid
    FROM f1_silver.fact_race_entries frew
    JOIN f1_silver.dim_drivers dd
        ON frew.driverId = dd.driverId
    JOIN f1_silver.dim_constructors dco
        ON frew.constructorId = dco.constructorId
    WHERE frew.is_winner
    GROUP BY frew.raceId
),
poles AS (
    SELECT
        fq.raceId,
        ARRAY_JOIN(SORT_ARRAY(COLLECT_SET(dd.driver_name)), ' | ') AS pole_driver_name,
        ARRAY_JOIN(SORT_ARRAY(COLLECT_SET(dco.constructor_name)), ' | ') AS pole_constructor_name
    FROM f1_silver.fact_qualifying fq
    JOIN f1_silver.dim_drivers dd
        ON fq.driverId = dd.driverId
    JOIN f1_silver.dim_constructors dco
        ON fq.constructorId = dco.constructorId
    WHERE fq.qualifying_position = 1
    GROUP BY fq.raceId
),
podiums AS (
    SELECT
        raceId,
        ARRAY_JOIN(
            TRANSFORM(
                ARRAY_SORT(COLLECT_LIST(NAMED_STRUCT('finish_position', finish_position, 'driver_name', driver_name))),
                x -> x.driver_name
            ),
            ' | '
        ) AS podium_names
    FROM (
        SELECT
            frep.raceId,
            frep.finish_position,
            dd.driver_name
        FROM f1_silver.fact_race_entries frep
        JOIN f1_silver.dim_drivers dd
            ON frep.driverId = dd.driverId
        WHERE frep.finish_position <= 3
    ) base_podiums
    GROUP BY raceId
),
pit_summary AS (
    SELECT
        raceId,
        COUNT(*) AS total_pit_stops,
        AVG(pit_duration_ms) AS avg_pit_stop_ms
    FROM f1_silver.fact_pit_stops
    GROUP BY raceId
)
SELECT
    dr.raceId,
    dr.season_year,
    dr.season_round,
    ds.total_races AS season_total_races,
    dr.race_name,
    dr.race_date,
    dr.has_sprint_weekend,
    dc.circuit_name,
    dc.country,
    COUNT(fre.resultId) AS race_entries,
    COUNT(DISTINCT fre.driverId) AS unique_drivers,
    COUNT(DISTINCT fre.constructorId) AS unique_constructors,
    ROUND(SUM(fre.total_event_points), 1) AS total_event_points_awarded,
    SUM(CASE WHEN fre.is_classified_finish THEN 1 ELSE 0 END) AS classified_entries,
    COUNT(fre.resultId) - SUM(CASE WHEN fre.is_classified_finish THEN 1 ELSE 0 END) AS non_classified_entries,
    ROUND(
        (COUNT(fre.resultId) - SUM(CASE WHEN fre.is_classified_finish THEN 1 ELSE 0 END)) * 100.0
        / COUNT(fre.resultId),
        2
    ) AS non_classified_rate_pct,
    SUM(CASE WHEN fre.shared_drive_candidate THEN 1 ELSE 0 END) AS shared_drive_entries,
    wr.winner_driver_name,
    wr.winner_constructor_name,
    wr.winner_starting_grid,
    ps.pole_driver_name,
    ps.pole_constructor_name,
    MAX(CASE WHEN fre.is_winner AND fre.qualified_on_pole THEN 1 ELSE 0 END) AS pole_converted_to_win,
    pd.podium_names,
    pit.total_pit_stops,
    ROUND(pit.avg_pit_stop_ms, 2) AS avg_pit_stop_ms,
    MAX(fre.positions_gained) AS max_positions_gained
FROM f1_silver.dim_races dr
JOIN f1_silver.dim_seasons ds
    ON dr.season_year = ds.season_year
JOIN f1_silver.dim_circuits dc
    ON dr.circuitId = dc.circuitId
LEFT JOIN f1_silver.fact_race_entries fre
    ON dr.raceId = fre.raceId
LEFT JOIN winners wr
    ON dr.raceId = wr.raceId
LEFT JOIN poles ps
    ON dr.raceId = ps.raceId
LEFT JOIN podiums pd
    ON dr.raceId = pd.raceId
LEFT JOIN pit_summary pit
    ON dr.raceId = pit.raceId
GROUP BY
    dr.raceId,
    dr.season_year,
    dr.season_round,
    ds.total_races,
    dr.race_name,
    dr.race_date,
    dr.has_sprint_weekend,
    dc.circuit_name,
    dc.country,
    wr.winner_driver_name,
    wr.winner_constructor_name,
    wr.winner_starting_grid,
    ps.pole_driver_name,
    ps.pole_constructor_name,
    pd.podium_names,
    pit.total_pit_stops,
    pit.avg_pit_stop_ms;

CREATE OR REPLACE TABLE f1_gold.mart_kpi_snapshot
USING DELTA
AS
SELECT
    'total_seasons' AS kpi_code,
    CAST(COUNT(*) AS DECIMAL(18,2)) AS kpi_value_numeric,
    CAST(COUNT(*) AS STRING) AS kpi_value_text
FROM f1_silver.dim_seasons

UNION ALL

SELECT
    'total_races',
    CAST(COUNT(*) AS DECIMAL(18,2)),
    CAST(COUNT(*) AS STRING)
FROM f1_silver.dim_races

UNION ALL

SELECT
    'total_drivers',
    CAST(COUNT(*) AS DECIMAL(18,2)),
    CAST(COUNT(*) AS STRING)
FROM f1_silver.dim_drivers

UNION ALL

SELECT
    'total_constructors',
    CAST(COUNT(*) AS DECIMAL(18,2)),
    CAST(COUNT(*) AS STRING)
FROM f1_silver.dim_constructors

UNION ALL

SELECT
    'classified_finish_rate_pct',
    CAST(ROUND(SUM(CASE WHEN is_classified_finish THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS DECIMAL(18,2)),
    CONCAT(CAST(ROUND(SUM(CASE WHEN is_classified_finish THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS STRING), '%')
FROM f1_silver.fact_race_entries

UNION ALL

SELECT
    'dnf_rate_pct',
    CAST(ROUND((COUNT(*) - SUM(CASE WHEN is_classified_finish THEN 1 ELSE 0 END)) * 100.0 / COUNT(*), 2) AS DECIMAL(18,2)),
    CONCAT(CAST(ROUND((COUNT(*) - SUM(CASE WHEN is_classified_finish THEN 1 ELSE 0 END)) * 100.0 / COUNT(*), 2) AS STRING), '%')
FROM f1_silver.fact_race_entries

UNION ALL

SELECT
    'avg_points_per_entry',
    CAST(ROUND(AVG(total_event_points), 2) AS DECIMAL(18,2)),
    CAST(ROUND(AVG(total_event_points), 2) AS STRING)
FROM f1_silver.fact_race_entries

UNION ALL

SELECT
    'pole_to_win_rate_pct',
    CAST(
        ROUND(
            SUM(CASE WHEN is_winner AND started_from_pole THEN 1 ELSE 0 END) * 100.0
            / NULLIF(SUM(CASE WHEN is_winner THEN 1 ELSE 0 END), 0),
            2
        ) AS DECIMAL(18,2)
    ),
    CONCAT(
        CAST(
            ROUND(
                SUM(CASE WHEN is_winner AND started_from_pole THEN 1 ELSE 0 END) * 100.0
                / NULLIF(SUM(CASE WHEN is_winner THEN 1 ELSE 0 END), 0),
                2
            ) AS STRING
        ),
        '%'
    )
FROM f1_silver.fact_race_entries

UNION ALL

SELECT
    'sprint_weekend_share_pct',
    CAST(ROUND(SUM(CASE WHEN has_sprint_weekend THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS DECIMAL(18,2)),
    CONCAT(CAST(ROUND(SUM(CASE WHEN has_sprint_weekend THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS STRING), '%')
FROM f1_silver.dim_races

UNION ALL

SELECT
    'shared_drive_entry_rate_pct',
    CAST(ROUND(SUM(CASE WHEN shared_drive_candidate THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS DECIMAL(18,2)),
    CONCAT(CAST(ROUND(SUM(CASE WHEN shared_drive_candidate THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS STRING), '%')
FROM f1_silver.fact_race_entries;

-- ============================================================
-- Cleanup deprecated Gold star views
-- ============================================================

DROP VIEW IF EXISTS f1_gold.star_fact_kpi_snapshot;
DROP VIEW IF EXISTS f1_gold.star_fact_race_weekend;
DROP VIEW IF EXISTS f1_gold.star_fact_qualifying_season;
DROP VIEW IF EXISTS f1_gold.star_fact_circuit_risk;
DROP VIEW IF EXISTS f1_gold.star_fact_constructor_season;
DROP VIEW IF EXISTS f1_gold.star_fact_driver_season;
DROP VIEW IF EXISTS f1_gold.star_dim_kpi;
DROP VIEW IF EXISTS f1_gold.star_dim_circuit;
DROP VIEW IF EXISTS f1_gold.star_dim_constructor;
DROP VIEW IF EXISTS f1_gold.star_dim_driver;
DROP VIEW IF EXISTS f1_gold.star_dim_season;
DROP TABLE IF EXISTS f1_gold.fact_race_entry;
DROP TABLE IF EXISTS f1_gold.dim_status;
DROP TABLE IF EXISTS f1_gold.dim_race;
DROP TABLE IF EXISTS f1_gold.dim_driver;
DROP TABLE IF EXISTS f1_gold.dim_constructor;
DROP TABLE IF EXISTS f1_gold.dim_circuit;
DROP TABLE IF EXISTS f1_gold.dim_season;

-- ============================================================
-- Executive views
-- ============================================================

CREATE OR REPLACE VIEW f1_gold.vw_dashboard_kpi_cards AS
SELECT
    kc.kpi_code,
    kc.kpi_name,
    kc.business_question,
    kc.unit_of_measure,
    ks.kpi_value_numeric,
    ks.kpi_value_text
FROM f1_gold.kpi_catalog kc
JOIN f1_gold.mart_kpi_snapshot ks
    ON kc.kpi_code = ks.kpi_code;

CREATE OR REPLACE VIEW f1_gold.vw_dashboard_top_drivers AS
SELECT
    driverId,
    driver_name,
    COUNT(*) AS seasons_competed,
    SUM(CASE WHEN championship_position = 1 THEN 1 ELSE 0 END) AS titles,
    SUM(wins) AS wins,
    SUM(podiums) AS podiums,
    SUM(poles) AS poles,
    ROUND(SUM(total_points), 1) AS total_points,
    ROUND(AVG(total_points), 2) AS avg_points_per_season,
    MIN(season_year) AS first_season,
    MAX(season_year) AS last_season
FROM f1_gold.mart_driver_season
GROUP BY driverId, driver_name;

CREATE OR REPLACE VIEW f1_gold.vw_dashboard_top_constructors AS
SELECT
    constructorId,
    constructor_name,
    COUNT(*) AS seasons_competed,
    SUM(CASE WHEN championship_position = 1 THEN 1 ELSE 0 END) AS titles,
    SUM(wins) AS wins,
    SUM(podiums) AS podiums,
    SUM(poles) AS poles,
    ROUND(SUM(total_points), 1) AS total_points,
    ROUND(AVG(total_points), 2) AS avg_points_per_season,
    MIN(season_year) AS first_season,
    MAX(season_year) AS last_season
FROM f1_gold.mart_constructor_season
GROUP BY constructorId, constructor_name;

CREATE OR REPLACE VIEW f1_gold.vw_dashboard_circuit_risk AS
SELECT
    circuitId,
    circuit_name,
    country,
    race_weekends_hosted,
    total_entries,
    non_classified_entries,
    non_classified_rate_pct,
    mechanical_non_classified_entries,
    accident_non_classified_entries,
    disqualified_entries,
    pole_to_win_rate_pct
FROM f1_gold.mart_circuit_risk
WHERE total_entries >= 100;

CREATE OR REPLACE VIEW f1_gold.vw_dashboard_qualifying_effect_recent AS
SELECT
    *
FROM f1_gold.mart_qualifying_effect_season;

CREATE OR REPLACE VIEW f1_gold.vw_dashboard_latest_driver_championship AS
SELECT
    mds.season_year,
    mds.championship_position,
    mds.driver_name,
    mds.primary_constructor_name,
    mds.total_points,
    mds.wins,
    mds.podiums,
    mds.poles,
    mds.avg_starting_grid,
    mds.avg_finish_position
FROM f1_gold.mart_driver_season mds
WHERE mds.season_year = (SELECT MAX(season_year) FROM f1_gold.mart_driver_season);

CREATE OR REPLACE VIEW f1_gold.vw_dashboard_latest_constructor_championship AS
SELECT
    mcs.season_year,
    mcs.championship_position,
    mcs.constructor_name,
    mcs.total_points,
    mcs.wins,
    mcs.podiums,
    mcs.poles,
    mcs.drivers_used,
    mcs.avg_starting_grid,
    mcs.avg_finish_position
FROM f1_gold.mart_constructor_season mcs
WHERE mcs.season_year = (SELECT MAX(season_year) FROM f1_gold.mart_constructor_season);

CREATE OR REPLACE VIEW f1_gold.vw_dashboard_recent_race_highlights AS
SELECT
    mrw.season_year,
    mrw.season_round,
    mrw.race_name,
    mrw.circuit_name,
    mrw.country,
    mrw.race_date,
    mrw.winner_driver_name,
    mrw.winner_constructor_name,
    mrw.pole_driver_name,
    mrw.pole_converted_to_win,
    mrw.podium_names,
    mrw.non_classified_rate_pct,
    mrw.total_event_points_awarded,
    mrw.total_pit_stops,
    mrw.avg_pit_stop_ms
FROM f1_gold.mart_race_weekend mrw;

-- ============================================================
-- Quick validation queries
-- ============================================================
-- Use fully qualified names because some SQL clients may not preserve
-- the active schema for standalone validation statements.

SELECT COUNT(*) AS mart_driver_season_rows FROM f1_gold.mart_driver_season;
SELECT COUNT(*) AS mart_constructor_season_rows FROM f1_gold.mart_constructor_season;
SELECT COUNT(*) AS mart_circuit_risk_rows FROM f1_gold.mart_circuit_risk;
SELECT COUNT(*) AS mart_qualifying_effect_season_rows FROM f1_gold.mart_qualifying_effect_season;
SELECT COUNT(*) AS mart_race_weekend_rows FROM f1_gold.mart_race_weekend;
SELECT COUNT(*) AS mart_kpi_snapshot_rows FROM f1_gold.mart_kpi_snapshot;

SELECT * FROM f1_gold.vw_dashboard_kpi_cards;
