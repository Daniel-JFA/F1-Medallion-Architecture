-- Databricks-compatible schema for the local F1 dataset.
-- Source: local CSV files in "DB F1" and the MySQL schema used by import_f1.py.
-- Optional for Unity Catalog:
-- USE CATALOG workspace;

CREATE SCHEMA IF NOT EXISTS f1;
USE f1;

CREATE TABLE IF NOT EXISTS circuits (
    circuitId INT NOT NULL,
    circuitRef STRING NOT NULL,
    name STRING NOT NULL,
    location STRING,
    country STRING,
    lat DOUBLE,
    lng DOUBLE,
    alt INT,
    url STRING
)
USING DELTA;

CREATE TABLE IF NOT EXISTS constructors (
    constructorId INT NOT NULL,
    constructorRef STRING NOT NULL,
    name STRING NOT NULL,
    nationality STRING,
    url STRING
)
USING DELTA;

CREATE TABLE IF NOT EXISTS drivers (
    driverId INT NOT NULL,
    driverRef STRING NOT NULL,
    number INT,
    code STRING,
    forename STRING NOT NULL,
    surname STRING NOT NULL,
    dob DATE,
    nationality STRING,
    url STRING
)
USING DELTA;

CREATE TABLE IF NOT EXISTS seasons (
    year INT NOT NULL,
    url STRING
)
USING DELTA;

CREATE TABLE IF NOT EXISTS status (
    statusId INT NOT NULL,
    status STRING NOT NULL
)
USING DELTA;

CREATE TABLE IF NOT EXISTS races (
    raceId INT NOT NULL,
    year INT NOT NULL,
    round INT NOT NULL,
    circuitId INT NOT NULL,
    name STRING NOT NULL,
    date DATE,
    time STRING,
    url STRING,
    fp1_date DATE,
    fp1_time STRING,
    fp2_date DATE,
    fp2_time STRING,
    fp3_date DATE,
    fp3_time STRING,
    quali_date DATE,
    quali_time STRING,
    sprint_date DATE,
    sprint_time STRING
)
USING DELTA;

CREATE TABLE IF NOT EXISTS constructor_results (
    constructorResultsId INT NOT NULL,
    raceId INT NOT NULL,
    constructorId INT NOT NULL,
    points DOUBLE,
    status STRING
)
USING DELTA;

CREATE TABLE IF NOT EXISTS constructor_standings (
    constructorStandingsId INT NOT NULL,
    raceId INT NOT NULL,
    constructorId INT NOT NULL,
    points DOUBLE NOT NULL,
    position INT,
    positionText STRING,
    wins INT NOT NULL
)
USING DELTA;

CREATE TABLE IF NOT EXISTS driver_standings (
    driverStandingsId INT NOT NULL,
    raceId INT NOT NULL,
    driverId INT NOT NULL,
    points DOUBLE NOT NULL,
    position INT,
    positionText STRING,
    wins INT NOT NULL
)
USING DELTA;

CREATE TABLE IF NOT EXISTS results (
    resultId INT NOT NULL,
    raceId INT NOT NULL,
    driverId INT NOT NULL,
    constructorId INT NOT NULL,
    number INT,
    grid INT NOT NULL,
    position INT,
    positionText STRING,
    positionOrder INT NOT NULL,
    points DOUBLE NOT NULL,
    laps INT NOT NULL,
    time STRING,
    milliseconds INT,
    fastestLap INT,
    `rank` INT,
    fastestLapTime STRING,
    fastestLapSpeed STRING,
    statusId INT NOT NULL
)
USING DELTA;

CREATE TABLE IF NOT EXISTS sprint_results (
    resultId INT NOT NULL,
    raceId INT NOT NULL,
    driverId INT NOT NULL,
    constructorId INT NOT NULL,
    number INT,
    grid INT NOT NULL,
    position INT,
    positionText STRING,
    positionOrder INT NOT NULL,
    points DOUBLE NOT NULL,
    laps INT NOT NULL,
    time STRING,
    milliseconds INT,
    fastestLap INT,
    fastestLapTime STRING,
    statusId INT NOT NULL
)
USING DELTA;

