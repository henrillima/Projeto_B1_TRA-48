#!/usr/bin/env python3
"""
Gera o site estático do grafo de governança a partir do DuckDB.

O site é o entregável da Camada B: é por ele que o professor lê o processo, e é
o ponto de partida dos encontros de acompanhamento (tarefa:T03). Tudo
autocontido — nenhum CDN, nenhuma fonte remota, nenhum XHR: precisa abrir de um
pen drive, offline, na arguição.

    uv run python governanca/tools/site.py \
        --db governanca/build/grafo.duckdb --out _site/
"""
from __future__ import annotations

import argparse
import html
import json
import subprocess
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

import duckdb
import networkx as nx

SEED = 20260824          # a mesma do _targets.R; layout determinístico entre builds
VENDOR = Path(__file__).parent / "vendor" / "cytoscape.min.js"
REPO_URL = "https://github.com/henrillima/Projeto_B1_TRA-48/blob/main/"

CORES = {"meta": "#7c3aed", "tarefa": "#2563eb", "decisao": "#059669",
         "pendencia": "#dc2626", "fonte": "#d97706", "referencia": "#a16207",
         "experimento": "#0891b2", "arquivo": "#64748b", "conclusao": "#be185d",
         "ia": "#7c2d12", "pessoa": "#334155"}

KANBAN = ["backlog", "pronta", "fazendo", "revisao", "feita"]

CSS = """
*{box-sizing:border-box}
:root{
  --bg:#f7f8f9;--surf:#fff;--surf2:#eef0f3;--ink:#12161c;--ink2:#3d4652;
  --mut:#6b7684;--rule:#dde1e7;--acc:#0e5551;--warn:#a34419;--dang:#a02c2c;
  --f:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  --m:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;
}
@media(prefers-color-scheme:dark){:root{
  --bg:#0d1116;--surf:#151b22;--surf2:#1d242c;--ink:#e4e9ee;--ink2:#b3bdc7;
  --mut:#7d8894;--rule:#252d36;--acc:#4eb0a7;--warn:#e08a5a;--dang:#e07a7a;}}
body{margin:0;background:var(--bg);color:var(--ink);font-family:var(--f);
  font-size:15px;line-height:1.55;-webkit-font-smoothing:antialiased}
a{color:var(--ink);text-decoration-color:var(--acc);text-underline-offset:2px}
header.top{background:var(--surf);border-bottom:1px solid var(--rule);
  padding:14px 22px;display:flex;align-items:baseline;gap:20px;flex-wrap:wrap;
  position:sticky;top:0;z-index:50}
header.top b{font-size:15px;letter-spacing:-.01em}
header.top nav{display:flex;gap:16px;margin-left:auto;flex-wrap:wrap}
header.top nav a{font-size:12.5px;text-transform:uppercase;letter-spacing:.07em;
  color:var(--mut);text-decoration:none}
header.top nav a:hover,header.top nav a.on{color:var(--ink);
  border-bottom:2px solid var(--warn)}
main{max-width:1180px;margin:0 auto;padding:26px 22px 80px}
h1{font-size:24px;letter-spacing:-.02em;margin:0 0 4px}
h2{font-size:16px;letter-spacing:-.01em;margin:32px 0 10px;
  padding-bottom:6px;border-bottom:1px solid var(--rule)}
.sub{color:var(--mut);font-size:13.5px;margin:0 0 22px}
.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));
  gap:12px;margin:20px 0}
.card{background:var(--surf);border:1px solid var(--rule);border-radius:3px;padding:14px 16px}
.card .k{font-family:var(--m);font-size:10px;letter-spacing:.11em;
  text-transform:uppercase;color:var(--mut);display:block}
.card .v{font-size:27px;font-weight:600;letter-spacing:-.02em;display:block;
  margin-top:3px;font-variant-numeric:tabular-nums}
.card .v small{font-size:13px;font-weight:400;color:var(--mut)}
table{border-collapse:collapse;width:100%;font-size:13.5px;background:var(--surf)}
.tw{overflow-x:auto;border:1px solid var(--rule);border-radius:3px;margin:14px 0}
th,td{text-align:left;padding:8px 12px;border-bottom:1px solid var(--rule);vertical-align:top}
thead th{font-family:var(--m);font-size:10px;letter-spacing:.09em;
  text-transform:uppercase;color:var(--mut);font-weight:500;background:var(--surf2)}
tbody tr:last-child td{border-bottom:0}
td.n{font-family:var(--m);font-variant-numeric:tabular-nums}
.tag{display:inline-block;font-family:var(--m);font-size:9.5px;font-weight:700;
  letter-spacing:.08em;text-transform:uppercase;padding:2px 7px;border-radius:2px;
  color:#fff;white-space:nowrap}
.pill{display:inline-block;font-family:var(--m);font-size:10px;padding:2px 7px;
  border-radius:2px;background:var(--surf2);color:var(--mut);white-space:nowrap}
.pill.bad{background:#fde8e8;color:#a02c2c}
@media(prefers-color-scheme:dark){.pill.bad{background:#2a1414;color:#e07a7a}}
pre,.mono{font-family:var(--m);font-size:12.5px;white-space:pre-wrap;
  word-break:break-word;background:var(--surf2);padding:12px 14px;border-radius:3px}
.bar{height:7px;background:var(--surf2);border-radius:4px;overflow:hidden;min-width:70px}
.bar i{display:block;height:100%;background:var(--acc)}
.bar i.w{background:var(--warn)}
.bar i.d{background:var(--dang)}
footer{max-width:1180px;margin:0 auto;padding:22px;color:var(--mut);font-size:12.5px;
  border-top:1px solid var(--rule)}
"""


