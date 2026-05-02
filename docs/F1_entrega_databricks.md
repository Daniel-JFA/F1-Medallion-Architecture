# Taller SQL F1 para Databricks

Este archivo contiene las `15` consultas y las `2` vistas permanentes listas para usar en Databricks SQL.

## Antes de ejecutar

- Este material asume que ya cargaste la base con:
  - `F1_databricks_schema.sql`
  - `F1_databricks_load.sql`
- Si usas Unity Catalog, define primero tu catalogo actual.
- Si tus tablas no viven en `f1`, reemplaza el prefijo `f1.` por el que corresponda.
- En notebook de Databricks, pega cada bloque en una celda `%sql`.

## Contexto inicial opcional

```sql
-- Opcional si usas Unity Catalog
-- USE CATALOG main;

USE f1;
```

## Q1. Pilotos con mayor frecuencia en el top 5 de salida

```sql
SELECT
    CONCAT(d.forename, ' ', d.surname) AS piloto,
    COUNT(*) AS total_carreras,
    SUM(CASE WHEN r.grid <= 5 THEN 1 ELSE 0 END) AS veces_top5,
    ROUND(AVG(r.grid), 2) AS promedio_salida
FROM f1.results r
JOIN f1.drivers d
    ON r.driverId = d.driverId
WHERE r.grid > 0
GROUP BY d.driverId, CONCAT(d.forename, ' ', d.surname)
HAVING COUNT(*) >= 20
ORDER BY veces_top5 DESC, promedio_salida ASC;
```

## Q2. Piloto o pilotos con mas victorias por temporada

```sql
WITH victorias AS (
    SELECT
        ra.year AS temporada,
        CONCAT(d.forename, ' ', d.surname) AS piloto,
        COUNT(*) AS wins
    FROM f1.results r
    JOIN f1.drivers d
        ON r.driverId = d.driverId
    JOIN f1.races ra
        ON r.raceId = ra.raceId
    WHERE r.positionOrder = 1
    GROUP BY ra.year, d.driverId, CONCAT(d.forename, ' ', d.surname)
),
ranking AS (
    SELECT
        temporada,
        piloto,
        wins,
        RANK() OVER (PARTITION BY temporada ORDER BY wins DESC) AS rk
    FROM victorias
)
SELECT
    temporada,
    piloto,
    wins
FROM ranking
WHERE rk = 1
ORDER BY temporada DESC;
```

## Q3. Tiempo promedio de pit stops por escuderia

```sql
SELECT
    con.name AS escuderia,
    COUNT(*) AS total_pitstops,
    ROUND(AVG(ps.milliseconds), 2) AS promedio_ms
FROM f1.pit_stops ps
JOIN f1.results r
    ON ps.raceId = r.raceId
   AND ps.driverId = r.driverId
JOIN f1.constructors con
    ON r.constructorId = con.constructorId
WHERE ps.milliseconds IS NOT NULL
GROUP BY con.constructorId, con.name
HAVING COUNT(*) >= 20
ORDER BY promedio_ms ASC;
```

## Q4. Escuderia con mas puntos en cada circuito

```sql
WITH puntos_circuito AS (
    SELECT
        c.circuitId,
        c.name AS circuito,
        con.constructorId,
        con.name AS escuderia,
        ROUND(SUM(r.points), 2) AS total_points
    FROM f1.results r
    JOIN f1.races ra
        ON r.raceId = ra.raceId
    JOIN f1.circuits c
        ON ra.circuitId = c.circuitId
    JOIN f1.constructors con
        ON r.constructorId = con.constructorId
    GROUP BY c.circuitId, c.name, con.constructorId, con.name
),
ranking AS (
    SELECT
        circuito,
        escuderia,
        total_points,
        RANK() OVER (PARTITION BY circuito ORDER BY total_points DESC) AS rk
    FROM puntos_circuito
)
SELECT
    circuito,
    escuderia,
    total_points
FROM ranking
WHERE rk = 1
ORDER BY total_points DESC;
```

## Q5. Pilotos con mejor posicion promedio de salida

