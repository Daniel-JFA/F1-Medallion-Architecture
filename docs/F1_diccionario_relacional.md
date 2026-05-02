# Diccionario Relacional de la Base de Datos F1

## Resumen Ejecutivo

La base `F1` esta modelada alrededor de la tabla `races`, que funciona como entidad pivote del ecosistema. A partir de ella se conectan:

- Dimensiones maestras (`seasons`, `circuits`).
- Actores principales (`drivers`, `constructors`).
- Catalogo de estados (`status`).
- Hechos de competencia (`results`, `sprint_results`, `qualifying`, `constructor_results`).
- Hechos acumulados (`driver_standings`, `constructor_standings`).
- Micro-datos operativos (`lap_times`, `pit_stops`).

El modelo esta enfocado en analitica historica, trazabilidad por carrera y consistencia referencial.

## Volumen de Datos

| Tabla | Registros | Densidad |
| --- | ---: | --- |
| `lap_times` | 589081 | Muy alta (telemetria) |
| `driver_standings` | 34863 | Media-alta (acumulado) |
| `results` | 26759 | Media (transaccional) |
| `constructor_standings` | 13391 | Media (acumulado) |
| `constructor_results` | 12625 | Media (agregacion) |
| `pit_stops` | 11371 | Media (operacional) |
| `qualifying` | 10494 | Media (transaccional) |
| `races` | 1125 | Baja (hub) |
| `drivers` | 861 | Baja (maestro) |
| `sprint_results` | 360 | Muy baja (transaccional) |
| `constructors` | 212 | Muy baja (maestro) |
| `status` | 139 | Muy baja (catalogo) |
| `circuits` | 77 | Minima (dimension) |
| `seasons` | 75 | Minima (dimension) |

## Arquitectura del Modelo

### 1. Nucleo del ecosistema: `races`

`races` es la entidad pivote del modelo porque concentra el contexto temporal, geoespacial y competitivo de cada Gran Premio.

- Clave primaria: `raceId`.
- Claves de contexto:
  - `year` -> dimension temporal (`seasons`).
  - `circuitId` -> dimension geografica (`circuits`).
  - `round` -> orden cronologico dentro de la temporada.
- Metadatos relevantes: `name`, `date`, `time`, `url` y campos de sesiones (`fp1_*`, `fp2_*`, `fp3_*`, `quali_*`, `sprint_*`).

### 2. Dimensiones maestras

#### 2.1 `seasons` (temporalidad)

- Proposito: agrupar carreras por temporada.
- Clave primaria: `year` (clave natural).
- Relacion: `seasons (1) -> (N) races`.

#### 2.2 `circuits` (localizacion)

- Proposito: describir el trazado donde ocurre la carrera.
- Clave primaria: `circuitId`.
- Relacion: `circuits (1) -> (N) races`.
- Datos tecnicos utiles para analitica: `lat`, `lng`, `alt`, `country`, `location`.

### 3. Actores y catalogos

#### 3.1 `drivers`

- Proposito: catalogo de pilotos.
- Clave primaria: `driverId`.
- Participa en hechos transaccionales (`results`, `sprint_results`, `qualifying`) y operacionales (`lap_times`, `pit_stops`), ademas de acumulados (`driver_standings`).

#### 3.2 `constructors`

- Proposito: catalogo de escuderias.
- Clave primaria: `constructorId`.
- Participa en `constructor_results`, `constructor_standings`, `results`, `sprint_results`, `qualifying`.

#### 3.3 `status`

- Proposito: normalizar estado de finalizacion.
- Clave primaria: `statusId`.
- Relacionado con `results` y `sprint_results`.

### 4. Ramas de hechos

#### 4.1 Competencia (hechos transaccionales)

- `results`:
  - Clave primaria: `resultId`.
  - Grano: resultado de un piloto en una carrera.
  - Incluye puntos, posicion final, vueltas, tiempo y estado.

- `sprint_results`:
  - Clave primaria: `resultId`.
  - Estructura analoga a `results` pero para carreras sprint.

- `qualifying`:
  - Clave primaria: `qualifyId`.
  - Registra posiciones y tiempos `q1`, `q2`, `q3`.

- `constructor_results`:
  - Clave primaria: `constructorResultsId`.
  - Grano: resultado agregado del equipo por GP.

#### 4.2 Acumulados (seguimiento de campeonato)

- `driver_standings`:
  - Clave primaria: `driverStandingsId`.
  - Estado acumulado de pilotos despues de cada carrera.

- `constructor_standings`:
  - Clave primaria: `constructorStandingsId`.
  - Estado acumulado de escuderias despues de cada carrera.

#### 4.3 Operacional (micro-datos en pista)

- `lap_times`:
  - Clave primaria compuesta: (`raceId`, `driverId`, `lap`).
  - Grano fino por vuelta y piloto.

- `pit_stops`:
  - Clave primaria compuesta: (`raceId`, `driverId`, `stop`).
  - Registra cada intervencion de pits por piloto/carrera.

## Vista General de Relaciones

