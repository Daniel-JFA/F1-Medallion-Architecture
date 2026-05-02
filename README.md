# F1 Gold Streamlit

Dashboard en `Streamlit` para presentar la capa analitica `F1_gold` y el historial de KPIs guardado en `F1_control`.

Este proyecto no trabaja directamente sobre los CSV al momento de visualizar. La app consume bases ya preparadas en MySQL:

```text
CSV originales -> F1 -> F1_silver -> F1_gold -> F1_control -> Streamlit
```

## Estado Validado

Validado el `2026-05-02` sobre MySQL local en Linux. El equipo puede restaurar y ejecutar el mismo proyecto en Windows usando los comandos especificos de Windows que aparecen mas abajo.

- Base fuente: `F1`
- Base curada: `F1_silver`
- Base de consumo: `F1_gold`
- Base de control: `F1_control`
- Snapshot congelado: `equipo_2026_05_02`
- KPIs congelados: `10`
- Dump recomendado para compartir: `sql_exports/F1_full_project_2026_05_02_portable.sql`
- Checksum SHA-256: `sql_exports/F1_full_project_2026_05_02_portable.sql.sha256`
- Manifiesto de consolidacion: `CONSOLIDATION_MANIFEST.md`
- URL local esperada: `http://127.0.0.1:8501`

## Que Incluye El Proyecto

La carpeta principal del dashboard es:

```bash
/home/djfa/Dev/f1_gold_streamlit
```

En Windows, la ruta dependera de donde el equipo copie el proyecto. Un ejemplo posible:

```powershell
C:\Users\TU_USUARIO\Documents\f1_gold_streamlit
```

La carpeta historica donde antes vivian la base, los scripts SQL y muchos respaldos era:

```bash
"/home/djfa/Dev/DBs BackUps"
```

El proyecto quedo consolidado en `f1_gold_streamlit`. La carpeta `DBs BackUps` ya no debe ser necesaria para ejecutar el dashboard ni para restaurar el dump compartible.

Contenido importante:

- `app.py`: dashboard principal en Streamlit.
- `requirements.txt`: dependencias Python del dashboard.
- `.streamlit/config.toml`: tema visual y configuracion de Streamlit.
- `run_streamlit.sh`: inicia el dashboard local.
- `stop_streamlit.sh`: detiene el dashboard local.
- `run_public_tunnel.sh`: abre tunel publico con Cloudflare.
- `stop_public_tunnel.sh`: detiene el tunel publico.
- `CONSOLIDATION_MANIFEST.md`: lista lo que ya fue consolidado dentro de este proyecto.
- `sql_exports/F1_full_project_2026_05_02_portable.sql`: dump SQL portable incluido en este proyecto.
- `sql_exports/F1_full_project_2026_05_02_portable.sql.sha256`: checksum del dump incluido en este proyecto.
- `database/source_csv/DB F1/*.csv`: CSV originales.
- `database/source_csv/import_f1.py`: importador CSV a MySQL.
- `database/mysql/F1_relationships.sql`: crea llaves foraneas sobre `F1`.
- `database/mysql/F1_mysql_silver.sql`: reconstruye `F1_silver`.
- `database/mysql/F1_mysql_gold.sql`: reconstruye `F1_gold`.
- `database/mysql/F1_gold_kpi_history.sql`: guarda snapshots en `F1_control`.
- `database/mysql/F1_refresh_layers.sh`: ejecuta el refresco completo.
- `database/mysql/F1_freeze_kpis.sh`: congela KPIs con una etiqueta.
- `database/databricks/`: scripts y documentacion Databricks.
- `docs/`: documentacion historica y de entrega.
- `assets/F1.png`: diagrama/imagen del proyecto.

## Bases De Datos

### `F1`

Es la base relacional fuente. Sale de los CSV historicos de Formula 1.

Tablas principales:

- `circuits`
- `constructors`
- `drivers`
- `seasons`
- `races`
- `results`
- `sprint_results`
- `qualifying`
- `lap_times`
- `pit_stops`
- `driver_standings`
- `constructor_standings`
- `constructor_results`
- `status`

### `F1_silver`

Es la capa curada. Normaliza dimensiones, hechos y columnas analiticas. Sirve como base confiable para Gold.

Objetos principales:

- `dim_drivers`
- `dim_constructors`
- `dim_circuits`
- `dim_status`
- `dim_seasons`
- `dim_races`
- `fact_results`
- `fact_sprint_results`
- `fact_constructor_results`
- `fact_qualifying`
- `fact_lap_times`
- `fact_pit_stops`
- `fact_driver_standings`
- `fact_constructor_standings`
- `fact_race_entries`
- `vw_silver_summary`
- `vw_data_quality_checks`

### `F1_gold`

Es la capa de consumo para dashboard y presentacion. Materializa marts y vistas ejecutivas.

Tablas principales:

- `kpi_catalog`
- `mart_kpi_snapshot`
- `mart_driver_season`
- `mart_constructor_season`
- `mart_circuit_risk`
- `mart_qualifying_effect_season`
- `mart_race_weekend`

Vistas principales:

- `vw_dashboard_kpi_cards`
- `vw_dashboard_top_drivers`
- `vw_dashboard_top_constructors`
- `vw_dashboard_circuit_risk`
- `vw_dashboard_qualifying_effect_recent`
- `vw_dashboard_latest_driver_championship`
- `vw_dashboard_latest_constructor_championship`
- `vw_dashboard_recent_race_highlights`

### `F1_control`

Es la base de control. Guarda historicos versionados de KPIs para clase, demo, entrega o comparacion.

Tabla principal:

- `f1_gold_kpi_snapshot_history`

## Que Muestra El Dashboard

- KPIs oficiales de la capa Gold.
- Campeonato de pilotos por temporada.
- Campeonato de constructores por temporada.
- Liderazgo historico de pilotos y escuderias.
- Circuitos con mayor nivel de riesgo o caos.
- Impacto de la clasificacion en los resultados.
- Resumen narrativo de carreras recientes.
- Historial versionado de snapshots de KPIs.
- Arquitectura del flujo Bronze, F1, Silver, Gold y Control.

## Requisitos

- Python `3.10+`
- MySQL o MariaDB local/remoto
- Cliente de MySQL en el `PATH` para poder usar `mysql` desde terminal
- Usuario MySQL con permisos para crear bases, tablas, vistas e insertar datos
- Dependencias Python del archivo `requirements.txt`

En Windows, si `mysql` no se reconoce en PowerShell o CMD, agregar al `PATH` la carpeta `bin` de MySQL. Suele estar en una ruta parecida a:

```text
C:\Program Files\MySQL\MySQL Server 8.0\bin
```

Valores usados en la maquina local:

```bash
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=root
```

## Instalacion Del Dashboard En Linux

```bash
cd /home/djfa/Dev/f1_gold_streamlit
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Instalacion Del Dashboard En Windows

Abrir PowerShell en la carpeta donde se copio el proyecto:

```powershell
cd C:\Users\TU_USUARIO\Documents\f1_gold_streamlit
py -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

Si PowerShell bloquea la activacion del entorno virtual, ejecutar una vez:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Luego cerrar y abrir PowerShell de nuevo, y repetir:

```powershell
.\.venv\Scripts\Activate.ps1
```

Alternativa usando CMD:

```cmd
cd C:\Users\TU_USUARIO\Documents\f1_gold_streamlit
py -m venv .venv
.venv\Scripts\activate.bat
python -m pip install -r requirements.txt
```

## Restaurar El Dump Compartible

El dump completo ya existe en:

```text
sql_exports/F1_full_project_2026_05_02_portable.sql
```

Ese archivo contiene las cuatro bases:

- `F1`
- `F1_silver`
- `F1_gold`
- `F1_control`

### Restaurar En Linux

```bash
cd /home/djfa/Dev/f1_gold_streamlit
mysql --ssl=0 -h 127.0.0.1 -P 3306 -uroot -proot < sql_exports/F1_full_project_2026_05_02_portable.sql
```

### Restaurar En Windows PowerShell

Desde PowerShell, la forma mas estable es pedirle a `cmd` que haga la redireccion del archivo SQL:

```powershell
cd C:\Users\TU_USUARIO\Documents\f1_gold_streamlit
cmd /c "mysql --ssl=0 -h 127.0.0.1 -P 3306 -uroot -proot < sql_exports\F1_full_project_2026_05_02_portable.sql"
```

Tambien se puede usar CMD directamente:

```cmd
cd C:\Users\TU_USUARIO\Documents\f1_gold_streamlit
mysql --ssl=0 -h 127.0.0.1 -P 3306 -uroot -proot < sql_exports\F1_full_project_2026_05_02_portable.sql
```

Si el equipo usa otro usuario o password, cambiar credenciales. En Linux o CMD:

