-- ============================================================
-- Gold Star schema for Databricks SQL.
--
-- Purpose:
-- - Keep f1_gold as the medallion Gold consumption layer.
-- - Expose a separate dimensional star schema for BI/modeling tools.
-- - Build only from f1_gold value objects, not from Silver raw/detail grain.
-- ============================================================

CREATE CATALOG IF NOT EXISTS f1;
USE CATALOG f1;

CREATE SCHEMA IF NOT EXISTS f1_gold_star;
USE f1_gold_star;

-- ============================================================
-- Cleanup for reruns
-- ============================================================

DROP TABLE IF EXISTS f1_gold_star.fact_kpi_snapshot;
DROP TABLE IF EXISTS f1_gold_star.fact_race_weekend;
DROP TABLE IF EXISTS f1_gold_star.fact_qualifying_season;
DROP TABLE IF EXISTS f1_gold_star.fact_circuit_risk;
DROP TABLE IF EXISTS f1_gold_star.fact_constructor_season;
DROP TABLE IF EXISTS f1_gold_star.fact_driver_season;

DROP TABLE IF EXISTS f1_gold_star.dim_kpi;
DROP TABLE IF EXISTS f1_gold_star.dim_circuit;
DROP TABLE IF EXISTS f1_gold_star.dim_constructor;
DROP TABLE IF EXISTS f1_gold_star.dim_driver;
DROP TABLE IF EXISTS f1_gold_star.dim_season;

-- ============================================================
-- Dimensions
-- ============================================================

CREATE OR REPLACE TABLE f1_gold_star.dim_season
USING DELTA
AS
WITH seasons AS (
    SELECT season_year FROM f1_gold.mart_driver_season
    UNION
    SELECT season_year FROM f1_gold.mart_constructor_season
    UNION
    SELECT season_year FROM f1_gold.mart_qualifying_effect_season
    UNION
    SELECT season_year FROM f1_gold.mart_race_weekend
)
SELECT
    s.season_year,
    MAX(mrw.season_total_races) AS season_total_races,
    MIN(mrw.race_date) AS first_race_date,
    MAX(mrw.race_date) AS last_race_date,
    MAX(CASE WHEN mrw.has_sprint_weekend THEN TRUE ELSE FALSE END) AS has_sprint_weekend
FROM seasons s
LEFT JOIN f1_gold.mart_race_weekend mrw
    ON s.season_year = mrw.season_year
GROUP BY s.season_year;

CREATE OR REPLACE TABLE f1_gold_star.dim_driver
USING DELTA
AS
SELECT
    driverId,
    driver_name,
    MIN(season_year) AS first_season,
    MAX(season_year) AS last_season,
    COUNT(*) AS seasons_competed
FROM f1_gold.mart_driver_season
GROUP BY driverId, driver_name;

CREATE OR REPLACE TABLE f1_gold_star.dim_constructor
USING DELTA
AS
WITH constructors AS (
    SELECT
        constructorId,
        constructor_name,
        season_year
    FROM f1_gold.mart_constructor_season
    UNION ALL
    SELECT
        primary_constructorId AS constructorId,
        primary_constructor_name AS constructor_name,
        season_year
    FROM f1_gold.mart_driver_season
    WHERE primary_constructorId IS NOT NULL
)
SELECT
    constructorId,
    constructor_name,
    MIN(season_year) AS first_season,
    MAX(season_year) AS last_season,
    COUNT(DISTINCT season_year) AS seasons_present
FROM constructors
GROUP BY constructorId, constructor_name;

CREATE OR REPLACE TABLE f1_gold_star.dim_circuit
USING DELTA
AS
SELECT
    circuitId,
    circuit_name,
    country,
    first_season,
    last_season,
    race_weekends_hosted
FROM f1_gold.mart_circuit_risk;

CREATE OR REPLACE TABLE f1_gold_star.dim_kpi
USING DELTA
AS
SELECT
    kpi_code,
    kpi_name,
    business_question,
    business_definition,
    formula_definition,
    unit_of_measure,
    grain_level,
    source_objects
FROM f1_gold.kpi_catalog;

-- ============================================================
-- Facts
-- ============================================================

CREATE OR REPLACE TABLE f1_gold_star.fact_driver_season
USING DELTA
AS
SELECT
    season_year,
    driverId,
    primary_constructorId AS constructorId,
    race_entries,
    race_weekends,
    shared_drive_entries,
    wins,
    podiums,
    poles,
    race_points,
    sprint_points,
    total_points,
    avg_starting_grid,
    avg_finish_position,
    avg_positions_gained,
    avg_qualifying_delta,
    classified_finishes,
    non_classified_finishes,
    non_classified_rate_pct,
    win_rate_pct,
    podium_rate_pct,
    pole_rate_pct,
    best_event_points,
    best_positions_gained,
    championship_position,
    final_standings_points,
    championship_wins
