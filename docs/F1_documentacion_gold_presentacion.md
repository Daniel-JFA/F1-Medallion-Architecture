# Documentación de Cómo se Llegó y se Finalizó la Capa `Gold`

## 1. Propósito del documento

Este documento fue preparado para apoyar una presentación sobre la construcción y finalización de la capa `Gold` del proyecto de Formula 1.

Su objetivo es explicar:

- por qué fue necesaria una capa `Gold`,
- desde qué punto partía el proyecto,
- cómo se aprovechó la capa `Silver`,
- qué objetos se construyeron,
- qué KPIs y marts se materializaron,
- cómo se validó la capa,
- y por qué `Gold` representa el nivel de consumo final del proyecto.

## 2. Contexto del proyecto

El proyecto evolucionó por capas:

```text
Bronze -> F1 relacional -> F1_silver -> F1_gold -> F1_control
```

Cada nivel cumple una función distinta:

- `Bronze`: conserva los CSV originales,
- `F1`: formaliza el modelo relacional base,
- `Silver`: limpia, normaliza y enriquece,
- `Gold`: materializa consumo de negocio,
- `Control`: conserva snapshots históricos de KPIs.

La capa `Gold` no aparece desde cero.  
Se construye sobre una `Silver` ya validada, consistente y enriquecida.

## 3. Problema que resolvía `Gold`

Aunque `F1_silver` ya era una capa curada y analíticamente útil, todavía tenía una orientación principalmente técnica.

Sus limitaciones para consumo ejecutivo eran:

- seguía siendo una capa detallada, no un producto final de negocio,
- requería construir consultas para responder preguntas ejecutivas,
- no tenía KPIs formalizados como catálogo,
- no materializaba resúmenes listos para dashboard,
- y no ofrecía vistas directas para exposición o storytelling.

Por eso se construyó `F1_gold`.

## 4. Objetivo de la capa `Gold`

La capa `Gold` se diseñó con cinco objetivos principales:

1. traducir la capa técnica en una capa de negocio,
2. materializar KPIs oficiales,
3. exponer marts reutilizables para consumo,
4. evitar consultas complejas en la presentación,
5. dejar la base lista para dashboard y visualización.

En una frase:

> `Gold` convierte un modelo analítico detallado en una capa ejecutiva lista para consumir.

## 5. Cómo se llegó a `Gold`

La construcción de `Gold` se desarrolló por etapas.

### 5.1 Se tomó `Silver` como base confiable

Antes de construir `Gold`, la capa `Silver` ya ofrecía:

- dimensiones y hechos separados,
- reglas de limpieza ya aplicadas,
- banderas analíticas útiles,
- control de calidad validado,
- y un hecho enriquecido clave: `fact_race_entries`.

Eso permitió diseñar `Gold` sin depender de lógica repetida sobre la base fuente.

### 5.2 Se definieron las preguntas de negocio

La capa `Gold` se pensó a partir de preguntas que sí tienen sentido en una presentación o dashboard, por ejemplo:

- ¿cuántas temporadas cubre el proyecto?
- ¿qué tan frecuente es convertir una pole en victoria?
- ¿qué pilotos y escuderías dominan históricamente?
- ¿qué circuitos son más caóticos?
- ¿qué tan fuerte es la relación entre clasificación y resultado final?
- ¿cómo resumir un fin de semana de carrera en una sola vista?

Con base en esas preguntas se diseñaron los marts y KPIs.

### 5.3 Se formalizó un catálogo de KPIs

No se dejó la capa dependiente de métricas implícitas.  
Se construyó un objeto específico para gobernanza:

- `kpi_catalog`

Este catálogo describe:

- código del KPI,
- nombre del indicador,
- pregunta de negocio,
- definición,
- fórmula,
- grano,
- y objetos fuente.

Esto le dio consistencia al lenguaje analítico del proyecto.

### 5.4 Se materializaron marts de negocio

Después del catálogo, se construyeron marts enfocados en distintos ejes analíticos:

- piloto por temporada,
- escudería por temporada,
- riesgo por circuito,
- impacto de clasificación,
- resumen narrativo por carrera.

Esto hizo que `Gold` no fuera solo “una capa de KPIs”, sino una base reutilizable para análisis ejecutivos.

### 5.5 Se construyeron vistas ejecutivas