```sql
SELECT
    CONCAT(d.forename, ' ', d.surname) AS piloto,
    COUNT(*) AS total_carreras,
    ROUND(AVG(r.grid), 2) AS promedio_salida,
    MIN(r.grid) AS mejor_salida,
    MAX(r.grid) AS peor_salida
FROM f1.results r
JOIN f1.drivers d
    ON r.driverId = d.driverId
WHERE r.grid > 0
GROUP BY d.driverId, CONCAT(d.forename, ' ', d.surname)
HAVING COUNT(*) >= 30
ORDER BY promedio_salida ASC, total_carreras DESC;
```

## Q6. Circuitos mas caoticos por porcentaje de abandonos

```sql
SELECT
    c.name AS circuito,
    c.country AS pais,
    COUNT(*) AS total_resultados,
    SUM(
        CASE
            WHEN s.status NOT LIKE 'Finished%' AND s.status NOT LIKE '+%' THEN 1
            ELSE 0
        END
    ) AS abandonos,
    ROUND(
        SUM(
            CASE
                WHEN s.status NOT LIKE 'Finished%' AND s.status NOT LIKE '+%' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS porcentaje_abandonos
FROM f1.results r
JOIN f1.races ra
    ON r.raceId = ra.raceId
JOIN f1.circuits c
    ON ra.circuitId = c.circuitId
JOIN f1.status s
    ON r.statusId = s.statusId
GROUP BY c.circuitId, c.name, c.country
HAVING COUNT(*) >= 100
ORDER BY porcentaje_abandonos DESC, abandonos DESC;
```

## Q7. Promedio de puntos por piloto

```sql
SELECT
    CONCAT(d.forename, ' ', d.surname) AS piloto,
    COUNT(*) AS total_carreras,
    ROUND(AVG(r.points), 2) AS promedio_puntos
FROM f1.results r
JOIN f1.drivers d
    ON r.driverId = d.driverId
GROUP BY d.driverId, CONCAT(d.forename, ' ', d.surname)
HAVING COUNT(*) >= 30
ORDER BY promedio_puntos DESC;
```

## Q8. Numero total de carreras por temporada

```sql
SELECT
    year AS temporada,
    COUNT(*) AS total_carreras
FROM f1.races
GROUP BY year
ORDER BY year DESC;
```

## Q9. Pilotos con mas puntos acumulados entre 2005 y 2024

```sql
SELECT
    CONCAT(d.forename, ' ', d.surname) AS piloto,
    ROUND(SUM(r.points), 1) AS puntos_totales
FROM f1.results r
JOIN f1.drivers d
    ON r.driverId = d.driverId
JOIN f1.races ra
    ON r.raceId = ra.raceId
WHERE ra.year >= 2005
GROUP BY d.driverId, CONCAT(d.forename, ' ', d.surname)
ORDER BY puntos_totales DESC;
```

## Q10. Pilotos con mas de 10 podios

```sql
SELECT
    CONCAT(d.forename, ' ', d.surname) AS piloto,
    COUNT(*) AS podios
FROM f1.results r
JOIN f1.drivers d
    ON r.driverId = d.driverId
WHERE r.positionOrder BETWEEN 1 AND 3
GROUP BY d.driverId, CONCAT(d.forename, ' ', d.surname)
HAVING COUNT(*) > 10
ORDER BY podios DESC;
```

## Q11. Victorias desde posiciones de salida 10 o peores

```sql
SELECT
    ra.year AS temporada,
    ra.name AS carrera,
    c.name AS circuito,
    CONCAT(d.forename, ' ', d.surname) AS ganador,
    r.grid AS posicion_salida
FROM f1.results r
JOIN f1.drivers d
    ON r.driverId = d.driverId
JOIN f1.races ra
    ON r.raceId = ra.raceId
JOIN f1.circuits c
    ON ra.circuitId = c.circuitId
WHERE r.positionOrder = 1
  AND r.grid >= 10
ORDER BY r.grid DESC, ra.year DESC;
```

## Q12. Pilotos de dinastias o tradicion por apellido