FROM f1_gold.mart_driver_season;

CREATE OR REPLACE TABLE f1_gold_star.fact_constructor_season
USING DELTA
AS
SELECT
    season_year,
    constructorId,
    race_entries,
    race_weekends,
    drivers_used,
    shared_drive_entries,
    wins,
    podiums,
    poles,
    race_points_from_entries,
    sprint_points,
    total_points,
    official_constructor_race_points,
    avg_starting_grid,
    avg_finish_position,
    avg_positions_gained,
    classified_entries,
    non_classified_entries,
    non_classified_rate_pct,
    win_rate_pct,
    podium_rate_pct,
    championship_position,
    final_standings_points,
    championship_wins
FROM f1_gold.mart_constructor_season;

CREATE OR REPLACE TABLE f1_gold_star.fact_circuit_risk
USING DELTA
AS
SELECT
    circuitId,
    race_weekends_hosted,
    first_season,
    last_season,
    total_entries,
    unique_drivers,
    classified_entries,
    non_classified_entries,
    non_classified_rate_pct,
    mechanical_non_classified_entries,
    accident_non_classified_entries,
    disqualified_entries,
    pole_to_win_occurrences,
    pole_to_win_rate_pct,
    avg_positions_gained,
    avg_points_per_entry
FROM f1_gold.mart_circuit_risk;

CREATE OR REPLACE TABLE f1_gold_star.fact_qualifying_season
USING DELTA
AS
SELECT
    season_year,
    race_entries_analyzed,
    race_weekends,
    avg_qualifying_position,
    avg_finish_position,
    avg_positions_gained,
    avg_qualifying_to_finish_delta,
    winners_from_pole,
    pole_to_win_rate_pct,
    front_row_podium_entries,
    front_row_podium_rate_pct,
    winner_avg_grid,
    winner_avg_qualifying_position
FROM f1_gold.mart_qualifying_effect_season;

CREATE OR REPLACE TABLE f1_gold_star.fact_race_weekend
USING DELTA
AS
SELECT
    raceId,
    season_year,
    season_round,
    circuit_name,
    country,
    race_name,
    race_date,
    has_sprint_weekend,
    race_entries,
    unique_drivers,
    unique_constructors,
    total_event_points_awarded,
    classified_entries,
    non_classified_entries,
    non_classified_rate_pct,
    shared_drive_entries,
    winner_driver_name,
    winner_constructor_name,
    winner_starting_grid,
    pole_driver_name,
    pole_constructor_name,
    pole_converted_to_win,
    podium_names,
    total_pit_stops,
    avg_pit_stop_ms,
    max_positions_gained
FROM f1_gold.mart_race_weekend;

CREATE OR REPLACE TABLE f1_gold_star.fact_kpi_snapshot
USING DELTA
AS
SELECT
    kpi_code,
    kpi_value_numeric,
    kpi_value_text
FROM f1_gold.mart_kpi_snapshot;

-- ============================================================
-- Validation
-- ============================================================

SELECT COUNT(*) AS dim_season_rows FROM f1_gold_star.dim_season;
SELECT COUNT(*) AS dim_driver_rows FROM f1_gold_star.dim_driver;
SELECT COUNT(*) AS dim_constructor_rows FROM f1_gold_star.dim_constructor;
SELECT COUNT(*) AS dim_circuit_rows FROM f1_gold_star.dim_circuit;
SELECT COUNT(*) AS dim_kpi_rows FROM f1_gold_star.dim_kpi;
SELECT COUNT(*) AS fact_driver_season_rows FROM f1_gold_star.fact_driver_season;
SELECT COUNT(*) AS fact_constructor_season_rows FROM f1_gold_star.fact_constructor_season;
SELECT COUNT(*) AS fact_circuit_risk_rows FROM f1_gold_star.fact_circuit_risk;
SELECT COUNT(*) AS fact_qualifying_season_rows FROM f1_gold_star.fact_qualifying_season;
SELECT COUNT(*) AS fact_race_weekend_rows FROM f1_gold_star.fact_race_weekend;
SELECT COUNT(*) AS fact_kpi_snapshot_rows FROM f1_gold_star.fact_kpi_snapshot;