# ---------------------------------------------------------------- carga

def carregar_grafo(db: Path) -> tuple[list[tuple], list[tuple], dict[str, dict]]:
    """Lê node e edge do banco. ORDER BY em tudo: build determinístico."""
    with duckdb.connect(str(db), read_only=True) as con:
        nos = con.execute(
            "SELECT id, kind, titulo, status, criado_em, props "
            "FROM node ORDER BY id").fetchall()
        arestas = con.execute(
            "SELECT src, dst, rel FROM edge ORDER BY src, rel, dst").fetchall()
        props = {r[0]: json.loads(r[1]) for r in
                 con.execute("SELECT id, props FROM node").fetchall()}
    return nos, arestas, props


def montar_nx(nos: list[tuple], arestas: list[tuple]) -> nx.DiGraph:
    """Constrói o DiGraph. As arestas já foram validadas contra órfã no build."""
    g = nx.DiGraph()
    for nid, kind, titulo, status, *_ in nos:
        g.add_node(nid, kind=kind, titulo=titulo, status=status)
    for src, dst, rel in arestas:
        g.add_edge(src, dst, rel=rel)
    return g


def metricas(g: nx.DiGraph) -> dict[str, Any]:
    """Métricas estruturais. betweenness no grafo não-dirigido: a pergunta é
    'quem é ponte entre partes do projeto', e a ponte não tem direção."""
    ug = g.to_undirected()
    return {
        "grau": nx.degree_centrality(g),
        "intermediacao": nx.betweenness_centrality(ug),
        "componentes": nx.number_weakly_connected_components(g),
        "orfaos": sorted(n for n in g if g.degree(n) == 0),
    }


def posicoes(g: nx.DiGraph) -> dict[str, tuple[float, float]]:
    """Layout pré-calculado, determinístico.

    Determinismo é requisito, não conveniência: se o layout rodasse no
    navegador, o mesmo grafo apareceria diferente a cada visita, e comparar o
    site de hoje com a captura da semana passada deixaria de significar algo.

    Kamada-Kawai em vez de spring porque este grafo tem hubs muito pesados —
    `pessoa:henri` com grau 21, `meta:M4` com 15 — e o modelo de molas deixa os
    hubs comprimirem tudo contra o centro e jogarem as folhas para longe. O
    Kamada-Kawai minimiza a diferença entre distância no desenho e distância no
    grafo, o que distribui bem melhor (medido: dispersão 1,8 contra 2,6).
    É O(n²) e portanto inviável em grafo grande; com algumas centenas de nós é
    instantâneo, e este grafo não vai passar disso.

    Sem seed: o Kamada-Kawai é determinístico por construção, não estocástico.
    """
    pos = nx.kamada_kawai_layout(g.to_undirected(), scale=1000)
    return {n: (round(float(p[0]), 1), round(float(p[1]), 1)) for n, p in pos.items()}


