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
