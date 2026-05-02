# Guia De Publicacion: Streamlit + Databricks

## Objetivo

Publicar el dashboard `app.py` en Streamlit Cloud usando Databricks como backend.

El token de Databricks no debe guardarse en Git. Debe cargarse como secret en Streamlit Cloud.

## Estado GitHub

GitHub ya quedo preparado y actualizado.

Repositorio:

```text
https://github.com/Daniel-JFA/F1-Medallion-Architecture
```

Rama:

```text
main
```

Ultimo commit publicado:

```text
c86556f Prepare Databricks Streamlit publication
```

Validaciones realizadas:

- El repo fue empujado a `origin/main`.
- No hay token `dapi...` escrito en archivos del proyecto.
- `app.py` lee credenciales desde variables de entorno o Streamlit secrets.
- Existe `.streamlit/secrets.example.toml` como plantilla sin secretos reales.
- `.streamlit/secrets.toml` esta ignorado por Git.

## Paso 1. Entrar A Streamlit Cloud

Ir a:

```text
https://share.streamlit.io/
```

Iniciar sesion con GitHub.

Si Streamlit Cloud pide permisos sobre GitHub, autorizar acceso al repositorio:

```text
Daniel-JFA/F1-Medallion-Architecture
```

## Paso 2. Crear Una Nueva App

En Streamlit Cloud:

1. Clic en `Create app` o `New app`.
2. Elegir `Deploy a public app from GitHub` o equivalente.
3. Seleccionar:

```text
Repository: Daniel-JFA/F1-Medallion-Architecture
Branch: main
Main file path: app.py
```

Si aparece campo de app URL/name, usar algo como:

```text
f1-medallion-analytics
```

## Paso 3. Confirmar Dependencias

Streamlit Cloud detecta automaticamente:

```text
requirements.txt
```

Ese archivo contiene:

```text
streamlit
pandas
plotly
databricks-sql-connector
```

No hay que instalar nada manualmente.

## Paso 4. Configurar Secrets

Antes de desplegar, o despues desde `App settings`, abrir la seccion `Secrets`.

Pegar exactamente este bloque. En `DATABRICKS_TOKEN`, poner el token actual de Databricks que se va a usar para la demo:

```toml
DATABRICKS_TOKEN = "PEGAR_TOKEN_ACTUAL_AQUI"
DATABRICKS_SERVER_HOSTNAME = "dbc-27294608-e1ce.cloud.databricks.com"
DATABRICKS_HTTP_PATH = "/sql/1.0/warehouses/14f76675cb754d43"
DATABRICKS_CATALOG = "f1"
```

Importante:

- No pegar el token en GitHub.
- No crear `.streamlit/secrets.toml` con el token real dentro del repo.
- El token solo debe vivir en Streamlit Cloud Secrets.

## Paso 5. Deploy

Hacer clic en:

```text
Deploy
```

La primera ejecucion puede tardar unos minutos porque instala dependencias.

Si aparece un error de importacion, revisar que `requirements.txt` tenga:

```text
databricks-sql-connector>=3.5,<5
```

Si aparece error de conexion, revisar:

- token,
- hostname,
- HTTP path,
- permisos del SQL Warehouse,
- que el warehouse este encendido o pueda iniciar.

## Paso 6. Validar El Dashboard

Revisar que carguen estas secciones:

- Resumen Ejecutivo
- Campeonatos
- Liderazgo Historico
- Circuitos y Riesgo
- Clasificacion
- Carreras Recientes
- KPIs Versionados
- Arquitectura

Validar que las tarjetas KPI aparezcan. El valor esperado es que existan 10 KPIs.

El dashboard debe consultar:

- `f1_gold.vw_dashboard_kpi_cards`
- `f1_gold.kpi_catalog`
- `f1_gold.mart_driver_season`
- `f1_gold.mart_constructor_season`
- `f1_gold.vw_dashboard_top_drivers`
- `f1_gold.vw_dashboard_top_constructors`
- `f1_gold.vw_dashboard_circuit_risk`
- `f1_gold.mart_qualifying_effect_season`
- `f1_gold.mart_race_weekend`
- `f1_control.f1_gold_kpi_snapshot_history`

## Paso 7. Validar Databricks

En Databricks o DBeaver, confirmar que existan estos esquemas:

```text
f1
f1_silver
f1_gold
f1_gold_star
f1_control
```

Para demostrar el modelo estrella, mostrar `f1_gold_star` con:

```text
dim_season
dim_driver
dim_constructor
dim_circuit
dim_kpi
fact_driver_season
fact_constructor_season
fact_circuit_risk
fact_qualifying_season
fact_race_weekend
fact_kpi_snapshot
```

Consulta de validacion opcional:

```sql
SELECT COUNT(*) AS kpis
FROM f1_gold.vw_dashboard_kpi_cards;

SELECT COUNT(*) AS driver_season_rows
FROM f1_gold_star.fact_driver_season;
```

Resultados esperados:

```text
kpis = 10
driver_season_rows = 3211
```

## Paso 8. Evidencia Para Entrega

Guardar:

- Link de GitHub.
- Link publico de Streamlit.
- Captura de Databricks con esquemas:
  - `f1`
  - `f1_silver`
  - `f1_gold`
  - `f1_gold_star`
  - `f1_control`
- Captura del modelo estrella `f1_gold_star`.
- Presentacion generada con NotebookLM.

## Paso 9. Entrega Final Recomendada

Entregar:

1. Link de Streamlit publico.
2. Link de GitHub.
3. PDF o presentacion generada con NotebookLM.
4. Captura de Databricks con arquitectura medallon.
5. Captura de `f1_gold_star`.

## Paso 10. Despues De Publicar

Revocar el token usado en la entrega inicial.

Crear uno nuevo en Databricks y reemplazarlo en:

```text
Streamlit Cloud -> App settings -> Secrets
```

No hace falta cambiar codigo para rotar el token.
