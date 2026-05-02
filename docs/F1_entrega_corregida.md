# Entrega Corregida - Taller SQL F1

## Archivos de la entrega

- Reporte: `F1_entrega_corregida.md`
- SQL ejecutable: `F1_taller_consultas_corregidas.sql`

## Validacion

Las consultas de esta entrega fueron revisadas y ejecutadas directamente sobre la base local `F1` en MySQL.

Datos base del analisis:

- Rango historico de temporadas disponible: `1950` a `2024`
- Tabla pivote del modelo: `races`
- Tablas principales usadas: `results`, `drivers`, `constructors`, `races`, `circuits`, `status`, `pit_stops`, `lap_times`

## Cumplimiento del taller

- `15` consultas ejecutadas
- `14` consultas con `JOIN`
- `13` consultas con agregaciones (`SUM`, `COUNT`, `AVG`)
- `6` consultas con `HAVING`
- `4` consultas con `LIKE` o filtros avanzados
- `1` consulta con `CTE (WITH)`
- `2` vistas permanentes con `CREATE OR REPLACE VIEW`

## Desarrollo

El objetivo del trabajo fue analizar el rendimiento historico de pilotos, escuderias y circuitos de Formula 1 usando consultas SQL sobre una base relacional. Para ello se formularon preguntas enfocadas en consistencia competitiva, dominancia por temporada, eficiencia operativa, comportamiento de los circuitos y tendencias historicas.

La entrega fue reorganizada para que cada consulta responda exactamente a la pregunta planteada y para que la documentacion muestre resultados reales obtenidos desde la base.

## Resumen de consultas

| Query | Tema | Recursos SQL destacados |
| --- | --- | --- |
| Q1 | Top 5 de salida por piloto | `JOIN`, `SUM`, `AVG`, `HAVING` |
| Q2 | Mas victorias por temporada | `JOIN`, `COUNT`, `RANK()` |
| Q3 | Promedio de pit stop por escuderia | `JOIN`, `AVG`, `HAVING` |
| Q4 | Escuderia lider por circuito | `JOIN`, `SUM`, `RANK()` |
| Q5 | Mejor promedio de salida | `JOIN`, `AVG`, `HAVING` |
| Q6 | Circuitos mas caoticos | `JOIN`, `CASE`, `HAVING`, filtros |
| Q7 | Promedio de puntos por piloto | `JOIN`, `AVG`, `HAVING` |
| Q8 | Carreras por temporada | `COUNT` |
| Q9 | Puntos acumulados 2005-2024 | `JOIN`, `SUM` |
| Q10 | Pilotos con mas de 10 podios | `JOIN`, `COUNT`, `HAVING` |
| Q11 | Victorias desde atras | `JOIN`, filtro avanzado |
| Q12 | Dinastias por apellido | `JOIN`, `LIKE`, `SUM` |
| Q13 | Nacionalidades tradicionales | `JOIN`, `REGEXP`, `SUM` |
| Q14 | Vuelta mas rapida por carrera | `JOIN`, `ROW_NUMBER()` |
| Q15 | Ranking en ultimas 5 temporadas | `WITH`, `SUM`, `RANK()` |

## Consultas documentadas

### Q1. Pilotos con mayor frecuencia en el top 5 de salida

**Objetivo**  
Identificar que pilotos han largado con mayor frecuencia dentro de las cinco primeras posiciones, considerando solo aquellos con al menos 20 carreras registradas.

**Resultado destacado**

```text
piloto                total_carreras  veces_top5  promedio_salida
Lewis Hamilton        355             273         4.31
Michael Schumacher    308             215         4.87
Sebastian Vettel      298             173         6.31
Alain Prost           201             159         4.16
Kimi Räikkönen        347             156         7.64
```

**Interpretacion**  
Lewis Hamilton y Michael Schumacher destacan por su frecuencia de salidas en posiciones privilegiadas, lo que refleja consistencia historica en clasificacion.

### Q2. Piloto(s) con mas victorias por temporada

**Objetivo**  
Obtener al piloto con mayor cantidad de victorias en cada temporada, incluyendo empates cuando existan.

**Resultado destacado**

```text
year  piloto             wins
2024  Max Verstappen     9
2023  Max Verstappen     19
2022  Max Verstappen     15
2021  Max Verstappen     10
2020  Lewis Hamilton     11
```

**Interpretacion**  
La consulta confirma ciclos claros de dominancia. En las temporadas mas recientes resalta el control competitivo de Max Verstappen.

### Q3. Tiempo promedio de pit stops por escuderia

**Objetivo**  
Comparar la eficiencia operativa en boxes entre escuderias, considerando solo aquellas con al menos 20 pit stops registrados.

**Resultado destacado**

```text
escuderia   total_pitstops  promedio_ms
Virgin      77              24236.19
Lotus       85              24444.21
Lotus F1    285             32463.75
HRT         150             32677.77
Caterham    241             33924.62
```

**Interpretacion**  
Se observan diferencias operativas importantes entre equipos. La consulta permite comparar eficiencia de boxes de manera historica.

### Q4. Escuderia con mas puntos en cada circuito

