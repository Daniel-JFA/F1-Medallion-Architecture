# Informe de Avance del Proyecto F1

## 1. Resumen ejecutivo

Durante esta fase de trabajo se consolidó la base de datos `F1` como un repositorio relacional funcional, se construyó una capa `Silver` en una base separada llamada `F1_silver` y finalmente se materializó una capa `Gold` en `F1_gold` orientada a consumo analítico. Adicionalmente, se preparó la documentación del taller SQL, se validaron consultas analíticas, se generaron entregables tanto para entorno local MySQL como para Databricks y se automatizó el refresco operativo de capas con versionamiento de KPIs.

El resultado actual es un proyecto con tres niveles claramente distinguibles y una capa operativa de control:

- `Bronze`: archivos CSV originales.
- `Silver`: modelo relacional depurado y enriquecido en `F1_silver`.
- `Gold`: marts de negocio, KPIs oficiales y vistas ejecutivas en `F1_gold`.
- `Control`: historial de snapshots de KPIs y scripts de refresco en `F1_control`.

## 2. Objetivo del trabajo realizado

El objetivo principal fue mejorar la calidad estructural y analítica del proyecto F1, logrando:

- formalizar relaciones referenciales en la base `F1`,
- construir una capa `Silver` separada y más útil para análisis,
- materializar una capa `Gold` formal de consumo,
- automatizar el refresco `F1 -> F1_silver -> F1_gold`,
- versionar KPIs oficiales mediante snapshots trazables,
- preparar entregables académicos consistentes,
- dejar una base analítica completa y profesional.

## 3. Actividades ejecutadas

### 3.1 Revisión del modelo relacional

Se revisó el diccionario relacional y la estructura de la base para identificar:

- tabla pivote del modelo (`races`),
- dimensiones maestras (`drivers`, `constructors`, `circuits`, `status`, `seasons`),
- tablas de hechos transaccionales y acumuladas,
- oportunidades de mejora en calidad y explotación analítica.

Archivo de referencia:

- [F1_diccionario_relacional.md](/home/djfa/Dev/DBs%20BackUps/F1_diccionario_relacional.md)

### 3.2 Revisión y corrección del taller SQL

Se revisó el archivo de respuestas del taller y se identificaron consultas que:

- no respondían exactamente la pregunta formulada,
- estaban desalineadas con la explicación escrita,
- requerían ajustes de `HAVING`, `LIKE`, agregaciones o funciones de ventana.

Como resultado, se generó una versión corregida y validada:

- [F1_entrega_corregida.md](/home/djfa/Dev/DBs%20BackUps/F1_entrega_corregida.md)
- [F1_taller_consultas_corregidas.sql](/home/djfa/Dev/DBs%20BackUps/F1_taller_consultas_corregidas.sql)
- [F1_entrega_databricks.md](/home/djfa/Dev/DBs%20BackUps/F1_entrega_databricks.md)

### 3.3 Preparación de versión para Databricks

Se generó una versión específica para Databricks SQL con:

- consultas adaptadas al esquema `f1`,
- sintaxis compatible con Databricks,
- vistas permanentes listas para ejecución.

Archivo generado:

- [F1_entrega_databricks.md](/home/djfa/Dev/DBs%20BackUps/F1_entrega_databricks.md)

### 3.4 Construcción de capa Silver local

Se diseñó y ejecutó una capa `Silver` local sobre MySQL, separada del origen `F1`, mediante la creación de la base:

- `F1_silver`

Se construyeron y posteriormente se ampliaron las siguientes tablas:

- dimensiones:
  - `dim_drivers`
  - `dim_constructors`
  - `dim_circuits`
  - `dim_seasons`
  - `dim_races`
  - `dim_status`
- hechos:
  - `fact_results`
  - `fact_sprint_results`
  - `fact_constructor_results`
  - `fact_qualifying`
  - `fact_lap_times`
  - `fact_pit_stops`
  - `fact_driver_standings`
  - `fact_constructor_standings`
  - `fact_race_entries`