CREATE TABLE IF NOT EXISTS qualifying (
    qualifyId INT NOT NULL,
    raceId INT NOT NULL,
    driverId INT NOT NULL,
    constructorId INT NOT NULL,
    number INT NOT NULL,
    position INT,
    q1 STRING,
    q2 STRING,
    q3 STRING
)
USING DELTA;

CREATE TABLE IF NOT EXISTS lap_times (
    raceId INT NOT NULL,
    driverId INT NOT NULL,
    lap INT NOT NULL,
    position INT,
    time STRING,
    milliseconds INT
)
USING DELTA;

CREATE TABLE IF NOT EXISTS pit_stops (
    raceId INT NOT NULL,
    driverId INT NOT NULL,
    stop INT NOT NULL,
    lap INT NOT NULL,
    time STRING,
    duration STRING,
    milliseconds INT
)
USING DELTA;

-- Load the F1 CSV files into the Databricks Delta tables created by
-- F1_databricks_schema.sql.
--
-- Replace the path below with a Unity Catalog volume or external location
-- that contains these files:
-- circuits.csv
-- constructors.csv
-- drivers.csv
-- seasons.csv
-- status.csv
-- races.csv
-- constructor_results.csv
-- constructor_standings.csv
-- driver_standings.csv
-- results.csv
-- sprint_results.csv
-- qualifying.csv
-- lap_times.csv
-- pit_stops.csv
--
-- Example path for the current workspace:
-- /Volumes/workspace/default/f1_raw/
-- If your volume lives in another catalog/schema, replace the full path.
--
-- Optional for Unity Catalog:
-- USE CATALOG workspace;

USE f1;

COPY INTO circuits
FROM '/Volumes/workspace/default/f1_raw/'
FILEFORMAT = CSV
FILES = ('circuits.csv')
FORMAT_OPTIONS (
    'header' = 'true',
    'enforceSchema' = 'false',
    'nullValue' = '\\N',
    'dateFormat' = 'yyyy-MM-dd',
    'encoding' = 'UTF-8',
    'quote' = '"',
    'escape' = '\\',
    'mode' = 'FAILFAST'
);

COPY INTO constructors
FROM '/Volumes/workspace/default/f1_raw/'
FILEFORMAT = CSV
FILES = ('constructors.csv')
FORMAT_OPTIONS (
    'header' = 'true',
    'enforceSchema' = 'false',
    'nullValue' = '\\N',
    'dateFormat' = 'yyyy-MM-dd',
    'encoding' = 'UTF-8',
    'quote' = '"',
    'escape' = '\\',
    'mode' = 'FAILFAST'
);

COPY INTO drivers
FROM '/Volumes/workspace/default/f1_raw/'
FILEFORMAT = CSV
FILES = ('drivers.csv')
FORMAT_OPTIONS (
    'header' = 'true',
    'enforceSchema' = 'false',
    'nullValue' = '\\N',
    'dateFormat' = 'yyyy-MM-dd',
    'encoding' = 'UTF-8',
    'quote' = '"',
    'escape' = '\\',
    'mode' = 'FAILFAST'
);

COPY INTO seasons
FROM '/Volumes/workspace/default/f1_raw/'
FILEFORMAT = CSV
FILES = ('seasons.csv')
FORMAT_OPTIONS (
    'header' = 'true',
    'enforceSchema' = 'false',
    'nullValue' = '\\N',
    'dateFormat' = 'yyyy-MM-dd',
    'encoding' = 'UTF-8',
    'quote' = '"',
    'escape' = '\\',
    'mode' = 'FAILFAST'
);

COPY INTO status
FROM '/Volumes/workspace/default/f1_raw/'
FILEFORMAT = CSV
FILES = ('status.csv')
FORMAT_OPTIONS (
    'header' = 'true',
    'enforceSchema' = 'false',
    'nullValue' = '\\N',
    'dateFormat' = 'yyyy-MM-dd',
    'encoding' = 'UTF-8',
    'quote' = '"',
    'escape' = '\\',
    'mode' = 'FAILFAST'
);

