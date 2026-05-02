-- Improved Silver layer for the F1 dataset in Databricks SQL.
--
-- Assumption:
-- - Schema f1 already exists and contains the typed base tables loaded from CSV.
-- - This script creates a curated Silver layer in schema f1_silver.
--
-- Optional for Unity Catalog:
-- USE CATALOG workspace;

CREATE CATALOG IF NOT EXISTS f1;
USE CATALOG f1;

CREATE SCHEMA IF NOT EXISTS f1_silver;
USE f1_silver;

-- ============================================================
-- Dimensions
-- ============================================================

CREATE OR REPLACE TABLE f1_silver.dim_drivers
USING DELTA
AS
WITH ranked AS (
    SELECT
        d.*,
        ROW_NUMBER() OVER (PARTITION BY d.driverId ORDER BY d.driverId) AS rn
    FROM f1.drivers d
)
SELECT
    driverId,
    LOWER(TRIM(driverRef)) AS driver_ref_normalized,
    number AS driver_number,
    UPPER(TRIM(code)) AS driver_code,
    TRIM(forename) AS forename,
    TRIM(surname) AS surname,
    TRIM(CONCAT_WS(' ', forename, surname)) AS driver_name,
    dob,
    INITCAP(TRIM(nationality)) AS nationality,
    url,
    CURRENT_TIMESTAMP() AS silver_loaded_at
FROM ranked
WHERE rn = 1;

CREATE OR REPLACE TABLE f1_silver.dim_constructors
USING DELTA
AS
WITH ranked AS (
    SELECT
        c.*,
        ROW_NUMBER() OVER (PARTITION BY c.constructorId ORDER BY c.constructorId) AS rn
    FROM f1.constructors c
)
SELECT
    constructorId,
    LOWER(TRIM(constructorRef)) AS constructor_ref_normalized,
    TRIM(name) AS constructor_name,
    INITCAP(TRIM(nationality)) AS nationality,
    url,
    CURRENT_TIMESTAMP() AS silver_loaded_at
FROM ranked
WHERE rn = 1;

CREATE OR REPLACE TABLE f1_silver.dim_circuits
USING DELTA
AS
WITH ranked AS (
    SELECT
        c.*,
        ROW_NUMBER() OVER (PARTITION BY c.circuitId ORDER BY c.circuitId) AS rn
    FROM f1.circuits c
)
SELECT
    circuitId,
    LOWER(TRIM(circuitRef)) AS circuit_ref_normalized,
    TRIM(name) AS circuit_name,
    INITCAP(TRIM(location)) AS location,
    INITCAP(TRIM(country)) AS country,
    lat,
    lng,
    alt,
    url,
    CURRENT_TIMESTAMP() AS silver_loaded_at
FROM ranked
WHERE rn = 1;

CREATE OR REPLACE TABLE f1_silver.dim_status
USING DELTA
AS
WITH ranked AS (
    SELECT
        s.*,
        ROW_NUMBER() OVER (PARTITION BY s.statusId ORDER BY s.statusId) AS rn
    FROM f1.status s
)
SELECT
    statusId,
    TRIM(status) AS status_name,
    CASE
        WHEN status = 'Finished' THEN 'finished'
        WHEN status LIKE '+%' THEN 'classified_lapped'
        WHEN LOWER(status) RLIKE 'accident|collision|spun off|damage' THEN 'accident_incident'
        WHEN LOWER(status) RLIKE 'disqual' THEN 'disqualified'
        WHEN LOWER(status) RLIKE 'engine|gearbox|transmission|clutch|electrical|hydraulic|brakes|suspension|wheel|tyre|puncture|fuel|oil|water|driveshaft|turbo|throttle|vibration|power unit|ers|ignition|radiator|axle|differential|overheating' THEN 'mechanical'
        ELSE 'other_dnf'
    END AS status_category,
    CASE
        WHEN status = 'Finished' OR status LIKE '+%' THEN TRUE
        ELSE FALSE
    END AS is_classified_finish,
    CASE
        WHEN status = 'Finished' THEN TRUE
        ELSE FALSE
    END AS finished_on_lead_lap,
    CURRENT_TIMESTAMP() AS silver_loaded_at