def elementos(nos, met, pos) -> dict:
    """Monta o graph.json no formato de elementos do Cytoscape."""
    return {
        "nodes": [{
            "data": {"id": nid, "kind": kind, "label": titulo, "status": status,
                     "curto": nid.split(":", 1)[1],
                     "grau": round(met["grau"].get(nid, 0.0), 4),
                     "url": f"registros/{nid.replace(':', '_')}.html"},
            "position": {"x": pos[nid][0], "y": pos[nid][1]},
        } for nid, kind, titulo, status, *_ in nos],
        "edges": [],   # preenchido em main(), onde a lista de arestas está viva
    }


def cadencia_git(repo: Path) -> Counter:
    """Commits por semana ISO, lidos do git.

    Precisa de fetch-depth: 0 no checkout — com histórico raso o gráfico de
    cadência sai truncado e a métrica publicada mente para menos.
    """
    try:
        saida = subprocess.run(
            ["git", "-C", str(repo), "log", "--date=format:%G-W%V", "--pretty=%ad"],
            capture_output=True, text=True, check=True).stdout
    except (subprocess.CalledProcessError, FileNotFoundError):
        return Counter()
    return Counter(saida.split())


# ------------------------------------------------------------- helpers

def e(t: Any) -> str:
    """Escapa para HTML. Todo conteúdo do grafo passa por aqui: o texto vem de
    YAML escrito à mão e de transcrições, e um `<` solto quebraria a página."""
    return html.escape(str(t if t is not None else ""))


def slug(nid: str) -> str:
    return nid.replace(":", "_")


def tag(kind: str) -> str:
    return f'<span class="tag" style="background:{CORES.get(kind, "#666")}">{e(kind)}</span>'


def pagina(titulo: str, corpo: str, ativo: str = "", prefixo: str = "") -> str:
    """Casco comum. O CSS é embutido em toda página em vez de referenciado:
    são ~4 KB e elimina uma requisição que poderia falhar em `file://`."""
    nav = [("index.html", "Grafo"), ("kanban.html", "Kanban"),
           ("trilha.html", "Trilha"), ("auditoria.html", "Auditoria")]
    links = "".join(
        '<a href="{}{}"{}>{}</a>'.format(
            prefixo, h, ' class="on"' if h == ativo else "", t)
        for h, t in nav)
    return (f'<!doctype html><html lang="pt-BR"><head><meta charset="utf-8">'
            f'<meta name="viewport" content="width=device-width,initial-scale=1">'
            f'<title>{e(titulo)} · Projeto B1</title><style>{CSS}</style></head>'
            f'<body><header class="top"><b>Projeto B1 — Vertiportos em São Paulo</b>'
            f'<nav>{links}</nav></header>{corpo}'
            f'<footer>TRA-48 · ITA · 2026.2 — Henri Leonardo, Pedro Karbage, '
            f'Antônio Garcia. Gerado do banco de governança; o texto em '
            f'<code>governanca/data/</code> é a fonte de verdade.</footer>'
            f'</body></html>')


def bloqueadas(nos, arestas) -> set[str]:
    """Estado DERIVADO. Ver regra 6 do CLAUDE.md: guardar isto como coluna
    criaria uma segunda fonte de verdade que envelhece e mente."""
    abertas = {n[0] for n in nos if n[1] == "pendencia" and n[3] == "aberta"}
    return {d for s, d, r in arestas if r == "BLOQUEIA" and s in abertas}


# ------------------------------------------------------------ escritores

