-- F1 all-in-one rebuild script for Databricks SQL.
--
-- Before running:
-- 1. If you use Unity Catalog, optionally uncomment and adjust:
--    USE CATALOG main;
-- 2. Replace every occurrence of:
--    /Volumes/main/default/f1_raw/
--    with the real path that contains your CSV files.
-- 3. This script rebuilds existing tables from scratch using the CSV files.
--    It is intended for the case where the current table structures are wrong.
-- 4. If your tables are in hive_metastore, run only sections 1 and 2.
--    Section 3 is for Unity Catalog only.
--
-- Optional for Unity Catalog:
-- USE CATALOG main;

-- ============================================================
-- 1. Schema
-- ============================================================

CREATE SCHEMA IF NOT EXISTS f1;
USE f1;

CREATE OR REPLACE TABLE circuits (
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

CREATE OR REPLACE TABLE constructors (
    constructorId INT NOT NULL,
    constructorRef STRING NOT NULL,
    name STRING NOT NULL,
    nationality STRING,
    url STRING
)
USING DELTA;

CREATE OR REPLACE TABLE drivers (
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

CREATE OR REPLACE TABLE seasons (
    year INT NOT NULL,
    url STRING
)
USING DELTA;

CREATE OR REPLACE TABLE status (
    statusId INT NOT NULL,
    status STRING NOT NULL
)
USING DELTA;

CREATE OR REPLACE TABLE races (
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

CREATE OR REPLACE TABLE constructor_results (
    constructorResultsId INT NOT NULL,
    raceId INT NOT NULL,
    constructorId INT NOT NULL,
    points DOUBLE,
    status STRING
)
USING DELTA;

CREATE OR REPLACE TABLE constructor_standings (
    constructorStandingsId INT NOT NULL,
    raceId INT NOT NULL,
    constructorId INT NOT NULL,
    points DOUBLE NOT NULL,
    position INT,
    positionText STRING,
    wins INT NOT NULL
)
USING DELTA;

CREATE OR REPLACE TABLE driver_standings (
    driverStandingsId INT NOT NULL,
    raceId INT NOT NULL,
    driverId INT NOT NULL,
    points DOUBLE NOT NULL,
    position INT,
    positionText STRING,
    wins INT NOT NULL
)
USING DELTA;

CREATE OR REPLACE TABLE results (
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

CREATE OR REPLACE TABLE sprint_results (
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

CREATE OR REPLACE TABLE qualifying (
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

CREATE OR REPLACE TABLE lap_times (
    raceId INT NOT NULL,
    driverId INT NOT NULL,
    lap INT NOT NULL,
    position INT,
    time STRING,
    milliseconds INT
)
USING DELTA;

CREATE OR REPLACE TABLE pit_stops (
    raceId INT NOT NULL,
    driverId INT NOT NULL,
    stop INT NOT NULL,
    lap INT NOT NULL,
    time STRING,
    duration STRING,
    milliseconds INT
)
USING DELTA;

-- ============================================================
-- 2. Load CSV files
-- ============================================================

COPY INTO circuits
FROM '/Volumes/main/default/f1_raw/'
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
)
COPY_OPTIONS (
    'force' = 'true'
);

COPY INTO constructors
FROM '/Volumes/main/default/f1_raw/'
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
)
COPY_OPTIONS (
    'force' = 'true'
);

COPY INTO drivers
FROM '/Volumes/main/default/f1_raw/'
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
)
COPY_OPTIONS (
    'force' = 'true'
);

COPY INTO seasons
FROM '/Volumes/main/default/f1_raw/'
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
)
COPY_OPTIONS (
    'force' = 'true'
);

COPY INTO status
FROM '/Volumes/main/default/f1_raw/'
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
)
COPY_OPTIONS (
    'force' = 'true'
);

COPY INTO races
FROM '/Volumes/main/default/f1_raw/'
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
)
COPY_OPTIONS (
    'force' = 'true'
);

COPY INTO constructor_results
FROM '/Volumes/main/default/f1_raw/'
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
)
COPY_OPTIONS (
    'force' = 'true'
);

COPY INTO constructor_standings
FROM '/Volumes/main/default/f1_raw/'
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
)
COPY_OPTIONS (
    'force' = 'true'
);

COPY INTO driver_standings
FROM '/Volumes/main/default/f1_raw/'
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
)
COPY_OPTIONS (
    'force' = 'true'
);

COPY INTO results
FROM '/Volumes/main/default/f1_raw/'
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
)
COPY_OPTIONS (
    'force' = 'true'
);

COPY INTO sprint_results
FROM '/Volumes/main/default/f1_raw/'
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
)
COPY_OPTIONS (
    'force' = 'true'
);

COPY INTO qualifying
FROM '/Volumes/main/default/f1_raw/'
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
)
COPY_OPTIONS (
    'force' = 'true'
);

COPY INTO lap_times
FROM '/Volumes/main/default/f1_raw/'
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
)
COPY_OPTIONS (
    'force' = 'true'
);

COPY INTO pit_stops
FROM '/Volumes/main/default/f1_raw/'
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
)
COPY_OPTIONS (
    'force' = 'true'
);

-- ============================================================
-- 3. Unity Catalog only: informational PK/FK constraints
-- If you are using hive_metastore, stop before this section.
-- ============================================================
/*

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
*/