COPY INTO races
FROM '/Volumes/workspace/default/f1_raw/'
FILEFORMAT = CSV
FILES = ('races.csv')
FORMAT_OPTIONS (
    'header' = 'true',
    'enforceSchema' = 'false',
    'nullValue' = '\\N',
    'dateFormat' = 'yyyy-MM-dd',
    'encoding' = 'UTF-8',
    'quote' = '"',
    'escape' = '\\',
    'mode' = 'FAILFAST'
);

COPY INTO constructor_results
FROM '/Volumes/workspace/default/f1_raw/'
FILEFORMAT = CSV
FILES = ('constructor_results.csv')
FORMAT_OPTIONS (
    'header' = 'true',
    'enforceSchema' = 'false',
    'nullValue' = '\\N',
    'dateFormat' = 'yyyy-MM-dd',
    'encoding' = 'UTF-8',
    'quote' = '"',
    'escape' = '\\',
    'mode' = 'FAILFAST'
);

COPY INTO constructor_standings
FROM '/Volumes/workspace/default/f1_raw/'
FILEFORMAT = CSV
FILES = ('constructor_standings.csv')
FORMAT_OPTIONS (
    'header' = 'true',
    'enforceSchema' = 'false',
    'nullValue' = '\\N',
    'dateFormat' = 'yyyy-MM-dd',
    'encoding' = 'UTF-8',
    'quote' = '"',
    'escape' = '\\',
    'mode' = 'FAILFAST'
);

COPY INTO driver_standings
FROM '/Volumes/workspace/default/f1_raw/'
FILEFORMAT = CSV
FILES = ('driver_standings.csv')
FORMAT_OPTIONS (
    'header' = 'true',
    'enforceSchema' = 'false',
    'nullValue' = '\\N',
    'dateFormat' = 'yyyy-MM-dd',
    'encoding' = 'UTF-8',
    'quote' = '"',
    'escape' = '\\',
    'mode' = 'FAILFAST'
);

COPY INTO results
FROM '/Volumes/workspace/default/f1_raw/'
FILEFORMAT = CSV
FILES = ('results.csv')
FORMAT_OPTIONS (
    'header' = 'true',
    'enforceSchema' = 'false',
    'nullValue' = '\\N',
    'dateFormat' = 'yyyy-MM-dd',
    'encoding' = 'UTF-8',
    'quote' = '"',
    'escape' = '\\',
    'mode' = 'FAILFAST'
);

COPY INTO sprint_results
FROM '/Volumes/workspace/default/f1_raw/'
FILEFORMAT = CSV
FILES = ('sprint_results.csv')
FORMAT_OPTIONS (
    'header' = 'true',
    'enforceSchema' = 'false',
    'nullValue' = '\\N',
    'dateFormat' = 'yyyy-MM-dd',
    'encoding' = 'UTF-8',
    'quote' = '"',
    'escape' = '\\',
    'mode' = 'FAILFAST'
);

COPY INTO qualifying
FROM '/Volumes/workspace/default/f1_raw/'
FILEFORMAT = CSV
FILES = ('qualifying.csv')
FORMAT_OPTIONS (
    'header' = 'true',
    'enforceSchema' = 'false',
    'nullValue' = '\\N',
    'dateFormat' = 'yyyy-MM-dd',
    'encoding' = 'UTF-8',
    'quote' = '"',
    'escape' = '\\',
    'mode' = 'FAILFAST'
);

COPY INTO lap_times
FROM '/Volumes/workspace/default/f1_raw/'
FILEFORMAT = CSV
FILES = ('lap_times.csv')
FORMAT_OPTIONS (
    'header' = 'true',
    'enforceSchema' = 'false',
    'nullValue' = '\\N',
    'dateFormat' = 'yyyy-MM-dd',
    'encoding' = 'UTF-8',
    'quote' = '"',
    'escape' = '\\',
    'mode' = 'FAILFAST'
);