FROM ranked
WHERE rn = 1;

-- ============================================================
-- Facts
-- ============================================================

CREATE OR REPLACE TABLE f1_silver.fact_results
USING DELTA
PARTITIONED BY (season_year)
AS
WITH ranked AS (
    SELECT
        r.*,
        ROW_NUMBER() OVER (PARTITION BY r.resultId ORDER BY r.resultId) AS rn
    FROM f1.results r
)
SELECT
    r.resultId,
    ra.year AS season_year,
    r.raceId,
    r.driverId,
    r.constructorId,
    r.number AS car_number,
    r.grid,
    r.position AS finish_position_raw,
    r.positionText AS finish_position_text,
    r.positionOrder AS finish_position,
    r.points,
    r.laps,
    r.time AS finish_time_text,
    r.milliseconds AS finish_time_ms,
    r.fastestLap AS fastest_lap_number,
    r.`rank` AS fastest_lap_rank,
    r.fastestLapTime AS fastest_lap_time_text,
    CASE
        WHEN r.fastestLapTime IS NOT NULL THEN
            CAST(REGEXP_EXTRACT(r.fastestLapTime, '^(\\d+):', 1) AS INT) * 60000
            + CAST(REGEXP_EXTRACT(r.fastestLapTime, ':(\\d+)\\.', 1) AS INT) * 1000
            + CAST(REGEXP_EXTRACT(r.fastestLapTime, '\\.(\\d+)$', 1) AS INT)
        ELSE NULL
    END AS fastest_lap_time_ms,
    TRY_CAST(r.fastestLapSpeed AS DOUBLE) AS fastest_lap_speed_kph,
    r.statusId,
    s.status_name,
    s.status_category,
    s.is_classified_finish,
    s.finished_on_lead_lap,
    CASE WHEN r.positionOrder = 1 THEN TRUE ELSE FALSE END AS is_winner,
    CASE WHEN r.positionOrder <= 3 THEN TRUE ELSE FALSE END AS is_podium,
    CASE WHEN r.points > 0 THEN TRUE ELSE FALSE END AS scored_points,
    CASE WHEN r.grid = 1 THEN TRUE ELSE FALSE END AS started_from_pole,
    CURRENT_TIMESTAMP() AS silver_loaded_at
FROM ranked r
JOIN f1.races ra
    ON r.raceId = ra.raceId
LEFT JOIN f1_silver.dim_status s
    ON r.statusId = s.statusId
WHERE r.rn = 1;

CREATE OR REPLACE TABLE f1_silver.fact_sprint_results
USING DELTA
PARTITIONED BY (season_year)
AS
WITH ranked AS (
    SELECT
        sr.*,
        ROW_NUMBER() OVER (PARTITION BY sr.resultId ORDER BY sr.resultId) AS rn
    FROM f1.sprint_results sr
)
SELECT
    sr.resultId,
    ra.year AS season_year,
    sr.raceId,
    sr.driverId,
    sr.constructorId,
    sr.number AS car_number,
    sr.grid,
    sr.position AS finish_position_raw,
    sr.positionText AS finish_position_text,
    sr.positionOrder AS finish_position,
    sr.points,
    sr.laps,
    sr.time AS finish_time_text,
    sr.milliseconds AS finish_time_ms,
    sr.fastestLap AS fastest_lap_number,
    sr.fastestLapTime AS fastest_lap_time_text,
    CASE
        WHEN sr.fastestLapTime IS NOT NULL THEN
            CAST(REGEXP_EXTRACT(sr.fastestLapTime, '^(\\d+):', 1) AS INT) * 60000
            + CAST(REGEXP_EXTRACT(sr.fastestLapTime, ':(\\d+)\\.', 1) AS INT) * 1000
            + CAST(REGEXP_EXTRACT(sr.fastestLapTime, '\\.(\\d+)$', 1) AS INT)
        ELSE NULL
    END AS fastest_lap_time_ms,
    sr.statusId,
    s.status_name,
    s.status_category,
    s.is_classified_finish,
    CASE WHEN sr.positionOrder = 1 THEN TRUE ELSE FALSE END AS is_winner,
    CASE WHEN sr.positionOrder <= 3 THEN TRUE ELSE FALSE END AS is_podium,
    CASE WHEN sr.points > 0 THEN TRUE ELSE FALSE END AS scored_points,
    CURRENT_TIMESTAMP() AS silver_loaded_at
