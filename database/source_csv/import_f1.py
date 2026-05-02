#!/usr/bin/env python3
"""
Import F1 CSV files into MySQL database 'F1'.
Run: python3 import_f1.py
"""

import csv
import os
import sys
import mysql.connector

DB_HOST = "127.0.0.1"
DB_PORT = 3306
DB_USER = "root"
DB_PASS = "root"
DB_NAME = "F1"

CSV_DIR = os.path.join(os.path.dirname(__file__), "DB F1")

# ── DDL ────────────────────────────────────────────────────────────────────────

DDL = [
    """
    CREATE TABLE IF NOT EXISTS circuits (
        circuitId   INT          NOT NULL PRIMARY KEY,
        circuitRef  VARCHAR(255) NOT NULL,
        name        VARCHAR(255) NOT NULL,
        location    VARCHAR(255),
        country     VARCHAR(255),
        lat         FLOAT,
        lng         FLOAT,
        alt         INT,
        url         TEXT
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS constructors (
        constructorId  INT          NOT NULL PRIMARY KEY,
        constructorRef VARCHAR(255) NOT NULL,
        name           VARCHAR(255) NOT NULL,
        nationality    VARCHAR(255),
        url            TEXT
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS drivers (
        driverId    INT          NOT NULL PRIMARY KEY,
        driverRef   VARCHAR(255) NOT NULL,
        number      INT,
        code        VARCHAR(4),
        forename    VARCHAR(255) NOT NULL,
        surname     VARCHAR(255) NOT NULL,
        dob         DATE,
        nationality VARCHAR(255),
        url         TEXT
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS seasons (
        year INT  NOT NULL PRIMARY KEY,
        url  TEXT
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS status (
        statusId INT          NOT NULL PRIMARY KEY,
        status   VARCHAR(255) NOT NULL
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS races (
        raceId       INT          NOT NULL PRIMARY KEY,
        year         INT          NOT NULL,
        round        INT          NOT NULL,
        circuitId    INT          NOT NULL,
        name         VARCHAR(255) NOT NULL,
        date         DATE,
        time         TIME,
        url          TEXT,
        fp1_date     DATE,
        fp1_time     TIME,
        fp2_date     DATE,
        fp2_time     TIME,
        fp3_date     DATE,
        fp3_time     TIME,
        quali_date   DATE,
        quali_time   TIME,
        sprint_date  DATE,
        sprint_time  TIME
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS constructor_results (
        constructorResultsId INT   NOT NULL PRIMARY KEY,
        raceId               INT   NOT NULL,
        constructorId        INT   NOT NULL,
        points               FLOAT,
        status               VARCHAR(16)
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS constructor_standings (
        constructorStandingsId INT          NOT NULL PRIMARY KEY,
        raceId                 INT          NOT NULL,
        constructorId          INT          NOT NULL,
        points                 FLOAT        NOT NULL,
        position               INT,
        positionText           VARCHAR(8),
        wins                   INT          NOT NULL
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS driver_standings (
        driverStandingsId INT          NOT NULL PRIMARY KEY,
        raceId            INT          NOT NULL,
        driverId          INT          NOT NULL,
        points            FLOAT        NOT NULL,
        position          INT,
        positionText      VARCHAR(8),
        wins              INT          NOT NULL
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS results (
        resultId        INT          NOT NULL PRIMARY KEY,
        raceId          INT          NOT NULL,
        driverId        INT          NOT NULL,
        constructorId   INT          NOT NULL,
        number          INT,
        grid            INT          NOT NULL,
        position        INT,
        positionText    VARCHAR(8),
        positionOrder   INT          NOT NULL,
        points          FLOAT        NOT NULL,
        laps            INT          NOT NULL,
        time            VARCHAR(32),
        milliseconds    INT,
        fastestLap      INT,
        `rank`          INT,
        fastestLapTime  VARCHAR(16),
        fastestLapSpeed VARCHAR(16),
        statusId        INT          NOT NULL
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS sprint_results (
        resultId       INT     NOT NULL PRIMARY KEY,
        raceId         INT     NOT NULL,
        driverId       INT     NOT NULL,
        constructorId  INT     NOT NULL,
        number         INT,
        grid           INT     NOT NULL,
        position       INT,
        positionText   VARCHAR(8),
        positionOrder  INT     NOT NULL,
        points         FLOAT   NOT NULL,
        laps           INT     NOT NULL,
        time           VARCHAR(32),
        milliseconds   INT,
        fastestLap     INT,
        fastestLapTime VARCHAR(16),
        statusId       INT     NOT NULL
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS qualifying (
        qualifyId     INT         NOT NULL PRIMARY KEY,
        raceId        INT         NOT NULL,
        driverId      INT         NOT NULL,
        constructorId INT         NOT NULL,
        number        INT         NOT NULL,
        position      INT,
        q1            VARCHAR(16),
        q2            VARCHAR(16),
        q3            VARCHAR(16)
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS lap_times (
        raceId       INT         NOT NULL,
        driverId     INT         NOT NULL,
        lap          INT         NOT NULL,
        position     INT,
        time         VARCHAR(16),
        milliseconds INT,
        PRIMARY KEY (raceId, driverId, lap)
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS pit_stops (
        raceId       INT         NOT NULL,
        driverId     INT         NOT NULL,
        stop         INT         NOT NULL,
        lap          INT         NOT NULL,
        time         VARCHAR(16),
        duration     VARCHAR(16),
        milliseconds INT,
        PRIMARY KEY (raceId, driverId, stop)
    )
    """,
]

