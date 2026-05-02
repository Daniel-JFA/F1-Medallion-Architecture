#!/usr/bin/env python3
"""Execute a large Databricks SQL script through JDBC.

The script intentionally reads the Databricks token from an environment
variable so secrets are not committed or printed.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path


DEFAULT_JDBC_URL = (
    "jdbc:databricks://dbc-27294608-e1ce.cloud.databricks.com:443/default;"
    "transportMode=http;ssl=1;AuthMech=3;"
    "httpPath=/sql/1.0/warehouses/14f76675cb754d43;"
)

DEFAULT_SQL_FILES = [
    Path(__file__).resolve().parents[1] / "database/databricks/F1_databricks_silver.sql",
    Path(__file__).resolve().parents[1] / "database/databricks/F1_databricks_gold.sql",
    Path(__file__).resolve().parents[1] / "database/databricks/F1_databricks_control.sql",
]

DRIVER_CANDIDATES = [
    Path.home()
    / ".local/share/DBeaverData/drivers/maven/maven-central/com.databricks/databricks-jdbc-3.3.3.jar",
    Path.home()
    / ".local/share/DBeaverData/drivers/maven/maven-central/com.databricks/databricks-jdbc-3.3.1.jar",
]


def is_comment_only(statement: str) -> bool:
    without_block = re.sub(r"/\*.*?\*/", "", statement, flags=re.S)
    without_lines = "\n".join(
        line for line in without_block.splitlines() if not line.strip().startswith("--")
    )
    return not without_lines.strip()


def split_sql(script: str) -> list[str]:
    """Split SQL on semicolons outside quoted strings and comments."""

    statements: list[str] = []
    buf: list[str] = []
    in_single = False
    in_double = False
    in_line_comment = False
    in_block_comment = False
    i = 0
    while i < len(script):
        ch = script[i]
        nxt = script[i + 1] if i + 1 < len(script) else ""

        if in_line_comment:
            buf.append(ch)
            if ch == "\n":
                in_line_comment = False
            i += 1
            continue

        if in_block_comment:
            buf.append(ch)
            if ch == "*" and nxt == "/":
                buf.append(nxt)
                in_block_comment = False
                i += 2
            else:
                i += 1
            continue

        if not in_single and not in_double:
            if ch == "-" and nxt == "-":
                buf.append(ch)
                buf.append(nxt)
                in_line_comment = True
                i += 2
                continue
            if ch == "/" and nxt == "*":
                buf.append(ch)
                buf.append(nxt)
                in_block_comment = True
                i += 2
                continue

        if ch == "'" and not in_double:
            buf.append(ch)
            if in_single and nxt == "'":
                buf.append(nxt)
                i += 2
                continue
            in_single = not in_single
            i += 1
            continue

        if ch == '"' and not in_single:
            in_double = not in_double
            buf.append(ch)
            i += 1
            continue

        if ch == ";" and not in_single and not in_double:
            statement = "".join(buf).strip()
            if statement and not is_comment_only(statement):
                statements.append(statement)
            buf.clear()
            i += 1
            continue

        buf.append(ch)
        i += 1

    statement = "".join(buf).strip()
    if statement and not is_comment_only(statement):
        statements.append(statement)
    return statements


def main() -> int:
    token = os.getenv("DATABRICKS_TOKEN")
    if not token:
        print("ERROR: exporta DATABRICKS_TOKEN antes de ejecutar.", file=sys.stderr)
        print("Ejemplo: export DATABRICKS_TOKEN='dapi...'", file=sys.stderr)
        return 2

    catalog = os.getenv("DATABRICKS_CATALOG", "f1").strip()
    jdbc_url = os.getenv("DATABRICKS_JDBC_URL", DEFAULT_JDBC_URL)
    
    sql_files_env = os.getenv("DATABRICKS_SQL_FILE")
    if sql_files_env:
        sql_files = [Path(f.strip()).resolve() for f in sql_files_env.split(",")]
    else:
        sql_files = [f.resolve() for f in DEFAULT_SQL_FILES]

    driver_env = os.getenv("DATABRICKS_JDBC_DRIVER", "").strip()
    driver = Path(driver_env).expanduser() if driver_env else Path()
    if not driver_env:
        driver = next((p for p in DRIVER_CANDIDATES if p.exists()), Path())

    if not driver.exists():
        print("ERROR: no encontre el driver JDBC de Databricks.", file=sys.stderr)
        print("Define DATABRICKS_JDBC_DRIVER=/ruta/databricks-jdbc.jar", file=sys.stderr)
        return 2

    for f in sql_files:
        if not f.exists():
            print(f"ERROR: no existe el SQL: {f}", file=sys.stderr)
            return 2

    statements = [
        f"CREATE CATALOG IF NOT EXISTS {catalog};",
        f"USE CATALOG {catalog};",
    ]
    for f in sql_files:
        statements.extend(split_sql(f.read_text(encoding="utf-8")))

    print(f"SQL files to execute: {[f.name for f in sql_files]}")
    print(f"Total statements: {len(statements)}")
    print(f"Driver: {driver}")

    java_source = r"""