FROM ranked sr
JOIN f1.races ra
    ON sr.raceId = ra.raceId
LEFT JOIN f1_silver.dim_status s
    ON sr.statusId = s.statusId
WHERE sr.rn = 1;

CREATE OR REPLACE TABLE f1_silver.fact_qualifying
USING DELTA
PARTITIONED BY (season_year)
AS
WITH ranked AS (
    SELECT
        q.*,
        ROW_NUMBER() OVER (PARTITION BY q.qualifyId ORDER BY q.qualifyId) AS rn
    FROM f1.qualifying q
)
SELECT
    q.qualifyId,
    ra.year AS season_year,
    q.raceId,
    q.driverId,
    q.constructorId,
    q.number AS car_number,
    q.position AS qualifying_position,
    q.q1,
    q.q2,
    q.q3,
    CASE
        WHEN q.q1 IS NOT NULL THEN
            CAST(REGEXP_EXTRACT(q.q1, '^(\\d+):', 1) AS INT) * 60000
            + CAST(REGEXP_EXTRACT(q.q1, ':(\\d+)\\.', 1) AS INT) * 1000
            + CAST(REGEXP_EXTRACT(q.q1, '\\.(\\d+)$', 1) AS INT)
        ELSE NULL
    END AS q1_ms,
    CASE
        WHEN q.q2 IS NOT NULL THEN
            CAST(REGEXP_EXTRACT(q.q2, '^(\\d+):', 1) AS INT) * 60000
            + CAST(REGEXP_EXTRACT(q.q2, ':(\\d+)\\.', 1) AS INT) * 1000
            + CAST(REGEXP_EXTRACT(q.q2, '\\.(\\d+)$', 1) AS INT)
        ELSE NULL
    END AS q2_ms,
    CASE
        WHEN q.q3 IS NOT NULL THEN
            CAST(REGEXP_EXTRACT(q.q3, '^(\\d+):', 1) AS INT) * 60000
            + CAST(REGEXP_EXTRACT(q.q3, ':(\\d+)\\.', 1) AS INT) * 1000
            + CAST(REGEXP_EXTRACT(q.q3, '\\.(\\d+)$', 1) AS INT)
        ELSE NULL
    END AS q3_ms,
    CASE
        WHEN q.q3 IS NOT NULL THEN 'Q3'
        WHEN q.q2 IS NOT NULL THEN 'Q2'
        WHEN q.q1 IS NOT NULL THEN 'Q1'
        ELSE 'NO_TIME'
    END AS final_session_reached,
    CASE
        WHEN q.q3 IS NOT NULL THEN
            CAST(REGEXP_EXTRACT(q.q3, '^(\\d+):', 1) AS INT) * 60000
            + CAST(REGEXP_EXTRACT(q.q3, ':(\\d+)\\.', 1) AS INT) * 1000
            + CAST(REGEXP_EXTRACT(q.q3, '\\.(\\d+)$', 1) AS INT)
        WHEN q.q2 IS NOT NULL THEN
            CAST(REGEXP_EXTRACT(q.q2, '^(\\d+):', 1) AS INT) * 60000
            + CAST(REGEXP_EXTRACT(q.q2, ':(\\d+)\\.', 1) AS INT) * 1000
            + CAST(REGEXP_EXTRACT(q.q2, '\\.(\\d+)$', 1) AS INT)
        WHEN q.q1 IS NOT NULL THEN
            CAST(REGEXP_EXTRACT(q.q1, '^(\\d+):', 1) AS INT) * 60000
            + CAST(REGEXP_EXTRACT(q.q1, ':(\\d+)\\.', 1) AS INT) * 1000
            + CAST(REGEXP_EXTRACT(q.q1, '\\.(\\d+)$', 1) AS INT)
        ELSE NULL
    END AS best_qualifying_time_ms,
    CURRENT_TIMESTAMP() AS silver_loaded_at