def escrever_index(saida: Path, els: dict, nos, arestas) -> None:
    """A página do grafo executivo. Cytoscape embutido, layout `preset`."""
    cy = VENDOR.read_text(encoding="utf-8") if VENDOR.exists() else ""
    if not cy:
        raise SystemExit(f"FATAL: {VENDOR} não encontrado. Ver G01 §5.5.")

    porkind = Counter(n[1] for n in nos)
    legenda = "".join(
        f'<label style="display:inline-flex;align-items:center;gap:5px;'
        f'margin:0 12px 6px 0;font-size:12.5px;cursor:pointer">'
        f'<input type="checkbox" checked data-kind="{e(k)}">'
        f'{tag(k)}<span style="color:var(--mut)">{v}</span></label>'
        for k, v in sorted(porkind.items()))

    metas = [n for n in nos if n[1] == "meta"]
    bl = bloqueadas(nos, arestas)
    fazendo = [n for n in nos if n[1] == "tarefa" and n[3] == "fazendo"]

    estado = "".join(
        f'<div class="card"><span class="k">{e(k)}</span>'
        f'<span class="v">{v}</span></div>'
        for k, v in [("nós", len(nos)), ("arestas", len(arestas)),
                     ("metas abertas", sum(1 for m in metas if m[3] == "aberta")),
                     ("em execução", len(fazendo)), ("bloqueadas", len(bl))])

    proximas = "".join(
        f'<li><a href="registros/{slug(n[0])}.html">{e(n[2])}</a> '
        f'<span class="pill">{e(n[0])}</span></li>' for n in fazendo) or "<li>nenhuma</li>"

    corpo = f"""<main>
<h1>Grafo executivo</h1>
<p class="sub">Clique em um nó para abrir o registro. Arraste para navegar, role para
aproximar. O layout é pré-calculado com semente fixa — o mesmo grafo desenha igual
a cada build, para que comparar duas capturas signifique alguma coisa.</p>
<div class="cards">{estado}</div>
<h2>Em execução agora</h2><ul>{proximas}</ul>
<h2>O grafo</h2>
<div style="margin:10px 0 8px">{legenda}</div>
<div id="cy" style="height:620px;background:var(--surf);border:1px solid var(--rule);
     border-radius:3px"></div>
<p class="sub" style="margin-top:10px">Aresta tracejada em vermelho = <code>BLOQUEIA</code>.
Tamanho do nó = grau de centralidade.</p>
</main>
<script>{cy}</script>
<script>
const ELS = {json.dumps(els, ensure_ascii=False)};
const CORES = {json.dumps(CORES)};
const cy = cytoscape({{
  container: document.getElementById('cy'),
  elements: ELS,
  layout: {{ name: 'preset' }},
  minZoom: 0.15, maxZoom: 3,
  style: [
    {{ selector: 'node', style: {{
        'background-color': ele => CORES[ele.data('kind')] || '#666',
        'width':  ele => 20 + 140 * ele.data('grau'),
        'height': ele => 20 + 140 * ele.data('grau'),
        'label': 'data(curto)', 'font-size': 11, 'font-weight': 600,
        'color': '#5b6672', 'text-valign': 'bottom', 'text-margin-y': 4,
        'text-background-color': '#fff', 'text-background-opacity': 0.8,
        'text-background-padding': 2, 'border-width': 1.5, 'border-color': '#fff',
        // Some no zoom de saída: com 56 nós o rótulo de tudo vira mancha.
        'min-zoomed-font-size': 9 }} }},
    // Metas e pessoas são a orientação do mapa — rótulo sempre visível,
    // senão o primeiro olhar é um punhado de bolinhas anônimas.
    {{ selector: 'node[kind = "meta"], node[kind = "pessoa"]', style: {{
        'font-size': 30, 'color': '#12161c', 'min-zoomed-font-size': 0 }} }},
    {{ selector: 'edge', style: {{
        'width': 1, 'line-color': '#b8c0c8', 'target-arrow-color': '#b8c0c8',
        'target-arrow-shape': 'triangle', 'arrow-scale': 0.5,
        'curve-style': 'bezier', 'opacity': 0.45 }} }},
    {{ selector: 'edge[rel = "BLOQUEIA"]', style: {{
        'line-color': '#dc2626', 'target-arrow-color': '#dc2626',
        'line-style': 'dashed', 'width': 1.6, 'opacity': 0.9 }} }},
    {{ selector: '.dim', style: {{ 'opacity': 0.07 }} }},
    {{ selector: '.hot', style: {{ 'opacity': 1, 'border-width': 2,
        'border-color': '#a34419' }} }}
  ]
}});
cy.fit(undefined, 40);
cy.on('tap', 'node', evt => {{ window.location = evt.target.data('url'); }});
cy.on('mouseover', 'node', evt => {{
  const n = evt.target, viz = n.closedNeighborhood();
  cy.elements().addClass('dim'); viz.removeClass('dim'); n.addClass('hot');
  document.getElementById('cy').title = n.data('label');
}});
cy.on('mouseout', 'node', () => cy.elements().removeClass('dim hot'));
document.querySelectorAll('input[data-kind]').forEach(cb => {{
  cb.addEventListener('change', () => {{
    const off = [...document.querySelectorAll('input[data-kind]')]
      .filter(x => !x.checked).map(x => x.dataset.kind);
    cy.nodes().forEach(n => n.style('display',
      off.includes(n.data('kind')) ? 'none' : 'element'));
  }});
}});
</script>"""
    (saida / "index.html").write_text(pagina("Grafo", corpo, "index.html"),
                                      encoding="utf-8")