# ── CSV → table mapping ────────────────────────────────────────────────────────

TABLES = [
    ("circuits.csv",              "circuits"),
    ("constructors.csv",          "constructors"),
    ("drivers.csv",               "drivers"),
    ("seasons.csv",               "seasons"),
    ("status.csv",                "status"),
    ("races.csv",                 "races"),
    ("constructor_results.csv",   "constructor_results"),
    ("constructor_standings.csv", "constructor_standings"),
    ("driver_standings.csv",      "driver_standings"),
    ("results.csv",               "results"),
    ("sprint_results.csv",        "sprint_results"),
    ("qualifying.csv",            "qualifying"),
    ("lap_times.csv",             "lap_times"),
    ("pit_stops.csv",             "pit_stops"),
]

FOREIGN_KEYS = [
    ("races", "fk_races_seasons", """
        ALTER TABLE `races`
            ADD CONSTRAINT `fk_races_seasons`
            FOREIGN KEY (`year`) REFERENCES `seasons` (`year`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
    ("races", "fk_races_circuits", """
        ALTER TABLE `races`
            ADD CONSTRAINT `fk_races_circuits`
            FOREIGN KEY (`circuitId`) REFERENCES `circuits` (`circuitId`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
    ("constructor_results", "fk_constructor_results_races", """
        ALTER TABLE `constructor_results`
            ADD CONSTRAINT `fk_constructor_results_races`
            FOREIGN KEY (`raceId`) REFERENCES `races` (`raceId`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
    ("constructor_results", "fk_constructor_results_constructors", """
        ALTER TABLE `constructor_results`
            ADD CONSTRAINT `fk_constructor_results_constructors`
            FOREIGN KEY (`constructorId`) REFERENCES `constructors` (`constructorId`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
    ("constructor_standings", "fk_constructor_standings_races", """
        ALTER TABLE `constructor_standings`
            ADD CONSTRAINT `fk_constructor_standings_races`
            FOREIGN KEY (`raceId`) REFERENCES `races` (`raceId`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
    ("constructor_standings", "fk_constructor_standings_constructors", """
        ALTER TABLE `constructor_standings`
            ADD CONSTRAINT `fk_constructor_standings_constructors`
            FOREIGN KEY (`constructorId`) REFERENCES `constructors` (`constructorId`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
    ("driver_standings", "fk_driver_standings_races", """
        ALTER TABLE `driver_standings`
            ADD CONSTRAINT `fk_driver_standings_races`
            FOREIGN KEY (`raceId`) REFERENCES `races` (`raceId`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
    ("driver_standings", "fk_driver_standings_drivers", """
        ALTER TABLE `driver_standings`
            ADD CONSTRAINT `fk_driver_standings_drivers`
            FOREIGN KEY (`driverId`) REFERENCES `drivers` (`driverId`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
    ("results", "fk_results_races", """
        ALTER TABLE `results`
            ADD CONSTRAINT `fk_results_races`
            FOREIGN KEY (`raceId`) REFERENCES `races` (`raceId`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
    ("results", "fk_results_drivers", """
        ALTER TABLE `results`
            ADD CONSTRAINT `fk_results_drivers`
            FOREIGN KEY (`driverId`) REFERENCES `drivers` (`driverId`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
    ("results", "fk_results_constructors", """
        ALTER TABLE `results`
            ADD CONSTRAINT `fk_results_constructors`
            FOREIGN KEY (`constructorId`) REFERENCES `constructors` (`constructorId`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
    ("results", "fk_results_status", """
        ALTER TABLE `results`
            ADD CONSTRAINT `fk_results_status`
            FOREIGN KEY (`statusId`) REFERENCES `status` (`statusId`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
    ("sprint_results", "fk_sprint_results_races", """
        ALTER TABLE `sprint_results`
            ADD CONSTRAINT `fk_sprint_results_races`
            FOREIGN KEY (`raceId`) REFERENCES `races` (`raceId`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
    ("sprint_results", "fk_sprint_results_drivers", """
        ALTER TABLE `sprint_results`
            ADD CONSTRAINT `fk_sprint_results_drivers`
            FOREIGN KEY (`driverId`) REFERENCES `drivers` (`driverId`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
    ("sprint_results", "fk_sprint_results_constructors", """
        ALTER TABLE `sprint_results`
            ADD CONSTRAINT `fk_sprint_results_constructors`
            FOREIGN KEY (`constructorId`) REFERENCES `constructors` (`constructorId`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
    ("sprint_results", "fk_sprint_results_status", """
        ALTER TABLE `sprint_results`
            ADD CONSTRAINT `fk_sprint_results_status`
            FOREIGN KEY (`statusId`) REFERENCES `status` (`statusId`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
    ("qualifying", "fk_qualifying_races", """
        ALTER TABLE `qualifying`
            ADD CONSTRAINT `fk_qualifying_races`
            FOREIGN KEY (`raceId`) REFERENCES `races` (`raceId`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
    ("qualifying", "fk_qualifying_drivers", """
        ALTER TABLE `qualifying`
            ADD CONSTRAINT `fk_qualifying_drivers`
            FOREIGN KEY (`driverId`) REFERENCES `drivers` (`driverId`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
    ("qualifying", "fk_qualifying_constructors", """
        ALTER TABLE `qualifying`
            ADD CONSTRAINT `fk_qualifying_constructors`
            FOREIGN KEY (`constructorId`) REFERENCES `constructors` (`constructorId`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
    ("lap_times", "fk_lap_times_races", """
        ALTER TABLE `lap_times`
            ADD CONSTRAINT `fk_lap_times_races`
            FOREIGN KEY (`raceId`) REFERENCES `races` (`raceId`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
    ("lap_times", "fk_lap_times_drivers", """
        ALTER TABLE `lap_times`
            ADD CONSTRAINT `fk_lap_times_drivers`
            FOREIGN KEY (`driverId`) REFERENCES `drivers` (`driverId`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
    ("pit_stops", "fk_pit_stops_races", """
        ALTER TABLE `pit_stops`
            ADD CONSTRAINT `fk_pit_stops_races`
            FOREIGN KEY (`raceId`) REFERENCES `races` (`raceId`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
    ("pit_stops", "fk_pit_stops_drivers", """
        ALTER TABLE `pit_stops`
            ADD CONSTRAINT `fk_pit_stops_drivers`
            FOREIGN KEY (`driverId`) REFERENCES `drivers` (`driverId`)
            ON UPDATE CASCADE
            ON DELETE RESTRICT
    """),
]


def null(val):
    """Convert MySQL null marker or empty string to Python None."""
    if val in (r"\N", "\\N", ""):
        return None
    return val


def load_csv(cursor, csv_path, table):
    with open(csv_path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        cols = reader.fieldnames
        placeholders = ", ".join(["%s"] * len(cols))
        col_names = ", ".join(f"`{c}`" for c in cols)
        sql = f"INSERT IGNORE INTO `{table}` ({col_names}) VALUES ({placeholders})"

        batch = []
        for row in reader:
            batch.append(tuple(null(row[c]) for c in cols))
            if len(batch) >= 5000:
                cursor.executemany(sql, batch)
                batch = []
        if batch:
            cursor.executemany(sql, batch)


def foreign_key_exists(cursor, table, constraint_name):
    cursor.execute(
        """
        SELECT 1
        FROM information_schema.TABLE_CONSTRAINTS
        WHERE CONSTRAINT_SCHEMA = %s
          AND TABLE_NAME = %s
          AND CONSTRAINT_NAME = %s
          AND CONSTRAINT_TYPE = 'FOREIGN KEY'
        LIMIT 1
        """,
        (DB_NAME, table, constraint_name),
    )
    return cursor.fetchone() is not None


def ensure_foreign_keys(cursor):
    print("\nCreating foreign keys...\n")
    for table, constraint_name, stmt in FOREIGN_KEYS:
        if foreign_key_exists(cursor, table, constraint_name):
            print(f"  [SKIP] {constraint_name} already exists")
            continue
        cursor.execute(stmt)
        print(f"  [OK]   {constraint_name}")


def main():
    print(f"Connecting to MySQL at {DB_HOST}:{DB_PORT}...")
    conn = mysql.connector.connect(
        host=DB_HOST, port=DB_PORT, user=DB_USER, password=DB_PASS
    )
    cursor = conn.cursor()

    print(f"Creating database `{DB_NAME}`...")
    cursor.execute(f"CREATE DATABASE IF NOT EXISTS `{DB_NAME}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
    cursor.execute(f"USE `{DB_NAME}`")

    print("Creating tables...")
    for stmt in DDL:
        cursor.execute(stmt)
    conn.commit()

    print("Loading CSV data...\n")
    for csv_file, table in TABLES:
        path = os.path.join(CSV_DIR, csv_file)
        if not os.path.exists(path):
            print(f"  [SKIP] {csv_file} not found")
            continue
        print(f"  Importing {csv_file} → {table}...", end=" ", flush=True)
        load_csv(cursor, path, table)
        conn.commit()
        cursor.execute(f"SELECT COUNT(*) FROM `{table}`")
        count = cursor.fetchone()[0]
        print(f"{count} rows")

    ensure_foreign_keys(cursor)
    conn.commit()

    cursor.close()
    conn.close()
    print(f"\nDone. Database `{DB_NAME}` is ready.")


if __name__ == "__main__":
    main()