FROM ranked q
JOIN f1.races ra
    ON q.raceId = ra.raceId
WHERE q.rn = 1;

CREATE OR REPLACE TABLE f1_silver.fact_lap_times
USING DELTA
PARTITIONED BY (season_year)
AS
WITH ranked AS (
    SELECT
        lt.*,
        ROW_NUMBER() OVER (
            PARTITION BY lt.raceId, lt.driverId, lt.lap
            ORDER BY lt.raceId, lt.driverId, lt.lap
        ) AS rn
    FROM f1.lap_times lt
)
SELECT
    ra.year AS season_year,
    lt.raceId,
    lt.driverId,
    lt.lap,
    lt.position AS lap_position,
    lt.time AS lap_time_text,
    lt.milliseconds AS lap_time_ms,
    ROUND(lt.milliseconds / 1000.0, 3) AS lap_time_seconds,
    CURRENT_TIMESTAMP() AS silver_loaded_at
FROM ranked lt
JOIN f1.races ra
    ON lt.raceId = ra.raceId
WHERE lt.rn = 1;

CREATE OR REPLACE TABLE f1_silver.fact_pit_stops
USING DELTA
PARTITIONED BY (season_year)
AS
WITH ranked AS (
    SELECT
        ps.*,
        ROW_NUMBER() OVER (
            PARTITION BY ps.raceId, ps.driverId, ps.stop
            ORDER BY ps.raceId, ps.driverId, ps.stop
        ) AS rn
    FROM f1.pit_stops ps
)
SELECT
    ra.year AS season_year,
    ps.raceId,
    ps.driverId,
    ps.stop,
    ps.lap,
    ps.time AS pit_time_text,
    ps.duration AS pit_duration_text,
    ps.milliseconds AS pit_duration_ms,
    ROUND(ps.milliseconds / 1000.0, 3) AS pit_duration_seconds,
    CURRENT_TIMESTAMP() AS silver_loaded_at
FROM ranked ps
JOIN f1.races ra
    ON ps.raceId = ra.raceId
WHERE ps.rn = 1;

CREATE OR REPLACE TABLE f1_silver.fact_driver_standings
USING DELTA
PARTITIONED BY (season_year)
AS
WITH ranked AS (
    SELECT
        ds.*,
        ROW_NUMBER() OVER (PARTITION BY ds.driverStandingsId ORDER BY ds.driverStandingsId) AS rn
    FROM f1.driver_standings ds
)
SELECT
    ds.driverStandingsId,
    ra.year AS season_year,
    ds.raceId,
    ds.driverId,
    ds.points,
    ds.position,
    ds.positionText,
    ds.wins,
    CURRENT_TIMESTAMP() AS silver_loaded_at
FROM ranked ds
JOIN f1.races ra
    ON ds.raceId = ra.raceId
WHERE ds.rn = 1;

CREATE OR REPLACE TABLE f1_silver.fact_constructor_standings
USING DELTA
PARTITIONED BY (season_year)
AS
WITH ranked AS (
    SELECT
        cs.*,
        ROW_NUMBER() OVER (PARTITION BY cs.constructorStandingsId ORDER BY cs.constructorStandingsId) AS rn
    FROM f1.constructor_standings cs
)
SELECT
    cs.constructorStandingsId,
    ra.year AS season_year,
    cs.raceId,
    cs.constructorId,
    cs.points,
    cs.position,
    cs.positionText,
    cs.wins,
    CURRENT_TIMESTAMP() AS silver_loaded_at
FROM ranked cs
JOIN f1.races ra
    ON cs.raceId = ra.raceId
WHERE cs.rn = 1;

-- ============================================================
-- Extended curated objects and monitoring views
-- ============================================================

