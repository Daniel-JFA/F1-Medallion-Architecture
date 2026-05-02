# Documentación del Proceso para Llegar a `F1_gold`

## 1. Propósito

Este documento resume el trabajo técnico realizado para transformar una base histórica de Formula 1 en una capa `Gold` lista para consumo analítico, dashboard y presentación académica.

El proyecto evolucionó desde datos fuente crudos hasta una arquitectura por capas:

```text
Bronze -> F1 relacional -> F1_silver -> F1_gold -> F1_control
```

## 2. Punto de partida

El proyecto comenzó con archivos CSV históricos de Formula 1. Estos archivos representan la capa `Bronze` y contienen la información original de:

- pilotos
- constructores
- circuitos
- carreras
- resultados
- clasificación
- paradas en pits
- tiempos por vuelta
- standings

Su valor principal es la trazabilidad: permiten volver al origen y reconstruir las capas posteriores si fuera necesario.

## 3. Consolidación de la base `F1`

Una vez cargados los datos, se trabajó sobre la base `F1` como fuente relacional oficial del proyecto.

### 3.1 Objetivo de esta etapa

- pasar de archivos sueltos a un modelo consultable
- validar estructura base
- incorporar integridad referencial real

### 3.2 Trabajo realizado

- revisión del diccionario relacional
- identificación de tablas maestras, pivotes y transaccionales
- aplicación de llaves foráneas con el script `F1_relationships.sql`
- validación de registros huérfanos antes de activar relaciones

### 3.3 Resultado

La base `F1` quedó con `23` llaves foráneas activas y funcionando como repositorio fuente para la capa `Silver`.

## 4. Construcción de `F1_silver`

La capa `Silver` se construyó en una base separada llamada `F1_silver`. Su propósito no fue copiar la base original, sino curarla y enriquecerla.

### 4.1 Objetivo de Silver

- limpiar y normalizar
- separar dimensiones y hechos
- introducir columnas útiles para análisis
- preparar un modelo estable para negocio

### 4.2 Transformaciones principales

- normalización de textos con `TRIM`, `LOWER` y `UPPER`
- construcción de dimensiones:
  - `dim_drivers`
  - `dim_constructors`
  - `dim_circuits`
  - `dim_status`
  - `dim_seasons`
  - `dim_races`
- construcción de hechos:
  - `fact_results`
  - `fact_sprint_results`
  - `fact_constructor_results`
  - `fact_qualifying`
  - `fact_lap_times`
  - `fact_pit_stops`
  - `fact_driver_standings`
  - `fact_constructor_standings`
  - `fact_race_entries`

### 4.3 Enriquecimiento analítico en Silver

Se incorporaron campos derivados para hacer análisis sin repetir lógica en cada consulta:

- `is_winner`
- `is_podium`
- `scored_points`
- `started_from_pole`
- `positions_gained`
- `qualifying_to_finish_delta`
- `shared_drive_candidate`

También se convirtieron tiempos a milisegundos y se añadieron timestamps útiles para sesiones y carreras.

### 4.4 Hallazgo histórico importante

Durante la validación apareció un comportamiento real del dataset:

- `85` casos donde un piloto aparece más de una vez en una misma carrera

Esto no se consideró error. Se modeló correctamente en `fact_race_entries` con grano por `resultId` y con la bandera `shared_drive_candidate`.

### 4.5 Resultado de Silver

La base `F1_silver` quedó con:

- `15` tablas
- `2` vistas
- `28` llaves foráneas

Esta capa se convirtió en la base curada para la construcción de `Gold`.

## 5. Construcción de `F1_gold`

La capa `Gold` se diseñó para consumo de negocio. Aquí ya no interesa tanto el detalle transaccional, sino los indicadores, resúmenes y vistas listas para exposición.

### 5.1 Objetivo de Gold

- materializar KPIs oficiales
- evitar consultas complejas al presentar resultados
- ofrecer marts reutilizables
- facilitar dashboards y storytelling analítico

### 5.2 Objetos construidos

#### Tablas

- `kpi_catalog`
- `mart_kpi_snapshot`
- `mart_driver_season`
- `mart_constructor_season`
- `mart_circuit_risk`
- `mart_qualifying_effect_season`
- `mart_race_weekend`

#### Vistas

- `vw_dashboard_kpi_cards`
- `vw_dashboard_top_drivers`
- `vw_dashboard_top_constructors`
- `vw_dashboard_circuit_risk`
- `vw_dashboard_qualifying_effect_recent`
- `vw_dashboard_latest_driver_championship`
- `vw_dashboard_latest_constructor_championship`
- `vw_dashboard_recent_race_highlights`

### 5.3 Qué resuelve cada mart

- `mart_driver_season`: rendimiento de pilotos por temporada
- `mart_constructor_season`: rendimiento de escuderías por temporada
- `mart_circuit_risk`: nivel de caos, abandono e incidentes por circuito
- `mart_qualifying_effect_season`: relación entre clasificación y resultado final
- `mart_race_weekend`: resumen narrativo por carrera
- `mart_kpi_snapshot`: corte actual de indicadores oficiales