**Objetivo**  
Determinar que escuderia ha acumulado la mayor cantidad de puntos historicos en cada circuito.

**Resultado destacado**

```text
circuito                          escuderia  total_points
Autodromo Nazionale di Monza      Ferrari    808.5
Circuit de Monaco                 Ferrari    634.5
Silverstone Circuit               Ferrari    583.78
Circuit de Spa-Francorchamps      Ferrari    522.5
Circuit Gilles Villeneuve         Ferrari    466
```

**Interpretacion**  
Ferrari aparece como la escuderia historicamente mas fuerte en varios circuitos tradicionales, especialmente en Monza y Monaco.

### Q5. Pilotos con mejor posicion promedio de salida

**Objetivo**  
Encontrar los pilotos con mejor promedio de salida, considerando solo aquellos con al menos 30 carreras.

**Resultado destacado**

```text
piloto         total_carreras  promedio_salida  mejor_salida  peor_salida
Juan Fangio    58              2.48             1             10
Ayrton Senna   161             3.15             1             19
Nino Farina    37              3.19             1             14
Jim Clark      73              3.60             1             16
Alain Prost    201             4.16             1             24
```

**Interpretacion**  
Pilotos historicos como Fangio y Senna sobresalen por arrancar sistematicamente desde posiciones muy competitivas.

### Q6. Circuitos mas caoticos por porcentaje de abandonos

**Objetivo**  
Identificar los circuitos con mayor nivel de caos competitivo a partir del porcentaje de resultados que terminan en abandono, exigiendo un minimo de 100 resultados historicos.

**Resultado destacado**

```text
circuito                 pais       total_resultados  abandonos  porcentaje_abandonos
Phoenix street circuit   USA        108               78         72.22
Long Beach               USA        220               141        64.09
Detroit Street Circuit   USA        191               121        63.35
Adelaide Street Circuit  Australia  312               195        62.50
Zolder                   Belgium    282               173        61.35
```

**Interpretacion**  
Los circuitos callejeros y urbanos aparecen entre los mas caoticos, con altas tasas historicas de abandono.

### Q7. Promedio de puntos por piloto

**Objetivo**  
Comparar el rendimiento promedio por piloto, tomando solo quienes tienen al menos 30 carreras para evitar casos aislados.

**Resultado destacado**

```text
piloto             total_carreras  promedio_puntos
Max Verstappen     209             13.94
Lewis Hamilton     356             13.54
Sebastian Vettel   300             10.33
Charles Leclerc    149             9.15
Nico Rosberg       206             7.74
```

**Interpretacion**  
Max Verstappen y Lewis Hamilton lideran el promedio historico de puntos entre pilotos con trayectoria amplia.

### Q8. Numero total de carreras por temporada

**Objetivo**  
Mostrar como ha evolucionado el calendario de Formula 1 a lo largo del tiempo.

**Resultado destacado**

```text
temporada  total_carreras
2024       24
2023       22
2022       22
2021       22
2020       17
```

**Interpretacion**  
El campeonato ha crecido de forma clara en numero de eventos, alcanzando calendarios muy extensos en los ultimos anos.

### Q9. Pilotos con mas puntos acumulados entre 2005 y 2024

**Objetivo**  
Analizar que pilotos concentran la mayor cantidad de puntos en las ultimas dos decadas disponibles de la base.

**Resultado destacado**

```text
piloto             puntos_totales
Lewis Hamilton     4820.5
Sebastian Vettel   3098
Max Verstappen     2912.5
Fernando Alonso    2215
Valtteri Bottas    1788
```

**Interpretacion**  
Lewis Hamilton lidera ampliamente el periodo 2005-2024, seguido por Sebastian Vettel y Max Verstappen.

### Q10. Pilotos con mas de 10 podios

**Objetivo**  
Detectar que pilotos han sostenido resultados de elite al terminar repetidamente en el podio.

**Resultado destacado**

```text
piloto                podios
Lewis Hamilton        202
Michael Schumacher    155
Sebastian Vettel      122
Max Verstappen        112
Fernando Alonso       106
```

**Interpretacion**  
La frecuencia de podios deja ver que el exito sostenido en Formula 1 se concentra en una elite muy reducida.

### Q11. Victorias desde posiciones de salida 10 o peores

**Objetivo**  
Encontrar victorias particularmente sorprendentes, logradas por pilotos que partieron desde posiciones poco favorables.

**Resultado destacado**

```text
temporada  carrera                      circuito                     ganador              posicion_salida
1983       United States Grand Prix West Long Beach                 John Watson          22
1954       Indianapolis 500             Indianapolis Motor Speedway Bill Vukovich        19
2000       German Grand Prix            Hockenheimring              Rubens Barrichello   18
2024       São Paulo Grand Prix         Autódromo José Carlos Pace  Max Verstappen       17
2005       Japanese Grand Prix          Suzuka Circuit              Kimi Räikkönen       17
```

**Interpretacion**  
Estas victorias reflejan carreras extraordinarias, donde estrategia, ritmo y contexto permitieron remontadas poco comunes.

### Q12. Pilotos de dinastias o tradicion por apellido

