# Guia de Presentacion - F1_gold

## 1. Estado final de la arquitectura

El proyecto queda organizado de la siguiente forma:

- `Bronze`: archivos CSV originales
- `Silver`: `F1_silver`, capa curada y relacional para analitica
- `Gold`: `F1_gold`, capa de consumo con marts de negocio, KPIs y vistas ejecutivas

## 2. Objetos principales creados en `F1_gold`

### Tablas

- `kpi_catalog`
- `mart_kpi_snapshot`
- `mart_driver_season`
- `mart_constructor_season`
- `mart_circuit_risk`
- `mart_qualifying_effect_season`
- `mart_race_weekend`

### Vistas ejecutivas

- `vw_dashboard_kpi_cards`
- `vw_dashboard_top_drivers`
- `vw_dashboard_top_constructors`
- `vw_dashboard_circuit_risk`
- `vw_dashboard_qualifying_effect_recent`
- `vw_dashboard_latest_driver_championship`
- `vw_dashboard_latest_constructor_championship`
- `vw_dashboard_recent_race_highlights`

## 3. Orden recomendado para la presentacion

### Paso 1. Mostrar la arquitectura por capas

Explica primero el flujo:

- datos crudos en `Bronze`
- limpieza y enriquecimiento en `Silver`
- consumo analitico en `Gold`

Mensaje recomendado:

> La base original `F1` se mantuvo como fuente relacional, `F1_silver` se construyo como capa curada y `F1_gold` se materializo para exponer indicadores y resumenes de negocio.

### Paso 2. Presentar los KPI cards

Vista recomendada:

```sql
SELECT *
FROM F1_gold.vw_dashboard_kpi_cards;
```

Que contar:

- cuantas temporadas cubre el proyecto
- cuantas carreras, pilotos y escuderias incluye
- tasa de clasificacion y no clasificacion
- porcentaje de conversion de pole a victoria
- presencia de fines de semana sprint
- proporcion de shared drives historicos

### Paso 3. Mostrar el campeonato mas reciente de pilotos

Vista recomendada:

```sql
SELECT *
FROM F1_gold.vw_dashboard_latest_driver_championship;
```

Que contar:

- posiciones finales del campeonato mas reciente
- puntos, victorias, podios y poles
- constructor principal de cada piloto

### Paso 4. Mostrar el campeonato mas reciente de constructores

Vista recomendada:

```sql
SELECT *
FROM F1_gold.vw_dashboard_latest_constructor_championship;
```

Que contar:

- jerarquia competitiva de escuderias
- puntos, victorias, podios y cantidad de pilotos usados

### Paso 5. Mostrar el ranking historico de grandes figuras

Vista recomendada:

```sql
SELECT *
FROM F1_gold.vw_dashboard_top_drivers
LIMIT 10;
```

y

```sql
SELECT *
FROM F1_gold.vw_dashboard_top_constructors
LIMIT 10;
```

Que contar:

- lideres historicos en titulos, victorias y puntos
- peso historico de Ferrari, McLaren, Williams, Mercedes y Red Bull

### Paso 6. Mostrar el riesgo o caos por circuito

Vista recomendada:

```sql
SELECT *
FROM F1_gold.vw_dashboard_circuit_risk
LIMIT 10;
```

Que contar:

- circuitos con mayor tasa de no clasificacion
- diferencia entre fallos mecanicos e incidentes
- lectura historica de circuitos callejeros o mas exigentes

### Paso 7. Mostrar el impacto de la clasificacion

Vista recomendada:

```sql
SELECT *
FROM F1_gold.vw_dashboard_qualifying_effect_recent
LIMIT 10;
```

Que contar:

- cuantas poles se convierten en victorias
- que tan fuerte es la relacion entre salir adelante y terminar adelante

### Paso 8. Cerrar con highlights recientes de fines de semana

Vista recomendada:

```sql
SELECT *
FROM F1_gold.vw_dashboard_recent_race_highlights
LIMIT 10;
```

Que contar:

- ganador, pole, podio, nivel de abandono y actividad en pits
- esta vista funciona muy bien como cierre narrativo

## 4. Historia analitica sugerida

Una narrativa profesional para exponer seria:

1. Se recibieron datos historicos crudos de Formula 1.
2. Se normalizaron y relacionaron en `F1`.
3. Se construyo `F1_silver` para limpieza, enriquecimiento y consistencia.
4. Se detecto un rasgo historico importante: `85` casos de shared drives.
5. Se construyo `F1_gold` para traducir el modelo tecnico en indicadores de negocio y consumo ejecutivo.
6. A partir de `F1_gold`, ya es posible alimentar dashboards y presentaciones sin depender de consultas complejas sobre la base fuente.

## 5. Mensajes clave para el profesor

- El proyecto no se quedo en consultas sueltas; evoluciono a arquitectura por capas.
- `Silver` no es copia de `F1`, sino una capa curada con logica analitica.
- `Gold` ya materializa marts, KPIs y vistas ejecutivas.
- El modelo esta listo para dashboards o visualizaciones externas.

## 6. Recomendacion visual

Si vas a mostrar esto en clase desde DBeaver o tu cliente SQL:

- abre primero `vw_dashboard_kpi_cards`
- luego `vw_dashboard_latest_driver_championship`
- luego `vw_dashboard_top_drivers`
- luego `vw_dashboard_circuit_risk`
- cierra con `vw_dashboard_recent_race_highlights`

Ese orden deja una presentacion clara, progresiva y profesional.
