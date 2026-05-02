from __future__ import annotations

import os

from databricks import sql as databricks_sql
import pandas as pd
import plotly.express as px
import streamlit as st


st.set_page_config(
    page_title="F1 Gold Analytics",
    layout="wide",
    initial_sidebar_state="expanded",
)


KPI_ORDER = [
    "total_seasons",
    "total_races",
    "total_drivers",
    "total_constructors",
    "classified_finish_rate_pct",
    "dnf_rate_pct",
    "avg_points_per_entry",
    "pole_to_win_rate_pct",
    "sprint_weekend_share_pct",
    "shared_drive_entry_rate_pct",
]

COLOR_SEQUENCE = [
    "#c1121f",
    "#f77f00",
    "#fcbf49",
    "#003049",
    "#669bbc",
]

COLUMN_LABELS = {
    "season_year": "Temporada",
    "season_round": "Ronda",
    "season_total_races": "Total carreras temporada",
    "driverId": "ID piloto",
    "driver_name": "Piloto",
    "constructorId": "ID escuderia",
    "constructor_name": "Escuderia",
    "primary_constructorId": "ID escuderia principal",
    "primary_constructor_name": "Escuderia principal",
    "constructors_used": "Escuderias utilizadas",
    "race_entries": "Participaciones",
    "race_entries_analyzed": "Participaciones analizadas",
    "race_weekends": "Fines de semana",
    "race_weekends_hosted": "GP organizados",
    "shared_drive_entries": "Shared drives",
    "wins": "Victorias",
    "podiums": "Podios",
    "poles": "Poles",
    "titles": "Titulos",
    "total_points": "Puntos totales",
    "race_points": "Puntos carrera",
    "race_points_from_entries": "Puntos desde participaciones",
    "sprint_points": "Puntos sprint",
    "official_constructor_race_points": "Puntos oficiales constructores",
    "avg_points_per_season": "Promedio puntos por temporada",
    "avg_points_per_entry": "Puntos promedio por participacion",
    "avg_starting_grid": "Promedio parrilla",
    "avg_finish_position": "Promedio llegada",
    "avg_positions_gained": "Promedio posiciones ganadas",
    "avg_qualifying_delta": "Promedio delta clasificacion-meta",
    "avg_qualifying_position": "Promedio clasificacion",
    "avg_qualifying_to_finish_delta": "Promedio delta clasificacion-llegada",
    "avg_pit_stop_ms": "Promedio pit stop ms",
    "best_event_points": "Mejor puntos del evento",
    "best_positions_gained": "Mejor remontada",
    "classified_finishes": "Finales clasificados",
    "classified_entries": "Participaciones clasificadas",
    "non_classified_finishes": "Finales no clasificados",
    "non_classified_entries": "Participaciones no clasificadas",
    "non_classified_rate_pct": "Tasa no clasificacion %",
    "mechanical_non_classified_entries": "Abandonos mecanicos",
    "accident_non_classified_entries": "Abandonos por incidente",
    "disqualified_entries": "Descalificaciones",
    "qualified_on_pole": "Poles logradas",
    "championship_position": "Posicion campeonato",
    "final_standings_points": "Puntos finales standings",
    "championship_wins": "Victorias standings",
    "win_rate_pct": "Tasa de victoria %",
    "podium_rate_pct": "Tasa de podio %",
    "pole_rate_pct": "Tasa de pole %",
    "drivers_used": "Pilotos utilizados",
    "first_season": "Primera temporada",
    "last_season": "Ultima temporada",
    "seasons_competed": "Temporadas disputadas",
    "circuitId": "ID circuito",
    "circuit_name": "Circuito",
    "country": "Pais",
    "location": "Ubicacion",
    "total_entries": "Participaciones totales",
    "unique_drivers": "Pilotos unicos",
    "unique_constructors": "Escuderias unicas",
    "pole_to_win_occurrences": "Poles convertidas",
    "pole_to_win_rate_pct": "Conversion pole-victoria %",
    "winners_from_pole": "Victorias desde la pole",
    "front_row_podium_entries": "Podios desde primera fila",
    "front_row_podium_rate_pct": "Tasa podio primera fila %",
    "winner_avg_grid": "Parrilla promedio del ganador",
    "winner_avg_qualifying_position": "Clasificacion promedio del ganador",
    "raceId": "ID carrera",
    "race_name": "Gran premio",
    "race_date": "Fecha",
    "has_sprint_weekend": "Tiene sprint",
    "total_event_points_awarded": "Puntos totales otorgados",
    "winner_driver_name": "Piloto ganador",
    "winner_constructor_name": "Escuderia ganadora",
    "winner_starting_grid": "Parrilla del ganador",
    "pole_driver_name": "Piloto pole",
    "pole_constructor_name": "Escuderia pole",
    "pole_converted_to_win": "Pole convertida en victoria",
    "podium_names": "Podio",
    "total_pit_stops": "Total pit stops",
    "max_positions_gained": "Maxima remontada",
    "metric": "Indicador",
    "value": "Valor",
    "race_label": "Carrera",
    "snapshot_label": "Etiqueta snapshot",
    "snapshot_taken_at": "Fecha snapshot",
    "source_schema": "Esquema fuente",
    "frozen_kpis": "KPIs congelados",
    "kpi_code": "Codigo KPI",
    "kpi_name": "KPI",
    "business_question": "Pregunta de negocio",
    "business_definition": "Definicion de negocio",
    "formula_definition": "Formula",
    "unit_of_measure": "Unidad",
    "grain_level": "Grano",
    "source_objects": "Objetos fuente",
    "kpi_value_numeric": "Valor numerico",
    "kpi_value_text": "Valor",
}