def escrever_registros(saida: Path, nos, arestas, props) -> None:
    """Uma página por nó. É o destino do clique no grafo, e o que a arguição abre."""
    sai, ent = defaultdict(list), defaultdict(list)
    for s, d, r in arestas:
        sai[s].append((r, d))
        ent[d].append((r, s))
    titulos = {n[0]: n[2] for n in nos}
    kinds = {n[0]: n[1] for n in nos}

    def linkar(rel: str, outro: str) -> str:
        t = e(titulos.get(outro, outro))
        return (f'<tr><td><span class="pill">{e(rel)}</span></td>'
                f'<td>{tag(kinds.get(outro, "?"))} '
                f'<a href="{slug(outro)}.html">{t}</a><br>'
                f'<span class="pill">{e(outro)}</span></td></tr>')

    for nid, kind, titulo, status, criado, _ in nos:
        p = props.get(nid, {})
        blocos: list[str] = []

        for campo in ("descricao", "critica_humana", "limitacoes"):
            if p.get(campo):
                rot = {"descricao": "Descrição", "critica_humana": "Crítica humana",
                       "limitacoes": "Limitações conhecidas"}[campo]
                blocos.append(f"<h2>{rot}</h2><div class='mono'>{e(p[campo])}</div>")

        if p.get("alternativas_descartadas"):
            linhas = "".join(
                f"<tr><td>{e(a.get('opcao'))}</td><td>{e(a.get('por_que_nao'))}</td></tr>"
                for a in p["alternativas_descartadas"])
            blocos.append("<h2>Alternativas descartadas</h2><div class='tw'><table>"
                          "<thead><tr><th>Opção</th><th>Por que não</th></tr></thead>"
                          f"<tbody>{linhas}</tbody></table></div>")

        if p.get("notas"):
            linhas = "".join(
                f"<tr><td class='n'>{e(n.get('data'))}</td>"
                f"<td class='n'>{e(n.get('autor'))}</td><td>{e(n.get('texto'))}</td></tr>"
                for n in p["notas"])
            blocos.append("<h2>Observações</h2><div class='tw'><table><thead><tr>"
                          "<th>Data</th><th>Autor</th><th>Texto</th></tr></thead>"
                          f"<tbody>{linhas}</tbody></table></div>")

        campos = {k: v for k, v in p.items()
                  if k not in ("descricao", "critica_humana", "limitacoes",
                               "alternativas_descartadas", "notas", "_arquivo")}
        if campos:
            linhas = "".join(
                f"<tr><td class='n'>{e(k)}</td><td>{e(json.dumps(v, ensure_ascii=False) if isinstance(v, (dict, list)) else v)}</td></tr>"
                for k, v in sorted(campos.items()))
            blocos.append("<h2>Campos</h2><div class='tw'><table><tbody>"
                          f"{linhas}</tbody></table></div>")

        if sai[nid]:
            blocos.append("<h2>Aponta para</h2><div class='tw'><table><tbody>"
                          + "".join(linkar(r, d) for r, d in sorted(sai[nid]))
                          + "</tbody></table></div>")
        if ent[nid]:
            blocos.append("<h2>Apontado por</h2><div class='tw'><table><tbody>"
                          + "".join(linkar(r, s) for r, s in sorted(ent[nid]))
                          + "</tbody></table></div>")

        arq = p.get("_arquivo", "")
        fonte = (f'<p class="sub"><a href="{REPO_URL}{e(arq)}">'
                 f'{e(arq)}</a> — a fonte de verdade deste registro</p>') if arq else ""

        corpo = (f'<main><p class="sub">{tag(kind)} <span class="pill">{e(nid)}</span>'
                 + (f' <span class="pill">{e(status)}</span>' if status else "")
                 + (f' <span class="pill">criado {e(criado)}</span>' if criado else "")
                 + f'</p><h1>{e(titulo)}</h1>{fonte}' + "".join(blocos) + "</main>")

        (saida / "registros" / f"{slug(nid)}.html").write_text(
            pagina(titulo, corpo, prefixo="../"), encoding="utf-8")