```bash
mysql --ssl=0 -h TU_HOST -P TU_PUERTO -uTU_USUARIO -p < sql_exports/F1_full_project_2026_05_02_portable.sql
```

En PowerShell:

```powershell
cmd /c "mysql --ssl=0 -h TU_HOST -P TU_PUERTO -uTU_USUARIO -p < sql_exports\F1_full_project_2026_05_02_portable.sql"
```

Despues de restaurar, validar en Linux, PowerShell o CMD:

```bash
mysql --ssl=0 -h 127.0.0.1 -P 3306 -uroot -proot -e "SHOW DATABASES LIKE 'F1%';"
```

Resultado esperado:

```text
F1
F1_control
F1_gold
F1_silver
```

## Validar El Checksum Del Dump

En Linux:

```bash
cd /home/djfa/Dev/f1_gold_streamlit/sql_exports
sha256sum -c F1_full_project_2026_05_02_portable.sql.sha256
```

En Windows PowerShell:

```powershell
cd C:\Users\TU_USUARIO\Documents\f1_gold_streamlit\sql_exports
Get-FileHash .\F1_full_project_2026_05_02_portable.sql -Algorithm SHA256
Get-Content .\F1_full_project_2026_05_02_portable.sql.sha256
```

El hash calculado debe coincidir con el hash guardado en el archivo `.sha256`.

## Reconstruir Capas Desde La Base `F1`

Para el equipo en Windows, lo recomendado es restaurar el dump portable incluido en `sql_exports`. Esta seccion es para reconstruir las capas desde la base `F1` cuando se trabaja en Linux o WSL.

Si ya existe `F1` y quieres regenerar Silver, Gold y Control:

```bash
cd /home/djfa/Dev/f1_gold_streamlit/database/mysql
./F1_refresh_layers.sh equipo_2026_05_02
```

Ese comando hace lo siguiente:

1. Aplica relaciones en `F1` con `F1_relationships.sql`.
2. Reconstruye `F1_silver` con `F1_mysql_silver.sql`.
3. Reconstruye `F1_gold` con `F1_mysql_gold.sql`.
4. Congela KPIs en `F1_control` usando la etiqueta indicada.
5. Ejecuta validaciones rapidas de conteos, foreign keys y KPIs.

Para refrescar sin congelar snapshot:

```bash
cd /home/djfa/Dev/f1_gold_streamlit/database/mysql
./F1_refresh_layers.sh
```

Para congelar KPIs despues de un refresco:

```bash
cd /home/djfa/Dev/f1_gold_streamlit/database/mysql
./F1_freeze_kpis.sh nombre_del_snapshot
```

## Generar Un Nuevo Dump

Cuando las bases ya esten listas, generar un respaldo nuevo:

```bash
cd /home/djfa/Dev/f1_gold_streamlit
mkdir -p sql_exports
mysqldump --ssl=0 \
  -h 127.0.0.1 \
  -P 3306 \
  -uroot \
  -proot \
  --single-transaction \
  --routines \
  --events \
  --triggers \
  --databases F1 F1_silver F1_gold F1_control \
  > sql_exports/F1_full_project_YYYY_MM_DD.sql
```

El dump recomendado para compartir ahora es la version portable incluida dentro de este proyecto, sin `DEFINER` fijo de MySQL:

```text
sql_exports/F1_full_project_2026_05_02_portable.sql
```

## Ejecutar El Dashboard En Linux

Desde la carpeta del dashboard:

```bash
cd /home/djfa/Dev/f1_gold_streamlit
source .venv/bin/activate
streamlit run app.py
```

O usando el lanzador preparado:

```bash
/home/djfa/Dev/f1_gold_streamlit/run_streamlit.sh
```

Para detenerlo:

```bash
./stop_streamlit.sh
```

El lanzador:

- reutiliza la instancia si ya esta corriendo
- escucha en `0.0.0.0`
- busca un puerto libre desde `8501`
- abre el navegador si `xdg-open` esta disponible
- deja el log en `/home/djfa/Dev/f1_gold_streamlit/logs/streamlit.log`
- guarda PID y puerto en `/home/djfa/Dev/f1_gold_streamlit/logs`
- evita el prompt inicial de onboarding de Streamlit

## Ejecutar El Dashboard En Windows

Desde PowerShell:

```powershell
cd C:\Users\TU_USUARIO\Documents\f1_gold_streamlit
.\.venv\Scripts\Activate.ps1
streamlit run app.py
```