También se crearon las vistas:

- `vw_data_quality_checks`
- `vw_silver_summary`

Archivo generado y ejecutado:

- [F1_mysql_silver.sql](/home/djfa/Dev/DBs%20BackUps/F1_mysql_silver.sql)

### 3.5 Formalización de relaciones en la base original F1

Se verificó que la base `F1` tenía llaves primarias, pero no relaciones foráneas activas.  
Después de validar la inexistencia de registros huérfanos, se ejecutó el script de relaciones y se agregaron llaves foráneas reales.

Archivo aplicado:

- [F1_relationships.sql](/home/djfa/Dev/DBs%20BackUps/F1_relationships.sql)

### 3.6 Construcción de capa Gold local

Se diseñó y ejecutó una capa `Gold` local sobre MySQL, separada de `F1_silver`, mediante la creación de la base:

- `F1_gold`

Se construyeron los siguientes objetos:

- catálogo de KPIs:
  - `kpi_catalog`
  - `mart_kpi_snapshot`
- marts de negocio:
  - `mart_driver_season`
  - `mart_constructor_season`
  - `mart_circuit_risk`
  - `mart_qualifying_effect_season`
  - `mart_race_weekend`
- vistas ejecutivas:
  - `vw_dashboard_kpi_cards`
  - `vw_dashboard_top_drivers`
  - `vw_dashboard_top_constructors`
  - `vw_dashboard_circuit_risk`
  - `vw_dashboard_qualifying_effect_recent`
  - `vw_dashboard_latest_driver_championship`
  - `vw_dashboard_latest_constructor_championship`
  - `vw_dashboard_recent_race_highlights`

Archivo generado y ejecutado:

- [F1_mysql_gold.sql](/home/djfa/Dev/DBs%20BackUps/F1_mysql_gold.sql)

### 3.7 Automatización operativa y versionamiento de KPIs

Se implementó una capa operativa adicional para profesionalizar la explotación del modelo analítico:

- script de refresco completo:
  - [F1_refresh_layers.sh](/home/djfa/Dev/DBs%20BackUps/F1_refresh_layers.sh)
- script de congelamiento de KPIs:
  - [F1_freeze_kpis.sh](/home/djfa/Dev/DBs%20BackUps/F1_freeze_kpis.sh)
- SQL de historial de snapshots:
  - [F1_gold_kpi_history.sql](/home/djfa/Dev/DBs%20BackUps/F1_gold_kpi_history.sql)

El diseño final usa una base separada llamada:

- `F1_control`

Esta decisión evita que el historial de KPIs interfiera con la reconstrucción de `F1_gold`. Los snapshots quedan desacoplados del catálogo operativo actual y preservan trazabilidad por etiqueta de ejecución.

Comandos operativos ya validados:

```bash
"/home/djfa/Dev/DBs BackUps/F1_refresh_layers.sh" clase_2026_04_18
"/home/djfa/Dev/DBs BackUps/F1_freeze_kpis.sh" clase_2026_04_18
```

### 3.8 Construcción y estabilización del dashboard Streamlit

Se construyó una aplicación `Streamlit` para visualizar la capa `F1_gold` y el historial almacenado en `F1_control`.

Archivos principales:

- aplicación:
  - [app.py](/home/djfa/Dev/f1_gold_streamlit/app.py)
- guía de uso:
  - [README.md](/home/djfa/Dev/f1_gold_streamlit/README.md)
- lanzadores:
  - [run_streamlit.sh](/home/djfa/Dev/f1_gold_streamlit/run_streamlit.sh)
  - [stop_streamlit.sh](/home/djfa/Dev/f1_gold_streamlit/stop_streamlit.sh)
  - [F1_gold_dashboard.sh](/home/djfa/Dev/DBs%20BackUps/F1_gold_dashboard.sh)
  - [F1_gold_dashboard_stop.sh](/home/djfa/Dev/DBs%20BackUps/F1_gold_dashboard_stop.sh)

