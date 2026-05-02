-- =========================================================
-- Gold layer for local MySQL / MariaDB
-- Source database: F1_silver
-- Target database: F1_gold
-- =========================================================

CREATE DATABASE IF NOT EXISTS F1_gold
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE F1_gold;

-- =========================================================
-- Cleanup for reruns
-- =========================================================

DROP VIEW IF EXISTS vw_dashboard_recent_race_highlights;
DROP VIEW IF EXISTS vw_dashboard_latest_constructor_championship;
DROP VIEW IF EXISTS vw_dashboard_latest_driver_championship;
DROP VIEW IF EXISTS vw_dashboard_qualifying_effect_recent;
DROP VIEW IF EXISTS vw_dashboard_circuit_risk;
DROP VIEW IF EXISTS vw_dashboard_top_constructors;
DROP VIEW IF EXISTS vw_dashboard_top_drivers;
DROP VIEW IF EXISTS vw_dashboard_kpi_cards;

DROP TABLE IF EXISTS mart_kpi_snapshot;
DROP TABLE IF EXISTS mart_race_weekend;
DROP TABLE IF EXISTS mart_qualifying_effect_season;
DROP TABLE IF EXISTS mart_circuit_risk;
DROP TABLE IF EXISTS mart_constructor_season;
DROP TABLE IF EXISTS mart_driver_season;
DROP TABLE IF EXISTS kpi_catalog;

-- =========================================================
-- KPI catalog
-- =========================================================