Desde CMD:

```cmd
cd C:\Users\TU_USUARIO\Documents\f1_gold_streamlit
.venv\Scripts\activate.bat
streamlit run app.py
```

Abrir en el navegador:

```text
http://127.0.0.1:8501
```

Nota: los scripts `.sh` (`run_streamlit.sh`, `stop_streamlit.sh`, `run_public_tunnel.sh`) estan pensados para Linux. En Windows es mas simple ejecutar `streamlit run app.py` desde el entorno virtual.

## Publicar Temporalmente Con Tunel

Esta seccion aplica a Linux con los scripts incluidos. En Windows se recomienda no usar el tunel salvo que el equipo instale y configure `cloudflared` manualmente.

Para abrir un tunel publico:

```bash
./run_public_tunnel.sh
```

Para detenerlo:

```bash
./stop_public_tunnel.sh
```

Advertencia: el tunel publico expone el dashboard. Usarlo solo para demos controladas y no dejarlo abierto innecesariamente.

## Variables De Conexion

La app toma estos valores por defecto si no se cambian en la barra lateral:

```bash
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=root
```

Tambien pueden exportarse antes de correr.

En Linux:

```bash
export MYSQL_HOST=127.0.0.1
export MYSQL_PORT=3306
export MYSQL_USER=root
export MYSQL_PASSWORD=root
```

En Windows PowerShell:

```powershell
$env:MYSQL_HOST="127.0.0.1"
$env:MYSQL_PORT="3306"
$env:MYSQL_USER="root"
$env:MYSQL_PASSWORD="root"
```

En Windows CMD:

```cmd
set MYSQL_HOST=127.0.0.1
set MYSQL_PORT=3306
set MYSQL_USER=root
set MYSQL_PASSWORD=root
```

## Validaciones Utiles

Ver bases creadas:

```bash
mysql --ssl=0 -h 127.0.0.1 -P 3306 -uroot -proot -e "SHOW DATABASES LIKE 'F1%';"
```

Ver objetos por base:

```bash
mysql --ssl=0 -h 127.0.0.1 -P 3306 -uroot -proot -e "
SELECT table_schema, COUNT(*) AS objects
FROM information_schema.tables
WHERE table_schema IN ('F1','F1_silver','F1_gold','F1_control')
GROUP BY table_schema
ORDER BY table_schema;"
```

Ver KPIs actuales:

```bash
mysql --ssl=0 -h 127.0.0.1 -P 3306 -uroot -proot -D F1_gold -e "SELECT * FROM vw_dashboard_kpi_cards;"
```

Ver snapshots guardados:

```bash
mysql --ssl=0 -h 127.0.0.1 -P 3306 -uroot -proot -D F1_control -e "
SELECT snapshot_label, source_schema, COUNT(*) AS frozen_kpis, MIN(snapshot_taken_at) AS snapshot_taken_at
FROM f1_gold_kpi_snapshot_history
GROUP BY snapshot_label, source_schema
ORDER BY snapshot_taken_at DESC;"
```

## Solucion De Problemas

### La app abre, pero no carga datos

Validar que existan las bases:

```bash
mysql --ssl=0 -h 127.0.0.1 -P 3306 -uroot -proot -e "SHOW DATABASES LIKE 'F1%';"
```

Si faltan `F1_silver`, `F1_gold` o `F1_control`, ejecutar:

```bash
cd /home/djfa/Dev/f1_gold_streamlit/database/mysql
./F1_refresh_layers.sh equipo_2026_05_02
```

En Windows, si faltan esas bases, restaurar de nuevo el dump:

PowerShell:

```powershell
cmd /c "mysql --ssl=0 -h 127.0.0.1 -P 3306 -uroot -proot < sql_exports\F1_full_project_2026_05_02_portable.sql"
```

CMD:

```cmd
mysql --ssl=0 -h 127.0.0.1 -P 3306 -uroot -proot < sql_exports\F1_full_project_2026_05_02_portable.sql
```

### La app no abre en el navegador

Revisar la URL impresa por el lanzador. Si no aparece, abrir manualmente:

```text
http://127.0.0.1:8501
```

### Ver error exacto del arranque

Linux:

```bash
tail -n 100 /home/djfa/Dev/f1_gold_streamlit/logs/streamlit.log
```

Windows: revisar la salida de la terminal donde se ejecuto `streamlit run app.py`.

### Reiniciar por completo