Trabajo realizado:

- conexión directa a `F1_gold` y `F1_control`
- visualización explicada de KPIs, campeonatos, liderazgo histórico, circuitos, clasificación y carreras recientes
- encapsulamiento de dependencias en un entorno virtual local
- corrección del arranque para evitar bloqueo por onboarding
- estabilización del lanzador para reutilizar instancia, abrir puerto libre y registrar logs

## 4. Estado actual del proyecto

### 4.1 Base original `F1`

Estado actual:

- `14` tablas base
- `23` llaves foráneas activas
- integridad referencial validada en tablas principales

Relaciones ya activas, entre otras:

- `races.year -> seasons.year`
- `races.circuitId -> circuits.circuitId`
- `results.raceId -> races.raceId`
- `results.driverId -> drivers.driverId`
- `results.constructorId -> constructors.constructorId`
- `results.statusId -> status.statusId`
- `qualifying.raceId -> races.raceId`
- `qualifying.driverId -> drivers.driverId`
- `qualifying.constructorId -> constructors.constructorId`
- `lap_times.raceId -> races.raceId`
- `lap_times.driverId -> drivers.driverId`
- `pit_stops.raceId -> races.raceId`
- `pit_stops.driverId -> drivers.driverId`

### 4.2 Capa `F1_silver`

Estado actual:

- `15` tablas base
- `2` vistas
- `28` llaves foráneas activas

Conteos actuales:

| Objeto | Filas |
| --- | ---: |
| `dim_drivers` | 861 |
| `dim_constructors` | 212 |
| `dim_circuits` | 77 |
| `dim_seasons` | 75 |
| `dim_races` | 1125 |
| `dim_status` | 139 |
| `fact_results` | 26759 |
| `fact_sprint_results` | 360 |
| `fact_constructor_results` | 12625 |
| `fact_qualifying` | 10494 |
| `fact_lap_times` | 589081 |
| `fact_pit_stops` | 11371 |
| `fact_driver_standings` | 34863 |
| `fact_constructor_standings` | 13391 |
| `fact_race_entries` | 26759 |

### 4.3 Capa `F1_gold`

Estado actual:

- `7` tablas
- `8` vistas ejecutivas

Objetos materializados:

- `kpi_catalog`
- `mart_kpi_snapshot`
- `mart_driver_season`
- `mart_constructor_season`
- `mart_circuit_risk`
- `mart_qualifying_effect_season`
- `mart_race_weekend`

Conteos actuales:

| Objeto | Filas |
| --- | ---: |
| `mart_driver_season` | 3211 |
| `mart_constructor_season` | 1111 |
| `mart_circuit_risk` | 77 |
| `mart_qualifying_effect_season` | 31 |
| `mart_race_weekend` | 1125 |
| `mart_kpi_snapshot` | 10 |

### 4.4 Base de control `F1_control`

Estado actual:

- `1` tabla operativa de historial
- `10` filas de snapshots almacenadas
- `1` ejecución versionada validada

Objeto actual:

- `f1_gold_kpi_snapshot_history`

Snapshots registrados:

| snapshot_label | source_schema | frozen_kpis | snapshot_taken_at |
| --- | --- | ---: | --- |
| `clase_2026_04_18` | `F1_gold` | 10 | `2026-04-18 13:11:59` |

### 4.5 Dashboard `Streamlit`

Estado actual:

- aplicación funcional y validada
- entorno virtual local creado
- lanzador operativo desde `DBs BackUps`
- URL local validada: `http://127.0.0.1:8501`

Capas consumidas por la app:

- `F1_gold`
- `F1_control`

## 5. Mejoras concretas logradas en Silver

La capa `F1_silver` no es una copia directa de `F1`; introduce mejoras estructurales y analíticas:

- normalización de nombres y referencias (`TRIM`, `LOWER`, `UPPER`),
- separación clara entre dimensiones y hechos,
- incorporación de una dimensión explícita de temporadas (`dim_seasons`),
- clasificación semántica de estados de carrera,
- incorporación del hecho `fact_constructor_results`,
- construcción de `fact_race_entries` como hecho enriquecido a nivel de entrada de carrera,
- creación de indicadores derivados:
  - `is_winner`
  - `is_podium`
  - `scored_points`
  - `started_from_pole`
- `positions_gained`
- `qualifying_to_finish_delta`
- `shared_drive_candidate`
- conversión de tiempos de clasificación y vuelta rápida a milisegundos,
- creación de timestamps útiles para carreras y sesiones,
- incorporación de vistas operativas para resumen de capa y calidad,
- base lista para construir mart de negocio o capa `Gold`.

## 5.1 Mejoras concretas logradas en Gold

La capa `F1_gold` transforma el modelo técnico en una capa de consumo analítico:

- formaliza un catálogo oficial de KPIs,
- materializa marts reutilizables por piloto, escudería, circuito, temporada y carrera,
- expone vistas ejecutivas listas para presentación,
- evita consultar directamente tablas operativas para análisis de negocio,
- soporta storytelling analítico en clase o en dashboard.

## 6. Validación de calidad

Se ejecutaron chequeos de calidad sobre `F1_silver` con los siguientes resultados:

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

El único hallazgo no nulo corresponde a `85` casos históricos donde un mismo piloto aparece más de una vez en una misma carrera. Esto no se trató como error, sino como una característica real del dataset histórico, y por eso se modeló `fact_race_entries` con grano por `resultId` y un indicador `shared_drive_candidate`.

## 6.1 Validación operativa del refresco

Se ejecutó exitosamente el refresco completo con la etiqueta:

- `clase_2026_04_18`

Resultados validados al cierre:

- `F1`: `23` llaves foráneas activas
- `F1_silver`: `28` llaves foráneas activas
- `F1_gold`: `7` tablas y `8` vistas
- snapshot congelado en `F1_control`: `10` KPIs

Esto confirma que el flujo completo ya opera correctamente:

```text
F1 -> F1_silver -> F1_gold -> F1_control
```

## 6.2 Validación operativa del dashboard

Se validó el dashboard `Streamlit` con los siguientes resultados:

- test de aplicación sin excepciones
- carga correcta de la capa `F1_gold`
- carga correcta del historial en `F1_control`
- servicio local respondiendo correctamente en `http://127.0.0.1:8501`

Lanzador validado:

```bash
"/home/djfa/Dev/DBs BackUps/F1_gold_dashboard.sh"
```

## 7. Entregables generados hasta el momento

- [F1_diccionario_relacional.md](/home/djfa/Dev/DBs%20BackUps/F1_diccionario_relacional.md)
- [F1_relationships.sql](/home/djfa/Dev/DBs%20BackUps/F1_relationships.sql)
- [F1_entrega_corregida.md](/home/djfa/Dev/DBs%20BackUps/F1_entrega_corregida.md)
- [F1_taller_consultas_corregidas.sql](/home/djfa/Dev/DBs%20BackUps/F1_taller_consultas_corregidas.sql)
- [F1_entrega_databricks.md](/home/djfa/Dev/DBs%20BackUps/F1_entrega_databricks.md)
- [F1_databricks_silver.sql](/home/djfa/Dev/DBs%20BackUps/F1_databricks_silver.sql)
- [F1_mysql_silver.sql](/home/djfa/Dev/DBs%20BackUps/F1_mysql_silver.sql)
- [F1_mysql_gold.sql](/home/djfa/Dev/DBs%20BackUps/F1_mysql_gold.sql)
- [F1_refresh_layers.sh](/home/djfa/Dev/DBs%20BackUps/F1_refresh_layers.sh)
- [F1_freeze_kpis.sh](/home/djfa/Dev/DBs%20BackUps/F1_freeze_kpis.sh)
- [F1_gold_kpi_history.sql](/home/djfa/Dev/DBs%20BackUps/F1_gold_kpi_history.sql)
- [F1_gold_presentacion.md](/home/djfa/Dev/DBs%20BackUps/F1_gold_presentacion.md)
- [F1_documentacion_hacia_gold.md](/home/djfa/Dev/DBs%20BackUps/F1_documentacion_hacia_gold.md)
- [F1_gold_dashboard.sh](/home/djfa/Dev/DBs%20BackUps/F1_gold_dashboard.sh)
- [F1_gold_dashboard_stop.sh](/home/djfa/Dev/DBs%20BackUps/F1_gold_dashboard_stop.sh)
- [README.md](/home/djfa/Dev/f1_gold_streamlit/README.md)