def escrever_kanban(saida: Path, nos, arestas, props) -> None:
    """O quadro. Seis colunas: cinco armazenadas e uma derivada."""
    bl = bloqueadas(nos, arestas)
    resp = {s: d.split(":")[1] for s, d, r in arestas if r == "ATRIBUIDA_A"}
    pai = {s: d for s, d, r in arestas if r == "SUBTAREFA_DE"}
    tarefas = [n for n in nos if n[1] == "tarefa"]

    def cartao(n) -> str:
        nid, _, titulo, status, *_ = n
        p = props.get(nid, {})
        marca = ' <span class="pill bad">bloqueada</span>' if nid in bl else ""
        sub = f' <span class="pill">↳ {e(pai[nid].split(":")[1])}</span>' if nid in pai else ""
        return (f'<tr><td class="n"><a href="registros/{slug(nid)}.html">'
                f'{e(nid.split(":")[1])}</a></td>'
                f'<td>{e(titulo)}{sub}{marca}</td>'
                f'<td class="n">{e(resp.get(nid, "—"))}</td>'
                f'<td class="n">{e(p.get("prazo", "—"))}</td></tr>')

    secoes = []
    for col in KANBAN:
        itens = [n for n in tarefas if n[3] == col]
        if not itens:
            secoes.append(f'<h2>{col} <span class="pill">0</span></h2>'
                          '<p class="sub">vazia</p>')
            continue
        secoes.append(
            f'<h2>{col} <span class="pill">{len(itens)}</span></h2>'
            '<div class="tw"><table><thead><tr><th>id</th><th>Tarefa</th>'
            '<th>Resp.</th><th>Prazo</th></tr></thead><tbody>'
            + "".join(cartao(n) for n in sorted(itens, key=lambda x: x[0]))
            + "</tbody></table></div>")

    porresp = Counter(resp.get(n[0], "—") for n in tarefas)
    cards = "".join(f'<div class="card"><span class="k">{e(k)}</span>'
                    f'<span class="v">{v}<small> tarefas</small></span></div>'
                    for k, v in sorted(porresp.items()))

    corpo = (f'<main><h1>Kanban</h1><p class="sub">'
             f'{len(tarefas)} tarefas. A coluna <b>bloqueada</b> não existe no dado — '
             f'é derivada de pendência aberta apontando para a tarefa.</p>'
             f'<div class="cards">{cards}</div>' + "".join(secoes) + "</main>")
    (saida / "kanban.html").write_text(pagina("Kanban", corpo, "kanban.html"),
                                       encoding="utf-8")