CREATE OR REPLACE TABLE f1_silver.dim_seasons
USING DELTA
AS
WITH ranked AS (
    SELECT
        s.*,
        ROW_NUMBER() OVER (PARTITION BY s.year ORDER BY s.year) AS rn
    FROM f1.seasons s
)
SELECT
    s.year AS season_year,
    s.url AS season_url,
    COUNT(DISTINCT r.raceId) AS total_races,
    MIN(r.date) AS first_race_date,
    MAX(r.date) AS last_race_date,
    SUM(
        CASE
            WHEN r.sprint_date IS NOT NULL OR r.sprint_time IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS scheduled_sprint_weekends,
    CASE
        WHEN SUM(
            CASE
                WHEN r.sprint_date IS NOT NULL OR r.sprint_time IS NOT NULL THEN 1
                ELSE 0
            END
        ) > 0 THEN TRUE
        ELSE FALSE
    END AS has_sprint_weekend,
    CURRENT_TIMESTAMP() AS silver_loaded_at
FROM ranked s
LEFT JOIN f1.races r
    ON s.year = r.year
WHERE s.rn = 1
GROUP BY s.year, s.url;

CREATE OR REPLACE TABLE f1_silver.dim_races
USING DELTA
AS
WITH ranked AS (
    SELECT
        r.*,
        ROW_NUMBER() OVER (PARTITION BY r.raceId ORDER BY r.raceId) AS rn
    FROM f1.races r
)
SELECT
    raceId,
    year AS season_year,
    round AS season_round,
    circuitId,
    TRIM(name) AS race_name,
    date AS race_date,
    time AS race_time_text,
    CASE
        WHEN date IS NOT NULL AND time IS NOT NULL
        THEN TO_TIMESTAMP(CONCAT(CAST(date AS STRING), ' ', time), 'yyyy-MM-dd HH:mm:ss')
        ELSE NULL
    END AS race_timestamp_utc,
    CASE
        WHEN fp1_date IS NOT NULL AND fp1_time IS NOT NULL
        THEN TO_TIMESTAMP(CONCAT(CAST(fp1_date AS STRING), ' ', fp1_time), 'yyyy-MM-dd HH:mm:ss')
        ELSE NULL
    END AS fp1_timestamp_utc,
    CASE
        WHEN fp2_date IS NOT NULL AND fp2_time IS NOT NULL
        THEN TO_TIMESTAMP(CONCAT(CAST(fp2_date AS STRING), ' ', fp2_time), 'yyyy-MM-dd HH:mm:ss')
        ELSE NULL
    END AS fp2_timestamp_utc,
    CASE
        WHEN fp3_date IS NOT NULL AND fp3_time IS NOT NULL
        THEN TO_TIMESTAMP(CONCAT(CAST(fp3_date AS STRING), ' ', fp3_time), 'yyyy-MM-dd HH:mm:ss')
        ELSE NULL
    END AS fp3_timestamp_utc,
    CASE
        WHEN quali_date IS NOT NULL AND quali_time IS NOT NULL
        THEN TO_TIMESTAMP(CONCAT(CAST(quali_date AS STRING), ' ', quali_time), 'yyyy-MM-dd HH:mm:ss')
        ELSE NULL
    END AS qualifying_timestamp_utc,
    CASE
        WHEN sprint_date IS NOT NULL AND sprint_time IS NOT NULL
        THEN TO_TIMESTAMP(CONCAT(CAST(sprint_date AS STRING), ' ', sprint_time), 'yyyy-MM-dd HH:mm:ss')
        ELSE NULL
    END AS sprint_timestamp_utc,
    CASE
        WHEN sprint_date IS NOT NULL OR sprint_time IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS has_sprint_weekend,
    CASE
        WHEN quali_date IS NOT NULL OR quali_time IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS has_qualifying_session,
    url,
    CURRENT_TIMESTAMP() AS silver_loaded_at
FROM ranked
WHERE rn = 1;

CREATE OR REPLACE TABLE f1_silver.fact_constructor_results
USING DELTA
PARTITIONED BY (season_year)
AS
WITH ranked AS (
    SELECT
        cr.*,
        ROW_NUMBER() OVER (PARTITION BY cr.constructorResultsId ORDER BY cr.constructorResultsId) AS rn
    FROM f1.constructor_results cr
)
SELECT
    cr.constructorResultsId,
    ra.year AS season_year,
    cr.raceId,
    cr.constructorId,
    cr.points,
    NULLIF(TRIM(cr.status), '') AS constructor_result_status,
    CASE
        WHEN COALESCE(cr.points, 0D) > 0 THEN TRUE
        ELSE FALSE
    END AS scored_points,
    CURRENT_TIMESTAMP() AS silver_loaded_at
FROM ranked cr
JOIN f1.races ra
    ON cr.raceId = ra.raceId
WHERE cr.rn = 1;

CREATE OR REPLACE TABLE f1_silver.fact_race_entries
USING DELTA
PARTITIONED BY (season_year)
AS
WITH duplicated_entries AS (
    SELECT
        raceId,
        driverId,
        COUNT(*) AS driver_race_entries
    FROM f1_silver.fact_results
    GROUP BY raceId, driverId
)
SELECT
    fr.resultId,
    fr.season_year,
    fr.raceId,
    dr.circuitId,
    fr.driverId,
    fr.constructorId,
    fr.statusId,
    fq.qualifyId,
    fsr.resultId AS sprint_resultId,
    fr.car_number,
    fq.qualifying_position,
    fr.grid AS starting_grid,
    fr.finish_position,
    fr.finish_position_text,
    fr.points AS race_points,
    COALESCE(fsr.points, 0D) AS sprint_points,
    fr.points + COALESCE(fsr.points, 0D) AS total_event_points,
    fr.laps AS race_laps_completed,
    fr.finish_time_ms,
    fr.fastest_lap_number,
    fr.fastest_lap_time_ms,
    fr.fastest_lap_speed_kph,
    fsr.finish_position AS sprint_finish_position,
    fsr.fastest_lap_time_ms AS sprint_fastest_lap_time_ms,
    fr.status_category,
    fr.is_classified_finish,
    fr.finished_on_lead_lap,
    fr.is_winner,
    fr.is_podium,
    fr.scored_points AS scored_race_points,
    CASE
        WHEN COALESCE(fsr.points, 0D) > 0 THEN TRUE
        ELSE FALSE
    END AS scored_sprint_points,
    CASE
        WHEN fq.qualifying_position = 1 THEN TRUE
        ELSE FALSE
    END AS qualified_on_pole,
    fr.started_from_pole,
    CASE
        WHEN fr.grid > 0 AND fr.finish_position IS NOT NULL THEN fr.grid - fr.finish_position
        ELSE NULL
    END AS positions_gained,
    CASE
        WHEN fq.qualifying_position IS NOT NULL AND fr.finish_position IS NOT NULL
        THEN fq.qualifying_position - fr.finish_position
        ELSE NULL
    END AS qualifying_to_finish_delta,
    dup.driver_race_entries,
    CASE
        WHEN dup.driver_race_entries > 1 THEN TRUE
        ELSE FALSE
    END AS shared_drive_candidate,
    CURRENT_TIMESTAMP() AS silver_loaded_at
FROM f1_silver.fact_results fr
JOIN f1_silver.dim_races dr
    ON fr.raceId = dr.raceId
LEFT JOIN f1_silver.fact_qualifying fq
    ON fr.raceId = fq.raceId
   AND fr.driverId = fq.driverId
LEFT JOIN f1_silver.fact_sprint_results fsr
    ON fr.raceId = fsr.raceId
   AND fr.driverId = fsr.driverId
LEFT JOIN duplicated_entries dup
    ON fr.raceId = dup.raceId
   AND fr.driverId = dup.driverId;

CREATE OR REPLACE VIEW f1_silver.vw_data_quality_checks AS
SELECT 'results_duplicate_resultId' AS check_name, COUNT(*) AS issue_count
FROM (
    SELECT resultId
    FROM f1.results
    GROUP BY resultId
    HAVING COUNT(*) > 1
) t

UNION ALL

SELECT 'lap_times_duplicate_pk' AS check_name, COUNT(*) AS issue_count
FROM (
    SELECT raceId, driverId, lap
    FROM f1.lap_times
    GROUP BY raceId, driverId, lap
    HAVING COUNT(*) > 1
) t

UNION ALL

SELECT 'pit_stops_duplicate_pk' AS check_name, COUNT(*) AS issue_count
FROM (
    SELECT raceId, driverId, stop
    FROM f1.pit_stops
    GROUP BY raceId, driverId, stop
    HAVING COUNT(*) > 1
) t

UNION ALL

SELECT 'results_missing_driver' AS check_name, COUNT(*) AS issue_count
FROM f1.results r
LEFT JOIN f1.drivers d ON r.driverId = d.driverId
WHERE d.driverId IS NULL

UNION ALL

SELECT 'results_missing_race' AS check_name, COUNT(*) AS issue_count
FROM f1.results r
LEFT JOIN f1.races ra ON r.raceId = ra.raceId
WHERE ra.raceId IS NULL

UNION ALL

SELECT 'results_missing_constructor' AS check_name, COUNT(*) AS issue_count
FROM f1.results r
LEFT JOIN f1.constructors c ON r.constructorId = c.constructorId
WHERE c.constructorId IS NULL

UNION ALL

SELECT 'results_missing_status' AS check_name, COUNT(*) AS issue_count
FROM f1.results r
LEFT JOIN f1.status s ON r.statusId = s.statusId
WHERE s.statusId IS NULL

UNION ALL

SELECT 'results_duplicate_race_driver' AS check_name, COUNT(*) AS issue_count
FROM (
    SELECT raceId, driverId
    FROM f1.results
    GROUP BY raceId, driverId
    HAVING COUNT(*) > 1
) t

UNION ALL

SELECT 'constructor_results_missing_race' AS check_name, COUNT(*) AS issue_count
FROM f1.constructor_results cr
LEFT JOIN f1.races r
    ON cr.raceId = r.raceId
WHERE r.raceId IS NULL

UNION ALL

SELECT 'constructor_results_missing_constructor' AS check_name, COUNT(*) AS issue_count
FROM f1.constructor_results cr
LEFT JOIN f1.constructors c
    ON cr.constructorId = c.constructorId
WHERE c.constructorId IS NULL;

CREATE OR REPLACE VIEW f1_silver.vw_silver_summary AS
SELECT 'dim_drivers' AS object_name, COUNT(*) AS row_count FROM f1_silver.dim_drivers
UNION ALL
SELECT 'dim_constructors', COUNT(*) FROM f1_silver.dim_constructors
UNION ALL
SELECT 'dim_circuits', COUNT(*) FROM f1_silver.dim_circuits
UNION ALL
SELECT 'dim_status', COUNT(*) FROM f1_silver.dim_status
UNION ALL
SELECT 'dim_seasons', COUNT(*) FROM f1_silver.dim_seasons
UNION ALL
SELECT 'dim_races', COUNT(*) FROM f1_silver.dim_races
UNION ALL
SELECT 'fact_results', COUNT(*) FROM f1_silver.fact_results
UNION ALL
SELECT 'fact_sprint_results', COUNT(*) FROM f1_silver.fact_sprint_results
UNION ALL
SELECT 'fact_constructor_results', COUNT(*) FROM f1_silver.fact_constructor_results
UNION ALL
SELECT 'fact_qualifying', COUNT(*) FROM f1_silver.fact_qualifying
UNION ALL
SELECT 'fact_lap_times', COUNT(*) FROM f1_silver.fact_lap_times
UNION ALL
SELECT 'fact_pit_stops', COUNT(*) FROM f1_silver.fact_pit_stops
UNION ALL
SELECT 'fact_driver_standings', COUNT(*) FROM f1_silver.fact_driver_standings
UNION ALL
SELECT 'fact_constructor_standings', COUNT(*) FROM f1_silver.fact_constructor_standings
UNION ALL
SELECT 'fact_race_entries', COUNT(*) FROM f1_silver.fact_race_entries;

-- Optional post-load maintenance in Databricks:
-- OPTIMIZE fact_results ZORDER BY (raceId, driverId, constructorId);
-- OPTIMIZE fact_lap_times ZORDER BY (raceId, driverId, lap);
-- OPTIMIZE fact_pit_stops ZORDER BY (raceId, driverId, stop);
-- OPTIMIZE fact_race_entries ZORDER BY (raceId, driverId, constructorId);