## 8. Conclusión del estado actual

El proyecto F1 ya superó la etapa de simple carga de datos. Actualmente cuenta con:

- una base original `F1` relacional y consistente,
- una capa `Silver` separada, más limpia y más útil para analítica,
- una capa `Gold` formal con marts, KPIs y vistas ejecutivas,
- documentación técnica suficiente para continuar con escalamiento académico o analítico.

En este punto, el proyecto ya se encuentra en una fase de explotación analítica madura.

Además, ya no depende de ejecución manual fragmentada: cuenta con un flujo reproducible de refresco y con trazabilidad histórica de KPIs.

## 9. Pasos a seguir recomendados

### Fase 1. Operación controlada

1. Externalizar credenciales de MySQL.
   Se recomienda mover usuario, contraseña, host y puerto a variables de entorno persistentes o a un archivo `.my.cnf`.

2. Agregar bitácora de ejecución.
   Conviene que el refresco escriba un log por corrida con fecha, duración, estado y etiqueta de snapshot.

3. Programar el refresco si el proyecto seguirá creciendo.
   Puede hacerse con `cron`, `systemd timers` o un scheduler externo.

### Fase 2. Gobierno de negocio

4. Consolidar un diccionario formal de KPIs.
   Cada indicador debe tener definición, fórmula, fuente, periodicidad y responsable.

5. Definir cortes oficiales para clase o presentación.
   Ejemplo: snapshot base, snapshot final y snapshot posterior a ajustes.

6. Establecer una convención de etiquetas.
   Por ejemplo: `clase_YYYY_MM_DD`, `entrega_YYYY_MM_DD` o `demo_YYYY_MM_DD`.

### Fase 3. Presentación ejecutiva

7. Construir dashboard final sobre `F1_gold`.
   Lo más recomendable es usar `vw_dashboard_kpi_cards`, `vw_dashboard_top_drivers`, `vw_dashboard_top_constructors`, `vw_dashboard_circuit_risk` y `vw_dashboard_recent_race_highlights`.

8. Preparar la narrativa del esquema medallón.
   Debe mostrarse con el flujo:
   `Bronze -> Silver -> Gold -> Control`

9. Seleccionar 3 a 5 insights principales.
   Ejemplo: dominancia histórica, relación clasificación-victoria, circuitos más caóticos, rendimiento por escudería y evolución reciente.

## 10. Recomendación profesional final

La operación técnica ya quedó resuelta en un nivel sólido: `F1` como fuente relacional, `F1_silver` como capa curada, `F1_gold` como capa formal de consumo y `F1_control` como esquema de trazabilidad operativa.  
La siguiente acción con mejor retorno ya no es seguir modelando tablas, sino capitalizar lo construido mediante dashboard, narrativa ejecutiva y presentación final.

Ese orden te dará:

- mayor claridad arquitectónica,
- mejor trazabilidad,
- mejor presentación académica,
- y una base mucho más sólida para futuros análisis o dashboards.