CUSTOM_CSS = """
<style>
    .block-container {
        padding-top: 1.4rem;
        padding-bottom: 2rem;
    }

    .hero-card {
        background: linear-gradient(135deg, #081c24 0%, #102f3d 55%, #c1121f 140%);
        padding: 1.6rem 1.8rem;
        border-radius: 20px;
        color: #fdf0d5;
        box-shadow: 0 14px 30px rgba(8, 28, 36, 0.25);
        margin-bottom: 1.2rem;
    }

    .hero-card h1 {
        margin: 0;
        font-size: 2rem;
        line-height: 1.1;
    }

    .hero-card p {
        margin: 0.55rem 0 0 0;
        font-size: 1rem;
        max-width: 60rem;
    }

    .metric-card {
        background: linear-gradient(180deg, #fffaf1 0%, #fff4da 100%);
        border: 1px solid rgba(193, 18, 31, 0.14);
        border-left: 5px solid #c1121f;
        border-radius: 18px;
        padding: 1rem 1rem 0.95rem 1rem;
        min-height: 160px;
        box-shadow: 0 10px 24px rgba(16, 47, 61, 0.08);
    }

    .metric-label {
        font-size: 0.9rem;
        color: #5f4b32;
        margin-bottom: 0.45rem;
        font-weight: 600;
    }

    .metric-value {
        font-size: 1.7rem;
        color: #003049;
        font-weight: 800;
        line-height: 1.05;
        margin-bottom: 0.55rem;
    }

    .metric-help {
        font-size: 0.88rem;
        color: #5f4b32;
        line-height: 1.35;
    }

    .section-note {
        background: #f8f9fa;
        border-radius: 14px;
        border: 1px solid rgba(0, 48, 73, 0.09);
        padding: 0.95rem 1rem;
        margin-bottom: 0.8rem;
    }

    .section-note strong {
        color: #003049;
    }

    [data-testid="stSidebar"] {
        background: linear-gradient(180deg, #f8f4ea 0%, #fffdf8 100%);
    }
</style>
"""


def get_setting(name: str, default: str = "") -> str:
    """Read config from environment first, then Streamlit secrets."""
    value = os.getenv(name)
    if value:
        return value
    try:
        return str(st.secrets.get(name, default))
    except Exception:
        return default


@st.cache_data(ttl=300, show_spinner=False)
def run_query(
    server_hostname: str,
    http_path: str,
    access_token: str,
    catalog: str,
    query: str,
) -> pd.DataFrame:
    with databricks_sql.connect(
        server_hostname=server_hostname,
        http_path=http_path,
        access_token=access_token,
    ) as conn:
        with conn.cursor() as cursor:
            cursor.execute(f"USE CATALOG `{catalog.replace('`', '``')}`")
            cursor.execute(query)
            rows = cursor.fetchall()
            columns = [column[0] for column in cursor.description]
    return pd.DataFrame(rows, columns=columns)


def render_metric_cards(kpis: pd.DataFrame) -> None:
    ordered = kpis.copy()
    ordered["sort_key"] = ordered["kpi_code"].apply(
        lambda code: KPI_ORDER.index(code) if code in KPI_ORDER else 999
    )
    ordered = ordered.sort_values(["sort_key", "kpi_name"]).drop(columns=["sort_key"])

    cols = st.columns(5)
    for idx, row in ordered.reset_index(drop=True).iterrows():
        with cols[idx % 5]:
            st.markdown(
                f"""
                <div class="metric-card">
                    <div class="metric-label">{row["kpi_name"]}</div>
                    <div class="metric-value">{row["kpi_value_text"]}</div>
                    <div class="metric-help">{row["business_question"]}</div>
                </div>
                """,
                unsafe_allow_html=True,
            )