```bash
cd /home/djfa/Dev/f1_gold_streamlit
./stop_streamlit.sh
./run_streamlit.sh
```

## Resumen Para El Equipo

Para recibir el proyecto ya armado, el equipo solo necesita:

1. Tener MySQL o MariaDB disponible.
2. Restaurar `F1_full_project_2026_05_02_portable.sql`.
3. Instalar dependencias Python con `pip install -r requirements.txt`.
4. Ejecutar el dashboard.
5. Abrir `http://127.0.0.1:8501`.

En Linux se puede usar `run_streamlit.sh`. En Windows usar `streamlit run app.py`.

Con el dump restaurado no hace falta correr los scripts de reconstruccion. Los scripts quedan disponibles para refrescar las capas cuando cambie la fuente `F1`.

## Paso A Paso VAD

Esta guia es para el equipo VAD y asume poca experiencia tecnica. La idea es seguir los pasos en orden, sin saltarse validaciones. Si algo falla, copiar el mensaje de error completo y revisar la seccion de solucion de problemas.

### Objetivo

Al final de este paso a paso, cada persona debe tener:

- Las bases `F1`, `F1_silver`, `F1_gold` y `F1_control` restauradas en MySQL.
- El dashboard instalado en Python.
- La app abierta en el navegador.
- Los KPIs visibles en `http://127.0.0.1:8501`.

### Archivos Que Deben Estar En La Carpeta

Dentro de la carpeta del proyecto deben existir estos archivos:

```text
f1_gold_streamlit/
  app.py
  README.md
  requirements.txt
  sql_exports/
    F1_full_project_2026_05_02_portable.sql
    F1_full_project_2026_05_02_portable.sql.sha256
```

El archivo mas pesado es:

```text
sql_exports/F1_full_project_2026_05_02_portable.sql
```

Ese archivo contiene toda la base de datos lista para restaurar.

### Paso 1. Instalar MySQL

En Windows:

1. Instalar MySQL Community Server o MariaDB.
2. Recordar el usuario y la contrasena configurados durante la instalacion.
3. Para seguir esta guia sin cambios, usar:

```text
usuario: root
password: root
host: 127.0.0.1
puerto: 3306
```

Si se usa otra contrasena, reemplazar `-proot` por `-pTU_PASSWORD` en los comandos.

Importante: verificar que el comando `mysql` funcione en PowerShell o CMD:

```cmd
mysql --version
```

Si Windows dice que `mysql` no se reconoce, agregar esta carpeta al `PATH`:

```text
C:\Program Files\MySQL\MySQL Server 8.0\bin
```

### Paso 2. Instalar Python

En Windows:

1. Instalar Python 3.10 o superior.
2. Durante la instalacion, marcar la opcion `Add Python to PATH`.
3. Verificar en PowerShell:

```powershell
py --version
```

Debe mostrar una version parecida a:

```text
Python 3.10.x
```

### Paso 3. Abrir La Carpeta Del Proyecto

En Windows PowerShell, ir a la carpeta donde se descargo o copio el proyecto. Ejemplo:

```powershell
cd C:\Users\TU_USUARIO\Documents\f1_gold_streamlit
```

Confirmar que estan los archivos:

```powershell
dir
dir .\sql_exports
```

Debe aparecer el archivo:

```text
F1_full_project_2026_05_02_portable.sql
```

### Paso 4. Validar Que El Dump No Se Dano Al Copiarlo

En PowerShell:

```powershell
cd C:\Users\TU_USUARIO\Documents\f1_gold_streamlit\sql_exports
Get-FileHash .\F1_full_project_2026_05_02_portable.sql -Algorithm SHA256
Get-Content .\F1_full_project_2026_05_02_portable.sql.sha256
```

Comparar el hash que muestra `Get-FileHash` con el hash del archivo `.sha256`.

El valor esperado es:

```text
1c439007e51efbd154a3ee11be4252224c9d6bc650e031dbc3e17f1e98676e38
```

Si no coincide, volver a copiar el archivo SQL.

### Paso 5. Restaurar Las Bases En MySQL

Volver a la carpeta principal del proyecto:

```powershell
cd C:\Users\TU_USUARIO\Documents\f1_gold_streamlit
```

Restaurar usando PowerShell:

```powershell
cmd /c "mysql --ssl=0 -h 127.0.0.1 -P 3306 -uroot -proot < sql_exports\F1_full_project_2026_05_02_portable.sql"
```

Si la contrasena no es `root`, ejemplo con password `1234`:

```powershell
cmd /c "mysql --ssl=0 -h 127.0.0.1 -P 3306 -uroot -p1234 < sql_exports\F1_full_project_2026_05_02_portable.sql"
```

Este paso puede tardar. No cerrar la terminal mientras esta trabajando.

### Paso 6. Confirmar Que Las Bases Quedaron Creadas

Ejecutar:

```powershell
mysql --ssl=0 -h 127.0.0.1 -P 3306 -uroot -proot -e "SHOW DATABASES LIKE 'F1%';"
```

Resultado esperado:

```text
F1
F1_control
F1_gold
F1_silver
```

Si no aparecen las cuatro bases, repetir el paso 5 y revisar que la contrasena sea correcta.

### Paso 7. Crear El Entorno Python

En PowerShell, desde la carpeta del proyecto:

```powershell
cd C:\Users\TU_USUARIO\Documents\f1_gold_streamlit
py -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

Si PowerShell bloquea la activacion, ejecutar:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Cerrar PowerShell, abrirlo otra vez, volver a la carpeta y activar:

```powershell
cd C:\Users\TU_USUARIO\Documents\f1_gold_streamlit
.\.venv\Scripts\Activate.ps1
```

### Paso 8. Ejecutar El Dashboard

Con el entorno virtual activado, ejecutar:

```powershell
streamlit run app.py
```

Streamlit mostrara una URL parecida a:

```text
Local URL: http://localhost:8501
```

Abrir en el navegador:

```text
http://127.0.0.1:8501
```

### Paso 9. Configurar La Conexion En La Barra Lateral

En el dashboard, revisar la barra lateral `Conexion`.

Valores esperados:

```text
Host: 127.0.0.1
Puerto: 3306
Usuario: root
Contrasena: root
```

Si el equipo uso otra contrasena de MySQL, escribir esa contrasena en la barra lateral.

Luego presionar `Recargar datos` si la app ya estaba abierta.

### Paso 10. Validar Que La App Esta Bien

La app debe mostrar:

- Tarjetas de KPIs en `Resumen Ejecutivo`.
- Campeonatos por temporada.
- Liderazgo historico.
- Circuitos y riesgo.
- Clasificacion.
- Carreras recientes.
- KPIs versionados.

En `KPIs Versionados` debe existir el snapshot:

```text
equipo_2026_05_02
```

### Paso 11. Apagar La App

Para detener Streamlit:

1. Volver a la terminal donde corre `streamlit run app.py`.
2. Presionar `Ctrl + C`.

### Paso 12. Como Volver A Abrir Otro Dia

No hay que restaurar la base otra vez si MySQL conserva las bases.

Solo hacer:

```powershell
cd C:\Users\TU_USUARIO\Documents\f1_gold_streamlit
.\.venv\Scripts\Activate.ps1
streamlit run app.py
```

Abrir:

```text
http://127.0.0.1:8501
```

### Problemas Comunes Del Equipo VAD

#### `mysql` no se reconoce

Agregar MySQL al `PATH` o abrir la terminal desde la carpeta `bin` de MySQL.

Ruta comun:

```text
C:\Program Files\MySQL\MySQL Server 8.0\bin
```

#### `Access denied for user 'root'`

La contrasena no es `root`. Cambiar `-proot` por la contrasena correcta:

```powershell
cmd /c "mysql --ssl=0 -h 127.0.0.1 -P 3306 -uroot -pTU_PASSWORD < sql_exports\F1_full_project_2026_05_02_portable.sql"
```

#### PowerShell no deja activar `.venv`

Ejecutar:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Luego cerrar y abrir PowerShell.

#### La app abre pero no carga datos

Validar las bases:

```powershell
mysql --ssl=0 -h 127.0.0.1 -P 3306 -uroot -proot -e "SHOW DATABASES LIKE 'F1%';"
```

Si faltan bases, repetir la restauracion del paso 5.

#### El navegador no abre solo

Abrir manualmente:

```text
http://127.0.0.1:8501
```

### Mini Resumen VAD

Para Windows, el orden corto es:

```powershell
cd C:\Users\TU_USUARIO\Documents\f1_gold_streamlit
cmd /c "mysql --ssl=0 -h 127.0.0.1 -P 3306 -uroot -proot < sql_exports\F1_full_project_2026_05_02_portable.sql"
py -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
streamlit run app.py
```

Luego abrir:

```text
http://127.0.0.1:8501
```