COPY INTO pit_stops
FROM '/Volumes/workspace/default/f1_raw/'
FILEFORMAT = CSV
FILES = ('pit_stops.csv')
FORMAT_OPTIONS (
    'header' = 'true',
    'enforceSchema' = 'false',
    'nullValue' = '\\N',
    'dateFormat' = 'yyyy-MM-dd',
    'encoding' = 'UTF-8',
    'quote' = '"',
    'escape' = '\\',
    'mode' = 'FAILFAST'
);

-- Unity Catalog only.
-- Do not run this file if your tables are in hive_metastore.
-- Run this after F1_databricks_schema.sql and F1_databricks_load.sql.
-- Optional:
-- USE CATALOG workspace;

USE f1;

-- Drop foreign keys first so the script can be rerun safely.
ALTER TABLE races DROP CONSTRAINT IF EXISTS fk_races_seasons;
ALTER TABLE races DROP CONSTRAINT IF EXISTS fk_races_circuits;
ALTER TABLE constructor_results DROP CONSTRAINT IF EXISTS fk_constructor_results_races;
ALTER TABLE constructor_results DROP CONSTRAINT IF EXISTS fk_constructor_results_constructors;
ALTER TABLE constructor_standings DROP CONSTRAINT IF EXISTS fk_constructor_standings_races;
ALTER TABLE constructor_standings DROP CONSTRAINT IF EXISTS fk_constructor_standings_constructors;
ALTER TABLE driver_standings DROP CONSTRAINT IF EXISTS fk_driver_standings_races;
ALTER TABLE driver_standings DROP CONSTRAINT IF EXISTS fk_driver_standings_drivers;
ALTER TABLE results DROP CONSTRAINT IF EXISTS fk_results_races;
ALTER TABLE results DROP CONSTRAINT IF EXISTS fk_results_drivers;
ALTER TABLE results DROP CONSTRAINT IF EXISTS fk_results_constructors;
ALTER TABLE results DROP CONSTRAINT IF EXISTS fk_results_status;
ALTER TABLE sprint_results DROP CONSTRAINT IF EXISTS fk_sprint_results_races;
ALTER TABLE sprint_results DROP CONSTRAINT IF EXISTS fk_sprint_results_drivers;
ALTER TABLE sprint_results DROP CONSTRAINT IF EXISTS fk_sprint_results_constructors;
ALTER TABLE sprint_results DROP CONSTRAINT IF EXISTS fk_sprint_results_status;
ALTER TABLE qualifying DROP CONSTRAINT IF EXISTS fk_qualifying_races;
ALTER TABLE qualifying DROP CONSTRAINT IF EXISTS fk_qualifying_drivers;
ALTER TABLE qualifying DROP CONSTRAINT IF EXISTS fk_qualifying_constructors;
ALTER TABLE lap_times DROP CONSTRAINT IF EXISTS fk_lap_times_races;
ALTER TABLE lap_times DROP CONSTRAINT IF EXISTS fk_lap_times_drivers;
ALTER TABLE pit_stops DROP CONSTRAINT IF EXISTS fk_pit_stops_races;
ALTER TABLE pit_stops DROP CONSTRAINT IF EXISTS fk_pit_stops_drivers;