**Objetivo**  
Medir el impacto historico de apellidos emblematicos usando filtros `LIKE`.

**Resultado destacado**

```text
piloto                puntos_totales
Max Verstappen        2912.5
Nico Rosberg          1594.5
Michael Schumacher    1566
Damon Hill            360
Ralf Schumacher       329
```

**Interpretacion**  
La consulta evidencia la continuidad historica de ciertos apellidos dentro de la Formula 1.

### Q13. Nacionalidades tradicionales con mas puntos acumulados

**Objetivo**  
Comparar el peso historico de nacionalidades fuertemente asociadas al automovilismo usando un filtro avanzado con `REGEXP`.

**Resultado destacado**

```text
nacionalidad  puntos_totales
British       11908.64
German        7988.5
Italian       2040.66
```

**Interpretacion**  
Los pilotos britanicos concentran una ventaja historica muy marcada en puntos acumulados.

### Q14. Piloto con la vuelta mas rapida de cada carrera

**Objetivo**  
Identificar al piloto que registro la vuelta mas rapida en cada carrera usando `ROW_NUMBER()`.

**Resultado destacado**

```text
temporada  carrera                  piloto            fastest_lap_ms
2024       Abu Dhabi Grand Prix     Kevin Magnussen   85637
2024       Australian Grand Prix    Charles Leclerc   79813
2024       Austrian Grand Prix      Fernando Alonso   67694
2024       Azerbaijan Grand Prix    Lando Norris      105255
2024       Bahrain Grand Prix       Max Verstappen    92608
```

**Interpretacion**  
La vuelta mas rapida no siempre coincide con el ganador de la carrera, lo que permite analizar rendimiento puntual aparte del resultado final.

### Q15. Ranking de pilotos por puntos en las ultimas 5 temporadas disponibles

**Objetivo**  
Construir un ranking por temporada usando `CTE (WITH)` y funciones de ventana. Las ultimas 5 temporadas disponibles en la base son `2020`, `2021`, `2022`, `2023` y `2024`.

**Resultado destacado**

```text
temporada  piloto            puntos  ranking
2024       Max Verstappen    399     1
2024       Lando Norris      344     2
2024       Charles Leclerc   327     3
2024       Oscar Piastri     265     4
2024       Carlos Sainz      262     5
```

**Interpretacion**  
El ranking por temporada facilita observar cambios de jerarquia competitiva entre anos recientes.

## Vistas permanentes

### V1. `vw_resultados_carrera`

**Descripcion**  
Vista pensada para consultar rapidamente resultados enriquecidos por carrera, piloto y escuderia.

**Muestra**

```text
temporada  carrera               piloto           escuderia  posicion_salida  posicion_final  points
2024       Abu Dhabi Grand Prix  Lando Norris     McLaren    1                1               25
2024       Abu Dhabi Grand Prix  Carlos Sainz     Ferrari    3                2               18
2024       Abu Dhabi Grand Prix  Charles Leclerc  Ferrari    19               3               15
2024       Abu Dhabi Grand Prix  Lewis Hamilton   Mercedes   16               4               12
2024       Abu Dhabi Grand Prix  George Russell   Mercedes   6                5               10
```

**Utilidad**  
Permite cruzar rendimiento deportivo y contexto de carrera sin repetir `JOIN` en cada consulta futura.

### V2. `vw_info_carreras`

**Descripcion**  
Vista orientada a la consulta del calendario historico de carreras con informacion basica de circuito y pais.

**Muestra**

```text
raceId  temporada  ronda  carrera                 circuito                         pais           fecha
1121    2024       1      Bahrain Grand Prix      Bahrain International Circuit    Bahrain        2024-03-02
1122    2024       2      Saudi Arabian Grand Prix Jeddah Corniche Circuit        Saudi Arabia   2024-03-09
1123    2024       3      Australian Grand Prix   Albert Park Grand Prix Circuit   Australia      2024-03-24
1124    2024       4      Japanese Grand Prix     Suzuka Circuit                   Japan          2024-04-07
1125    2024       5      Chinese Grand Prix      Shanghai International Circuit   China          2024-04-21
```

**Utilidad**  
Facilita consultas de calendario, ubicacion y cronologia sin depender de `JOIN` repetidos entre `races` y `circuits`.

## Conclusiones

- El rendimiento historico en Formula 1 se concentra en un grupo reducido de pilotos, especialmente cuando se analizan victorias, podios y puntos acumulados.
- Las escuderias muestran fortalezas diferenciadas tanto en eficiencia operativa como en dominio historico de ciertos circuitos.
- Los circuitos callejeros o urbanos tienden a exhibir mayores niveles de abandono y caos competitivo.
- Las funciones de ventana y las CTE permiten responder preguntas mas precisas que una agregacion simple, especialmente cuando se requiere ranking o seleccion del lider por grupo.
- La base de datos F1 permite combinar analisis historico, operativo y competitivo dentro de un modelo relacional consistente.

## Nota final

El SQL completo y ejecutable de todas las consultas y vistas se encuentra en el archivo `F1_taller_consultas_corregidas.sql`.
