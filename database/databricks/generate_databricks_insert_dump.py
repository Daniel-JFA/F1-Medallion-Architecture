#!/usr/bin/env python3
"""
Generate Databricks-compatible INSERT-based load scripts from the local F1 CSVs.

Outputs:
- F1_databricks_load_inserts.sql
- F1_databricks_full_rebuild_inserts.sql
"""

from __future__ import annotations

import csv
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent
CSV_DIR = BASE_DIR / "DB F1"
BATCH_SIZE = 1000


TABLES = [
    (
        "circuits",
        "circuits.csv",
        [
            ("circuitId", "int"),
            ("circuitRef", "string"),
            ("name", "string"),
            ("location", "string"),
            ("country", "string"),
            ("lat", "double"),
            ("lng", "double"),
            ("alt", "int"),
            ("url", "string"),
        ],
    ),
    (
        "constructors",
        "constructors.csv",
        [
            ("constructorId", "int"),
            ("constructorRef", "string"),
            ("name", "string"),
            ("nationality", "string"),
            ("url", "string"),
        ],
    ),
    (
        "drivers",
        "drivers.csv",
        [
            ("driverId", "int"),
            ("driverRef", "string"),
            ("number", "int"),
            ("code", "string"),
            ("forename", "string"),
            ("surname", "string"),
            ("dob", "date"),
            ("nationality", "string"),
            ("url", "string"),
        ],
    ),
    (
        "seasons",
        "seasons.csv",
        [
            ("year", "int"),
            ("url", "string"),
        ],
    ),
    (
        "status",
        "status.csv",
        [
            ("statusId", "int"),
            ("status", "string"),
        ],
    ),
    (
        "races",
        "races.csv",
        [
            ("raceId", "int"),
            ("year", "int"),
            ("round", "int"),
            ("circuitId", "int"),
            ("name", "string"),
            ("date", "date"),
            ("time", "string"),
            ("url", "string"),
            ("fp1_date", "date"),
            ("fp1_time", "string"),
            ("fp2_date", "date"),
            ("fp2_time", "string"),
            ("fp3_date", "date"),
            ("fp3_time", "string"),
            ("quali_date", "date"),
            ("quali_time", "string"),
            ("sprint_date", "date"),
            ("sprint_time", "string"),
        ],
    ),
    (
        "constructor_results",
        "constructor_results.csv",
        [
            ("constructorResultsId", "int"),
            ("raceId", "int"),
            ("constructorId", "int"),
            ("points", "double"),
            ("status", "string"),
        ],
    ),
    (
        "constructor_standings",
        "constructor_standings.csv",
        [
            ("constructorStandingsId", "int"),
            ("raceId", "int"),
            ("constructorId", "int"),
            ("points", "double"),
            ("position", "int"),
            ("positionText", "string"),
            ("wins", "int"),
        ],
    ),
    (
        "driver_standings",
        "driver_standings.csv",
        [
            ("driverStandingsId", "int"),
            ("raceId", "int"),
            ("driverId", "int"),
            ("points", "double"),
            ("position", "int"),
            ("positionText", "string"),
            ("wins", "int"),
        ],
    ),
    (
        "results",
        "results.csv",
        [
            ("resultId", "int"),
            ("raceId", "int"),
            ("driverId", "int"),
            ("constructorId", "int"),
            ("number", "int"),
            ("grid", "int"),
            ("position", "int"),
            ("positionText", "string"),
            ("positionOrder", "int"),
            ("points", "double"),
            ("laps", "int"),
            ("time", "string"),
            ("milliseconds", "int"),
            ("fastestLap", "int"),
            ("rank", "int"),
            ("fastestLapTime", "string"),
            ("fastestLapSpeed", "string"),
            ("statusId", "int"),
        ],
    ),
    (
        "sprint_results",
        "sprint_results.csv",
        [
            ("resultId", "int"),
            ("raceId", "int"),
            ("driverId", "int"),
            ("constructorId", "int"),
            ("number", "int"),
            ("grid", "int"),
            ("position", "int"),
            ("positionText", "string"),
            ("positionOrder", "int"),
            ("points", "double"),
            ("laps", "int"),
            ("time", "string"),
            ("milliseconds", "int"),
            ("fastestLap", "int"),
            ("fastestLapTime", "string"),
            ("statusId", "int"),
        ],
    ),
    (
        "qualifying",
        "qualifying.csv",
        [
            ("qualifyId", "int"),
            ("raceId", "int"),
            ("driverId", "int"),
            ("constructorId", "int"),
            ("number", "int"),
            ("position", "int"),
            ("q1", "string"),
            ("q2", "string"),
            ("q3", "string"),
        ],
    ),
    (
        "lap_times",
        "lap_times.csv",
        [
            ("raceId", "int"),
            ("driverId", "int"),
            ("lap", "int"),
            ("position", "int"),
            ("time", "string"),
            ("milliseconds", "int"),
        ],
    ),
    (
        "pit_stops",
        "pit_stops.csv",
        [
            ("raceId", "int"),
            ("driverId", "int"),
            ("stop", "int"),
            ("lap", "int"),
            ("time", "string"),
            ("duration", "string"),
            ("milliseconds", "int"),
        ],
    ),
]


