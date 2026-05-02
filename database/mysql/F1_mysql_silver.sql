-- =========================================================
-- Silver layer for local MySQL / MariaDB
-- Source database: F1
-- Target database: F1_silver
-- =========================================================

CREATE DATABASE IF NOT EXISTS F1_silver
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE F1_silver;

-- =========================================================
-- Cleanup for reruns
-- =========================================================

DROP VIEW IF EXISTS vw_silver_summary;
DROP VIEW IF EXISTS vw_data_quality_checks;

DROP TABLE IF EXISTS fact_race_entries;
DROP TABLE IF EXISTS fact_constructor_results;
DROP TABLE IF EXISTS fact_constructor_standings;
DROP TABLE IF EXISTS fact_driver_standings;
DROP TABLE IF EXISTS fact_pit_stops;
DROP TABLE IF EXISTS fact_lap_times;
DROP TABLE IF EXISTS fact_qualifying;
DROP TABLE IF EXISTS fact_sprint_results;
DROP TABLE IF EXISTS fact_results;

DROP TABLE IF EXISTS dim_races;
DROP TABLE IF EXISTS dim_seasons;
DROP TABLE IF EXISTS dim_status;
DROP TABLE IF EXISTS dim_circuits;
DROP TABLE IF EXISTS dim_constructors;
DROP TABLE IF EXISTS dim_drivers;

-- =========================================================
-- Dimensions
-- =========================================================

CREATE TABLE dim_drivers AS
SELECT
    driverId,
    LOWER(TRIM(driverRef)) AS driver_ref_normalized,
    number AS driver_number,
    UPPER(TRIM(code)) AS driver_code,
    TRIM(forename) AS forename,
    TRIM(surname) AS surname,
    TRIM(CONCAT_WS(' ', forename, surname)) AS driver_name,
    dob,
    TRIM(nationality) AS nationality,
    url
FROM (
    SELECT
        d.*,
        ROW_NUMBER() OVER (PARTITION BY d.driverId ORDER BY d.driverId) AS rn
    FROM F1.drivers d
) t
WHERE rn = 1;

ALTER TABLE dim_drivers
    ADD PRIMARY KEY (driverId),
    ADD KEY idx_dim_drivers_name (driver_name),
    ADD KEY idx_dim_drivers_nationality (nationality);


CREATE TABLE dim_constructors AS
SELECT
    constructorId,
    LOWER(TRIM(constructorRef)) AS constructor_ref_normalized,
    TRIM(name) AS constructor_name,
    TRIM(nationality) AS nationality,
    url
FROM (
    SELECT
        c.*,
        ROW_NUMBER() OVER (PARTITION BY c.constructorId ORDER BY c.constructorId) AS rn
    FROM F1.constructors c
) t
WHERE rn = 1;

ALTER TABLE dim_constructors
    ADD PRIMARY KEY (constructorId),
    ADD KEY idx_dim_constructors_name (constructor_name);


CREATE TABLE dim_circuits AS
SELECT
    circuitId,
    LOWER(TRIM(circuitRef)) AS circuit_ref_normalized,
    TRIM(name) AS circuit_name,
    TRIM(location) AS location,
    TRIM(country) AS country,
    lat,
    lng,
    alt,
    url
FROM (
    SELECT
        c.*,
        ROW_NUMBER() OVER (PARTITION BY c.circuitId ORDER BY c.circuitId) AS rn
    FROM F1.circuits c
) t
WHERE rn = 1;

ALTER TABLE dim_circuits
    ADD PRIMARY KEY (circuitId),
    ADD KEY idx_dim_circuits_country (country),
    ADD KEY idx_dim_circuits_name (circuit_name);


CREATE TABLE dim_status AS
SELECT
    statusId,
    TRIM(status) AS status_name,
    CASE
        WHEN status = 'Finished' THEN 'finished'
        WHEN status LIKE '+%' THEN 'classified_lapped'
        WHEN LOWER(status) REGEXP 'accident|collision|spun off|damage' THEN 'accident_incident'
        WHEN LOWER(status) REGEXP 'disqual' THEN 'disqualified'
        WHEN LOWER(status) REGEXP 'engine|gearbox|transmission|clutch|electrical|hydraulic|brakes|suspension|wheel|tyre|puncture|fuel|oil|water|driveshaft|turbo|throttle|vibration|power unit|ers|ignition|radiator|axle|differential|overheating' THEN 'mechanical'
        ELSE 'other_dnf'
    END AS status_category,
    CASE
        WHEN status = 'Finished' OR status LIKE '+%' THEN 1
        ELSE 0
    END AS is_classified_finish,
    CASE
        WHEN status = 'Finished' THEN 1
        ELSE 0
    END AS finished_on_lead_lap