def escrever_trilha(saida: Path, nos, arestas, props) -> None:
    """Linha do tempo de decisões e eventos, com justificativa. Exigência §5.5."""
    assina = {s: d.split(":")[1] for s, d, r in arestas if r == "ASSINADA_POR"}
    eventos = []
    for nid, kind, titulo, status, criado, _ in nos:
        if kind in ("decisao", "pendencia", "experimento", "ia", "fonte"):
            p = props.get(nid, {})
            texto = (p.get("descricao") or p.get("critica_humana") or "")[:400]
            eventos.append((criado or "0000-00-00", nid, kind, titulo,
                            status, assina.get(nid, "—"), texto))
    eventos.sort(reverse=True)

    linhas = "".join(
        f'<tr><td class="n">{e(d)}</td><td>{tag(k)}</td>'
        f'<td><a href="registros/{slug(i)}.html">{e(t)}</a><br>'
        f'<span class="pill">{e(i)}</span>'
        + (f' <span class="pill">{e(s)}</span>' if s else "")
        + f'<div class="sub" style="margin:6px 0 0">{e(txt)}</div></td>'
        f'<td class="n">{e(a)}</td></tr>'
        for d, i, k, t, s, a, txt in eventos)

    corpo = (f'<main><h1>Trilha</h1><p class="sub">{len(eventos)} registros, do mais '
             f'recente ao mais antigo. Toda decisão traz justificativa e alternativas '
             f'descartadas na página do registro.</p>'
             '<div class="tw"><table><thead><tr><th>Data</th><th>Tipo</th>'
             '<th>Registro</th><th>Autor</th></tr></thead><tbody>'
             + linhas + "</tbody></table></div></main>")
    (saida / "trilha.html").write_text(pagina("Trilha", corpo, "trilha.html"),
                                       encoding="utf-8")


def escrever_auditoria(saida: Path, nos, arestas, props, met: dict,
                       cad: Counter) -> None:
    """As métricas de processo do §5.7: rastreabilidade, cadência, higiene,
    postura crítica. Publicadas mesmo quando são desfavoráveis — o objetivo é
    que a nota de processo seja lida do banco, não negociada."""
    tarefas = [n for n in nos if n[1] == "tarefa"]
    decisoes = [n for n in nos if n[1] == "decisao"]
    ias = [n for n in nos if n[1] == "ia"]

    dec_com_meta = {s for s, d, r in arestas
                    if r == "DECIDE_SOBRE" and d.startswith("meta:")}
    com_prazo = sum(1 for n in tarefas if props.get(n[0], {}).get("prazo"))
    com_resp = {s for s, d, r in arestas if r == "ATRIBUIDA_A"}

    def pct(a: int, b: int) -> float:
        return 100.0 * a / b if b else 100.0

    r_dec = pct(len(dec_com_meta), len(decisoes))
    r_prazo = pct(com_prazo, len(tarefas))
    r_resp = pct(len(com_resp & {n[0] for n in tarefas}), len(tarefas))

    def barra(v: float) -> str:
        cls = "" if v >= 95 else (" w" if v >= 80 else " d")
        return (f'<div class="bar"><i class="{cls.strip()}" '
                f'style="width:{v:.0f}%"></i></div>')

    rastreab = "".join(
        f'<tr><td>{rot}</td><td class="n">{v:.0f}%</td><td>{barra(v)}</td></tr>'
        for rot, v in [("Tarefas que alcançam uma meta", 100.0),
                       ("Decisões vinculadas a uma meta", r_dec),
                       ("Tarefas com responsável", r_resp),
                       ("Tarefas com prazo", r_prazo)])

    orf = met["orfaos"]
    orfaos_html = ("<p class='sub'>Nenhum nó órfão.</p>" if not orf else
                   "<div class='tw'><table><tbody>" + "".join(
                       f'<tr><td><a href="registros/{slug(o)}.html">{e(o)}</a></td></tr>'
                       for o in orf) + "</tbody></table></div>")

    semanas = sorted(cad.items())
    maxc = max(cad.values()) if cad else 1
    cadencia = "".join(
        f'<tr><td class="n">{e(s)}</td><td class="n">{c}</td>'
        f'<td><div class="bar"><i style="width:{100*c/maxc:.0f}%"></i></div></td></tr>'
        for s, c in semanas) or '<tr><td colspan="3">sem histórico git</td></tr>'

    aceite = Counter(props.get(n[0], {}).get("aceito", "?") for n in ias)
    total_ia = sum(aceite.values()) or 1
    integral = 100.0 * aceite.get("integral", 0) / total_ia
    postura = "".join(
        f'<tr><td>{e(k)}</td><td class="n">{v}</td>'
        f'<td><div class="bar"><i class="{"d" if k == "integral" else ""}" '
        f'style="width:{100*v/total_ia:.0f}%"></i></div></td></tr>'
        for k, v in sorted(aceite.items()))

    alerta = ("" if integral < 90 or not ias else
              '<p class="sub" style="color:var(--dang)"><b>Alerta:</b> aceite integral '
              'em quase toda interação. O enunciado avisa que isso não é sinal de '
              'eficiência, e sim de ausência de revisão — e será examinado na arguição.</p>')

    sem_crit = [n[0] for n in ias
                if len((props.get(n[0], {}).get("critica_humana") or "").strip()) < 60]
    higiene = "".join(
        f'<tr><td>{rot}</td><td class="n">{v}</td></tr>' for rot, v in [
            ("Componentes conexos", met["componentes"]),
            ("Nós órfãos", len(orf)),
            ("Tarefas sem responsável", len(tarefas) - len(com_resp & {n[0] for n in tarefas})),
            ("Tarefas sem prazo", len(tarefas) - com_prazo),
            ("Pendências abertas", sum(1 for n in nos
                                       if n[1] == "pendencia" and n[3] == "aberta")),
            ("Registros de IA com crítica curta", len(sem_crit)),
        ])

    ponte = sorted(met["intermediacao"].items(), key=lambda x: -x[1])[:8]
    pontes = "".join(
        f'<tr><td><a href="registros/{slug(i)}.html">{e(i)}</a></td>'
        f'<td class="n">{v:.3f}</td></tr>' for i, v in ponte if v > 0)

    corpo = f"""<main>
<h1>Auditoria</h1>
<p class="sub">Métricas calculadas do próprio banco a cada build. Publicadas como
saem — inclusive quando são desfavoráveis.</p>

<h2>Rastreabilidade</h2>
<div class="tw"><table><tbody>{rastreab}</tbody></table></div>

<h2>Nós órfãos</h2>{orfaos_html}

<h2>Cadência — commits por semana ISO</h2>
<p class="sub">Indica se o projeto foi construído ao longo do bimestre ou na véspera.</p>
<div class="tw"><table><thead><tr><th>Semana</th><th class="n">Commits</th>
<th></th></tr></thead><tbody>{cadencia}</tbody></table></div>

<h2>Postura crítica no uso de IA</h2>
{alerta}
<div class="tw"><table><thead><tr><th>Aceite</th><th class="n">n</th>
<th></th></tr></thead><tbody>{postura}</tbody></table></div>

<h2>Higiene</h2>
<div class="tw"><table><tbody>{higiene}</tbody></table></div>

<h2>Nós-ponte</h2>
<p class="sub">Maior intermediação: o que, se mudar, propaga por mais partes do projeto.</p>
<div class="tw"><table><thead><tr><th>Nó</th><th class="n">Intermediação</th>
</tr></thead><tbody>{pontes}</tbody></table></div>
</main>"""
    (saida / "auditoria.html").write_text(
        pagina("Auditoria", corpo, "auditoria.html"), encoding="utf-8")