Además de los marts, se diseñaron vistas pensadas directamente para consumo:

- tarjetas KPI,
- ranking histórico de pilotos,
- ranking histórico de escuderías,
- circuitos más riesgosos,
- campeonatos,
- y carreras recientes.

Estas vistas simplifican mucho la exposición y el dashboard.

## 6. Estructura final de `Gold`

La implementación final de `Gold` se consolidó en la base:

- `F1_gold`

### 6.1 Tablas creadas

- `kpi_catalog`
- `mart_kpi_snapshot`
- `mart_driver_season`
- `mart_constructor_season`
- `mart_circuit_risk`
- `mart_qualifying_effect_season`
- `mart_race_weekend`

### 6.2 Vistas creadas

- `vw_dashboard_kpi_cards`
- `vw_dashboard_top_drivers`
- `vw_dashboard_top_constructors`
- `vw_dashboard_circuit_risk`
- `vw_dashboard_qualifying_effect_recent`
- `vw_dashboard_latest_driver_championship`
- `vw_dashboard_latest_constructor_championship`
- `vw_dashboard_recent_race_highlights`

## 7. Qué resuelve cada objeto principal

### 7.1 `kpi_catalog`

Resuelve la necesidad de tener un lenguaje común de negocio.

Permite saber:

- qué mide cada KPI,
- cómo se calcula,
- y desde qué objetos se obtiene.

### 7.2 `mart_kpi_snapshot`

Resuelve la necesidad de tener un corte actual de los indicadores oficiales.

Es el resumen ejecutivo de la capa.

### 7.3 `mart_driver_season`

Resuelve el análisis de rendimiento por piloto y temporada.

Permite ver:

- puntos,
- victorias,
- podios,
- poles,
- promedio de parrilla,
- promedio de llegada,
- posición final del campeonato.

### 7.4 `mart_constructor_season`

Resuelve el análisis de rendimiento por escudería y temporada.

Permite comparar:

- puntos,
- victorias,
- podios,
- poles,
- pilotos utilizados,
- posición final del campeonato.

### 7.5 `mart_circuit_risk`

Resuelve la pregunta:

> ¿qué circuitos han sido históricamente más caóticos o problemáticos?

Mide:

- tasa de no clasificación,
- peso de fallos mecánicos,
- incidentes,
- descalificaciones,
- conversión pole-victoria por circuito.

### 7.6 `mart_qualifying_effect_season`

Resuelve la pregunta:

> ¿qué tan importante es la clasificación para el resultado final?

Mide:

- conversión de pole en victoria,
- podios desde primera fila,
- grid promedio del ganador,
- relación entre posición de salida y posición final.

### 7.7 `mart_race_weekend`

Resuelve el resumen ejecutivo de una carrera en una sola estructura.

Integra:

- ganador,
- pole,
- podio,
- tasa de no clasificación,
- actividad en pits,
- puntos otorgados,
- y datos del circuito.

## 8. KPI oficiales materializados

La capa `Gold` formalizó `10` KPIs oficiales.

Valores actuales validados:

| KPI | Valor |
| --- | ---: |
| Temporadas cubiertas | 75 |
| Carreras registradas | 1125 |
| Pilotos registrados | 861 |
| Escuderías registradas | 212 |
| Tasa de clasificación | 56.66% |
| Tasa de no clasificación | 43.34% |
| Puntos promedio por entrada | 2.01 |
| Conversión pole a victoria | 42.64% |
| Participación de fines de semana sprint | 1.60% |
| Participaciones con shared drive | 0.66% |

## 9. Estado final de `Gold`

Al cierre del trabajo, `F1_gold` quedó con:

- `7` tablas,
- `8` vistas,
- `10` KPIs materializados en el snapshot actual.

Conteos validados:

| Objeto | Filas |
| --- | ---: |
| `mart_driver_season` | 3211 |
| `mart_constructor_season` | 1111 |
| `mart_circuit_risk` | 77 |
| `mart_qualifying_effect_season` | 31 |
| `mart_race_weekend` | 1125 |
| `mart_kpi_snapshot` | 10 |

## 10. Validación y cierre de `Gold`

Decir que `Gold` quedó finalizada significa que:

- la capa ya tiene indicadores oficiales,
- ya tiene resúmenes reutilizables por tema,
- ya tiene vistas listas para exposición,
- ya puede alimentar dashboard,
- y ya no depende de construir consultas complejas en vivo.

En términos profesionales, `Gold` convirtió el modelo analítico en un producto final de consumo.

## 11. Relación con `F1_control`

Una parte importante del cierre de `Gold` fue no dejarlo aislado operativamente.  
Por eso se creó:

- `F1_control`

Y dentro de ella:

- `f1_gold_kpi_snapshot_history`

Su función es guardar snapshots históricos de los KPIs de `Gold`.

Esto permite:

- congelar cortes oficiales,
- comparar versiones del tablero,
- y mantener trazabilidad de indicadores en el tiempo.

## 12. Relación con el dashboard

La capa `Gold` fue conectada a una aplicación `Streamlit` para visualización ejecutiva.

La app consume directamente:

- `F1_gold`
- `F1_control`

Qué permite mostrar:

- KPIs,
- campeonatos por temporada,
- liderazgo histórico,
- circuitos de riesgo,
- impacto de clasificación,
- carreras recientes,
- historial de snapshots.

Esto demuestra que `Gold` no quedó solo como diseño de base de datos, sino como capa real de consumo.

## 13. Mensaje clave para la presentación

La idea principal que debes comunicar es esta:

> `Gold` fue la etapa donde el proyecto dejó de hablar en tablas técnicas y empezó a hablar en métricas, resúmenes y decisiones de negocio.

## 14. Estructura sugerida para la presentación

### Diapositiva 1. Título

`Construcción y finalización de la capa Gold del proyecto F1`

Qué decir:

- se explicará cómo se pasó de una capa analítica curada a una capa ejecutiva lista para dashboard.

### Diapositiva 2. Punto de partida

Contenido:

- `Silver` como base ya limpia y consistente
- necesidad de una capa final de consumo

Qué decir:

- `Silver` resolvía calidad y estructura; `Gold` debía resolver consumo y negocio.

### Diapositiva 3. Problema a resolver

Contenido:

- capa técnica demasiado detallada
- falta de KPIs oficiales
- ausencia de marts ejecutivos
- necesidad de dashboard y storytelling

Qué decir:

- `Gold` se construyó para que los resultados pudieran presentarse y entenderse fácilmente.

### Diapositiva 4. Diseño de Gold

Contenido:

- catálogo de KPIs
- marts
- vistas ejecutivas

Qué decir:

- el modelo se organizó en objetos listos para responder preguntas de negocio.

### Diapositiva 5. KPIs oficiales

Contenido:

- temporadas
- carreras
- pilotos
- escuderías
- clasificación
- pole a victoria

Qué decir:

- aquí `Gold` deja de ser detalle y se convierte en resumen ejecutivo.

### Diapositiva 6. Marts construidos

Contenido:

- pilotos por temporada
- escuderías por temporada
- riesgo por circuito
- clasificación vs resultado
- resumen por carrera

Qué decir:

- los marts convierten preguntas frecuentes en estructuras listas para consumo.

### Diapositiva 7. Vistas ejecutivas

Contenido:

- tarjetas KPI
- líderes históricos
- circuitos más caóticos
- highlights recientes

Qué decir:

- las vistas simplifican la exposición y el dashboard.

### Diapositiva 8. Estado final

Contenido:

- `7` tablas
- `8` vistas
- `10` KPIs
- conteos validados

Qué decir:

- en este punto `Gold` ya estaba lista para ser consumida por usuarios y no solo por desarrolladores.

### Diapositiva 9. Conexión con Control y dashboard

Contenido:

- snapshots en `F1_control`
- dashboard `Streamlit`

Qué decir:

- `Gold` se cerró como producto porque además de calcular métricas, quedó visualizable y versionable.

### Diapositiva 10. Cierre

Mensaje final sugerido:

> La capa `Gold` fue la pieza que convirtió una base analítica en una herramienta de lectura ejecutiva del desempeño histórico de la Fórmula 1.

## 15. Cierre profesional

Si necesitas resumir todo en una sola idea para exponer, usa esta:

> `Silver` preparó los datos; `Gold` los convirtió en información lista para entender, comparar y presentar.

Ese mensaje deja muy clara la función de `Gold` dentro del proyecto completo.