FROM (
    SELECT
        s.*,
        ROW_NUMBER() OVER (PARTITION BY s.statusId ORDER BY s.statusId) AS rn
    FROM F1.status s
) t
WHERE rn = 1;

ALTER TABLE dim_status
    ADD PRIMARY KEY (statusId),
    ADD KEY idx_dim_status_category (status_category);


CREATE TABLE dim_seasons AS
SELECT
    s.year AS season_year,
    s.url AS season_url,
    COUNT(DISTINCT r.raceId) AS total_races,
    MIN(r.date) AS first_race_date,
    MAX(r.date) AS last_race_date,
    SUM(CASE WHEN r.sprint_date IS NOT NULL OR r.sprint_time IS NOT NULL THEN 1 ELSE 0 END) AS scheduled_sprint_weekends,
    CASE
        WHEN SUM(CASE WHEN r.sprint_date IS NOT NULL OR r.sprint_time IS NOT NULL THEN 1 ELSE 0 END) > 0 THEN 1
        ELSE 0
    END AS has_sprint_weekend
FROM (
    SELECT
        x.*,
        ROW_NUMBER() OVER (PARTITION BY x.year ORDER BY x.year) AS rn
    FROM F1.seasons x
) s
LEFT JOIN F1.races r
    ON s.year = r.year
WHERE s.rn = 1
GROUP BY s.year, s.url;

ALTER TABLE dim_seasons
    ADD PRIMARY KEY (season_year);


CREATE TABLE dim_races AS
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
        THEN STR_TO_DATE(CONCAT(date, ' ', time), '%Y-%m-%d %H:%i:%s')
        ELSE NULL
    END AS race_timestamp_utc,
    CASE
        WHEN fp1_date IS NOT NULL AND fp1_time IS NOT NULL
        THEN STR_TO_DATE(CONCAT(fp1_date, ' ', fp1_time), '%Y-%m-%d %H:%i:%s')
        ELSE NULL
    END AS fp1_timestamp_utc,
    CASE
        WHEN fp2_date IS NOT NULL AND fp2_time IS NOT NULL
        THEN STR_TO_DATE(CONCAT(fp2_date, ' ', fp2_time), '%Y-%m-%d %H:%i:%s')
        ELSE NULL
    END AS fp2_timestamp_utc,
    CASE
        WHEN fp3_date IS NOT NULL AND fp3_time IS NOT NULL
        THEN STR_TO_DATE(CONCAT(fp3_date, ' ', fp3_time), '%Y-%m-%d %H:%i:%s')
        ELSE NULL
    END AS fp3_timestamp_utc,
    CASE
        WHEN quali_date IS NOT NULL AND quali_time IS NOT NULL
        THEN STR_TO_DATE(CONCAT(quali_date, ' ', quali_time), '%Y-%m-%d %H:%i:%s')
        ELSE NULL
    END AS qualifying_timestamp_utc,
    CASE
        WHEN sprint_date IS NOT NULL AND sprint_time IS NOT NULL
        THEN STR_TO_DATE(CONCAT(sprint_date, ' ', sprint_time), '%Y-%m-%d %H:%i:%s')
        ELSE NULL
    END AS sprint_timestamp_utc,
    CASE
        WHEN sprint_date IS NOT NULL OR sprint_time IS NOT NULL THEN 1
        ELSE 0
    END AS has_sprint_weekend,
    CASE
        WHEN quali_date IS NOT NULL OR quali_time IS NOT NULL THEN 1
        ELSE 0
    END AS has_qualifying_session,
    url
FROM (
    SELECT
        r.*,
        ROW_NUMBER() OVER (PARTITION BY r.raceId ORDER BY r.raceId) AS rn
    FROM F1.races r
) t
WHERE rn = 1;

ALTER TABLE dim_races
    ADD PRIMARY KEY (raceId),
    ADD KEY idx_dim_races_year_round (season_year, season_round),
    ADD KEY idx_dim_races_circuit (circuitId);

-- =========================================================
-- Facts
-- =========================================================