```sql
SELECT
    CONCAT(d.forename, ' ', d.surname) AS piloto,
    ROUND(SUM(r.points), 1) AS puntos_totales
FROM f1.results r
JOIN f1.drivers d
    ON r.driverId = d.driverId
WHERE d.surname LIKE '%Schumacher%'
   OR d.surname LIKE '%Verstappen%'
   OR d.surname LIKE '%Hill%'
   OR d.surname LIKE '%Rosberg%'
GROUP BY d.driverId, CONCAT(d.forename, ' ', d.surname)
ORDER BY puntos_totales DESC;
```

## Q13. Nacionalidades tradicionales con mas puntos acumulados

```sql
SELECT
    d.nationality AS nacionalidad,
    ROUND(SUM(r.points), 2) AS puntos_totales
FROM f1.results r
JOIN f1.drivers d
    ON r.driverId = d.driverId
WHERE d.nationality RLIKE '^(British|German|Italian)$'
GROUP BY d.nationality
ORDER BY puntos_totales DESC;
```

## Q14. Piloto con la vuelta mas rapida de cada carrera

```sql
WITH vueltas_rapidas AS (
    SELECT
        ra.year AS temporada,
        ra.name AS carrera,
        CONCAT(d.forename, ' ', d.surname) AS piloto,
        lt.milliseconds AS fastest_lap_ms,
        ROW_NUMBER() OVER (PARTITION BY lt.raceId ORDER BY lt.milliseconds ASC) AS rn
    FROM f1.lap_times lt
    JOIN f1.drivers d
        ON lt.driverId = d.driverId
    JOIN f1.races ra
        ON lt.raceId = ra.raceId
)
SELECT
    temporada,
    carrera,
    piloto,
    fastest_lap_ms
FROM vueltas_rapidas
WHERE rn = 1
ORDER BY temporada DESC, carrera;
```

## Q15. Ranking de pilotos por puntos en las ultimas 5 temporadas disponibles

```sql
WITH ultimas_temporadas AS (
    SELECT year
    FROM (
        SELECT DISTINCT year
        FROM f1.races
    ) t
    ORDER BY year DESC
    LIMIT 5
),
tabla_puntos AS (
    SELECT
        ra.year AS temporada,
        CONCAT(d.forename, ' ', d.surname) AS piloto,
        SUM(r.points) AS puntos
    FROM f1.results r
    JOIN f1.drivers d
        ON r.driverId = d.driverId
    JOIN f1.races ra
        ON r.raceId = ra.raceId
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
```

## V1. Vista permanente de resultados enriquecidos

```sql
CREATE OR REPLACE VIEW f1.vw_resultados_carrera AS
SELECT
    ra.year AS temporada,
    ra.name AS carrera,
    CONCAT(d.forename, ' ', d.surname) AS piloto,
    con.name AS escuderia,
    r.grid AS posicion_salida,
    r.positionOrder AS posicion_final,
    r.points
FROM f1.results r
JOIN f1.races ra
    ON r.raceId = ra.raceId
JOIN f1.drivers d
    ON r.driverId = d.driverId
JOIN f1.constructors con
    ON r.constructorId = con.constructorId;
```

### Consulta de prueba para la vista

```sql
SELECT *
FROM f1.vw_resultados_carrera
ORDER BY temporada DESC, carrera, posicion_final
LIMIT 10;
```

## V2. Vista permanente de informacion general de carreras

```sql
CREATE OR REPLACE VIEW f1.vw_info_carreras AS
SELECT
    ra.raceId,
    ra.year AS temporada,
    ra.round AS ronda,
    ra.name AS carrera,
    c.name AS circuito,
    c.country AS pais,
    ra.date AS fecha
FROM f1.races ra
JOIN f1.circuits c
    ON ra.circuitId = c.circuitId;
```

### Consulta de prueba para la vista

```sql
SELECT *
FROM f1.vw_info_carreras
ORDER BY temporada DESC, ronda ASC
LIMIT 10;
```

## Nota final

Si quieres conservar tambien la version explicada para entregar al profesor, ya tienes otra copia mas documentada en:

- `/home/djfa/Dev/DBs BackUps/F1_entrega_corregida.md`

Y este archivo nuevo queda como version practica para ejecutar en Databricks:

- `/home/djfa/Dev/DBs BackUps/F1_entrega_databricks.md`