### 5.4 KPI oficiales definidos

Se formalizó un catálogo de indicadores de negocio, entre ellos:

- temporadas cubiertas
- carreras registradas
- pilotos registrados
- escuderías registradas
- tasa de clasificación
- tasa de no clasificación
- puntos promedio por entrada
- conversión pole a victoria
- participación de fines de semana sprint
- participación de shared drives

### 5.5 Resultado de Gold

La base `F1_gold` quedó con:

- `7` tablas
- `8` vistas

Esto deja el proyecto listo para visualización ejecutiva sin depender de joins complejos sobre la base fuente.

## 6. Operación y trazabilidad

Para que la capa `Gold` no dependiera de ejecución manual aislada, se construyó un flujo operativo reproducible.

### 6.1 Scripts creados

- `F1_relationships.sql`
- `F1_mysql_silver.sql`
- `F1_mysql_gold.sql`
- `F1_refresh_layers.sh`
- `F1_freeze_kpis.sh`
- `F1_gold_kpi_history.sql`

### 6.2 Base de control

Se creó la base `F1_control` para guardar snapshots históricos de KPIs sin interferir con la reconstrucción de `F1_gold`.

Objeto principal:

- `f1_gold_kpi_snapshot_history`

### 6.3 Flujo operativo final

```text
F1 -> F1_silver -> F1_gold -> F1_control
```

Este flujo permite:

- refrescar relaciones
- reconstruir Silver
- reconstruir Gold
- congelar un corte oficial de KPIs

## 7. Validación realizada

Al cierre del proceso, el estado validado fue:

- `F1`: `23` llaves foráneas
- `F1_silver`: `15` tablas, `2` vistas y `28` llaves foráneas
- `F1_gold`: `7` tablas y `8` vistas
- `F1_control`: snapshots de KPIs almacenados

KPIs actuales en Gold:

- `75` temporadas
- `1125` carreras
- `861` pilotos
- `212` escuderías
- `56.66%` tasa de clasificación
- `43.34%` tasa de no clasificación
- `42.64%` conversión pole a victoria

## 8. Visualización en Streamlit

Se creó una app dedicada para consumir directamente la capa `Gold`.

Ubicación:

- `/home/djfa/Dev/f1_gold_streamlit`

### 8.1 Qué visualiza

- KPIs oficiales
- campeonato más reciente de pilotos
- campeonato más reciente de constructores
- líderes históricos
- riesgo por circuito
- efecto de clasificación
- carreras recientes
- historial versionado de KPIs

### 8.2 Propósito de la app

Su función es convertir `F1_gold` en una visualización clara, explicada y lista para presentación, de modo que el profesor o cualquier usuario entienda:

- qué mide cada indicador
- qué mart alimenta cada sección
- cómo se conectan las capas del proyecto

### 8.3 Operación de la app

La app no depende de un `streamlit` global del sistema. Se dejó encapsulada en:

- `/home/djfa/Dev/f1_gold_streamlit/.venv`

Lanzadores disponibles:

- dashboard:
  - `/home/djfa/Dev/DBs BackUps/F1_gold_dashboard.sh`
- detención:
  - `/home/djfa/Dev/DBs BackUps/F1_gold_dashboard_stop.sh`

Comportamiento operativo del lanzador:

- reutiliza una instancia si ya está activa
- selecciona un puerto libre desde `8501`
- registra PID y puerto
- escribe el log en `f1_gold_streamlit/logs/streamlit.log`
- evita el bloqueo por onboarding de `Streamlit`

### 8.4 Estado validado del dashboard

Al cierre de esta documentación, el dashboard quedó validado en la instancia local con estas condiciones:

- URL local operativa: `http://127.0.0.1:8501`
- respuesta HTTP correcta desde el servidor local
- consumo exitoso de `F1_gold`
- consumo exitoso de `F1_control`

El historial actual registrado en control corresponde a:

- snapshot: `clase_2026_04_18`
- esquema fuente: `F1_gold`
- KPIs congelados: `10`

### 8.5 Archivos relacionados con la visualización

- `/home/djfa/Dev/f1_gold_streamlit/app.py`
- `/home/djfa/Dev/f1_gold_streamlit/README.md`
- `/home/djfa/Dev/f1_gold_streamlit/requirements.txt`
- `/home/djfa/Dev/f1_gold_streamlit/run_streamlit.sh`
- `/home/djfa/Dev/f1_gold_streamlit/stop_streamlit.sh`
- `/home/djfa/Dev/f1_gold_streamlit/.streamlit/config.toml`

## 9. Conclusión

El proyecto ya no es solo una colección de consultas SQL. Se consolidó como una arquitectura analítica por capas:

- `Bronze` conserva el origen
- `F1` formaliza el modelo relacional
- `Silver` limpia y enriquece
- `Gold` materializa el consumo de negocio
- `Control` preserva los cortes oficiales de KPIs

Desde un punto de vista profesional, el trabajo necesario para llegar a `Gold` ya quedó resuelto. El siguiente paso con más valor no es seguir creando tablas, sino aprovecharlas en dashboard, exposición y storytelling analítico.