CREATE TABLE fact_results AS
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
            CAST(SUBSTRING_INDEX(r.fastestLapTime, ':', 1) AS UNSIGNED) * 60000
            + CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(r.fastestLapTime, '.', 1), ':', -1) AS UNSIGNED) * 1000
            + CAST(SUBSTRING_INDEX(r.fastestLapTime, '.', -1) AS UNSIGNED)
        ELSE NULL
    END AS fastest_lap_time_ms,
    CAST(r.fastestLapSpeed AS DECIMAL(10,3)) AS fastest_lap_speed_kph,
    r.statusId,
    s.status_name,
    s.status_category,
    s.is_classified_finish,
    s.finished_on_lead_lap,
    CASE WHEN r.positionOrder = 1 THEN 1 ELSE 0 END AS is_winner,
    CASE WHEN r.positionOrder <= 3 THEN 1 ELSE 0 END AS is_podium,
    CASE WHEN r.points > 0 THEN 1 ELSE 0 END AS scored_points,
    CASE WHEN r.grid = 1 THEN 1 ELSE 0 END AS started_from_pole
FROM (
    SELECT
        x.*,
        ROW_NUMBER() OVER (PARTITION BY x.resultId ORDER BY x.resultId) AS rn
    FROM F1.results x
) r
JOIN F1.races ra
    ON r.raceId = ra.raceId
LEFT JOIN dim_status s
    ON r.statusId = s.statusId
WHERE r.rn = 1;

ALTER TABLE fact_results
    ADD PRIMARY KEY (resultId),
    ADD KEY idx_fact_results_race_driver (raceId, driverId),
    ADD KEY idx_fact_results_year (season_year),
    ADD KEY idx_fact_results_constructor (constructorId),
    ADD KEY idx_fact_results_status (statusId);


CREATE TABLE fact_sprint_results AS
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
            CAST(SUBSTRING_INDEX(sr.fastestLapTime, ':', 1) AS UNSIGNED) * 60000
            + CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(sr.fastestLapTime, '.', 1), ':', -1) AS UNSIGNED) * 1000
            + CAST(SUBSTRING_INDEX(sr.fastestLapTime, '.', -1) AS UNSIGNED)
        ELSE NULL
    END AS fastest_lap_time_ms,
    sr.statusId,
    s.status_name,
    s.status_category,
    s.is_classified_finish,
    CASE WHEN sr.positionOrder = 1 THEN 1 ELSE 0 END AS is_winner,
    CASE WHEN sr.positionOrder <= 3 THEN 1 ELSE 0 END AS is_podium,
    CASE WHEN sr.points > 0 THEN 1 ELSE 0 END AS scored_points
FROM (
    SELECT
        x.*,
        ROW_NUMBER() OVER (PARTITION BY x.resultId ORDER BY x.resultId) AS rn
    FROM F1.sprint_results x
) sr
JOIN F1.races ra
    ON sr.raceId = ra.raceId
LEFT JOIN dim_status s
    ON sr.statusId = s.statusId
WHERE sr.rn = 1;

ALTER TABLE fact_sprint_results
    ADD PRIMARY KEY (resultId),
    ADD KEY idx_fact_sprint_race_driver (raceId, driverId),
    ADD KEY idx_fact_sprint_year (season_year);


CREATE TABLE fact_constructor_results AS
SELECT
    cr.constructorResultsId,
    ra.year AS season_year,
    cr.raceId,
    cr.constructorId,
    cr.points,
    NULLIF(TRIM(cr.status), '') AS constructor_result_status,
    CASE WHEN COALESCE(cr.points, 0) > 0 THEN 1 ELSE 0 END AS scored_points
FROM (
    SELECT
        x.*,
        ROW_NUMBER() OVER (PARTITION BY x.constructorResultsId ORDER BY x.constructorResultsId) AS rn
    FROM F1.constructor_results x
) cr
JOIN F1.races ra
    ON cr.raceId = ra.raceId
WHERE cr.rn = 1;

ALTER TABLE fact_constructor_results
    ADD PRIMARY KEY (constructorResultsId),
    ADD KEY idx_fact_constructor_results_year (season_year),
    ADD KEY idx_fact_constructor_results_race_constructor (raceId, constructorId);


