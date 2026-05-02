-- Optional KPI history layer for Databricks SQL.
--
-- Assumption:
-- - Schema f1_gold already exists.
-- - You want to preserve historical snapshots of the KPI cards.
--
-- Optional for Unity Catalog:
-- USE CATALOG workspace;

CREATE CATALOG IF NOT EXISTS f1;
USE CATALOG f1;

CREATE SCHEMA IF NOT EXISTS f1_control;
USE f1_control;

CREATE TABLE IF NOT EXISTS f1_control.f1_gold_kpi_snapshot_history (
    snapshot_label STRING NOT NULL,
    source_schema STRING NOT NULL,
    snapshot_taken_at TIMESTAMP NOT NULL,
    kpi_code STRING NOT NULL,
    kpi_name STRING NOT NULL,
    unit_of_measure STRING NOT NULL,
    kpi_value_numeric DECIMAL(18,2) NOT NULL,
    kpi_value_text STRING NOT NULL
)
USING DELTA;

-- Replace the snapshot label if you want a semantic cut such as:
-- 'clase_2026_04_18' or 'entrega_final'.
MERGE INTO f1_control.f1_gold_kpi_snapshot_history AS target
USING (
    SELECT
        'snapshot_actual' AS snapshot_label,
        'f1_gold' AS source_schema,
        CURRENT_TIMESTAMP() AS snapshot_taken_at,
        kc.kpi_code,
        kc.kpi_name,
        kc.unit_of_measure,
        ks.kpi_value_numeric,
        ks.kpi_value_text
    FROM f1_gold.kpi_catalog kc
    JOIN f1_gold.mart_kpi_snapshot ks
        ON kc.kpi_code = ks.kpi_code
) AS source
ON target.snapshot_label = source.snapshot_label
AND target.source_schema = source.source_schema
AND target.kpi_code = source.kpi_code
WHEN MATCHED THEN UPDATE SET
    target.snapshot_taken_at = source.snapshot_taken_at,
    target.kpi_name = source.kpi_name,
    target.unit_of_measure = source.unit_of_measure,
    target.kpi_value_numeric = source.kpi_value_numeric,
    target.kpi_value_text = source.kpi_value_text
WHEN NOT MATCHED THEN INSERT (
    snapshot_label,
    source_schema,
    snapshot_taken_at,
    kpi_code,
    kpi_name,
    unit_of_measure,
    kpi_value_numeric,
    kpi_value_text
) VALUES (
    source.snapshot_label,
    source.source_schema,
    source.snapshot_taken_at,
    source.kpi_code,
    source.kpi_name,
    source.unit_of_measure,
    source.kpi_value_numeric,
    source.kpi_value_text
);

SELECT
    snapshot_label,
    source_schema,
    COUNT(*) AS frozen_kpis
FROM f1_control.f1_gold_kpi_snapshot_history
GROUP BY snapshot_label, source_schema
ORDER BY snapshot_label DESC, source_schema;