ALTER TABLE circuits DROP CONSTRAINT IF EXISTS circuits_pk;
ALTER TABLE constructors DROP CONSTRAINT IF EXISTS constructors_pk;
ALTER TABLE drivers DROP CONSTRAINT IF EXISTS drivers_pk;
ALTER TABLE seasons DROP CONSTRAINT IF EXISTS seasons_pk;
ALTER TABLE status DROP CONSTRAINT IF EXISTS status_pk;
ALTER TABLE races DROP CONSTRAINT IF EXISTS races_pk;
ALTER TABLE constructor_results DROP CONSTRAINT IF EXISTS constructor_results_pk;
ALTER TABLE constructor_standings DROP CONSTRAINT IF EXISTS constructor_standings_pk;
ALTER TABLE driver_standings DROP CONSTRAINT IF EXISTS driver_standings_pk;
ALTER TABLE results DROP CONSTRAINT IF EXISTS results_pk;
ALTER TABLE sprint_results DROP CONSTRAINT IF EXISTS sprint_results_pk;
ALTER TABLE qualifying DROP CONSTRAINT IF EXISTS qualifying_pk;
ALTER TABLE lap_times DROP CONSTRAINT IF EXISTS lap_times_pk;
ALTER TABLE pit_stops DROP CONSTRAINT IF EXISTS pit_stops_pk;

ALTER TABLE circuits
ADD CONSTRAINT circuits_pk PRIMARY KEY (circuitId) NOT ENFORCED;

ALTER TABLE constructors
ADD CONSTRAINT constructors_pk PRIMARY KEY (constructorId) NOT ENFORCED;

ALTER TABLE drivers
ADD CONSTRAINT drivers_pk PRIMARY KEY (driverId) NOT ENFORCED;

ALTER TABLE seasons
ADD CONSTRAINT seasons_pk PRIMARY KEY (year) NOT ENFORCED;

ALTER TABLE status
ADD CONSTRAINT status_pk PRIMARY KEY (statusId) NOT ENFORCED;

ALTER TABLE races
ADD CONSTRAINT races_pk PRIMARY KEY (raceId) NOT ENFORCED;

ALTER TABLE constructor_results
ADD CONSTRAINT constructor_results_pk PRIMARY KEY (constructorResultsId) NOT ENFORCED;

ALTER TABLE constructor_standings
ADD CONSTRAINT constructor_standings_pk PRIMARY KEY (constructorStandingsId) NOT ENFORCED;

ALTER TABLE driver_standings
ADD CONSTRAINT driver_standings_pk PRIMARY KEY (driverStandingsId) NOT ENFORCED;

ALTER TABLE results
ADD CONSTRAINT results_pk PRIMARY KEY (resultId) NOT ENFORCED;

ALTER TABLE sprint_results
ADD CONSTRAINT sprint_results_pk PRIMARY KEY (resultId) NOT ENFORCED;

ALTER TABLE qualifying
ADD CONSTRAINT qualifying_pk PRIMARY KEY (qualifyId) NOT ENFORCED;

ALTER TABLE lap_times
ADD CONSTRAINT lap_times_pk PRIMARY KEY (raceId, driverId, lap) NOT ENFORCED;

ALTER TABLE pit_stops
ADD CONSTRAINT pit_stops_pk PRIMARY KEY (raceId, driverId, stop) NOT ENFORCED;

ALTER TABLE races
ADD CONSTRAINT fk_races_seasons
FOREIGN KEY (year) REFERENCES seasons (year) NOT ENFORCED;

ALTER TABLE races
ADD CONSTRAINT fk_races_circuits
FOREIGN KEY (circuitId) REFERENCES circuits (circuitId) NOT ENFORCED;

ALTER TABLE constructor_results
ADD CONSTRAINT fk_constructor_results_races
FOREIGN KEY (raceId) REFERENCES races (raceId) NOT ENFORCED;

ALTER TABLE constructor_results
ADD CONSTRAINT fk_constructor_results_constructors
FOREIGN KEY (constructorId) REFERENCES constructors (constructorId) NOT ENFORCED;

ALTER TABLE constructor_standings
ADD CONSTRAINT fk_constructor_standings_races
FOREIGN KEY (raceId) REFERENCES races (raceId) NOT ENFORCED;

ALTER TABLE constructor_standings
ADD CONSTRAINT fk_constructor_standings_constructors
FOREIGN KEY (constructorId) REFERENCES constructors (constructorId) NOT ENFORCED;

ALTER TABLE driver_standings
ADD CONSTRAINT fk_driver_standings_races
FOREIGN KEY (raceId) REFERENCES races (raceId) NOT ENFORCED;