CREATE TABLE fact_qualifying AS
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
            CAST(SUBSTRING_INDEX(q.q1, ':', 1) AS UNSIGNED) * 60000
            + CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(q.q1, '.', 1), ':', -1) AS UNSIGNED) * 1000
            + CAST(SUBSTRING_INDEX(q.q1, '.', -1) AS UNSIGNED)
        ELSE NULL
    END AS q1_ms,
    CASE
        WHEN q.q2 IS NOT NULL THEN
            CAST(SUBSTRING_INDEX(q.q2, ':', 1) AS UNSIGNED) * 60000
            + CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(q.q2, '.', 1), ':', -1) AS UNSIGNED) * 1000
            + CAST(SUBSTRING_INDEX(q.q2, '.', -1) AS UNSIGNED)
        ELSE NULL
    END AS q2_ms,
    CASE
        WHEN q.q3 IS NOT NULL THEN
            CAST(SUBSTRING_INDEX(q.q3, ':', 1) AS UNSIGNED) * 60000
            + CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(q.q3, '.', 1), ':', -1) AS UNSIGNED) * 1000
            + CAST(SUBSTRING_INDEX(q.q3, '.', -1) AS UNSIGNED)
        ELSE NULL
    END AS q3_ms,
    CASE
        WHEN q.q3 IS NOT NULL THEN 'Q3'
        WHEN q.q2 IS NOT NULL THEN 'Q2'
        WHEN q.q1 IS NOT NULL THEN 'Q1'
        ELSE 'NO_TIME'
    END AS final_session_reached
FROM (
    SELECT
        x.*,
        ROW_NUMBER() OVER (PARTITION BY x.qualifyId ORDER BY x.qualifyId) AS rn
    FROM F1.qualifying x
) q
JOIN F1.races ra
    ON q.raceId = ra.raceId
WHERE q.rn = 1;

ALTER TABLE fact_qualifying
    ADD PRIMARY KEY (qualifyId),
    ADD KEY idx_fact_qualifying_race_driver (raceId, driverId),
    ADD KEY idx_fact_qualifying_year (season_year);


CREATE TABLE fact_lap_times AS
SELECT
    ra.year AS season_year,
    lt.raceId,
    lt.driverId,
    lt.lap,
    lt.position AS lap_position,
    lt.time AS lap_time_text,
    lt.milliseconds AS lap_time_ms,
    ROUND(lt.milliseconds / 1000.0, 3) AS lap_time_seconds
FROM (
    SELECT
        x.*,
        ROW_NUMBER() OVER (
            PARTITION BY x.raceId, x.driverId, x.lap
            ORDER BY x.raceId, x.driverId, x.lap
        ) AS rn
    FROM F1.lap_times x
) lt
JOIN F1.races ra
    ON lt.raceId = ra.raceId
WHERE lt.rn = 1;

ALTER TABLE fact_lap_times
    ADD PRIMARY KEY (raceId, driverId, lap),
    ADD KEY idx_fact_lap_times_year (season_year),
    ADD KEY idx_fact_lap_times_driver (driverId);


CREATE TABLE fact_pit_stops AS
SELECT
    ra.year AS season_year,
    ps.raceId,
    ps.driverId,
    ps.stop,
    ps.lap,
    ps.time AS pit_time_text,
    ps.duration AS pit_duration_text,
    ps.milliseconds AS pit_duration_ms,
    ROUND(ps.milliseconds / 1000.0, 3) AS pit_duration_seconds
FROM (
    SELECT
        x.*,
        ROW_NUMBER() OVER (
            PARTITION BY x.raceId, x.driverId, x.stop
            ORDER BY x.raceId, x.driverId, x.stop
        ) AS rn
    FROM F1.pit_stops x
) ps
JOIN F1.races ra
    ON ps.raceId = ra.raceId
WHERE ps.rn = 1;

ALTER TABLE fact_pit_stops
    ADD PRIMARY KEY (raceId, driverId, stop),
    ADD KEY idx_fact_pit_stops_year (season_year),
    ADD KEY idx_fact_pit_stops_driver (driverId);


CREATE TABLE fact_driver_standings AS
SELECT
    ds.driverStandingsId,
    ra.year AS season_year,
    ds.raceId,
    ds.driverId,
    ds.points,
    ds.position,
    ds.positionText,
    ds.wins
FROM (
    SELECT
        x.*,
        ROW_NUMBER() OVER (PARTITION BY x.driverStandingsId ORDER BY x.driverStandingsId) AS rn
    FROM F1.driver_standings x
) ds
JOIN F1.races ra
    ON ds.raceId = ra.raceId
