USE F1;

-- =========================================================
-- TALLER SQL - BASE DE DATOS F1
-- Version corregida y validada sobre la base local F1
-- =========================================================

-- Q1. Pilotos con mayor frecuencia en el top 5 de salida
-- Tipo: JOIN + agregacion + HAVING
SELECT
    CONCAT(d.forename, ' ', d.surname) AS piloto,
    COUNT(*) AS total_carreras,
    SUM(CASE WHEN r.grid <= 5 THEN 1 ELSE 0 END) AS veces_top5,
    ROUND(AVG(r.grid), 2) AS promedio_salida
FROM results r
JOIN drivers d ON r.driverId = d.driverId
WHERE r.grid > 0
GROUP BY d.driverId, CONCAT(d.forename, ' ', d.surname)
HAVING COUNT(*) >= 20
ORDER BY veces_top5 DESC, promedio_salida ASC;

-- Q2. Piloto(s) con mas victorias por temporada
-- Tipo: JOIN + agregacion + funcion de ventana
SELECT year, piloto, wins
FROM (
    SELECT
        ra.year,
        CONCAT(d.forename, ' ', d.surname) AS piloto,
        COUNT(*) AS wins,
        RANK() OVER (PARTITION BY ra.year ORDER BY COUNT(*) DESC) AS rk
    FROM results r
    JOIN drivers d ON r.driverId = d.driverId
    JOIN races ra ON r.raceId = ra.raceId
    WHERE r.positionOrder = 1
    GROUP BY ra.year, d.driverId, CONCAT(d.forename, ' ', d.surname)
) t
WHERE rk = 1
ORDER BY year DESC;

-- Q3. Tiempo promedio de pit stops por escuderia
-- Tipo: JOIN + agregacion + HAVING
SELECT
    con.name AS escuderia,
    COUNT(*) AS total_pitstops,
    ROUND(AVG(ps.milliseconds), 2) AS promedio_ms
FROM pit_stops ps
JOIN results r
    ON ps.raceId = r.raceId
   AND ps.driverId = r.driverId
JOIN constructors con
    ON r.constructorId = con.constructorId
WHERE ps.milliseconds IS NOT NULL
GROUP BY con.constructorId, con.name
HAVING COUNT(*) >= 20
ORDER BY promedio_ms ASC;

-- Q4. Escuderia con mas puntos en cada circuito
-- Tipo: JOIN + agregacion + funcion de ventana
SELECT circuito, escuderia, total_points
FROM (
    SELECT
        c.name AS circuito,
        con.name AS escuderia,
        ROUND(SUM(r.points), 2) AS total_points,
        RANK() OVER (PARTITION BY c.circuitId ORDER BY SUM(r.points) DESC) AS rk
    FROM results r
    JOIN races ra ON r.raceId = ra.raceId
    JOIN circuits c ON ra.circuitId = c.circuitId
    JOIN constructors con ON r.constructorId = con.constructorId
    GROUP BY c.circuitId, c.name, con.constructorId, con.name
) t
WHERE rk = 1
ORDER BY total_points DESC;

-- Q5. Pilotos con mejor posicion promedio de salida
-- Tipo: JOIN + agregacion + HAVING
SELECT
    CONCAT(d.forename, ' ', d.surname) AS piloto,
    COUNT(*) AS total_carreras,
    ROUND(AVG(r.grid), 2) AS promedio_salida,
    MIN(r.grid) AS mejor_salida,
    MAX(r.grid) AS peor_salida
FROM results r
JOIN drivers d ON r.driverId = d.driverId
WHERE r.grid > 0
GROUP BY d.driverId, CONCAT(d.forename, ' ', d.surname)
HAVING COUNT(*) >= 30
ORDER BY promedio_salida ASC, total_carreras DESC;

-- Q6. Circuitos mas caoticos por porcentaje de abandonos
-- Tipo: JOIN + agregacion + filtros avanzados
SELECT
    c.name AS circuito,
    c.country AS pais,
    COUNT(*) AS total_resultados,
    SUM(CASE
        WHEN s.status NOT LIKE 'Finished%' AND s.status NOT LIKE '+%' THEN 1
        ELSE 0
    END) AS abandonos,
    ROUND(
        SUM(CASE
            WHEN s.status NOT LIKE 'Finished%' AND s.status NOT LIKE '+%' THEN 1
            ELSE 0
        END) * 100.0 / COUNT(*),
        2
    ) AS porcentaje_abandonos
FROM results r
JOIN races ra ON r.raceId = ra.raceId
JOIN circuits c ON ra.circuitId = c.circuitId
JOIN status s ON r.statusId = s.statusId
GROUP BY c.circuitId, c.name, c.country
HAVING COUNT(*) >= 100
ORDER BY porcentaje_abandonos DESC, abandonos DESC;

-- Q7. Promedio de puntos por piloto
-- Tipo: JOIN + agregacion + HAVING
SELECT
    CONCAT(d.forename, ' ', d.surname) AS piloto,
    COUNT(*) AS total_carreras,
    ROUND(AVG(r.points), 2) AS promedio_puntos
FROM results r
JOIN drivers d ON r.driverId = d.driverId
GROUP BY d.driverId, CONCAT(d.forename, ' ', d.surname)
HAVING COUNT(*) >= 30
ORDER BY promedio_puntos DESC;

-- Q8. Numero total de carreras por temporada
-- Tipo: agregacion
SELECT
    year AS temporada,
    COUNT(*) AS total_carreras
FROM races
GROUP BY year
ORDER BY year DESC;

-- Q9. Pilotos con mas puntos acumulados entre 2005 y 2024
-- Tipo: JOIN + agregacion
SELECT
    CONCAT(d.forename, ' ', d.surname) AS piloto,
    ROUND(SUM(r.points), 1) AS puntos_totales
