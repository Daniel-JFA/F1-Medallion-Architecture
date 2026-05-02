# Documentación de Cómo se Llegó y se Finalizó la Capa `Silver`

## 1. Propósito del documento

Este documento fue preparado para apoyar una presentación sobre la construcción de la capa `Silver` del proyecto de Formula 1.

Su objetivo es explicar:

- de dónde partía el proyecto,
- por qué fue necesaria una capa `Silver`,
- qué decisiones técnicas se tomaron,
- cómo quedó estructurada,
- qué validaciones se realizaron,
- y cuál fue el resultado final listo para usar en analítica y presentación.

## 2. Contexto del proyecto

El proyecto parte de un conjunto histórico de datos de Formula 1 en archivos CSV.  
Esos archivos representan la capa `Bronze`, es decir, los datos originales tal como fueron obtenidos.

Posteriormente, esos datos se cargaron a una base relacional llamada `F1`, donde se organizaron en tablas como:

- `drivers`
- `constructors`
- `circuits`
- `status`
- `races`
- `results`
- `qualifying`
- `lap_times`
- `pit_stops`
- `driver_standings`
- `constructor_standings`

La base `F1` ya permitía consultas, pero todavía no era una capa curada de analítica.

## 3. Problema que resolvía `Silver`

Aunque `F1` ya era relacional, todavía presentaba limitaciones para análisis y presentación:

- el modelo estaba orientado a estructura fuente, no a consumo analítico,
- había que repetir lógica en muchas consultas,
- no existían dimensiones y hechos claramente separados,
- no había banderas analíticas listas para usar,
- la calidad debía verificarse formalmente,
- y no existía una capa intermedia preparada para alimentar una capa `Gold`.

Por eso se construyó `F1_silver`.

## 4. Objetivo de la capa `Silver`

La capa `Silver` se diseñó con cinco objetivos principales:

1. limpiar y normalizar datos,
2. separar dimensiones y hechos,
3. enriquecer el modelo con variables analíticas,
4. validar consistencia e integridad,
5. dejar una base estable para construir `Gold`.

En otras palabras, `Silver` no se pensó como una copia de `F1`, sino como una versión curada y analíticamente útil.

## 5. Cómo se llegó a `Silver`

La construcción de `Silver` se desarrolló por etapas.

### 5.1 Revisión del modelo fuente

Antes de modelar `Silver`, se analizó la base `F1` para identificar:

- tablas maestras,
- relaciones clave,
- tabla pivote del modelo,
- dependencias entre carreras, pilotos, constructores y estados,
- y qué tablas funcionaban mejor como hechos o dimensiones.

La tabla pivote del modelo fue `races`, ya que conecta temporada, circuito y todos los hechos deportivos.

### 5.2 Formalización de la base relacional

La base `F1` fue fortalecida mediante la activación de relaciones reales entre tablas, usando llaves foráneas.  
Esto permitió asegurar que `Silver` se construyera sobre un origen consistente.

Resultado de esta etapa:

- `F1` quedó con `23` llaves foráneas activas.

### 5.3 Definición del enfoque dimensional

Se decidió dividir `Silver` en:

- dimensiones: entidades descriptivas relativamente estables,
- hechos: eventos, resultados, métricas y acumulados.

Esa separación facilita:

- análisis más claros,
- joins más simples,
- reutilización del modelo,
- y transición natural hacia `Gold`.

### 5.4 Normalización y curaduría

Se aplicaron reglas de limpieza y estandarización, entre ellas:

- `TRIM` para eliminar espacios sobrantes,
- `LOWER` y `UPPER` para normalizar referencias y códigos,
- normalización de nombres de pilotos y escuderías,
- categorización semántica de estados de carrera,
- conversión de tiempos a milisegundos,
- construcción de timestamps útiles para sesiones y carreras.

### 5.5 Enriquecimiento analítico

Se añadieron columnas calculadas que antes no existían como dato directo:

- `is_winner`
- `is_podium`
- `scored_points`
- `started_from_pole`
- `positions_gained`
- `qualifying_to_finish_delta`
- `shared_drive_candidate`

Esto fue clave para reducir complejidad en las consultas analíticas posteriores.

## 6. Estructura final de `Silver`

La implementación final de `Silver` se consolidó en la base:

- `F1_silver`

### 6.1 Dimensiones creadas

- `dim_drivers`
- `dim_constructors`
- `dim_circuits`
- `dim_status`
- `dim_seasons`
- `dim_races`

### 6.2 Hechos creados

- `fact_results`
- `fact_sprint_results`
- `fact_constructor_results`
- `fact_qualifying`
- `fact_lap_times`
- `fact_pit_stops`
- `fact_driver_standings`
- `fact_constructor_standings`
- `fact_race_entries`

### 6.3 Vistas operativas

- `vw_data_quality_checks`
- `vw_silver_summary`

## 7. Decisiones técnicas importantes

### 7.1 Se agregó `dim_seasons`

Aunque la base original tenía `seasons`, en `Silver` se convirtió en una dimensión analítica explícita con datos útiles como:

- total de carreras por temporada,
- primera y última carrera,
- existencia de fines de semana sprint.

### 7.2 Se creó `fact_race_entries`

Esta fue una de las decisiones más valiosas de la capa `Silver`.

`fact_race_entries` consolida información de:

- resultados,
- clasificación,
- contexto de carrera,
- escudería,
- estado,
- y variables analíticas derivadas.

Esto permitió crear una tabla de hechos rica y mucho más útil para consumo posterior.

### 7.3 Se modeló correctamente el fenómeno de `shared drives`

Durante la validación se detectó que en el histórico existían:

- `85` casos donde un mismo piloto aparece más de una vez en una misma carrera

Esto no se trató como error.  
Se documentó como comportamiento real del dataset histórico y se incorporó mediante la bandera:

- `shared_drive_candidate`

## 8. Validación de calidad

Una parte clave de la finalización de `Silver` fue demostrar que la capa no solo existía, sino que era confiable.

Se validaron los siguientes puntos:

| Chequeo | Resultado |
| --- | ---: |
| Duplicados en `results` por `resultId` | 0 |
| Duplicados en `lap_times` por clave compuesta | 0 |
| Duplicados en `pit_stops` por clave compuesta | 0 |
| Resultados sin piloto asociado | 0 |
| Resultados sin carrera asociada | 0 |
| Resultados sin constructor asociado | 0 |
| Resultados sin estado asociado | 0 |
| Duplicados por `raceId + driverId` en `results` | 85 |
| Registros de `constructor_results` sin carrera asociada | 0 |
| Registros de `constructor_results` sin constructor asociado | 0 |

Interpretación:

- no hubo problemas estructurales graves,
- no hubo huérfanos en los hechos principales,
- el único hallazgo relevante fue histórico y se modeló explícitamente.

## 9. Estado final de `Silver`

Al cierre del trabajo, `F1_silver` quedó con:

- `15` tablas base,
- `2` vistas,
- `28` llaves foráneas activas.

Conteos validados:

| Objeto | Filas |
| --- | ---: |
| `dim_drivers` | 861 |
| `dim_constructors` | 212 |
| `dim_circuits` | 77 |
| `dim_status` | 139 |
| `dim_seasons` | 75 |
| `dim_races` | 1125 |
| `fact_results` | 26759 |
| `fact_sprint_results` | 360 |
| `fact_constructor_results` | 12625 |
| `fact_qualifying` | 10494 |
| `fact_lap_times` | 589081 |
| `fact_pit_stops` | 11371 |
| `fact_driver_standings` | 34863 |
| `fact_constructor_standings` | 13391 |
| `fact_race_entries` | 26759 |

## 10. Qué significa que `Silver` quedó finalizada