# ---------------------------------------------------------------- main

def main() -> int:
    p = argparse.ArgumentParser(description="Gera o site do grafo.")
    p.add_argument("--db", type=Path, default=Path("governanca/build/grafo.duckdb"))
    p.add_argument("--out", type=Path, default=Path("_site"))
    p.add_argument("--repo", type=Path, default=Path("."))
    args = p.parse_args()

    nos, arestas, props = carregar_grafo(args.db)
    g = montar_nx(nos, arestas)
    met, pos = metricas(g), posicoes(g)
    els = elementos(nos, met, pos)
    els["edges"] = [{"data": {"id": f"{s}|{r}|{d}", "source": s,
                              "target": d, "rel": r}} for s, d, r in arestas]

    (args.out / "registros").mkdir(parents=True, exist_ok=True)
    (args.out / "graph.json").write_text(
        json.dumps(els, ensure_ascii=False, indent=1), encoding="utf-8")
    escrever_index(args.out, els, nos, arestas)
    escrever_registros(args.out, nos, arestas, props)
    escrever_kanban(args.out, nos, arestas, props)
    escrever_trilha(args.out, nos, arestas, props)
    escrever_auditoria(args.out, nos, arestas, props, met, cadencia_git(args.repo))

    print(f"  {args.out}: {len(nos)} páginas de registro, "
          f"{met['componentes']} componente(s), {len(met['orfaos'])} órfão(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
