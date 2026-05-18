from __future__ import annotations

import base64
import html
import json
import os
from pathlib import Path

from databricks import sql as databricks_sql
import pandas as pd
import plotly.express as px
import streamlit as st


st.set_page_config(
    page_title="F1 Gold Analytics",
    layout="wide",
    initial_sidebar_state="collapsed",
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

BASE_DIR = Path(__file__).resolve().parent
PRESENTATION_PDF = BASE_DIR / "assets" / "F1_Telemetry_Blueprint.pdf"
CIRCUIT_SVG_DIR = BASE_DIR / "assets" / "f1_circuits_svg"

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
    "decade": "Década",
    "story_segment": "Lectura",
    "anomaly_type": "Lectura del circuito",
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

    .circuit-card {
        background: #151515;
        border: 1px solid rgba(255, 255, 255, 0.14);
        border-radius: 22px;
        box-shadow: 0 18px 30px rgba(0, 0, 0, 0.22);
        overflow: hidden;
        min-height: 440px;
        display: flex;
        flex-direction: column;
    }

    .circuit-card-gallery {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
        gap: 1.25rem;
        margin: 1rem 0 1.4rem;
    }

    .circuit-card-image {
        background: #f7f7f7;
        height: 250px;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 1rem;
    }

    .circuit-card-image img {
        width: 100%;
        height: 210px;
        object-fit: contain;
    }

    .circuit-card-body {
        padding: 1.15rem 1.15rem 1.2rem;
        flex: 1;
        display: flex;
        flex-direction: column;
    }

    .circuit-card-kicker {
        color: #ff9f9f;
        font-size: 0.78rem;
        font-weight: 900;
        letter-spacing: 0.18em;
        text-transform: uppercase;
        margin-bottom: 0.65rem;
    }

    .circuit-card-title {
        color: #ffffff;
        font-size: 1.25rem;
        font-weight: 900;
        line-height: 1.12;
        margin-bottom: 0.45rem;
    }

    .circuit-card-city {
        color: #b8b8b8;
        font-size: 0.92rem;
        margin-bottom: 0.9rem;
    }

    .circuit-card-stats {
        color: #e9e9e9;
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 0.45rem;
        font-size: 0.82rem;
        margin-bottom: 1rem;
    }

    .circuit-card-stats strong {
        color: #ffffff;
        display: block;
        font-size: 1rem;
    }

    .circuit-card-actions {
        display: flex;
        gap: 0.75rem;
        margin-top: auto;
    }

    .circuit-card-action {
        align-items: center;
        border-radius: 999px;
        display: inline-flex;
        font-size: 0.9rem;
        font-weight: 800;
        gap: 0.4rem;
        justify-content: center;
        min-height: 38px;
        padding: 0 1rem;
        text-decoration: none !important;
        width: 50%;
    }

    .circuit-card-action.primary {
        background: #ffffff;
        color: #101010 !important;
    }

    .circuit-card-action.secondary {
        background: transparent;
        border: 1px solid rgba(255, 255, 255, 0.16);
        color: #ffffff !important;
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


@st.cache_data(show_spinner=False)
def render_pdf_pages_as_png(pdf_bytes: bytes, dpi: int = 150) -> list[bytes]:
    import fitz

    zoom = dpi / 72
    matrix = fitz.Matrix(zoom, zoom)
    pages: list[bytes] = []
    with fitz.open(stream=pdf_bytes, filetype="pdf") as document:
        for page in document:
            pixmap = page.get_pixmap(matrix=matrix, alpha=False)
            pages.append(pixmap.tobytes("png"))
    return pages


def clamp_pdf_page(page: int, total_pages: int) -> int:
    return min(max(page, 1), total_pages)


def set_pdf_page(page_state_key: str, page_select_key: str, total_pages: int, delta: int) -> None:
    current_page = int(st.session_state.get(page_state_key, 1))
    next_page = clamp_pdf_page(current_page + delta, total_pages)
    st.session_state[page_state_key] = next_page
    st.session_state[page_select_key] = next_page


def sync_pdf_page_selector(page_state_key: str, page_select_key: str, total_pages: int) -> None:
    selected_page = int(st.session_state.get(page_select_key, 1))
    next_page = clamp_pdf_page(selected_page, total_pages)
    st.session_state[page_state_key] = next_page
    st.session_state[page_select_key] = next_page


def render_pdf_viewer(pdf_path: Path, height: int = 780, key: str | None = None) -> None:
    if not pdf_path.exists():
        st.warning("No se encontró el archivo de presentación.")
        return

    pdf_bytes = pdf_path.read_bytes()
    st.download_button(
        "Descargar presentación PDF",
        data=pdf_bytes,
        file_name=pdf_path.name,
        mime="application/pdf",
        width="stretch",
        key=f"{key}_download" if key else None,
    )

    try:
        pages = render_pdf_pages_as_png(pdf_bytes)
    except Exception as exc:
        st.warning(f"No se pudo renderizar el PDF en pantalla: {exc}")
        encoded_pdf = base64.b64encode(pdf_bytes).decode("ascii")
        st.markdown(
            f"""
            <iframe
                src="data:application/pdf;base64,{encoded_pdf}"
                width="100%"
                height="{height}"
                style="border: 1px solid rgba(0, 48, 73, 0.18); border-radius: 8px;"
            ></iframe>
            """,
            unsafe_allow_html=True,
        )
        return

    if not pages:
        st.warning("El PDF no contiene páginas para mostrar.")
        return

    page_state_key = f"{key}_page_number" if key else "pdf_page_number"
    page_select_key = f"{key}_page_select" if key else "pdf_page_select"
    if page_state_key not in st.session_state:
        st.session_state[page_state_key] = 1

    current_page = min(max(int(st.session_state[page_state_key]), 1), len(pages))
    st.session_state[page_state_key] = current_page
    if page_select_key not in st.session_state:
        st.session_state[page_select_key] = current_page

    prev_col, page_col, count_col, next_col = st.columns([1, 2, 1, 1])
    with prev_col:
        st.button(
            "Anterior",
            disabled=current_page <= 1,
            key=f"{key}_prev" if key else None,
            width="stretch",
            on_click=set_pdf_page,
            args=(page_state_key, page_select_key, len(pages), -1),
        )
    with page_col:
        st.selectbox(
            "Página",
            options=list(range(1, len(pages) + 1)),
            index=current_page - 1,
            format_func=lambda page: f"Página {page}",
            key=page_select_key,
            on_change=sync_pdf_page_selector,
            args=(page_state_key, page_select_key, len(pages)),
        )
    with count_col:
        st.metric("Total", f"{current_page}/{len(pages)}")
    with next_col:
        st.button(
            "Siguiente",
            disabled=current_page >= len(pages),
            key=f"{key}_next" if key else None,
            width="stretch",
            on_click=set_pdf_page,
            args=(page_state_key, page_select_key, len(pages), 1),
        )

    page_number = int(st.session_state[page_state_key])
    st.image(
        pages[page_number - 1],
        caption=f"{pdf_path.name} - página {page_number} de {len(pages)}",
        use_container_width=True,
    )


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


def normalize_lookup(value: object) -> str:
    text = str(value or "").lower()
    replacements = {
        "á": "a",
        "à": "a",
        "ä": "a",
        "â": "a",
        "ã": "a",
        "é": "e",
        "è": "e",
        "ë": "e",
        "ê": "e",
        "í": "i",
        "ï": "i",
        "ó": "o",
        "ö": "o",
        "ô": "o",
        "õ": "o",
        "ú": "u",
        "ü": "u",
        "ñ": "n",
        "ç": "c",
    }
    for old, new in replacements.items():
        text = text.replace(old, new)
    return "".join(character if character.isalnum() else "-" for character in text).strip("-")


@st.cache_data(show_spinner=False)
def load_circuit_svg_metadata() -> list[dict[str, object]]:
    metadata_path = CIRCUIT_SVG_DIR / "circuits_metadata.json"
    if not metadata_path.exists():
        return []
    return json.loads(metadata_path.read_text(encoding="utf-8"))


def find_circuit_svg(circuit: pd.Series) -> tuple[Path | None, dict[str, object] | None]:
    metadata = load_circuit_svg_metadata()
    if not metadata:
        return None, None

    aliases = {
        "americas": "austin",
        "albert-park": "melbourne",
        "red-bull-ring": "spielberg",
        "catalunya": "catalunya",
        "villeneuve": "montreal",
        "ricard": "paul-ricard",
        "rodriguez": "mexico-city",
        "interlagos": "interlagos",
        "jose-carlos-pace": "interlagos",
        "jacarepagua": "jacarepagua",
        "yas-marina": "yas-marina",
    }
    candidates = {
        normalize_lookup(circuit.get("circuit_ref_normalized")),
        normalize_lookup(circuit.get("circuit_name")),
        normalize_lookup(circuit.get("location")),
    }
    alias_matches = {
        alias_value
        for alias_key, alias_value in aliases.items()
        if any(alias_key in candidate for candidate in candidates)
    }
    candidates.update(alias_matches)

    for item in metadata:
        item_keys = {
            normalize_lookup(item.get("id")),
            normalize_lookup(item.get("name")),
        }
        if candidates & item_keys:
            svg_path = CIRCUIT_SVG_DIR / str(item["svg"])
            return (svg_path if svg_path.exists() else None), item
    return None, None


def format_pct(value: object) -> str:
    return f"{float(value):.2f}%" if pd.notna(value) else "N/D"


def format_int(value: object) -> str:
    return f"{int(value):,}".replace(",", ".") if pd.notna(value) else "N/D"


def build_circuit_card(circuit: pd.Series) -> str:
    location = html.escape(str(circuit.get("location", "") or "").strip())
    country = html.escape(str(circuit.get("country", "") or "").strip())
    name = html.escape(str(circuit["circuit_name"]))
    svg_path, _ = find_circuit_svg(circuit)
    circuit_url = html.escape(str(circuit.get("url", "") or "#").strip() or "#")

    if svg_path:
        svg_bytes = svg_path.read_bytes()
        svg_base64 = base64.b64encode(svg_bytes).decode("ascii")
        svg_image = (
            f'<img src="data:image/svg+xml;base64,{svg_base64}" '
            f'alt="Trazado de {name}">'
        )
        download_attr = f'download="{html.escape(svg_path.name)}"'
        svg_href = f"data:image/svg+xml;base64,{svg_base64}"
    else:
        svg_image = '<span style="color:#555;font-weight:700;">Sin SVG disponible</span>'
        download_attr = ""
        svg_href = "#"

    return f"""
    <div class="circuit-card">
        <div class="circuit-card-image">{svg_image}</div>
        <div class="circuit-card-body">
            <div class="circuit-card-kicker">GP de {country or "F1"}</div>
            <div class="circuit-card-title">{name}</div>
            <div class="circuit-card-city">{location or "Ubicación no disponible"}</div>
            <div class="circuit-card-stats">
                <div>Pole a victoria<strong>{format_pct(circuit["pole_to_win_rate_pct"])}</strong></div>
                <div>No clasificación<strong>{format_pct(circuit["non_classified_rate_pct"])}</strong></div>
                <div>Entradas<strong>{format_int(circuit["total_entries"])}</strong></div>
                <div>Grandes premios<strong>{format_int(circuit["race_weekends_hosted"])}</strong></div>
            </div>
            <div class="circuit-card-actions">
                <a class="circuit-card-action primary" href="{circuit_url}" target="_blank" rel="noreferrer">Abrir</a>
                <a class="circuit-card-action secondary" href="{svg_href}" {download_attr}>SVG</a>
            </div>
        </div>
    </div>
    """


def translate_columns(df: pd.DataFrame, columns: list[str] | None = None) -> pd.DataFrame:
    view = df.copy()
    if columns is not None:
        view = view[columns]
    labels = {column: COLUMN_LABELS.get(column, column) for column in view.columns}
    return view.rename(columns=labels)


def get_kpi_row(kpis: pd.DataFrame, kpi_code: str) -> pd.Series | None:
    matches = kpis[kpis["kpi_code"] == kpi_code]
    if matches.empty:
        return None
    return matches.iloc[0]


def format_kpi_value(kpis: pd.DataFrame, kpi_code: str, fallback: str = "N/D") -> str:
    row = get_kpi_row(kpis, kpi_code)
    if row is None:
        return fallback
    return str(row.get("kpi_value_text") or fallback)


def numeric_kpi_value(kpis: pd.DataFrame, kpi_code: str) -> float | None:
    row = get_kpi_row(kpis, kpi_code)
    if row is None:
        return None
    value = row.get("kpi_value_numeric")
    if pd.isna(value):
        return None
    return float(value)


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
            SELECT
                cr.*,
                dc.circuit_ref_normalized,
                dc.location,
                dc.lat,
                dc.lng,
                dc.url
            FROM f1_gold.vw_dashboard_circuit_risk cr
            LEFT JOIN f1_silver.dim_circuits dc
                ON cr.circuitId = dc.circuitId
            ORDER BY cr.non_classified_rate_pct DESC, cr.total_entries DESC
            """,
        ),
        "qualifying": query(
            """
            SELECT *
            FROM f1_gold.mart_qualifying_effect_season
            ORDER BY season_year
            """,
        ),
        "pole_survival": query(
            """
            SELECT
                COUNT(*) AS pole_entries,
                SUM(CASE WHEN is_classified_finish THEN 1 ELSE 0 END) AS pole_classified_entries,
                COUNT(*) - SUM(CASE WHEN is_classified_finish THEN 1 ELSE 0 END) AS pole_non_classified_entries,
                ROUND(SUM(CASE WHEN is_classified_finish THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
                    AS pole_classified_rate_pct,
                ROUND((COUNT(*) - SUM(CASE WHEN is_classified_finish THEN 1 ELSE 0 END)) * 100.0 / COUNT(*), 2)
                    AS pole_non_classified_rate_pct
            FROM f1_silver.fact_race_entries
            WHERE qualified_on_pole = true
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
    server_hostname = get_setting(
        "DATABRICKS_SERVER_HOSTNAME",
        "dbc-27294608-e1ce.cloud.databricks.com",
    )
    http_path = get_setting(
        "DATABRICKS_HTTP_PATH",
        "/sql/1.0/warehouses/14f76675cb754d43",
    )
    catalog = get_setting("DATABRICKS_CATALOG", "f1")
    access_token = get_setting("DATABRICKS_TOKEN", "")

    with st.sidebar:
        st.title("F1 Gold")
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
            "- `F1_silver.fact_race_entries` (supervivencia desde pole)\n"
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
    for column in [
        "race_weekends_hosted",
        "total_entries",
        "non_classified_entries",
        "non_classified_rate_pct",
        "mechanical_non_classified_entries",
        "accident_non_classified_entries",
        "disqualified_entries",
        "pole_to_win_rate_pct",
        "lat",
        "lng",
    ]:
        if column in circuit_risk.columns:
            circuit_risk[column] = pd.to_numeric(circuit_risk[column], errors="coerce")
    qualifying = data["qualifying"]
    pole_survival = data["pole_survival"]
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
            "Storytelling Pole",
            "Carreras Recientes",
            "KPIs Versionados",
            "Arquitectura",
            "Presentación PDF",
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

        st.subheader("Tarjetas de circuitos")
        st.caption("Galería visual de pistas con trazados SVG y métricas clave.")
        selected_circuit_data = circuit_risk.sort_values(
            ["non_classified_rate_pct", "total_entries"],
            ascending=[False, False],
        ).head(8)
        cards_html = "\n".join(
            build_circuit_card(circuit) for _, circuit in selected_circuit_data.iterrows()
        )
        st.markdown(
            f'<div class="circuit-card-gallery">{cards_html}</div>',
            unsafe_allow_html=True,
        )
        st.caption("Trazados SVG: `julesr0y/f1-circuits-svg` (CC BY 4.0).")

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
        st.subheader("Storytelling: El Mito de la Pole Position")
        st.markdown(
            """
            En la Fórmula 1, se asume que ganar la clasificación del sábado garantiza
            la carrera del domingo. Pero los datos históricos cuentan una historia más
            interesante: riesgo, supervivencia, circuitos imposibles y épocas donde la
            pole vale mucho más que en otras.
            """
        )
        st.info(
            "Pregunta guía: ¿cuánto influye realmente la clasificación en el resultado final?"
        )

        pole_to_win_value = format_kpi_value(kpis, "pole_to_win_rate_pct")
        pole_to_win_numeric = numeric_kpi_value(kpis, "pole_to_win_rate_pct")
        pole_survival_row = pole_survival.iloc[0] if not pole_survival.empty else None
        pole_classified_rate = (
            float(pole_survival_row["pole_classified_rate_pct"])
            if pole_survival_row is not None and pd.notna(pole_survival_row["pole_classified_rate_pct"])
            else None
        )
        pole_non_classified_rate = (
            float(pole_survival_row["pole_non_classified_rate_pct"])
            if pole_survival_row is not None and pd.notna(pole_survival_row["pole_non_classified_rate_pct"])
            else None
        )

        impact_cols = st.columns(3)
        with impact_cols[0]:
            st.metric(
                "Conversión de Pole a Victoria",
                pole_to_win_value,
                help="Fuente: `F1_gold.vw_dashboard_kpi_cards`.",
            )
        with impact_cols[1]:
            st.metric(
                "Clasificación desde Pole",
                f"{pole_classified_rate:.2f}%" if pole_classified_rate is not None else "N/D",
                help="Fuente: `F1_silver.fact_race_entries`, filtrando participantes que clasificaron en pole.",
            )
        with impact_cols[2]:
            st.metric(
                "Abandono desde Pole",
                f"{pole_non_classified_rate:.2f}%" if pole_non_classified_rate is not None else "N/D",
                help="Fuente: `F1_silver.fact_race_entries`, calculado como no clasificación desde la primera posición.",
            )

        story_left, story_right = st.columns([3, 2])
        with story_left:
            yearly_trend = qualifying.copy()
            yearly_trend["season_year"] = pd.to_numeric(yearly_trend["season_year"], errors="coerce")
            yearly_trend["pole_to_win_rate_pct"] = pd.to_numeric(
                yearly_trend["pole_to_win_rate_pct"],
                errors="coerce",
            )
            yearly_trend = yearly_trend.dropna(
                subset=["season_year", "pole_to_win_rate_pct"]
            ).sort_values("season_year")
            if not yearly_trend.empty:
                yearly_trend["season_year"] = yearly_trend["season_year"].astype(int)
                yearly_trend["rolling_5y_pole_to_win_rate_pct"] = (
                    yearly_trend["pole_to_win_rate_pct"]
                    .rolling(window=5, min_periods=2)
                    .mean()
                )

                trend_long = yearly_trend.melt(
                    id_vars=["season_year", "race_weekends", "winners_from_pole"],
                    value_vars=[
                        "pole_to_win_rate_pct",
                        "rolling_5y_pole_to_win_rate_pct",
                    ],
                    var_name="metric",
                    value_name="value",
                ).dropna(subset=["value"])
                trend_long["metric"] = trend_long["metric"].map(
                    {
                        "pole_to_win_rate_pct": "Conversión anual",
                        "rolling_5y_pole_to_win_rate_pct": "Media móvil 5 años",
                    }
                )

                trend_fig = px.line(
                    trend_long,
                    x="season_year",
                    y="value",
                    color="metric",
                    markers=True,
                    labels=COLUMN_LABELS,
                    color_discrete_map={
                        "Conversión anual": "#669bbc",
                        "Media móvil 5 años": "#c1121f",
                    },
                    title="Evolución anual: conversión de Pole a Victoria",
                    hover_data={
                        "race_weekends": True,
                        "winners_from_pole": True,
                        "value": ":.2f",
                    },
                )
                trend_fig.update_yaxes(autorange=True, ticksuffix="%")
                trend_fig.update_layout(yaxis_title="Conversión Pole a Victoria (%)")
                st.plotly_chart(style_plot(trend_fig), width="stretch")

                best_year = yearly_trend.sort_values("pole_to_win_rate_pct", ascending=False).iloc[0]
                strongest_window = yearly_trend.dropna(
                    subset=["rolling_5y_pole_to_win_rate_pct"]
                ).sort_values("rolling_5y_pole_to_win_rate_pct", ascending=False).iloc[0]
                st.caption(
                    f"Punto de lectura: el pico anual fue {int(best_year['season_year'])} "
                    f"({best_year['pole_to_win_rate_pct']:.2f}%). "
                    f"La media móvil de 5 años alcanza su punto más alto alrededor de "
                    f"{int(strongest_window['season_year'])} "
                    f"({strongest_window['rolling_5y_pole_to_win_rate_pct']:.2f}%)."
                )
            else:
                st.warning("No hay datos suficientes para construir la evolución anual.")

        with story_right:
            st.markdown(
                """
                **Lectura ejecutiva**

                Una Pole Position no es solamente velocidad pura. Es una combinación de:

                - dificultad de adelantar,
                - confiabilidad mecánica,
                - riesgo histórico del circuito,
                - cambios reglamentarios,
                - y capacidad del equipo para convertir ventaja en resultado.
                """
            )
            if pole_to_win_numeric is not None:
                st.success(
                    f"En el histórico consolidado, la Pole se convierte en victoria el {pole_to_win_numeric:.2f}% de las veces."
                )

        story_risk = circuit_risk.copy()
        numeric_story_columns = [
            "non_classified_rate_pct",
            "pole_to_win_rate_pct",
            "total_entries",
            "race_weekends_hosted",
        ]
        for column in numeric_story_columns:
            if column in story_risk.columns:
                story_risk[column] = pd.to_numeric(story_risk[column], errors="coerce")
        story_risk = story_risk.dropna(
            subset=["non_classified_rate_pct", "pole_to_win_rate_pct"]
        )
        if not story_risk.empty:
            risk_threshold = story_risk["non_classified_rate_pct"].quantile(0.75)
            pole_threshold = story_risk["pole_to_win_rate_pct"].quantile(0.75)
            low_pole_threshold = story_risk["pole_to_win_rate_pct"].quantile(0.25)

            def classify_circuit(row: pd.Series) -> str:
                if (
                    row["non_classified_rate_pct"] >= risk_threshold
                    and row["pole_to_win_rate_pct"] >= pole_threshold
                ):
                    return "Pole protege en alto riesgo"
                if (
                    row["non_classified_rate_pct"] >= risk_threshold
                    and row["pole_to_win_rate_pct"] <= low_pole_threshold
                ):
                    return "Riesgo supera la pole"
                if row["pole_to_win_rate_pct"] >= pole_threshold:
                    return "Control desde la pole"
                return "Patrón histórico"

            story_risk["story_segment"] = story_risk.apply(classify_circuit, axis=1)
            top_pole_circuits = (
                story_risk.sort_values(
                    ["pole_to_win_rate_pct", "total_entries"],
                    ascending=[False, False],
                )
                .head(5)
                .copy()
            )
            bottom_pole_circuits = (
                story_risk.sort_values(
                    ["pole_to_win_rate_pct", "total_entries"],
                    ascending=[True, False],
                )
                .head(5)
                .copy()
            )
            top_pole_circuits["pole_extreme_type"] = "Garantía"
            bottom_pole_circuits["pole_extreme_type"] = "Riesgo"
            top_bottom_circuits = pd.concat(
                [bottom_pole_circuits, top_pole_circuits],
                ignore_index=True,
            )
            top_bottom_circuits["circuit_story_label"] = (
                top_bottom_circuits["circuit_name"]
                + " ("
                + top_bottom_circuits["country"].astype(str)
                + ")"
            )

            extremes_fig = px.bar(
                top_bottom_circuits.sort_values("pole_to_win_rate_pct", ascending=True),
                x="pole_to_win_rate_pct",
                y="circuit_story_label",
                orientation="h",
                color="pole_extreme_type",
                text="pole_to_win_rate_pct",
                labels={
                    **COLUMN_LABELS,
                    "circuit_story_label": "Circuito",
                    "pole_extreme_type": "Lectura",
                },
                color_discrete_map={
                    "Garantía": "#2a9d8f",
                    "Riesgo": "#c1121f",
                },
                title="La Trampa vs. La Garantía: extremos del calendario",
                hover_data={
                    "country": False,
                    "total_entries": True,
                    "race_weekends_hosted": True,
                    "non_classified_rate_pct": ":.2f",
                    "pole_to_win_rate_pct": ":.2f",
                    "pole_extreme_type": False,
                    "circuit_story_label": False,
                },
            )
            extremes_fig.update_traces(texttemplate="%{text:.1f}%", textposition="outside")
            extremes_fig.update_xaxes(range=[0, 100], ticksuffix="%")
            extremes_fig.update_layout(
                xaxis_title="Conversión Pole a Victoria (%)",
                yaxis_title="",
                legend_title_text="Lectura",
            )
            st.plotly_chart(style_plot(extremes_fig), width="stretch")
            st.caption(
                "Lectura rápida: las barras muestran los cinco circuitos donde la Pole más se convierte en victoria "
                "frente a los cinco donde la ventaja inicial pierde más fuerza."
            )

            label_candidates = story_risk[
                story_risk["story_segment"].isin(
                    [
                        "Pole protege en alto riesgo",
                        "Riesgo supera la pole",
                        "Control desde la pole",
                    ]
                )
            ].copy()
            label_candidates["label_score"] = (
                label_candidates["non_classified_rate_pct"].rank(ascending=False)
                + label_candidates["pole_to_win_rate_pct"].rank(ascending=False)
            )
            label_names = set(
                label_candidates.sort_values("label_score", ascending=False)
                .head(8)["circuit_name"]
                .tolist()
            )
            story_risk["circuit_label"] = story_risk["circuit_name"].where(
                story_risk["circuit_name"].isin(label_names),
                "",
            )

            circuit_story_fig = px.scatter(
                story_risk,
                x="non_classified_rate_pct",
                y="pole_to_win_rate_pct",
                size="total_entries",
                color="story_segment",
                text="circuit_label",
                hover_name="circuit_name",
                hover_data={
                    "country": True,
                    "race_weekends_hosted": True,
                    "total_entries": True,
                    "non_classified_rate_pct": ":.2f",
                    "pole_to_win_rate_pct": ":.2f",
                    "story_segment": False,
                },
                labels=COLUMN_LABELS,
                color_discrete_map={
                    "Pole protege en alto riesgo": "#003049",
                    "Riesgo supera la pole": "#c1121f",
                    "Control desde la pole": "#f77f00",
                    "Patrón histórico": "#669bbc",
                },
                title="Circuitos: supervivencia histórica vs valor de la Pole",
            )
            circuit_story_fig.update_traces(
                textposition="top center",
                textfont=dict(size=11),
                marker=dict(line=dict(width=0.7, color="white")),
            )
            st.plotly_chart(style_plot(circuit_story_fig), width="stretch")
            st.caption(
                "Eje X: tasa histórica de abandonos/no clasificación del circuito. "
                "Eje Y: conversión de Pole a Victoria. Los colores separan circuitos anómalos frente al patrón histórico."
            )
        else:
            st.warning("No hay datos suficientes para cruzar riesgo de circuito y conversión de pole.")

        st.info(
            "Conclusión: la clasificación influye mucho, pero no actúa sola. "
            "La Pole Position es una ventaja estratégica cuando el circuito permite control; "
            "en trazados con alto riesgo histórico, la confiabilidad y la supervivencia pueden pesar tanto como la velocidad del sábado."
        )
        with st.expander("Trazabilidad técnica: consultas y cálculos del slide"):
            st.markdown(
                """
                Esta vista consume principalmente objetos ya procesados de la arquitectura Medallón.
                La lectura ejecutiva se apoya en la capa `f1_gold`, mientras que la métrica de
                supervivencia desde Pole se calcula puntualmente desde `f1_silver.fact_race_entries`.
                """
            )
            st.markdown("**1. KPI principal: conversión Pole a Victoria**")
            st.code(
                """
SELECT
    kpi_code,
    kpi_name,
    kpi_value_numeric,
    kpi_value_text
FROM f1_gold.vw_dashboard_kpi_cards
WHERE kpi_code = 'pole_to_win_rate_pct';
                """.strip(),
                language="sql",
            )
            st.markdown("**2. Supervivencia desde Pole**")
            st.code(
                """
SELECT
    COUNT(*) AS pole_entries,
    SUM(CASE WHEN is_classified_finish THEN 1 ELSE 0 END) AS pole_classified_entries,
    COUNT(*) - SUM(CASE WHEN is_classified_finish THEN 1 ELSE 0 END) AS pole_non_classified_entries,
    ROUND(SUM(CASE WHEN is_classified_finish THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
        AS pole_classified_rate_pct,
    ROUND((COUNT(*) - SUM(CASE WHEN is_classified_finish THEN 1 ELSE 0 END)) * 100.0 / COUNT(*), 2)
        AS pole_non_classified_rate_pct
FROM f1_silver.fact_race_entries
WHERE qualified_on_pole = true;
                """.strip(),
                language="sql",
            )
            st.markdown("**3. Evolución anual y media móvil de 5 años**")
            st.code(
                """
SELECT *
FROM f1_gold.mart_qualifying_effect_season
ORDER BY season_year;
                """.strip(),
                language="sql",
            )
            st.code(
                """
yearly_trend["rolling_5y_pole_to_win_rate_pct"] = (
    yearly_trend["pole_to_win_rate_pct"]
    .rolling(window=5, min_periods=2)
    .mean()
)
                """.strip(),
                language="python",
            )
            st.markdown("**4. Riesgo por circuito: barras y scatter**")
            st.code(
                """
SELECT *
FROM f1_gold.vw_dashboard_circuit_risk
ORDER BY non_classified_rate_pct DESC, total_entries DESC;
                """.strip(),
                language="sql",
            )
            st.markdown(
                """
                Las barras toman los cinco circuitos con mayor conversión de Pole a Victoria
                y los cinco con menor conversión. El scatter clasifica anomalías usando percentiles:
                `P75` de riesgo, `P75` de conversión desde Pole y `P25` de conversión desde Pole.
                """
            )
            st.code(
                """
risk_threshold = story_risk["non_classified_rate_pct"].quantile(0.75)
pole_threshold = story_risk["pole_to_win_rate_pct"].quantile(0.75)
low_pole_threshold = story_risk["pole_to_win_rate_pct"].quantile(0.25)
                """.strip(),
                language="python",
            )

    with tabs[6]:
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

    with tabs[7]:
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

    with tabs[8]:
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

    with tabs[9]:
        st.subheader("Presentación PDF del proyecto")
        st.caption("Material complementario: `F1_Telemetry_Blueprint.pdf`")
        render_pdf_viewer(PRESENTATION_PDF, key="pdf_presentacion")


if __name__ == "__main__":
    main()