CREATE TABLE kpi_catalog (
    kpi_code VARCHAR(64) NOT NULL,
    kpi_name VARCHAR(255) NOT NULL,
    business_question VARCHAR(255) NOT NULL,
    business_definition TEXT NOT NULL,
    formula_definition TEXT NOT NULL,
    unit_of_measure VARCHAR(50) NOT NULL,
    grain_level VARCHAR(100) NOT NULL,
    source_objects VARCHAR(255) NOT NULL,
    PRIMARY KEY (kpi_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO kpi_catalog (
    kpi_code,
    kpi_name,
    business_question,
    business_definition,
    formula_definition,
    unit_of_measure,
    grain_level,
    source_objects
)
VALUES
(
    'total_seasons',
    'Temporadas cubiertas',
    'Cuantas temporadas historicas cubre el proyecto',
    'Cuenta total de temporadas modeladas en la capa Silver.',
    'COUNT(*) sobre F1_silver.dim_seasons',
    'temporadas',
    'global',
    'F1_silver.dim_seasons'
),
(
    'total_races',
    'Carreras registradas',
    'Cuantas carreras contiene la base analitica',
    'Cantidad total de grandes premios modelados en la dimension de carreras.',
    'COUNT(*) sobre F1_silver.dim_races',
    'carreras',
    'global',
    'F1_silver.dim_races'
),
(
    'total_drivers',
    'Pilotos registrados',
    'Cuantos pilotos unicos forman parte del historico',
    'Cantidad total de pilotos unicos disponibles para analisis.',
    'COUNT(*) sobre F1_silver.dim_drivers',
    'pilotos',
    'global',
    'F1_silver.dim_drivers'
),
(
    'total_constructors',
    'Escuderias registradas',
    'Cuantas escuderias aparecen en el historico',
    'Cantidad total de constructores unicos disponibles para analisis.',
    'COUNT(*) sobre F1_silver.dim_constructors',
    'escuderias',
    'global',
    'F1_silver.dim_constructors'
),
(
    'classified_finish_rate_pct',
    'Tasa de clasificacion',
    'Que porcentaje de participaciones termina clasificada',
    'Porcentaje de entradas de carrera que terminan clasificadas, incluyendo vueltas perdidas pero registradas como clasificadas.',
    'SUM(is_classified_finish) / COUNT(*) * 100',
    'porcentaje',
    'global',
    'F1_silver.fact_race_entries'
),
(
    'dnf_rate_pct',
    'Tasa de no clasificacion',
    'Que porcentaje de participaciones termina sin clasificar',
    'Porcentaje de entradas de carrera que no terminan clasificadas.',
    '(COUNT(*) - SUM(is_classified_finish)) / COUNT(*) * 100',
    'porcentaje',
    'global',
    'F1_silver.fact_race_entries'
),
(
    'avg_points_per_entry',
    'Puntos promedio por entrada',
    'Cuantos puntos produce en promedio una participacion de carrera',
    'Promedio de puntos totales del evento por cada entrada de carrera.',
    'AVG(total_event_points)',
    'puntos',
    'global',
    'F1_silver.fact_race_entries'
),
(
    'pole_to_win_rate_pct',
    'Conversion pole a victoria',
    'Con que frecuencia una pole termina en victoria',
    'Porcentaje de victorias que fueron logradas por un piloto que salio desde la pole.',
    'SUM(CASE WHEN is_winner = 1 AND started_from_pole = 1 THEN 1 ELSE 0 END) / SUM(is_winner) * 100',
    'porcentaje',
    'global',
    'F1_silver.fact_race_entries'
),
(
    'sprint_weekend_share_pct',
    'Participacion de fines de semana sprint',
    'Que proporción del calendario corresponde a fines de semana con sprint',
    'Porcentaje de carreras cuya configuracion de fin de semana incluye sprint.',
    'SUM(has_sprint_weekend) / COUNT(*) * 100',
    'porcentaje',
    'global',
    'F1_silver.dim_races'
),
(
    'shared_drive_entry_rate_pct',
    'Participaciones con shared drive',
    'Que porcentaje de entradas corresponden a casos historicos de shared drive',
    'Porcentaje de registros identificados como posibles shared drives o multiples entradas del mismo piloto en una carrera.',
    'SUM(shared_drive_candidate) / COUNT(*) * 100',
    'porcentaje',
    'global',
    'F1_silver.fact_race_entries'
);

-- =========================================================
-- Business marts
-- =========================================================

CREATE TABLE mart_driver_season AS
SELECT
    fre.season_year,
    fre.driverId,
    dd.driver_name,
    pcm.constructorId AS primary_constructorId,
    dc.constructor_name AS primary_constructor_name,
    cu.constructors_used,
    COUNT(*) AS race_entries,
    COUNT(DISTINCT fre.raceId) AS race_weekends,
    SUM(fre.shared_drive_candidate) AS shared_drive_entries,
    SUM(fre.is_winner) AS wins,
    SUM(fre.is_podium) AS podiums,
    SUM(fre.qualified_on_pole) AS poles,
    ROUND(SUM(fre.race_points), 1) AS race_points,
    ROUND(SUM(fre.sprint_points), 1) AS sprint_points,
    ROUND(SUM(fre.total_event_points), 1) AS total_points,
    ROUND(AVG(NULLIF(fre.starting_grid, 0)), 2) AS avg_starting_grid,
    ROUND(AVG(fre.finish_position), 2) AS avg_finish_position,
    ROUND(AVG(fre.positions_gained), 2) AS avg_positions_gained,
    ROUND(AVG(fre.qualifying_to_finish_delta), 2) AS avg_qualifying_delta,
    SUM(fre.is_classified_finish) AS classified_finishes,
    COUNT(*) - SUM(fre.is_classified_finish) AS non_classified_finishes,
    ROUND((COUNT(*) - SUM(fre.is_classified_finish)) * 100.0 / COUNT(*), 2) AS non_classified_rate_pct,
    ROUND(SUM(fre.is_winner) * 100.0 / COUNT(*), 2) AS win_rate_pct,
    ROUND(SUM(fre.is_podium) * 100.0 / COUNT(*), 2) AS podium_rate_pct,
    ROUND(SUM(fre.qualified_on_pole) * 100.0 / COUNT(*), 2) AS pole_rate_pct,
    MAX(fre.total_event_points) AS best_event_points,
    MAX(fre.positions_gained) AS best_positions_gained,
    fs.championship_position,
    ROUND(fs.championship_points, 1) AS final_standings_points,
    fs.championship_wins
FROM F1_silver.fact_race_entries fre
JOIN F1_silver.dim_drivers dd
    ON fre.driverId = dd.driverId
LEFT JOIN (
    SELECT
        season_year,
        driverId,
        constructorId,
        ROW_NUMBER() OVER (
            PARTITION BY season_year, driverId
            ORDER BY COUNT(*) DESC, SUM(total_event_points) DESC, constructorId
        ) AS rn
    FROM F1_silver.fact_race_entries
    GROUP BY season_year, driverId, constructorId
) pcm
    ON fre.season_year = pcm.season_year
   AND fre.driverId = pcm.driverId
   AND pcm.rn = 1
LEFT JOIN F1_silver.dim_constructors dc
    ON pcm.constructorId = dc.constructorId
LEFT JOIN (
    SELECT
        fre2.season_year,
        fre2.driverId,
        GROUP_CONCAT(DISTINCT dc2.constructor_name ORDER BY dc2.constructor_name SEPARATOR ', ') AS constructors_used
    FROM F1_silver.fact_race_entries fre2
    JOIN F1_silver.dim_constructors dc2
        ON fre2.constructorId = dc2.constructorId
    GROUP BY fre2.season_year, fre2.driverId
) cu
    ON fre.season_year = cu.season_year
   AND fre.driverId = cu.driverId
LEFT JOIN (
    SELECT
        x.season_year,
        x.driverId,
        x.position AS championship_position,
        x.points AS championship_points,
        x.wins AS championship_wins
    FROM (
        SELECT
            fds.*,
            dr.season_round,
            ROW_NUMBER() OVER (
                PARTITION BY fds.season_year, fds.driverId
                ORDER BY dr.season_round DESC, fds.raceId DESC, fds.driverStandingsId DESC
            ) AS rn
        FROM F1_silver.fact_driver_standings fds
        JOIN F1_silver.dim_races dr
            ON fds.raceId = dr.raceId
    ) x
    WHERE x.rn = 1
) fs
    ON fre.season_year = fs.season_year
   AND fre.driverId = fs.driverId
GROUP BY
    fre.season_year,
    fre.driverId,
    dd.driver_name,
    pcm.constructorId,
    dc.constructor_name,
    cu.constructors_used,
    fs.championship_position,
    fs.championship_points,
    fs.championship_wins;

ALTER TABLE mart_driver_season
    ADD PRIMARY KEY (season_year, driverId),
    ADD KEY idx_mart_driver_season_driver (driverId),
    ADD KEY idx_mart_driver_season_points (total_points),
    ADD KEY idx_mart_driver_season_champ (championship_position);


CREATE TABLE mart_constructor_season AS
SELECT
    fre.season_year,
    fre.constructorId,
    dc.constructor_name,
    COUNT(*) AS race_entries,
    COUNT(DISTINCT fre.raceId) AS race_weekends,
    COUNT(DISTINCT fre.driverId) AS drivers_used,
    SUM(fre.shared_drive_candidate) AS shared_drive_entries,
    SUM(fre.is_winner) AS wins,
    SUM(fre.is_podium) AS podiums,
    SUM(fre.qualified_on_pole) AS poles,
    ROUND(SUM(fre.race_points), 1) AS race_points_from_entries,
    ROUND(SUM(fre.sprint_points), 1) AS sprint_points,
    ROUND(SUM(fre.total_event_points), 1) AS total_points,
    ROUND(COALESCE(cr.official_constructor_race_points, 0), 1) AS official_constructor_race_points,
    ROUND(AVG(NULLIF(fre.starting_grid, 0)), 2) AS avg_starting_grid,
    ROUND(AVG(fre.finish_position), 2) AS avg_finish_position,
    ROUND(AVG(fre.positions_gained), 2) AS avg_positions_gained,
    SUM(fre.is_classified_finish) AS classified_entries,
    COUNT(*) - SUM(fre.is_classified_finish) AS non_classified_entries,
    ROUND((COUNT(*) - SUM(fre.is_classified_finish)) * 100.0 / COUNT(*), 2) AS non_classified_rate_pct,
    ROUND(SUM(fre.is_winner) * 100.0 / COUNT(*), 2) AS win_rate_pct,
    ROUND(SUM(fre.is_podium) * 100.0 / COUNT(*), 2) AS podium_rate_pct,
    cs.championship_position,
    ROUND(cs.championship_points, 1) AS final_standings_points,
    cs.championship_wins
FROM F1_silver.fact_race_entries fre
JOIN F1_silver.dim_constructors dc
    ON fre.constructorId = dc.constructorId
LEFT JOIN (
    SELECT
        season_year,
        constructorId,
        SUM(points) AS official_constructor_race_points
    FROM F1_silver.fact_constructor_results
    GROUP BY season_year, constructorId
) cr
    ON fre.season_year = cr.season_year
   AND fre.constructorId = cr.constructorId
LEFT JOIN (
    SELECT
        x.season_year,
        x.constructorId,
        x.position AS championship_position,
        x.points AS championship_points,
        x.wins AS championship_wins
    FROM (
        SELECT
            fcs.*,
            dr.season_round,
            ROW_NUMBER() OVER (
                PARTITION BY fcs.season_year, fcs.constructorId
                ORDER BY dr.season_round DESC, fcs.raceId DESC, fcs.constructorStandingsId DESC
            ) AS rn
        FROM F1_silver.fact_constructor_standings fcs
        JOIN F1_silver.dim_races dr
            ON fcs.raceId = dr.raceId
    ) x
    WHERE x.rn = 1
) cs
    ON fre.season_year = cs.season_year
   AND fre.constructorId = cs.constructorId
GROUP BY
    fre.season_year,
    fre.constructorId,
    dc.constructor_name,
    cr.official_constructor_race_points,
    cs.championship_position,
    cs.championship_points,
    cs.championship_wins;

ALTER TABLE mart_constructor_season
    ADD PRIMARY KEY (season_year, constructorId),
    ADD KEY idx_mart_constructor_season_constructor (constructorId),
    ADD KEY idx_mart_constructor_season_points (total_points),
    ADD KEY idx_mart_constructor_season_champ (championship_position);


CREATE TABLE mart_circuit_risk AS
SELECT
    fre.circuitId,
    dc.circuit_name,
    dc.country,
    COUNT(DISTINCT fre.raceId) AS race_weekends_hosted,
    MIN(fre.season_year) AS first_season,
    MAX(fre.season_year) AS last_season,
    COUNT(*) AS total_entries,
    COUNT(DISTINCT fre.driverId) AS unique_drivers,
    SUM(fre.is_classified_finish) AS classified_entries,
    COUNT(*) - SUM(fre.is_classified_finish) AS non_classified_entries,
    ROUND((COUNT(*) - SUM(fre.is_classified_finish)) * 100.0 / COUNT(*), 2) AS non_classified_rate_pct,
    SUM(CASE WHEN fre.status_category = 'mechanical' THEN 1 ELSE 0 END) AS mechanical_non_classified_entries,
    SUM(CASE WHEN fre.status_category = 'accident_incident' THEN 1 ELSE 0 END) AS accident_non_classified_entries,
    SUM(CASE WHEN fre.status_category = 'disqualified' THEN 1 ELSE 0 END) AS disqualified_entries,
    SUM(CASE WHEN fre.is_winner = 1 AND fre.started_from_pole = 1 THEN 1 ELSE 0 END) AS pole_to_win_occurrences,
    ROUND(
        SUM(CASE WHEN fre.is_winner = 1 AND fre.started_from_pole = 1 THEN 1 ELSE 0 END) * 100.0
        / NULLIF(SUM(fre.is_winner), 0),
        2
    ) AS pole_to_win_rate_pct,
    ROUND(AVG(fre.positions_gained), 2) AS avg_positions_gained,
    ROUND(AVG(fre.total_event_points), 2) AS avg_points_per_entry
FROM F1_silver.fact_race_entries fre
JOIN F1_silver.dim_circuits dc
    ON fre.circuitId = dc.circuitId
GROUP BY
    fre.circuitId,
    dc.circuit_name,
    dc.country;

ALTER TABLE mart_circuit_risk
    ADD PRIMARY KEY (circuitId),
    ADD KEY idx_mart_circuit_risk_rate (non_classified_rate_pct),
    ADD KEY idx_mart_circuit_risk_entries (total_entries);


CREATE TABLE mart_qualifying_effect_season AS
SELECT
    fre.season_year,
    COUNT(*) AS race_entries_analyzed,
    COUNT(DISTINCT fre.raceId) AS race_weekends,
    ROUND(AVG(fre.qualifying_position), 2) AS avg_qualifying_position,
    ROUND(AVG(fre.finish_position), 2) AS avg_finish_position,
    ROUND(AVG(fre.positions_gained), 2) AS avg_positions_gained,
    ROUND(AVG(fre.qualifying_to_finish_delta), 2) AS avg_qualifying_to_finish_delta,
    SUM(CASE WHEN fre.is_winner = 1 AND fre.qualified_on_pole = 1 THEN 1 ELSE 0 END) AS winners_from_pole,
    ROUND(
        SUM(CASE WHEN fre.is_winner = 1 AND fre.qualified_on_pole = 1 THEN 1 ELSE 0 END) * 100.0
        / NULLIF(SUM(fre.is_winner), 0),
        2
    ) AS pole_to_win_rate_pct,
    SUM(CASE WHEN fre.qualifying_position <= 2 AND fre.is_podium = 1 THEN 1 ELSE 0 END) AS front_row_podium_entries,
    ROUND(
        SUM(CASE WHEN fre.qualifying_position <= 2 AND fre.is_podium = 1 THEN 1 ELSE 0 END) * 100.0
        / NULLIF(SUM(CASE WHEN fre.qualifying_position <= 2 THEN 1 ELSE 0 END), 0),
        2
    ) AS front_row_podium_rate_pct,
    ROUND(AVG(CASE WHEN fre.is_winner = 1 THEN fre.starting_grid END), 2) AS winner_avg_grid,
    ROUND(AVG(CASE WHEN fre.is_winner = 1 THEN fre.qualifying_position END), 2) AS winner_avg_qualifying_position
FROM F1_silver.fact_race_entries fre
WHERE fre.qualifying_position IS NOT NULL
GROUP BY fre.season_year;

ALTER TABLE mart_qualifying_effect_season
    ADD PRIMARY KEY (season_year);


CREATE TABLE mart_race_weekend AS
SELECT
    dr.raceId,
    dr.season_year,
    dr.season_round,
    ds.total_races AS season_total_races,
    dr.race_name,
    dr.race_date,
    dr.has_sprint_weekend,
    dc.circuit_name,
    dc.country,
    COUNT(fre.resultId) AS race_entries,
    COUNT(DISTINCT fre.driverId) AS unique_drivers,
    COUNT(DISTINCT fre.constructorId) AS unique_constructors,
    ROUND(SUM(fre.total_event_points), 1) AS total_event_points_awarded,
    SUM(fre.is_classified_finish) AS classified_entries,
    COUNT(fre.resultId) - SUM(fre.is_classified_finish) AS non_classified_entries,
    ROUND((COUNT(fre.resultId) - SUM(fre.is_classified_finish)) * 100.0 / COUNT(fre.resultId), 2) AS non_classified_rate_pct,
    SUM(fre.shared_drive_candidate) AS shared_drive_entries,
    wr.winner_driver_names AS winner_driver_name,
    wr.winner_constructor_names AS winner_constructor_name,
    wr.winner_starting_grids AS winner_starting_grid,
    ps.pole_driver_names AS pole_driver_name,
    ps.pole_constructor_names AS pole_constructor_name,
    MAX(CASE WHEN fre.is_winner = 1 AND fre.qualified_on_pole = 1 THEN 1 ELSE 0 END) AS pole_converted_to_win,
    pd.podium_names,
    pit.total_pit_stops,
    ROUND(pit.avg_pit_stop_ms, 2) AS avg_pit_stop_ms,
    MAX(fre.positions_gained) AS max_positions_gained
FROM F1_silver.dim_races dr
JOIN F1_silver.dim_seasons ds
    ON dr.season_year = ds.season_year
JOIN F1_silver.dim_circuits dc
    ON dr.circuitId = dc.circuitId
LEFT JOIN F1_silver.fact_race_entries fre
    ON dr.raceId = fre.raceId
LEFT JOIN (
    SELECT
        frew.raceId,
        GROUP_CONCAT(DISTINCT dd.driver_name ORDER BY dd.driver_name SEPARATOR ' | ') AS winner_driver_names,
        GROUP_CONCAT(DISTINCT dco.constructor_name ORDER BY dco.constructor_name SEPARATOR ' | ') AS winner_constructor_names,
        GROUP_CONCAT(DISTINCT CAST(frew.starting_grid AS CHAR) ORDER BY frew.starting_grid SEPARATOR ' | ') AS winner_starting_grids
    FROM F1_silver.fact_race_entries frew
    JOIN F1_silver.dim_drivers dd
        ON frew.driverId = dd.driverId
    JOIN F1_silver.dim_constructors dco
        ON frew.constructorId = dco.constructorId
    WHERE frew.is_winner = 1
    GROUP BY frew.raceId
) wr
    ON dr.raceId = wr.raceId
LEFT JOIN (
    SELECT
        fq.raceId,
        GROUP_CONCAT(DISTINCT dd.driver_name ORDER BY dd.driver_name SEPARATOR ' | ') AS pole_driver_names,
        GROUP_CONCAT(DISTINCT dco.constructor_name ORDER BY dco.constructor_name SEPARATOR ' | ') AS pole_constructor_names
    FROM F1_silver.fact_qualifying fq
    JOIN F1_silver.dim_drivers dd
        ON fq.driverId = dd.driverId
    JOIN F1_silver.dim_constructors dco
        ON fq.constructorId = dco.constructorId
    WHERE fq.qualifying_position = 1
    GROUP BY fq.raceId
 ) ps
    ON dr.raceId = ps.raceId
LEFT JOIN (
    SELECT
        t.raceId,
        GROUP_CONCAT(t.driver_name ORDER BY t.finish_position SEPARATOR ' | ') AS podium_names
    FROM (
        SELECT
            frep.raceId,
            frep.finish_position,
            dd.driver_name
        FROM F1_silver.fact_race_entries frep
        JOIN F1_silver.dim_drivers dd
            ON frep.driverId = dd.driverId
        WHERE frep.finish_position <= 3
    ) t
    GROUP BY t.raceId
) pd
    ON dr.raceId = pd.raceId
LEFT JOIN (
    SELECT
        raceId,
        COUNT(*) AS total_pit_stops,
        AVG(pit_duration_ms) AS avg_pit_stop_ms
    FROM F1_silver.fact_pit_stops
    GROUP BY raceId
) pit
    ON dr.raceId = pit.raceId
GROUP BY
    dr.raceId,
    dr.season_year,
    dr.season_round,
    ds.total_races,
    dr.race_name,
    dr.race_date,
    dr.has_sprint_weekend,
    dc.circuit_name,
    dc.country,
    wr.winner_driver_names,
    wr.winner_constructor_names,
    wr.winner_starting_grids,
    ps.pole_driver_names,
    ps.pole_constructor_names,
    pd.podium_names,
    pit.total_pit_stops,
    pit.avg_pit_stop_ms;

ALTER TABLE mart_race_weekend
    ADD PRIMARY KEY (raceId),
    ADD KEY idx_mart_race_weekend_season (season_year, season_round),
    ADD KEY idx_mart_race_weekend_circuit (circuit_name);


CREATE TABLE mart_kpi_snapshot AS
SELECT
    'total_seasons' AS kpi_code,
    CAST(COUNT(*) AS DECIMAL(18,2)) AS kpi_value_numeric,
    CAST(COUNT(*) AS CHAR) AS kpi_value_text
FROM F1_silver.dim_seasons

UNION ALL

SELECT
    'total_races',
    CAST(COUNT(*) AS DECIMAL(18,2)),
    CAST(COUNT(*) AS CHAR)
FROM F1_silver.dim_races

UNION ALL

SELECT
    'total_drivers',
    CAST(COUNT(*) AS DECIMAL(18,2)),
    CAST(COUNT(*) AS CHAR)
FROM F1_silver.dim_drivers

UNION ALL

SELECT
    'total_constructors',
    CAST(COUNT(*) AS DECIMAL(18,2)),
    CAST(COUNT(*) AS CHAR)
FROM F1_silver.dim_constructors

UNION ALL

SELECT
    'classified_finish_rate_pct',
    ROUND(SUM(is_classified_finish) * 100.0 / COUNT(*), 2),
    CONCAT(ROUND(SUM(is_classified_finish) * 100.0 / COUNT(*), 2), '%')
FROM F1_silver.fact_race_entries

UNION ALL

SELECT
    'dnf_rate_pct',
    ROUND((COUNT(*) - SUM(is_classified_finish)) * 100.0 / COUNT(*), 2),
    CONCAT(ROUND((COUNT(*) - SUM(is_classified_finish)) * 100.0 / COUNT(*), 2), '%')
FROM F1_silver.fact_race_entries

UNION ALL

SELECT
    'avg_points_per_entry',
    ROUND(AVG(total_event_points), 2),
    CAST(ROUND(AVG(total_event_points), 2) AS CHAR)
FROM F1_silver.fact_race_entries

UNION ALL

SELECT
    'pole_to_win_rate_pct',
    ROUND(
        SUM(CASE WHEN is_winner = 1 AND started_from_pole = 1 THEN 1 ELSE 0 END) * 100.0
        / NULLIF(SUM(is_winner), 0),
        2
    ),
    CONCAT(
        ROUND(
            SUM(CASE WHEN is_winner = 1 AND started_from_pole = 1 THEN 1 ELSE 0 END) * 100.0
            / NULLIF(SUM(is_winner), 0),
            2
        ),
        '%'
    )
FROM F1_silver.fact_race_entries

UNION ALL

SELECT
    'sprint_weekend_share_pct',
    ROUND(SUM(has_sprint_weekend) * 100.0 / COUNT(*), 2),
    CONCAT(ROUND(SUM(has_sprint_weekend) * 100.0 / COUNT(*), 2), '%')
FROM F1_silver.dim_races

UNION ALL

SELECT
    'shared_drive_entry_rate_pct',
    ROUND(SUM(shared_drive_candidate) * 100.0 / COUNT(*), 2),
    CONCAT(ROUND(SUM(shared_drive_candidate) * 100.0 / COUNT(*), 2), '%')
FROM F1_silver.fact_race_entries;

ALTER TABLE mart_kpi_snapshot
    ADD PRIMARY KEY (kpi_code);

-- =========================================================
-- Executive views for presentation
-- =========================================================

CREATE OR REPLACE VIEW vw_dashboard_kpi_cards AS
SELECT
    kc.kpi_code,
    kc.kpi_name,
    kc.business_question,
    kc.unit_of_measure,
    ks.kpi_value_numeric,
    ks.kpi_value_text
FROM kpi_catalog kc
JOIN mart_kpi_snapshot ks
    ON kc.kpi_code COLLATE utf8mb4_general_ci = ks.kpi_code
ORDER BY FIELD(
    kc.kpi_code,
    'total_seasons',
    'total_races',
    'total_drivers',
    'total_constructors',
    'classified_finish_rate_pct',
    'dnf_rate_pct',
    'avg_points_per_entry',
    'pole_to_win_rate_pct',
    'sprint_weekend_share_pct',
    'shared_drive_entry_rate_pct'
);


CREATE OR REPLACE VIEW vw_dashboard_top_drivers AS
SELECT
    driverId,
    driver_name,
    COUNT(*) AS seasons_competed,
    SUM(CASE WHEN championship_position = 1 THEN 1 ELSE 0 END) AS titles,
    SUM(wins) AS wins,
    SUM(podiums) AS podiums,
    SUM(poles) AS poles,
    ROUND(SUM(total_points), 1) AS total_points,
    ROUND(AVG(total_points), 2) AS avg_points_per_season,
    MIN(season_year) AS first_season,
    MAX(season_year) AS last_season
FROM mart_driver_season
GROUP BY driverId, driver_name
ORDER BY titles DESC, total_points DESC, wins DESC;


CREATE OR REPLACE VIEW vw_dashboard_top_constructors AS
SELECT
    constructorId,
    constructor_name,
    COUNT(*) AS seasons_competed,
    SUM(CASE WHEN championship_position = 1 THEN 1 ELSE 0 END) AS titles,
    SUM(wins) AS wins,
    SUM(podiums) AS podiums,
    SUM(poles) AS poles,
    ROUND(SUM(total_points), 1) AS total_points,
    ROUND(AVG(total_points), 2) AS avg_points_per_season,
    MIN(season_year) AS first_season,
    MAX(season_year) AS last_season
FROM mart_constructor_season
GROUP BY constructorId, constructor_name
ORDER BY titles DESC, total_points DESC, wins DESC;


CREATE OR REPLACE VIEW vw_dashboard_circuit_risk AS
SELECT
    circuitId,
    circuit_name,
    country,
    race_weekends_hosted,
    total_entries,
    non_classified_entries,
    non_classified_rate_pct,
    mechanical_non_classified_entries,
    accident_non_classified_entries,
    disqualified_entries,
    pole_to_win_rate_pct
FROM mart_circuit_risk
WHERE total_entries >= 100
ORDER BY non_classified_rate_pct DESC, non_classified_entries DESC;


CREATE OR REPLACE VIEW vw_dashboard_qualifying_effect_recent AS
SELECT
    mqes.*
FROM mart_qualifying_effect_season mqes
ORDER BY mqes.season_year DESC;


CREATE OR REPLACE VIEW vw_dashboard_latest_driver_championship AS
SELECT
    mds.season_year,
    mds.championship_position,
    mds.driver_name,
    mds.primary_constructor_name,
    mds.total_points,
    mds.wins,
    mds.podiums,
    mds.poles,
    mds.avg_starting_grid,
    mds.avg_finish_position
FROM mart_driver_season mds
WHERE mds.season_year = (SELECT MAX(season_year) FROM mart_driver_season)
ORDER BY mds.championship_position ASC, mds.total_points DESC;


CREATE OR REPLACE VIEW vw_dashboard_latest_constructor_championship AS
SELECT
    mcs.season_year,
    mcs.championship_position,
    mcs.constructor_name,
    mcs.total_points,
    mcs.wins,
    mcs.podiums,
    mcs.poles,
    mcs.drivers_used,
    mcs.avg_starting_grid,
    mcs.avg_finish_position
FROM mart_constructor_season mcs
WHERE mcs.season_year = (SELECT MAX(season_year) FROM mart_constructor_season)
ORDER BY mcs.championship_position ASC, mcs.total_points DESC;


CREATE OR REPLACE VIEW vw_dashboard_recent_race_highlights AS
SELECT
    mrw.season_year,
    mrw.season_round,
    mrw.race_name,
    mrw.circuit_name,
    mrw.country,
    mrw.race_date,
    mrw.winner_driver_name,
    mrw.winner_constructor_name,
    mrw.pole_driver_name,
    mrw.pole_converted_to_win,
    mrw.podium_names,
    mrw.non_classified_rate_pct,
    mrw.total_event_points_awarded,
    mrw.total_pit_stops,
    mrw.avg_pit_stop_ms
FROM mart_race_weekend mrw
ORDER BY mrw.season_year DESC, mrw.season_round DESC;

-- =========================================================
-- Quick validation queries
-- =========================================================

SELECT COUNT(*) AS mart_driver_season_rows FROM mart_driver_season;
SELECT COUNT(*) AS mart_constructor_season_rows FROM mart_constructor_season;
SELECT COUNT(*) AS mart_circuit_risk_rows FROM mart_circuit_risk;
SELECT COUNT(*) AS mart_qualifying_effect_season_rows FROM mart_qualifying_effect_season;
SELECT COUNT(*) AS mart_race_weekend_rows FROM mart_race_weekend;
SELECT COUNT(*) AS mart_kpi_snapshot_rows FROM mart_kpi_snapshot;

SELECT * FROM vw_dashboard_kpi_cards;