def sql_string(value: str) -> str:
    escaped = (
        value.replace("\\", "\\\\")
        .replace("'", "''")
        .replace("\r", "\\r")
        .replace("\n", "\\n")
    )
    return f"'{escaped}'"


def sql_literal(value: str, kind: str) -> str:
    if value == "" or value == r"\N":
        return "NULL"
    if kind in {"int", "double"}:
        return value
    if kind in {"date", "string"}:
        return sql_string(value)
    raise ValueError(f"Unsupported kind: {kind}")


def flush_batch(handle, table_name: str, rows: list[str]) -> None:
    if not rows:
        return
    handle.write(f"INSERT INTO f1.{table_name} VALUES\n")
    handle.write(",\n".join(rows))
    handle.write(";\n\n")


def generate_load_inserts(output_path: Path) -> None:
    with output_path.open("w", encoding="utf-8") as out:
        out.write("-- Databricks SQL load script generated from the local F1 CSV files.\n")
        out.write("-- This version avoids volumes and COPY INTO by using INSERT statements.\n")
        out.write("-- Run it after creating the base schema/tables in schema f1.\n\n")
        out.write("USE f1;\n\n")

        for table_name, csv_name, columns in TABLES:
            csv_path = CSV_DIR / csv_name
            out.write("-- ============================================================\n")
            out.write(f"-- Load {table_name} from {csv_name}\n")
            out.write("-- ============================================================\n")
            out.write(f"TRUNCATE TABLE f1.{table_name};\n\n")

            with csv_path.open("r", encoding="utf-8", newline="") as fh:
                reader = csv.DictReader(fh)
                batch: list[str] = []
                row_count = 0
                for row in reader:
                    values = [
                        sql_literal(row[column_name], kind)
                        for column_name, kind in columns
                    ]
                    batch.append(f"({', '.join(values)})")
                    row_count += 1
                    if len(batch) >= BATCH_SIZE:
                        flush_batch(out, table_name, batch)
                        batch.clear()

                flush_batch(out, table_name, batch)

            out.write(f"-- Rows loaded into {table_name}: {row_count}\n\n")


def generate_full_rebuild(output_path: Path, load_insert_path: Path) -> None:
    parts = [
        BASE_DIR / "F1_databricks_schema.sql",
        load_insert_path,
        BASE_DIR / "F1_databricks_constraints.sql",
        BASE_DIR / "F1_databricks_silver.sql",
        BASE_DIR / "F1_databricks_gold.sql",
    ]

    footer = """

-- ============================================================
-- End of full rebuild
-- ============================================================
-- This INSERT-based consolidated rebuild avoids Databricks volumes.
-- It is intended for SQL clients such as DBeaver when COPY INTO is
-- not convenient in the current workspace setup.
--
-- If you want KPI versioning later, run the separate file:
-- /home/djfa/Dev/DBs BackUps/F1_databricks_control.sql
"""

    content = "\n\n".join(part.read_text(encoding="utf-8").rstrip() for part in parts)
    output_path.write_text(content + footer, encoding="utf-8")


def main() -> None:
    load_insert_path = BASE_DIR / "F1_databricks_load_inserts.sql"
    full_rebuild_path = BASE_DIR / "F1_databricks_full_rebuild_inserts.sql"
    generate_load_inserts(load_insert_path)
    generate_full_rebuild(full_rebuild_path, load_insert_path)
    print(load_insert_path)
    print(full_rebuild_path)


if __name__ == "__main__":
    main()