WHERE ds.rn = 1;

ALTER TABLE fact_driver_standings
    ADD PRIMARY KEY (driverStandingsId),
    ADD KEY idx_fact_driver_standings_year (season_year),
    ADD KEY idx_fact_driver_standings_race_driver (raceId, driverId);


CREATE TABLE fact_constructor_standings AS
SELECT
    cs.constructorStandingsId,
    ra.year AS season_year,
    cs.raceId,
    cs.constructorId,
    cs.points,
    cs.position,
    cs.positionText,
    cs.wins
FROM (
    SELECT
        x.*,
        ROW_NUMBER() OVER (PARTITION BY x.constructorStandingsId ORDER BY x.constructorStandingsId) AS rn
    FROM F1.constructor_standings x
) cs
JOIN F1.races ra
    ON cs.raceId = ra.raceId
WHERE cs.rn = 1;

ALTER TABLE fact_constructor_standings
    ADD PRIMARY KEY (constructorStandingsId),
    ADD KEY idx_fact_constructor_standings_year (season_year),
    ADD KEY idx_fact_constructor_standings_race_constructor (raceId, constructorId);


CREATE TABLE fact_race_entries AS
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
    COALESCE(fsr.points, 0) AS sprint_points,
    fr.points + COALESCE(fsr.points, 0) AS total_event_points,
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
    CASE WHEN COALESCE(fsr.points, 0) > 0 THEN 1 ELSE 0 END AS scored_sprint_points,
    CASE WHEN fq.qualifying_position = 1 THEN 1 ELSE 0 END AS qualified_on_pole,
    fr.started_from_pole,
    CASE
        WHEN fr.grid > 0 AND fr.finish_position IS NOT NULL THEN fr.grid - fr.finish_position
        ELSE NULL
    END AS positions_gained,
    CASE
        WHEN fq.qualifying_position IS NOT NULL AND fr.finish_position IS NOT NULL THEN fq.qualifying_position - fr.finish_position
        ELSE NULL
    END AS qualifying_to_finish_delta,
    dup.driver_race_entries,
    CASE
        WHEN dup.driver_race_entries > 1 THEN 1
        ELSE 0
    END AS shared_drive_candidate
FROM fact_results fr
JOIN dim_races dr
    ON fr.raceId = dr.raceId
LEFT JOIN fact_qualifying fq
    ON fr.raceId = fq.raceId
   AND fr.driverId = fq.driverId
LEFT JOIN fact_sprint_results fsr
    ON fr.raceId = fsr.raceId
   AND fr.driverId = fsr.driverId
LEFT JOIN (
    SELECT
        raceId,
        driverId,
        COUNT(*) AS driver_race_entries
    FROM fact_results
    GROUP BY raceId, driverId
) dup
    ON fr.raceId = dup.raceId
   AND fr.driverId = dup.driverId;

ALTER TABLE fact_race_entries
    ADD PRIMARY KEY (resultId),
    ADD KEY idx_fact_race_entries_year (season_year),
    ADD KEY idx_fact_race_entries_race_driver (raceId, driverId),
    ADD KEY idx_fact_race_entries_constructor (constructorId),
    ADD KEY idx_fact_race_entries_status (statusId),
    ADD KEY idx_fact_race_entries_circuit (circuitId);

-- =========================================================
-- Referential integrity
-- =========================================================

ALTER TABLE dim_races
    ADD CONSTRAINT fk_dim_races_season
    FOREIGN KEY (season_year) REFERENCES dim_seasons (season_year),
    ADD CONSTRAINT fk_dim_races_circuit
    FOREIGN KEY (circuitId) REFERENCES dim_circuits (circuitId);

ALTER TABLE fact_results
    ADD CONSTRAINT fk_fact_results_race
    FOREIGN KEY (raceId) REFERENCES dim_races (raceId),
    ADD CONSTRAINT fk_fact_results_driver
    FOREIGN KEY (driverId) REFERENCES dim_drivers (driverId),
    ADD CONSTRAINT fk_fact_results_constructor
    FOREIGN KEY (constructorId) REFERENCES dim_constructors (constructorId),
    ADD CONSTRAINT fk_fact_results_status
    FOREIGN KEY (statusId) REFERENCES dim_status (statusId);