Decir que `Silver` quedó finalizada significa que:

- ya existe una capa separada del origen,
- ya tiene un modelo más útil para analítica,
- ya tiene reglas de limpieza y enriquecimiento incorporadas,
- ya fue validada estructuralmente,
- y ya puede alimentar `Gold` sin depender de consultas improvisadas sobre la base fuente.

En términos profesionales, `Silver` pasó de ser una intención de limpieza a una capa formal, consistente y reutilizable.

## 11. Relación con Databricks

Además de la implementación local en MySQL, se dejó preparada una versión para Databricks:

- `F1_databricks_silver.sql`

Esa versión adapta la lógica de `Silver` al entorno lakehouse usando:

- `CREATE OR REPLACE TABLE`
- tablas `DELTA`
- timestamps con `CURRENT_TIMESTAMP()`
- y una estructura equivalente pensada para el esquema `f1_silver`

Esto demuestra que la capa `Silver` no quedó amarrada a un solo entorno, sino que puede migrarse a una arquitectura moderna de analítica.

## 12. Mensaje clave para la presentación

La idea principal que debes comunicar es esta:

> `Silver` fue la etapa donde el proyecto dejó de ser solo una base relacional cargada y se convirtió en una capa curada, confiable y preparada para análisis.

## 13. Estructura sugerida para la presentación

### Diapositiva 1. Título

`Construcción y finalización de la capa Silver del proyecto F1`

Qué decir:

- se explicará cómo se transformó una base relacional fuente en una capa curada lista para analítica.

### Diapositiva 2. Punto de partida

Contenido:

- CSV históricos
- base `F1`
- necesidad de una capa intermedia

Qué decir:

- la base fuente servía para almacenar, pero no todavía para consumir analíticamente.

### Diapositiva 3. Problema a resolver

Contenido:

- lógica repetida
- falta de separación entre hechos y dimensiones
- ausencia de variables analíticas
- necesidad de calidad y consistencia

Qué decir:

- `Silver` se construyó para resolver precisamente esas limitaciones.

### Diapositiva 4. Diseño de Silver

Contenido:

- dimensiones
- hechos
- vistas de calidad

Qué decir:

- el modelo se reorganizó para separar entidades descriptivas de eventos y métricas.

### Diapositiva 5. Transformaciones aplicadas

Contenido:

- limpieza y normalización
- categorías de estados
- milisegundos
- timestamps
- indicadores derivados

Qué decir:

- esta fue la etapa de curaduría real del dato.

### Diapositiva 6. Hallazgo importante

Contenido:

- `85` casos históricos de `shared drives`

Qué decir:

- no se descartaron como error; se modelaron explícitamente.

### Diapositiva 7. Validación de calidad

Contenido:

- duplicados en cero
- huérfanos en cero
- calidad controlada

Qué decir:

- la capa `Silver` no solo fue construida; también fue demostrada como consistente.

### Diapositiva 8. Estado final

Contenido:

- `15` tablas
- `2` vistas
- `28` llaves foráneas
- conteos principales

Qué decir:

- este fue el punto en el que la capa quedó lista para alimentar `Gold`.

### Diapositiva 9. Conexión con Gold

Contenido:

- `Silver` como base de KPIs, marts y vistas ejecutivas

Qué decir:

- sin una `Silver` bien hecha, `Gold` habría sido inestable o redundante.

### Diapositiva 10. Cierre

Mensaje final sugerido:

> La capa `Silver` fue la pieza que transformó datos estructurados en datos analíticamente confiables.

## 14. Cierre profesional

Si necesitas resumir todo en una sola idea para exponer, usa esta:

> `Bronze` conserva el origen, `F1` organiza el modelo relacional y `Silver` convierte ese modelo en una base limpia, enriquecida y lista para consumo analítico.

Ese mensaje deja muy clara la importancia de `Silver` dentro del proyecto completo.