def style_plot(fig):
    fig.update_layout(
        template="plotly_white",
        margin=dict(l=20, r=20, t=50, b=20),
        paper_bgcolor="white",
        plot_bgcolor="white",
        legend_title_text="",
    )
    return fig


def translate_columns(df: pd.DataFrame, columns: list[str] | None = None) -> pd.DataFrame:
    view = df.copy()
    if columns is not None:
        view = view[columns]
    labels = {column: COLUMN_LABELS.get(column, column) for column in view.columns}
    return view.rename(columns=labels)


def load_all_data(
    server_hostname: str,
    http_path: str,
    access_token: str,
    catalog: str,
) -> dict[str, pd.DataFrame]:
    def query(sql: str) -> pd.DataFrame:
        return run_query(server_hostname, http_path, access_token, catalog, sql)

    return {
        "kpis": query(
            """
            SELECT kpi_code, kpi_name, business_question, unit_of_measure,
                   kpi_value_numeric, kpi_value_text
            FROM f1_gold.vw_dashboard_kpi_cards
            """,
        ),
        "catalog": query(
            """
            SELECT kpi_code, kpi_name, business_definition, formula_definition,
                   unit_of_measure, grain_level, source_objects
            FROM f1_gold.kpi_catalog
            ORDER BY kpi_name
            """,
        ),
        "driver_championships": query(
            """
            SELECT *
            FROM f1_gold.mart_driver_season
            WHERE championship_position IS NOT NULL
            ORDER BY season_year DESC, championship_position ASC, total_points DESC
            """,
        ),
        "constructor_championships": query(
            """
            SELECT *
            FROM f1_gold.mart_constructor_season
            WHERE championship_position IS NOT NULL
            ORDER BY season_year DESC, championship_position ASC, total_points DESC
            """,
        ),
        "top_drivers": query(
            """
            SELECT *
            FROM f1_gold.vw_dashboard_top_drivers
            ORDER BY titles DESC, wins DESC, total_points DESC
            LIMIT 25
            """,
        ),
        "top_constructors": query(
            """
            SELECT *
            FROM f1_gold.vw_dashboard_top_constructors
            ORDER BY titles DESC, wins DESC, total_points DESC
            LIMIT 20
            """,
        ),
        "circuit_risk": query(
            """
            SELECT *
            FROM f1_gold.vw_dashboard_circuit_risk
            ORDER BY non_classified_rate_pct DESC, total_entries DESC
            LIMIT 25
            """,
        ),
        "qualifying": query(
            """
            SELECT *
            FROM f1_gold.mart_qualifying_effect_season
            ORDER BY season_year
            """,
        ),
        "weekends": query(
            """
            SELECT *
            FROM f1_gold.mart_race_weekend
            ORDER BY race_date DESC, raceId DESC
            LIMIT 30
            """,
        ),
        "snapshots": query(
            """
            SELECT snapshot_label, source_schema, snapshot_taken_at, kpi_code,
                   kpi_name, unit_of_measure, kpi_value_numeric, kpi_value_text
            FROM f1_control.f1_gold_kpi_snapshot_history
            ORDER BY snapshot_taken_at ASC, kpi_code ASC
            """,
        ),
    }