ALTER TABLE fact_sprint_results
    ADD KEY idx_fact_sprint_constructor (constructorId),
    ADD KEY idx_fact_sprint_status (statusId),
    ADD CONSTRAINT fk_fact_sprint_race
    FOREIGN KEY (raceId) REFERENCES dim_races (raceId),
    ADD CONSTRAINT fk_fact_sprint_driver
    FOREIGN KEY (driverId) REFERENCES dim_drivers (driverId),
    ADD CONSTRAINT fk_fact_sprint_constructor
    FOREIGN KEY (constructorId) REFERENCES dim_constructors (constructorId),
    ADD CONSTRAINT fk_fact_sprint_status
    FOREIGN KEY (statusId) REFERENCES dim_status (statusId);

ALTER TABLE fact_constructor_results
    ADD CONSTRAINT fk_fact_constructor_results_race
    FOREIGN KEY (raceId) REFERENCES dim_races (raceId),
    ADD CONSTRAINT fk_fact_constructor_results_constructor
    FOREIGN KEY (constructorId) REFERENCES dim_constructors (constructorId);

ALTER TABLE fact_qualifying
    ADD KEY idx_fact_qualifying_constructor (constructorId),
    ADD CONSTRAINT fk_fact_qualifying_race
    FOREIGN KEY (raceId) REFERENCES dim_races (raceId),
    ADD CONSTRAINT fk_fact_qualifying_driver
    FOREIGN KEY (driverId) REFERENCES dim_drivers (driverId),
    ADD CONSTRAINT fk_fact_qualifying_constructor
    FOREIGN KEY (constructorId) REFERENCES dim_constructors (constructorId);

ALTER TABLE fact_lap_times
    ADD CONSTRAINT fk_fact_lap_times_race
    FOREIGN KEY (raceId) REFERENCES dim_races (raceId),
    ADD CONSTRAINT fk_fact_lap_times_driver
    FOREIGN KEY (driverId) REFERENCES dim_drivers (driverId);

ALTER TABLE fact_pit_stops
    ADD CONSTRAINT fk_fact_pit_stops_race
    FOREIGN KEY (raceId) REFERENCES dim_races (raceId),
    ADD CONSTRAINT fk_fact_pit_stops_driver
    FOREIGN KEY (driverId) REFERENCES dim_drivers (driverId);

ALTER TABLE fact_driver_standings
    ADD CONSTRAINT fk_fact_driver_standings_race
    FOREIGN KEY (raceId) REFERENCES dim_races (raceId),
    ADD CONSTRAINT fk_fact_driver_standings_driver
    FOREIGN KEY (driverId) REFERENCES dim_drivers (driverId);

ALTER TABLE fact_constructor_standings
    ADD CONSTRAINT fk_fact_constructor_standings_race
    FOREIGN KEY (raceId) REFERENCES dim_races (raceId),
    ADD CONSTRAINT fk_fact_constructor_standings_constructor
    FOREIGN KEY (constructorId) REFERENCES dim_constructors (constructorId);

ALTER TABLE fact_race_entries
    ADD CONSTRAINT fk_fact_race_entries_race
    FOREIGN KEY (raceId) REFERENCES dim_races (raceId),
    ADD CONSTRAINT fk_fact_race_entries_circuit
    FOREIGN KEY (circuitId) REFERENCES dim_circuits (circuitId),
    ADD CONSTRAINT fk_fact_race_entries_driver
    FOREIGN KEY (driverId) REFERENCES dim_drivers (driverId),
    ADD CONSTRAINT fk_fact_race_entries_constructor
    FOREIGN KEY (constructorId) REFERENCES dim_constructors (constructorId),
    ADD CONSTRAINT fk_fact_race_entries_status
    FOREIGN KEY (statusId) REFERENCES dim_status (statusId);

-- =========================================================
-- Data quality monitoring
-- =========================================================

CREATE OR REPLACE VIEW vw_data_quality_checks AS
SELECT 'results_duplicate_resultId' AS check_name, COUNT(*) AS issue_count
FROM (
    SELECT resultId
    FROM F1.results
    GROUP BY resultId
    HAVING COUNT(*) > 1
) t

UNION ALL

SELECT 'lap_times_duplicate_pk' AS check_name, COUNT(*) AS issue_count
FROM (
    SELECT raceId, driverId, lap
    FROM F1.lap_times
    GROUP BY raceId, driverId, lap
    HAVING COUNT(*) > 1
) t

