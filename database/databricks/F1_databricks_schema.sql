-- Databricks-compatible schema for the local F1 dataset.
-- Source: Formula 1 CSV files already staged in a Databricks volume.
-- Optional for Unity Catalog:
-- USE CATALOG workspace;

CREATE CATALOG IF NOT EXISTS f1;
USE CATALOG f1;

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