def main() -> None:
    st.markdown(CUSTOM_CSS, unsafe_allow_html=True)

    with st.sidebar:
        st.title("Conexión")
        server_hostname = st.text_input(
            "Server hostname",
            value=get_setting("DATABRICKS_SERVER_HOSTNAME", "dbc-27294608-e1ce.cloud.databricks.com"),
        )
        http_path = st.text_input(
            "HTTP path",
            value=get_setting("DATABRICKS_HTTP_PATH", "/sql/1.0/warehouses/14f76675cb754d43"),
        )
        catalog = st.text_input(
            "Catálogo",
            value=get_setting("DATABRICKS_CATALOG", "f1"),
        )
        access_token = st.text_input(
            "Token",
            value=get_setting("DATABRICKS_TOKEN", ""),
            type="password",
        )

        if st.button("Recargar datos", width="stretch"):
            st.cache_data.clear()

        st.markdown("---")
        st.caption("Flujo analítico del proyecto")
        st.code("Databricks f1 -> f1_silver -> f1_gold -> f1_control")

        st.caption("Fuentes principales de la app")
        st.markdown(
            "- `F1_gold.vw_dashboard_kpi_cards`\n"
            "- `F1_gold.mart_driver_season`\n"
            "- `F1_gold.mart_constructor_season`\n"
            "- `F1_gold.vw_dashboard_top_drivers`\n"
            "- `F1_gold.vw_dashboard_top_constructors`\n"
            "- `F1_gold.vw_dashboard_circuit_risk`\n"
            "- `F1_gold.mart_qualifying_effect_season`\n"
            "- `F1_gold.mart_race_weekend`\n"
            "- `F1_control.f1_gold_kpi_snapshot_history`"
        )

    if not access_token:
        st.warning("Configura un token de Databricks para cargar el dashboard.")
        st.stop()

    try:
        data = load_all_data(server_hostname, http_path, access_token, catalog)
    except Exception as exc:
        st.error("No fue posible cargar la capa Gold desde Databricks.")
        st.code(str(exc))
        st.stop()

    kpis = data["kpis"]
    catalog = data["catalog"]
    driver_championships = data["driver_championships"]
    constructor_championships = data["constructor_championships"]
    top_drivers = data["top_drivers"]
    top_constructors = data["top_constructors"]
    circuit_risk = data["circuit_risk"]
    qualifying = data["qualifying"]
    weekends = data["weekends"]
    snapshots = data["snapshots"]

    if not weekends.empty:
        weekends["race_date"] = pd.to_datetime(weekends["race_date"])
    if not snapshots.empty:
        snapshots["snapshot_taken_at"] = pd.to_datetime(snapshots["snapshot_taken_at"])

    latest_snapshot_label = None
    latest_snapshot_time = None
    if not snapshots.empty:
        latest_snapshot_row = snapshots.sort_values("snapshot_taken_at").iloc[-1]
        latest_snapshot_label = latest_snapshot_row["snapshot_label"]
        latest_snapshot_time = latest_snapshot_row["snapshot_taken_at"]

    st.markdown(
        """
        <div class="hero-card">
            <h1>F1 Gold Analytics</h1>
            <p>
                Esta app muestra la capa <strong>Gold</strong> del proyecto de Formula 1.
                Su objetivo es traducir la base técnica en una lectura ejecutiva:
                KPIs oficiales, campeonatos recientes, líderes históricos, circuitos de riesgo,
                efecto de clasificación y highlights de carreras.
            </p>
        </div>
        """,
        unsafe_allow_html=True,
    )

    left_info, right_info = st.columns([3, 2])
    with left_info:
        st.markdown(
            """
            <div class="section-note">
                <strong>Qué estás viendo:</strong> la app no consulta la base cruda.
                Todo lo que aparece aquí proviene de <code>F1_gold</code>, que ya es una
                capa de consumo con marts materializados y vistas de negocio listas para presentación.
            </div>
            """,
            unsafe_allow_html=True,
        )
    with right_info:
        if latest_snapshot_label:
            st.success(
                f"Último snapshot de KPIs: {latest_snapshot_label} "
                f"({latest_snapshot_time:%Y-%m-%d %H:%M:%S})"
            )
        else:
            st.warning("Todavía no hay snapshots de KPIs en F1_control.")

    tabs = st.tabs(
        [
            "Resumen Ejecutivo",
            "Campeonatos",
            "Liderazgo Histórico",
            "Circuitos y Riesgo",
            "Clasificación",
            "Carreras Recientes",
            "KPIs Versionados",
            "Arquitectura",
        ]
    )

    with tabs[0]:
        st.subheader("KPIs oficiales de la capa Gold")
        st.caption("Fuente: `F1_gold.vw_dashboard_kpi_cards` + `F1_gold.kpi_catalog`")
        render_metric_cards(kpis)

        with st.expander("Cómo leer estos KPI"):
            st.markdown(
                """
                - `Temporadas cubiertas`, `Carreras registradas`, `Pilotos registrados` y `Escuderías registradas`
                  describen el alcance del modelo analítico.
                - `Tasa de clasificación` y `Tasa de no clasificación` resumen estabilidad deportiva y operativa.
                - `Conversión pole a victoria` mide cuánta ventaja competitiva se convierte realmente en triunfo.
                - `Participación de fines de semana sprint` y `Participaciones con shared drive` aportan contexto histórico.
                """
            )

        catalog_view = catalog[
            [
                "kpi_name",
                "business_definition",
                "formula_definition",
                "grain_level",
                "source_objects",
            ]
        ].rename(
            columns={
                "kpi_name": "KPI",
                "business_definition": "Definición de negocio",
                "formula_definition": "Fórmula",
                "grain_level": "Grano",
                "source_objects": "Fuente Gold/Silver",
            }
        )
        st.dataframe(catalog_view, width="stretch", hide_index=True)

    with tabs[1]:
        st.subheader("Campeonatos por temporada")
        st.caption(
            "Fuentes: `F1_gold.mart_driver_season` y "
            "`F1_gold.mart_constructor_season`"
        )

        season_options = sorted(
            set(driver_championships["season_year"].tolist())
            | set(constructor_championships["season_year"].tolist()),
            reverse=True,
        )
        season_selector_options = ["Todas las temporadas", *season_options]
        selected_season = st.selectbox(
            "Temporada a visualizar",
            options=season_selector_options,
            index=0,
            help="Selecciona una temporada histórica puntual o una vista consolidada de todas las temporadas.",
        )

        if selected_season == "Todas las temporadas":
            all_driver_champions = driver_championships[
                driver_championships["championship_position"] == 1
            ].sort_values("season_year", ascending=False)
            all_constructor_champions = constructor_championships[
                constructor_championships["championship_position"] == 1
            ].sort_values("season_year", ascending=False)

            st.info(
                f"Vista histórica completa. "
                f"Títulos de pilotos disponibles: {len(all_driver_champions)}. "
                f"Títulos de constructores disponibles: {len(all_constructor_champions)}."
            )

            col1, col2 = st.columns(2)
            with col1:
                driver_history_fig = px.line(
                    all_driver_champions.sort_values("season_year"),
                    x="season_year",
                    y="total_points",
                    markers=True,
                    hover_name="driver_name",
                    labels=COLUMN_LABELS,
                    color_discrete_sequence=["#c1121f"],
                    title="Campeón de pilotos por temporada",
                )
                st.plotly_chart(style_plot(driver_history_fig), width="stretch")

            with col2:
                constructor_history_fig = px.line(
                    all_constructor_champions.sort_values("season_year"),
                    x="season_year",
                    y="total_points",
                    markers=True,
                    hover_name="constructor_name",
                    labels=COLUMN_LABELS,
                    color_discrete_sequence=["#003049"],
                    title="Campeón de constructores por temporada",
                )
                st.plotly_chart(style_plot(constructor_history_fig), width="stretch")

            st.markdown(
                """
                Esta vista consolida todo el histórico de campeonatos. Sirve para recorrer año a año
                quién fue campeón y cómo evolucionaron los puntos de los campeones a lo largo del tiempo.
                """
            )

            row1, row2 = st.columns(2)
            with row1:
                st.dataframe(
                    translate_columns(
                        all_driver_champions,
                        [
                            "season_year",
                            "driver_name",
                            "primary_constructor_name",
                            "total_points",
                            "wins",
                            "podiums",
                            "poles",
                        ],
                    ),
                    width="stretch",
                    hide_index=True,
                )
            with row2:
                st.dataframe(
                    translate_columns(
                        all_constructor_champions,
                        [
                            "season_year",
                            "constructor_name",
                            "total_points",
                            "wins",
                            "podiums",
                            "poles",
                            "drivers_used",
                        ],
                    ),
                    width="stretch",
                    hide_index=True,
                )
        else:
            selected_driver_championship = driver_championships[
                driver_championships["season_year"] == selected_season
            ].sort_values(["championship_position", "total_points"], ascending=[True, False])

            selected_constructor_championship = constructor_championships[
                constructor_championships["season_year"] == selected_season
            ].sort_values(["championship_position", "total_points"], ascending=[True, False])

            st.info(
                f"Estás viendo la temporada {selected_season}. "
                f"Pilotos clasificados: {len(selected_driver_championship)}. "
                f"Escuderías clasificadas: {len(selected_constructor_championship)}."
            )

            col1, col2 = st.columns(2)
            with col1:
                driver_fig = px.bar(
                    selected_driver_championship.head(10),
                    x="total_points",
                    y="driver_name",
                    color="primary_constructor_name",
                    orientation="h",
                    text="total_points",
                    labels=COLUMN_LABELS,
                    color_discrete_sequence=COLOR_SEQUENCE,
                    title="Top 10 del campeonato de pilotos",
                )
                driver_fig.update_layout(yaxis={"categoryorder": "total ascending"})
                st.plotly_chart(style_plot(driver_fig), width="stretch")

            with col2:
                if selected_constructor_championship.empty:
                    st.warning(
                        "No hay clasificación de constructores disponible para esta temporada. "
                        "En los primeros años del histórico solo se muestra campeonato de pilotos."
                    )
                else:
                    constructor_fig = px.bar(
                        selected_constructor_championship.head(10),
                        x="total_points",
                        y="constructor_name",
                        color="constructor_name",
                        orientation="h",
                        text="total_points",
                        labels=COLUMN_LABELS,
                        color_discrete_sequence=COLOR_SEQUENCE,
                        title="Top 10 del campeonato de constructores",
                    )
                    constructor_fig.update_layout(showlegend=False, yaxis={"categoryorder": "total ascending"})
                    st.plotly_chart(style_plot(constructor_fig), width="stretch")

            st.markdown(
                """
                Esta sección sirve para comparar cualquier temporada histórica y explicar quién dominó ese año
                con qué mezcla de puntos, victorias, podios, poles y rendimiento promedio en parrilla y meta.
                """
            )

            row1, row2 = st.columns(2)
            with row1:
                st.dataframe(
                    translate_columns(selected_driver_championship),
                    width="stretch",
                    hide_index=True,
                )
            with row2:
                if selected_constructor_championship.empty:
                    st.caption(
                        "No hay tabla de constructores para esta temporada en el modelo histórico."
                    )
                else:
                    st.dataframe(
                        translate_columns(selected_constructor_championship),
                        width="stretch",
                        hide_index=True,
                    )

    with tabs[2]:
        st.subheader("Liderazgo histórico")
        st.caption(
            "Fuentes: `F1_gold.vw_dashboard_top_drivers` y `F1_gold.vw_dashboard_top_constructors`"
        )

        metric_driver = st.selectbox(
            "Métrica para pilotos",
            options=["titles", "wins", "podiums", "total_points"],
            format_func=lambda x: {
                "titles": "Títulos",
                "wins": "Victorias",
                "podiums": "Podios",
                "total_points": "Puntos totales",
            }[x],
            key="driver_metric",
        )

        metric_constructor = st.selectbox(
            "Métrica para escuderías",
            options=["titles", "wins", "podiums", "total_points"],
            format_func=lambda x: {
                "titles": "Títulos",
                "wins": "Victorias",
                "podiums": "Podios",
                "total_points": "Puntos totales",
            }[x],
            key="constructor_metric",
        )

        hist_left, hist_right = st.columns(2)
        with hist_left:
            drivers_fig = px.bar(
                top_drivers.sort_values(metric_driver, ascending=True).tail(12),
                x=metric_driver,
                y="driver_name",
                orientation="h",
                color="titles",
                labels=COLUMN_LABELS,
                color_continuous_scale=["#fcbf49", "#f77f00", "#c1121f"],
                title="Pilotos más grandes del histórico",
            )
            st.plotly_chart(style_plot(drivers_fig), width="stretch")

        with hist_right:
            constructors_fig = px.bar(
                top_constructors.sort_values(metric_constructor, ascending=True).tail(12),
                x=metric_constructor,
                y="constructor_name",
                orientation="h",
                color="titles",
                labels=COLUMN_LABELS,
                color_continuous_scale=["#669bbc", "#003049", "#c1121f"],
                title="Escuderías más grandes del histórico",
            )
            st.plotly_chart(style_plot(constructors_fig), width="stretch")

        bubble_left, bubble_right = st.columns(2)
        with bubble_left:
            bubble_drivers = px.scatter(
                top_drivers,
                x="wins",
                y="total_points",
                size="podiums",
                color="titles",
                hover_name="driver_name",
                labels=COLUMN_LABELS,
                color_continuous_scale=["#fcbf49", "#f77f00", "#c1121f"],
                title="Pilotos: victorias vs puntos",
            )
            st.plotly_chart(style_plot(bubble_drivers), width="stretch")

        with bubble_right:
            bubble_constructors = px.scatter(
                top_constructors,
                x="wins",
                y="total_points",
                size="podiums",
                color="titles",
                hover_name="constructor_name",
                labels=COLUMN_LABELS,
                color_continuous_scale=["#669bbc", "#003049", "#c1121f"],
                title="Escuderías: victorias vs puntos",
            )
            st.plotly_chart(style_plot(bubble_constructors), width="stretch")

    with tabs[3]:
        st.subheader("Circuitos y riesgo competitivo")
        st.caption("Fuente: `F1_gold.vw_dashboard_circuit_risk`")
        st.markdown(
            """
            Aquí se resume qué tan caótico ha sido cada circuito a lo largo del histórico.
            La tasa de no clasificación se complementa con el peso relativo de fallas mecánicas,
            incidentes y descalificaciones.
            """
        )

        risk_left, risk_right = st.columns(2)
        with risk_left:
            risk_fig = px.bar(
                circuit_risk.head(15).sort_values("non_classified_rate_pct", ascending=True),
                x="non_classified_rate_pct",
                y="circuit_name",
                color="country",
                orientation="h",
                labels=COLUMN_LABELS,
                title="Circuitos con mayor tasa de no clasificación",
                color_discrete_sequence=COLOR_SEQUENCE,
            )
            st.plotly_chart(style_plot(risk_fig), width="stretch")

        with risk_right:
            cause_fig = px.scatter(
                circuit_risk.head(20),
                x="mechanical_non_classified_entries",
                y="accident_non_classified_entries",
                size="total_entries",
                color="non_classified_rate_pct",
                hover_name="circuit_name",
                labels=COLUMN_LABELS,
                color_continuous_scale=["#fcbf49", "#f77f00", "#c1121f"],
                title="Mecánicos vs incidentes por circuito",
            )
            st.plotly_chart(style_plot(cause_fig), width="stretch")

        st.dataframe(translate_columns(circuit_risk), width="stretch", hide_index=True)

    with tabs[4]:
        st.subheader("Impacto de la clasificación")
        st.caption("Fuente: `F1_gold.mart_qualifying_effect_season`")

        qual_long = qualifying.melt(
            id_vars=["season_year"],
            value_vars=["pole_to_win_rate_pct", "front_row_podium_rate_pct"],
            var_name="metric",
            value_name="value",
        )
        qual_long["metric"] = qual_long["metric"].map(
            {
                "pole_to_win_rate_pct": "Pole convertida en victoria",
                "front_row_podium_rate_pct": "Podio desde primera fila",
            }
        )

        qual_left, qual_right = st.columns(2)
        with qual_left:
            qual_fig = px.line(
                qual_long,
                x="season_year",
                y="value",
                color="metric",
                markers=True,
                labels=COLUMN_LABELS,
                color_discrete_sequence=["#c1121f", "#003049"],
                title="Relación entre clasificación y resultado",
            )
            st.plotly_chart(style_plot(qual_fig), width="stretch")

        with qual_right:
            winner_grid_fig = px.bar(
                qualifying.tail(12),
                x="season_year",
                y="winner_avg_grid",
                color="pole_to_win_rate_pct",
                labels=COLUMN_LABELS,
                color_continuous_scale=["#669bbc", "#fcbf49", "#c1121f"],
                title="Grid promedio del ganador por temporada",
            )
            st.plotly_chart(style_plot(winner_grid_fig), width="stretch")

        st.markdown(
            """
            Si esta curva sube, la capa Gold está mostrando un deporte más dependiente de la posición
            de salida. Si baja, hay más espacio para remontadas y carreras abiertas.
            """
        )
        st.dataframe(
            translate_columns(qualifying.sort_values("season_year", ascending=False)),
            width="stretch",
            hide_index=True,
        )

    with tabs[5]:
        st.subheader("Carreras recientes y lectura narrativa")
        st.caption("Fuente: `F1_gold.mart_race_weekend`")

        recent = weekends.head(12).copy()
        recent["race_label"] = recent["season_year"].astype(str) + " R" + recent["season_round"].astype(str) + " - " + recent["race_name"]

        recent_left, recent_right = st.columns(2)
        with recent_left:
            dnf_fig = px.bar(
                recent.sort_values("race_date"),
                x="race_label",
                y="non_classified_rate_pct",
                color="pole_converted_to_win",
                labels=COLUMN_LABELS,
                color_discrete_map={0: "#669bbc", 1: "#c1121f"},
                title="No clasificación en las carreras más recientes",
            )
            dnf_fig.update_xaxes(tickangle=-45)
            st.plotly_chart(style_plot(dnf_fig), width="stretch")

        with recent_right:
            pits_fig = px.scatter(
                recent,
                x="total_pit_stops",
                y="avg_pit_stop_ms",
                size="total_event_points_awarded",
                color="non_classified_rate_pct",
                hover_name="race_name",
                labels=COLUMN_LABELS,
                color_continuous_scale=["#003049", "#f77f00", "#c1121f"],
                title="Actividad en pits vs severidad deportiva",
            )
            st.plotly_chart(style_plot(pits_fig), width="stretch")

        st.markdown(
            """
            Esta vista es ideal para cerrar una exposición: combina ganador, pole, podio,
            abandono y actividad en pits dentro de un mismo resumen de fin de semana.
            """
        )
        st.dataframe(
            translate_columns(
                recent,
                [
                    "season_year",
                    "season_round",
                    "race_name",
                    "circuit_name",
                    "country",
                    "race_date",
                    "winner_driver_name",
                    "winner_constructor_name",
                    "pole_driver_name",
                    "pole_converted_to_win",
                    "podium_names",
                    "non_classified_rate_pct",
                    "total_pit_stops",
                    "avg_pit_stop_ms",
                ],
            ),
            width="stretch",
            hide_index=True,
        )

    with tabs[6]:
        st.subheader("KPIs versionados")
        st.caption("Fuente: `F1_control.f1_gold_kpi_snapshot_history`")

        if snapshots.empty:
            st.warning("No hay historial de snapshots disponible.")
        else:
            selected_kpi = st.selectbox(
                "Selecciona un KPI para ver su historial",
                options=sorted(snapshots["kpi_name"].unique()),
            )
            kpi_history = snapshots[snapshots["kpi_name"] == selected_kpi].copy()
            history_fig = px.line(
                kpi_history,
                x="snapshot_taken_at",
                y="kpi_value_numeric",
                color="source_schema",
                markers=True,
                text="snapshot_label",
                labels=COLUMN_LABELS,
                title=f"Histórico versionado: {selected_kpi}",
                color_discrete_sequence=["#c1121f"],
            )
            history_fig.update_traces(textposition="top center")
            st.plotly_chart(style_plot(history_fig), width="stretch")

            latest_snapshot = snapshots["snapshot_label"].iloc[-1]
            latest_snapshot_table = snapshots[snapshots["snapshot_label"] == latest_snapshot][
                ["kpi_name", "unit_of_measure", "kpi_value_text"]
            ].rename(
                columns={
                    "kpi_name": "KPI",
                    "unit_of_measure": "Unidad",
                    "kpi_value_text": "Valor",
                }
            )
            summary_table = (
                snapshots.groupby(["snapshot_label", "source_schema", "snapshot_taken_at"], as_index=False)
                .agg(frozen_kpis=("kpi_code", "count"))
                .sort_values("snapshot_taken_at", ascending=False)
            )

            col_hist_1, col_hist_2 = st.columns([2, 1])
            with col_hist_1:
                st.dataframe(translate_columns(summary_table), width="stretch", hide_index=True)
            with col_hist_2:
                st.dataframe(latest_snapshot_table, width="stretch", hide_index=True)

    with tabs[7]:
        st.subheader("Arquitectura y recorrido hacia Gold")
        st.code("Databricks f1 -> f1_silver -> f1_gold -> f1_control")
        st.markdown(
            """
            La app existe para contar una historia técnica con lenguaje de negocio.
            Este es el recorrido que siguió el proyecto para llegar a una capa Gold reutilizable.
            """
        )

        arch_1, arch_2 = st.columns(2)
        with arch_1:
            st.markdown(
                """
                **Base y Silver**

                - Los datos historicos de Formula 1 ya estan cargados en Databricks.
                - El esquema `f1` conserva la estructura base de carreras, pilotos,
                  circuitos, estados, resultados y standings.
                - `f1_silver` limpia y enriquece esa base para consumo analitico.
                """
            )
            st.markdown(
                """
                **Silver**

                - `F1_silver` separa dimensiones y hechos.
                - Normaliza nombres, banderas analíticas y tiempos.
                - Incorpora `dim_seasons` y `fact_race_entries`.
                - Detecta `85` casos históricos de shared drives sin tratarlos como error.
                """
            )

        with arch_2:
            st.markdown(
                """
                **Gold**

                - `F1_gold` materializa marts por piloto, escudería, circuito, temporada y carrera.
                - Expone KPIs oficiales y vistas pensadas para dashboard.
                - Evita depender de joins complejos al momento de presentar.
                """
            )
            st.markdown(
                """
                **Control**

                - `F1_control` guarda snapshots de KPIs.
                - Permite congelar cortes para clase, demo o entrega.
                - Se alimenta con `F1_freeze_kpis.sh` después del refresco de capas.
                """
            )

        gold_objects = pd.DataFrame(
            {
                "Objeto": [
                    "kpi_catalog",
                    "mart_kpi_snapshot",
                    "mart_driver_season",
                    "mart_constructor_season",
                    "mart_circuit_risk",
                    "mart_qualifying_effect_season",
                    "mart_race_weekend",
                    "vw_dashboard_kpi_cards",
                    "vw_dashboard_top_drivers",
                    "vw_dashboard_top_constructors",
                    "vw_dashboard_circuit_risk",
                    "mart_driver_season",
                    "mart_constructor_season",
                    "vw_dashboard_recent_race_highlights",
                ],
                "Rol": [
                    "Catálogo oficial de KPIs",
                    "Snapshot actual de indicadores",
                    "Mart por piloto y temporada",
                    "Mart por escudería y temporada",
                    "Mart de riesgo por circuito",
                    "Mart del impacto de clasificación",
                    "Mart narrativo por fin de semana",
                    "Vista ejecutiva de tarjetas KPI",
                    "Vista de liderazgo histórico de pilotos",
                    "Vista de liderazgo histórico de escuderías",
                    "Vista de riesgo y caos por circuito",
                    "Mart para navegar campeonatos de pilotos por temporada",
                    "Mart para navegar campeonatos de constructores por temporada",
                    "Vista narrativa de carreras recientes",
                ],
            }
        )
        st.dataframe(gold_objects, width="stretch", hide_index=True)


if __name__ == "__main__":
    main()