FROM results r
JOIN drivers d ON r.driverId = d.driverId
JOIN races ra ON r.raceId = ra.raceId
WHERE ra.year >= 2005
GROUP BY d.driverId, CONCAT(d.forename, ' ', d.surname)
ORDER BY puntos_totales DESC;

-- Q10. Pilotos con mas de 10 podios
-- Tipo: JOIN + agregacion + HAVING
SELECT
    CONCAT(d.forename, ' ', d.surname) AS piloto,
    COUNT(*) AS podios
FROM results r
JOIN drivers d ON r.driverId = d.driverId
WHERE r.positionOrder BETWEEN 1 AND 3
GROUP BY d.driverId, CONCAT(d.forename, ' ', d.surname)
HAVING COUNT(*) > 10
ORDER BY podios DESC;

-- Q11. Victorias desde posiciones de salida 10 o peores
-- Tipo: JOIN + filtro avanzado
SELECT
    ra.year AS temporada,
    ra.name AS carrera,
    c.name AS circuito,
    CONCAT(d.forename, ' ', d.surname) AS ganador,
    r.grid AS posicion_salida
FROM results r
JOIN drivers d ON r.driverId = d.driverId
JOIN races ra ON r.raceId = ra.raceId
JOIN circuits c ON ra.circuitId = c.circuitId
WHERE r.positionOrder = 1
  AND r.grid >= 10
ORDER BY r.grid DESC, ra.year DESC;

-- Q12. Pilotos de dinastias o tradicion por apellido
-- Tipo: JOIN + LIKE
SELECT
    CONCAT(d.forename, ' ', d.surname) AS piloto,
    ROUND(SUM(r.points), 1) AS puntos_totales
FROM results r
JOIN drivers d ON r.driverId = d.driverId
WHERE d.surname LIKE '%Schumacher%'
   OR d.surname LIKE '%Verstappen%'
   OR d.surname LIKE '%Hill%'
   OR d.surname LIKE '%Rosberg%'
GROUP BY d.driverId, CONCAT(d.forename, ' ', d.surname)
ORDER BY puntos_totales DESC;

-- Q13. Nacionalidades tradicionales con mas puntos acumulados
-- Tipo: JOIN + filtro avanzado con REGEXP
SELECT
    d.nationality AS nacionalidad,
    ROUND(SUM(r.points), 2) AS puntos_totales
FROM results r
JOIN drivers d ON r.driverId = d.driverId
WHERE d.nationality REGEXP '^(British|German|Italian)$'
GROUP BY d.nationality
ORDER BY puntos_totales DESC;

-- Q14. Piloto con la vuelta mas rapida de cada carrera
-- Tipo: JOIN + funcion de ventana
SELECT temporada, carrera, piloto, fastest_lap_ms
FROM (
    SELECT
        ra.year AS temporada,
        ra.name AS carrera,
        CONCAT(d.forename, ' ', d.surname) AS piloto,
        lt.milliseconds AS fastest_lap_ms,
        ROW_NUMBER() OVER (PARTITION BY lt.raceId ORDER BY lt.milliseconds ASC) AS rn
    FROM lap_times lt
    JOIN drivers d ON lt.driverId = d.driverId
    JOIN races ra ON lt.raceId = ra.raceId
) t
WHERE rn = 1
ORDER BY temporada DESC, carrera;

-- Q15. Ranking de pilotos por puntos en las ultimas 5 temporadas disponibles
-- Tipo: CTE (WITH) + agregacion + funcion de ventana
WITH ultimas_temporadas AS (
    SELECT year
    FROM races
    GROUP BY year
    ORDER BY year DESC
    LIMIT 5
),
tabla_puntos AS (
    SELECT
        ra.year AS temporada,
        CONCAT(d.forename, ' ', d.surname) AS piloto,
        SUM(r.points) AS puntos
    FROM results r
    JOIN drivers d ON r.driverId = d.driverId
    JOIN races ra ON r.raceId = ra.raceId
    WHERE ra.year IN (SELECT year FROM ultimas_temporadas)
    GROUP BY ra.year, d.driverId, CONCAT(d.forename, ' ', d.surname)
)
SELECT
    temporada,
    piloto,
    puntos,
    RANK() OVER (PARTITION BY temporada ORDER BY puntos DESC) AS ranking
FROM tabla_puntos
ORDER BY temporada DESC, ranking ASC;

-- =========================================================
-- VISTAS PERMANENTES
-- =========================================================

-- V1. Vista de resultados enriquecidos por carrera
CREATE OR REPLACE VIEW vw_resultados_carrera AS
SELECT
    ra.year AS temporada,
    ra.name AS carrera,
    CONCAT(d.forename, ' ', d.surname) AS piloto,
    con.name AS escuderia,
    r.grid AS posicion_salida,
    r.positionOrder AS posicion_final,
    r.points
FROM results r
JOIN races ra ON r.raceId = ra.raceId
JOIN drivers d ON r.driverId = d.driverId
JOIN constructors con ON r.constructorId = con.constructorId;

SELECT *
FROM vw_resultados_carrera
ORDER BY temporada DESC, carrera, posicion_final
LIMIT 10;

-- V2. Vista de informacion general de carreras
CREATE OR REPLACE VIEW vw_info_carreras AS
SELECT
    ra.raceId,
    ra.year AS temporada,
    ra.round AS ronda,
    ra.name AS carrera,
    c.name AS circuito,
    c.country AS pais,
    ra.date AS fecha
FROM races ra
JOIN circuits c ON ra.circuitId = c.circuitId;

SELECT *
FROM vw_info_carreras
ORDER BY temporada DESC, ronda ASC
LIMIT 10;
