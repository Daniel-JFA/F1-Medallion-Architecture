# Guia De Publicacion: Streamlit + Databricks

## Objetivo

Publicar el dashboard `app.py` en Streamlit Cloud usando Databricks como backend.

El token de Databricks no debe guardarse en Git. Debe cargarse como secret en Streamlit Cloud.

## 1. Preparar Repositorio

Confirmar que no exista ningun token real en archivos:

```bash
rg "dapi" .
```

El unico archivo de referencia permitido es:

```text
.streamlit/secrets.example.toml
```

Ese archivo no contiene tokens reales.

## 2. Subir A GitHub

Repositorio esperado:

```text
git@github.com:Daniel-JFA/F1-Medallion-Architecture.git
```

Comandos:

```bash
git status
git add .
git commit -m "Prepare Databricks Streamlit publication"
git push origin main
```

Si la rama no se llama `main`, usar:

```bash
git branch --show-current
git push origin NOMBRE_RAMA
```

## 3. Crear App En Streamlit Cloud

1. Entrar a Streamlit Cloud.
2. Elegir `New app`.
3. Seleccionar el repositorio de GitHub.
4. Archivo principal:

```text
app.py
```

5. Python dependencies:

```text
requirements.txt
```

## 4. Configurar Secrets

En Streamlit Cloud, abrir:

```text
App settings -> Secrets
```

Pegar:

```toml
DATABRICKS_TOKEN = "TOKEN_ACTUAL_O_NUEVO"
DATABRICKS_SERVER_HOSTNAME = "dbc-27294608-e1ce.cloud.databricks.com"
DATABRICKS_HTTP_PATH = "/sql/1.0/warehouses/14f76675cb754d43"
DATABRICKS_CATALOG = "f1"
```

Para esta entrega se puede usar el token actual. Despues de publicar y validar, revocar ese token y reemplazarlo por uno nuevo en Streamlit Cloud.

## 5. Validar Dashboard

Revisar que carguen estas secciones:

- Resumen Ejecutivo
- Campeonatos
- Liderazgo Historico
- Circuitos y Riesgo
- Clasificacion
- Carreras Recientes
- KPIs Versionados
- Arquitectura

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

## 6. Evidencia Para Entrega

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

## 7. Despues De Publicar

Revocar el token usado en la entrega inicial.

Crear uno nuevo en Databricks y reemplazarlo en:

```text
Streamlit Cloud -> App settings -> Secrets
```
