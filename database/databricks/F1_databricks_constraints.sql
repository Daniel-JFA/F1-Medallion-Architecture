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