import java.sql.*;
import java.nio.file.*;
import java.util.*;

public class RunDatabricksSql {
    private static void printProgress(int current, int total, String preview) {
        int width = 24;
        int filled = (int) Math.round((double) current * width / total);
        StringBuilder bar = new StringBuilder();
        for (int i = 0; i < width; i++) {
            bar.append(i < filled ? '=' : ' ');
        }
        String line = String.format("\r[%s] %3d%% (%d/%d) %s", bar, Math.round(current * 100.0 / total), current, total, preview);
        System.out.print(line);
        System.out.flush();
        if (current == total) {
            System.out.println();
        }
    }

  public static void main(String[] args) throws Exception {
    String jdbcUrl = args[0];
    String statementsPath = args[1];
    String token = System.getenv("DATABRICKS_TOKEN");
    if (token == null || token.isBlank()) {
      throw new IllegalStateException("DATABRICKS_TOKEN no esta definido");
    }
    List<String> statements = Files.readAllLines(Path.of(statementsPath));
    Properties props = new Properties();
    props.setProperty("UID", "token");
    props.setProperty("PWD", token);
        int skipped = 0;
    try (Connection conn = DriverManager.getConnection(jdbcUrl, props);
         Statement stmt = conn.createStatement()) {
      int i = 0;
      for (String encodedSql : statements) {
        String sql = encodedSql.replace("\\n", "\n");
        i++;
        String preview = sql.replaceAll("\\s+", " ").trim();
        if (preview.length() > 100) preview = preview.substring(0, 100) + "...";
                if (i == 1 || i == statements.size() || i % 25 == 0) {
                    printProgress(i, statements.size(), preview);
                }
                try {
                    stmt.execute(sql);
                } catch (SQLException exc) {
                    String message = String.valueOf(exc.getMessage());
                    boolean alreadyExists = message.contains("PRIMARY KEY constraint")
                            || message.contains("UNIQUE CONSTRAINT")
                            || message.contains("RESOURCE_ALREADY_EXISTS");
                    boolean isConstraintStatement = sql.regionMatches(true, 0, "ALTER TABLE", 0, "ALTER TABLE".length())
                            && sql.toUpperCase(Locale.ROOT).contains("ADD CONSTRAINT");
                    if (alreadyExists && isConstraintStatement) {
                        skipped++;
                        continue;
                    }
                    throw exc;
                }
      }
            if (skipped > 0) {
                System.out.println("Skipped already-existing constraints: " + skipped);
            }
    }
  }
}
"""

    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        src = tmp_path / "RunDatabricksSql.java"
        src.write_text(java_source, encoding="utf-8")
        statements_path = tmp_path / "statements.txt"
        statements_path.write_text("\n".join(s.replace("\n", "\\n") for s in statements), encoding="utf-8")

        proc = subprocess.run(
            [
                "java",
                "-Xmx2g",
                "--class-path",
                str(driver),
                str(src),
                jdbc_url,
                str(statements_path),
            ],
            check=False,
        )
        return proc.returncode


if __name__ == "__main__":
    raise SystemExit(main())