ALTER TABLE driver_standings
ADD CONSTRAINT fk_driver_standings_drivers
FOREIGN KEY (driverId) REFERENCES drivers (driverId) NOT ENFORCED;

ALTER TABLE results
ADD CONSTRAINT fk_results_races
FOREIGN KEY (raceId) REFERENCES races (raceId) NOT ENFORCED;

ALTER TABLE results
ADD CONSTRAINT fk_results_drivers
FOREIGN KEY (driverId) REFERENCES drivers (driverId) NOT ENFORCED;

ALTER TABLE results
ADD CONSTRAINT fk_results_constructors
FOREIGN KEY (constructorId) REFERENCES constructors (constructorId) NOT ENFORCED;

ALTER TABLE results
ADD CONSTRAINT fk_results_status
FOREIGN KEY (statusId) REFERENCES status (statusId) NOT ENFORCED;

ALTER TABLE sprint_results
ADD CONSTRAINT fk_sprint_results_races
FOREIGN KEY (raceId) REFERENCES races (raceId) NOT ENFORCED;

ALTER TABLE sprint_results
ADD CONSTRAINT fk_sprint_results_drivers
FOREIGN KEY (driverId) REFERENCES drivers (driverId) NOT ENFORCED;

ALTER TABLE sprint_results
ADD CONSTRAINT fk_sprint_results_constructors
FOREIGN KEY (constructorId) REFERENCES constructors (constructorId) NOT ENFORCED;

ALTER TABLE sprint_results
ADD CONSTRAINT fk_sprint_results_status
FOREIGN KEY (statusId) REFERENCES status (statusId) NOT ENFORCED;

ALTER TABLE qualifying
ADD CONSTRAINT fk_qualifying_races
FOREIGN KEY (raceId) REFERENCES races (raceId) NOT ENFORCED;

ALTER TABLE qualifying
ADD CONSTRAINT fk_qualifying_drivers
FOREIGN KEY (driverId) REFERENCES drivers (driverId) NOT ENFORCED;

ALTER TABLE qualifying
ADD CONSTRAINT fk_qualifying_constructors
FOREIGN KEY (constructorId) REFERENCES constructors (constructorId) NOT ENFORCED;

ALTER TABLE lap_times
ADD CONSTRAINT fk_lap_times_races
FOREIGN KEY (raceId) REFERENCES races (raceId) NOT ENFORCED;

ALTER TABLE lap_times
ADD CONSTRAINT fk_lap_times_drivers
FOREIGN KEY (driverId) REFERENCES drivers (driverId) NOT ENFORCED;

ALTER TABLE pit_stops
ADD CONSTRAINT fk_pit_stops_races
FOREIGN KEY (raceId) REFERENCES races (raceId) NOT ENFORCED;

ALTER TABLE pit_stops
ADD CONSTRAINT fk_pit_stops_drivers
FOREIGN KEY (driverId) REFERENCES drivers (driverId) NOT ENFORCED;

-- Improved Silver layer for the F1 dataset in Databricks SQL.
--
-- Assumption:
-- - Schema f1 already exists and contains the typed base tables loaded from CSV.
-- - This script creates a curated Silver layer in schema f1_silver.
--
-- Optional for Unity Catalog:
-- USE CATALOG workspace;

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

-- Gold layer for Databricks SQL.
--
-- Assumption:
-- - Schema f1_silver already exists and contains the curated Silver layer.
-- - This script creates the presentation and business-consumption layer in f1_gold.
--
-- Optional for Unity Catalog:
-- USE CATALOG workspace;

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

-- ============================================================
-- End of full rebuild
-- ============================================================
-- The optional KPI history layer was intentionally left out of this
-- consolidated rebuild file to avoid blocking the main deployment in
-- Databricks SQL clients such as DBeaver.
--
-- If you want KPI versioning later, run the separate file:
-- /home/djfa/Dev/DBs BackUps/F1_databricks_control.sql