- `seasons (1) -> (N) races`
- `circuits (1) -> (N) races`
- `races (1) -> (N) constructor_results`
- `constructors (1) -> (N) constructor_results`
- `races (1) -> (N) constructor_standings`
- `constructors (1) -> (N) constructor_standings`
- `races (1) -> (N) driver_standings`
- `drivers (1) -> (N) driver_standings`
- `races (1) -> (N) results`
- `drivers (1) -> (N) results`
- `constructors (1) -> (N) results`
- `status (1) -> (N) results`
- `races (1) -> (N) sprint_results`
- `drivers (1) -> (N) sprint_results`
- `constructors (1) -> (N) sprint_results`
- `status (1) -> (N) sprint_results`
- `races (1) -> (N) qualifying`
- `drivers (1) -> (N) qualifying`
- `constructors (1) -> (N) qualifying`
- `races (1) -> (N) lap_times`
- `drivers (1) -> (N) lap_times`
- `races (1) -> (N) pit_stops`
- `drivers (1) -> (N) pit_stops`

## Diccionario Tabla por Tabla

### 1. `seasons`

- Proposito: almacenar cada temporada del campeonato.
- Clave primaria: `year`.
- Relacion: `seasons (1) -> (N) races` por `races.year`.

### 2. `circuits`

- Proposito: almacenar datos de los circuitos.
- Clave primaria: `circuitId`.
- Relacion: `circuits (1) -> (N) races` por `races.circuitId`.

### 3. `constructors`

- Proposito: catalogar escuderias/equipos.
- Clave primaria: `constructorId`.
- Relacionado con resultados, clasificaciones y standings.

### 4. `drivers`

- Proposito: catalogar pilotos.
- Clave primaria: `driverId`.
- Relacionado con resultados, qualy, standings, vueltas y pits.

### 5. `status`

- Proposito: catalogar estado de finalizacion.
- Clave primaria: `statusId`.
- Relacionado con `results` y `sprint_results`.

### 6. `races`

- Proposito: representar cada Gran Premio.
- Clave primaria: `raceId`.
- Entidad padre para la mayoria de tablas de hechos.

### 7. `constructor_results`

- Proposito: puntos/resultados de constructor por carrera.
- Clave primaria: `constructorResultsId`.
- Foreign keys: `raceId`, `constructorId`.

### 8. `constructor_standings`

- Proposito: clasificacion acumulada de constructores.
- Clave primaria: `constructorStandingsId`.
- Foreign keys: `raceId`, `constructorId`.

### 9. `driver_standings`

- Proposito: clasificacion acumulada de pilotos.
- Clave primaria: `driverStandingsId`.
- Foreign keys: `raceId`, `driverId`.

### 10. `results`

- Proposito: resultado principal por piloto/carrera.
- Clave primaria: `resultId`.
- Foreign keys: `raceId`, `driverId`, `constructorId`, `statusId`.

### 11. `sprint_results`

- Proposito: resultado de evento sprint.
- Clave primaria: `resultId`.
- Foreign keys: `raceId`, `driverId`, `constructorId`, `statusId`.

### 12. `qualifying`

- Proposito: resultado de clasificacion.
- Clave primaria: `qualifyId`.
- Foreign keys: `raceId`, `driverId`, `constructorId`.

### 13. `lap_times`

- Proposito: tiempos por vuelta.
- Clave primaria compuesta: (`raceId`, `driverId`, `lap`).
- Foreign keys: `raceId`, `driverId`.

### 14. `pit_stops`

- Proposito: eventos de parada en pits.
- Clave primaria compuesta: (`raceId`, `driverId`, `stop`).
- Foreign keys: `raceId`, `driverId`.

## Reglas de Integridad y Decisiones de Modelado

- `ON DELETE RESTRICT`: protege historia deportiva evitando borrar entidades padre con datos asociados.
- `ON UPDATE CASCADE`: propaga cambios excepcionales en claves primarias hacia tablas hijas.
- `constructor_results.status` se mantiene como texto libre y no como `statusId`.
- `lap_times` y `pit_stops` no dependen por FK de `results` para evitar conflictos de grano y casos excepcionales (por ejemplo, DNS o abandono temprano).

## Ejemplos de Negocio

- `raceId 1` (Australian Grand Prix 2009):
  - Temporada: `year = 2009`.
  - Circuito: `circuitId 1` (Albert Park).
  - Pilotos destacados en resultados: Lewis Hamilton, Nick Heidfeld, Nico Rosberg.
  - Constructores con puntos en `constructor_results`: McLaren, BMW Sauber, Williams.

- En carreras con formato sprint:
  - `sprint_results` mantiene el hecho separado de `results` para no mezclar estadisticas del GP principal con la sprint.

## Conclusiones

- El modelo esta bien normalizado para analitica historica de Formula 1.
- `races` organiza el evento deportivo y conecta dimensiones, hechos y micro-hechos.
- La separacion entre tablas transaccionales, acumuladas y operativas permite analisis desde resumen ejecutivo hasta detalle por vuelta.
