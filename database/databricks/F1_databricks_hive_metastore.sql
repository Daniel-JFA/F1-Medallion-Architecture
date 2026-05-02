-- F1 rebuild script for Databricks workspaces without Unity Catalog.
-- Use this when `SHOW CATALOGS;` does not include `main` and your SQL warehouse
-- works against the legacy `hive_metastore`.
--
-- Before running:
-- 1. Upload the 14 CSV files to:
--    dbfs:/FileStore/f1_raw/
-- 2. Then execute this entire script.
--
-- This script rebuilds the tables from scratch and reloads the CSV files.
-- It does not create primary/foreign key constraints because those are a
-- Unity Catalog feature in Databricks.

CREATE DATABASE IF NOT EXISTS f1;
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

COPY INTO circuits
FROM 'dbfs:/FileStore/f1_raw/'
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
FROM 'dbfs:/FileStore/f1_raw/'
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
FROM 'dbfs:/FileStore/f1_raw/'
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
FROM 'dbfs:/FileStore/f1_raw/'
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
FROM 'dbfs:/FileStore/f1_raw/'
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
FROM 'dbfs:/FileStore/f1_raw/'
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
FROM 'dbfs:/FileStore/f1_raw/'
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
FROM 'dbfs:/FileStore/f1_raw/'
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
FROM 'dbfs:/FileStore/f1_raw/'
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
FROM 'dbfs:/FileStore/f1_raw/'
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
FROM 'dbfs:/FileStore/f1_raw/'
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
FROM 'dbfs:/FileStore/f1_raw/'
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
FROM 'dbfs:/FileStore/f1_raw/'
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
FROM 'dbfs:/FileStore/f1_raw/'
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
