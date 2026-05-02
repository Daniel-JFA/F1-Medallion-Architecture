CREATE DATABASE IF NOT EXISTS F1_control
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE F1_control;

CREATE TABLE IF NOT EXISTS f1_gold_kpi_snapshot_history (
    snapshot_id BIGINT NOT NULL AUTO_INCREMENT,
    snapshot_label VARCHAR(128) NOT NULL,
    source_schema VARCHAR(64) NOT NULL,
    snapshot_taken_at DATETIME NOT NULL,
    kpi_code VARCHAR(64) NOT NULL,
    kpi_name VARCHAR(255) NOT NULL,
    unit_of_measure VARCHAR(50) NOT NULL,
    kpi_value_numeric DECIMAL(18,2) NOT NULL,
    kpi_value_text VARCHAR(255) NOT NULL,
    PRIMARY KEY (snapshot_id),
    UNIQUE KEY uk_kpi_snapshot_label_code (snapshot_label, source_schema, kpi_code),
    KEY idx_kpi_snapshot_label (snapshot_label),
    KEY idx_kpi_snapshot_source (source_schema),
    KEY idx_kpi_snapshot_taken_at (snapshot_taken_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET @snapshot_label = COALESCE(@snapshot_label, DATE_FORMAT(NOW(), 'snapshot_%Y%m%d_%H%i%s'));
SET @snapshot_taken_at = NOW();
SET @source_schema = 'F1_gold';

DELETE FROM f1_gold_kpi_snapshot_history
WHERE snapshot_label COLLATE utf8mb4_general_ci = @snapshot_label
  AND source_schema COLLATE utf8mb4_general_ci = @source_schema;

INSERT INTO f1_gold_kpi_snapshot_history (
    snapshot_label,
    source_schema,
    snapshot_taken_at,
    kpi_code,
    kpi_name,
    unit_of_measure,
    kpi_value_numeric,
    kpi_value_text
)
SELECT
    @snapshot_label AS snapshot_label,
    @source_schema AS source_schema,
    @snapshot_taken_at AS snapshot_taken_at,
    kc.kpi_code,
    kc.kpi_name,
    kc.unit_of_measure,
    ks.kpi_value_numeric,
    ks.kpi_value_text
FROM F1_gold.kpi_catalog kc
JOIN F1_gold.mart_kpi_snapshot ks
    ON kc.kpi_code COLLATE utf8mb4_general_ci = ks.kpi_code
ORDER BY kc.kpi_code;

SELECT
    snapshot_label,
    source_schema,
    COUNT(*) AS frozen_kpis
FROM f1_gold_kpi_snapshot_history
WHERE snapshot_label COLLATE utf8mb4_general_ci = @snapshot_label
  AND source_schema COLLATE utf8mb4_general_ci = @source_schema
GROUP BY snapshot_label, source_schema;