UNION ALL

SELECT 'pit_stops_duplicate_pk' AS check_name, COUNT(*) AS issue_count
FROM (
    SELECT raceId, driverId, stop
    FROM F1.pit_stops
    GROUP BY raceId, driverId, stop
    HAVING COUNT(*) > 1
) t

UNION ALL

SELECT 'results_missing_driver' AS check_name, COUNT(*) AS issue_count
FROM F1.results r
LEFT JOIN F1.drivers d
    ON r.driverId = d.driverId
WHERE d.driverId IS NULL

UNION ALL

SELECT 'results_missing_race' AS check_name, COUNT(*) AS issue_count
FROM F1.results r
LEFT JOIN F1.races ra
    ON r.raceId = ra.raceId
WHERE ra.raceId IS NULL

UNION ALL

SELECT 'results_missing_constructor' AS check_name, COUNT(*) AS issue_count
FROM F1.results r
LEFT JOIN F1.constructors c
    ON r.constructorId = c.constructorId
WHERE c.constructorId IS NULL

UNION ALL

SELECT 'results_missing_status' AS check_name, COUNT(*) AS issue_count
FROM F1.results r
LEFT JOIN F1.status s
    ON r.statusId = s.statusId
WHERE s.statusId IS NULL

UNION ALL

SELECT 'results_duplicate_race_driver' AS check_name, COUNT(*) AS issue_count
FROM (
    SELECT raceId, driverId
    FROM F1.results
    GROUP BY raceId, driverId
    HAVING COUNT(*) > 1
) t

UNION ALL

SELECT 'constructor_results_missing_race' AS check_name, COUNT(*) AS issue_count
FROM F1.constructor_results cr
LEFT JOIN F1.races r
    ON cr.raceId = r.raceId
WHERE r.raceId IS NULL

UNION ALL

SELECT 'constructor_results_missing_constructor' AS check_name, COUNT(*) AS issue_count
FROM F1.constructor_results cr
LEFT JOIN F1.constructors c
    ON cr.constructorId = c.constructorId
WHERE c.constructorId IS NULL;

CREATE OR REPLACE VIEW vw_silver_summary AS
SELECT 'dim_drivers' AS object_name, COUNT(*) AS row_count FROM dim_drivers
UNION ALL
SELECT 'dim_constructors', COUNT(*) FROM dim_constructors
UNION ALL
SELECT 'dim_circuits', COUNT(*) FROM dim_circuits
UNION ALL
SELECT 'dim_status', COUNT(*) FROM dim_status
UNION ALL
SELECT 'dim_seasons', COUNT(*) FROM dim_seasons
UNION ALL
SELECT 'dim_races', COUNT(*) FROM dim_races
UNION ALL
SELECT 'fact_results', COUNT(*) FROM fact_results
UNION ALL
SELECT 'fact_sprint_results', COUNT(*) FROM fact_sprint_results
UNION ALL
SELECT 'fact_constructor_results', COUNT(*) FROM fact_constructor_results
UNION ALL
SELECT 'fact_qualifying', COUNT(*) FROM fact_qualifying
UNION ALL
SELECT 'fact_lap_times', COUNT(*) FROM fact_lap_times
UNION ALL
SELECT 'fact_pit_stops', COUNT(*) FROM fact_pit_stops
UNION ALL
SELECT 'fact_driver_standings', COUNT(*) FROM fact_driver_standings
UNION ALL
SELECT 'fact_constructor_standings', COUNT(*) FROM fact_constructor_standings
UNION ALL
SELECT 'fact_race_entries', COUNT(*) FROM fact_race_entries;

-- =========================================================
-- Quick validation queries
-- =========================================================

SELECT COUNT(*) AS dim_drivers_rows FROM dim_drivers;
SELECT COUNT(*) AS dim_seasons_rows FROM dim_seasons;
SELECT COUNT(*) AS dim_races_rows FROM dim_races;
SELECT COUNT(*) AS fact_results_rows FROM fact_results;
SELECT COUNT(*) AS fact_constructor_results_rows FROM fact_constructor_results;
SELECT COUNT(*) AS fact_qualifying_rows FROM fact_qualifying;
SELECT COUNT(*) AS fact_race_entries_rows FROM fact_race_entries;
SELECT * FROM vw_silver_summary;
SELECT * FROM vw_data_quality_checks;
