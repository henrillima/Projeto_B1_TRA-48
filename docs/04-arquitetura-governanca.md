# Arquitetura do grafo de governança

Referência da Camada B. Explica **por que** a infraestrutura é como é. O passo a passo de
construção está em [`guias/G01-infraestrutura.md`](guias/G01-infraestrutura.md); as regras de
uso diário estão em [`referencia/convencoes.md`](referencia/convencoes.md).

---

## 1. Comece pelas perguntas

O erro clássico em grafo de conhecimento é modelar tudo o que existe e depois descobrir que
ninguém consulta. Aqui o enunciado já escreveu as perguntas — §5.4 — e elas são o requisito
funcional de tudo em `governanca/`:

1. Por que o valor do tempo adotado é este, **e quem decidiu**?
2. Qual script gerou o mapa da página 12 do relatório?
3. Se a fonte de dados de acesso terrestre for substituída, **quais decisões e resultados
   dependem dela**?
4. Quais conclusões ainda **não têm experimento** que as sustente?

Nenhuma é respondível por busca textual, e todas são **travessias** — seguir arestas, dois ou
três saltos, por caminhos de tipos diferentes. É o que uma planilha não faz.

A quarta é a mais interessante, porque a resposta é uma **ausência**: conclusões sem aresta de
sustentação. Um sistema que só guarda o que existe nunca responde isso.

> **Teste a aplicar a cada nó que se pense em criar:** qual das quatro perguntas fica sem
> resposta se este nó não existir? Se nenhuma, o nó é decoração.

---

## 2. Nó, propriedade ou aresta

Seis regras, em ordem de precedência.

1. **Vira nó** se tem identidade própria e ciclo de vida — se precisa ser referenciado de mais
   de um lugar, tem histórico, ou alguém pode querer abrir a página dele.
2. **Vira propriedade** se é atributo escalar sem vida própria. Teste: *eu precisaria de uma
   página para isso?*
3. **Vira aresta** se é relação binária tipada entre dois nós.
4. **Se a relação precisa de qualificadores próprios**, ou põe propriedade na aresta, ou
   reifica em nó. Reifique só quando o qualificador for ele mesmo consultável.
5. **Cardinalidade recorrente promove a nó.** Se um valor de propriedade se repete em muitos
   nós e você quer navegar por ele, promova. Este é o erro mais comum e o mais caro de
   corrigir depois.
6. **Anti-explosão.** Não crie nó para valor de enum de baixa cardinalidade. `status` como nó
   vira emaranhado e não agrega consulta nenhuma.

### Os dois casos que exigiram decisão aqui

**Observações nas tarefas.** Têm autor e data, mas ninguém as referencia de fora e ninguém
abre a página delas. Regra 2 vence: propriedade, uma lista de `{data, autor, texto}` dentro do
YAML. Não custa consulta — `UNNEST` no DuckDB abre a lista e "todas as observações de setembro
por autor" continua sendo uma linha de SQL. E são **append-only**: nunca se edita nem apaga
uma nota antiga, porque uma nota corrigida em silêncio perde a única coisa que a tornava
valiosa, que é ter sido escrita naquele dia.

**O estado "bloqueada" no kanban.** Não é armazenado. Já é dedutível: a tarefa está bloqueada
se existe pendência aberta apontando para ela. Guardar isso criaria uma segunda fonte de
verdade — alguém fecha a pendência, esquece de mover o cartão, e o quadro passa a mentir.
**Estado derivável nunca se armazena.**

---

## 3. Por que grafo emulado em tabelas, e não banco de grafo

Três modelos de dados eram possíveis.

| Modelo | Linguagem | Custo de aprendizado |
| --- | --- | --- |
| Property graph | Cypher, GQL | Baixo — Cypher é ASCII-art |
| RDF / triplas | SPARQL | Alto — IRI, ontologia, OWL, mundo aberto |
| **Emulado em tabelas** | **SQL + `WITH RECURSIVE`** | **Quase zero** |

O argumento decisivo não é técnico, é econômico: **Cypher só serve para grafo; SQL serve para
todo o resto do projeto** — relatórios de cadência, agregações, exportação para R. Aprender
SQL recursivo é conhecimento que se aproveita; aprender Cypher para 500 nós é imposto.

```sql
CREATE TABLE node (
  id      VARCHAR PRIMARY KEY,   -- 'tarefa:T12', 'decisao:D07'
  kind    VARCHAR NOT NULL,
  titulo  VARCHAR NOT NULL,
  status  VARCHAR,
  props   JSON
);
CREATE TABLE edge (
  src VARCHAR NOT NULL REFERENCES node(id),
  dst VARCHAR NOT NULL REFERENCES node(id),
  rel VARCHAR NOT NULL,
  PRIMARY KEY (src, dst, rel)
);
```

E a travessia que justifica o grafo existir — aqui respondendo a pergunta 3:

```sql
WITH RECURSIVE alcanca(id, salto) AS (
      SELECT 'fonte:osrm', 0
    UNION                          -- UNION, não UNION ALL: corta ciclo
      SELECT e.src, a.salto + 1    -- src, não dst: subindo as arestas
      FROM alcanca a JOIN edge e ON e.dst = a.id
      WHERE a.salto < 5
)
SELECT n.kind, n.titulo, min(a.salto) AS salto
FROM alcanca a JOIN node n USING (id)
WHERE n.kind IN ('decisao','conclusao','experimento')
GROUP BY 1, 2 ORDER BY 3;
```

Registrado em `decisao:D06`.

### O contexto de 2026 que mudou a decisão óbvia

**Kùzu — o banco de grafo embarcado que seria a escolha natural — foi arquivado em
10/10/2025**, e a empresa foi adquirida pela Apple. Existe fork comunitário ativo, o
LadybugDB, mas está em v0.17, pré-1.0, e sem binding em R.

Isso é um lembrete de que **estado de manutenção é critério de engenharia**, não detalhe — e
é o tipo de coisa que precisa entrar como registro de fonte no próprio banco de governança.

Neo4j, mesmo sendo o mais maduro, é **estruturalmente incompatível** com "fonte de verdade em
git + publicação estática": você acaba com um banco vivo em algum lugar que diverge do
repositório, que é precisamente o que este projeto existe para impedir.

---

## 4. Por que o YAML é a fonte de verdade e o banco é artefato

Um `.duckdb` é binário. Em git isso produz quatro problemas, e o quarto é o que importa aqui:

- **Diff ilegível** — `Binary files differ`, e o avaliador não audita nada.
- **Merge impossível** — qualquer conflito é irreconciliável.
- **Inchaço** — git guarda o blob inteiro a cada commit.
- **Não determinismo** — reconstruir o mesmo banco dos mesmos dados produz bytes diferentes.
  Você commita ruído mesmo sem ter mudado nada.

> **Commits de ruído binário destroem exatamente a auditabilidade que a métrica de cadência
> pretende medir.**

Com um arquivo por nó, **a granularidade do commit coincide com a granularidade semântica**:

```bash
git log data/decisoes/            # o histórico de decisões do projeto, literalmente
git blame data/decisoes/D07.yaml  # quem escreveu cada linha de justificativa
```

Dois integrantes editando entidades diferentes **nunca** conflitam. Conflito só ocorre na
mesma entidade — que é exatamente quando se quer que humanos conversem.

E torna a troca de banco uma reescrita de compilador, não uma migração de dados, o que
neutraliza o risco de plataforma da seção anterior.

**Regra de ouro:** `build/` no `.gitignore`. A única fonte de verdade é o texto; o banco é
artefato, como um `.o`. Registrado em `decisao:D07`.

---

## 5. Por que a IA só lê

O servidor MCP abre o banco com `read_only=True`, não declara nenhuma tool de escrita, e roda
com usuário sem permissão de escrita em `build/`. **Defesa em três camadas** — o pior caso é
vazamento de leitura, nunca corrupção.

A assimetria é **consequência** da decisão anterior, não restrição extra: se a IA escrevesse
no `.duckdb`, a escrita morreria no próximo build. Escrever *é* editar YAML *é* commitar. Mas
há cinco razões independentes que reforçam:

1. **Proveniência.** Toda mutação passa por commit com autor e mensagem. Escrita direta no
   banco produz mudança sem rastro — o que o banco existe para impedir. O grafo perderia a
   capacidade de responder a pergunta 1.
2. **Validação.** A CLI valida contra o schema, checa integridade referencial e impede ciclo
   em `BLOQUEIA`. SQL cru gerado por modelo contorna tudo isso.
3. **Prompt injection.** O grafo contém texto de terceiros — referências, transcrições,
   descrições de fonte. Com escrita exposta, texto lido pelo modelo pode induzir escrita.
4. **Reprodutibilidade.** `git checkout <sha> && make build` reproduz o grafo daquele momento.
   Escrita fora de banda quebra isso, e com ela a capacidade de auditar entregas passadas.
5. **Avaliação.** Se a nota depende de cadência de commits, escrita que não passa por commit é
   trabalho invisível.

Isso é consenso de indústria, não opinião: o servidor MCP oficial do DuckDB é read-only por
padrão, e o do Neo4j valida read-only rodando `EXPLAIN` antes de executar o Cypher.

O fluxo em sessão assistida: **a IA propõe o comando `gov`; um de vocês executa e commita.**
Registrado em `decisao:D08`.

### Tools semânticas, não SQL cru

O servidor expõe `pendencias_que_bloqueiam(meta)` e `por_que(node_id)`, não `query(sql)` como
interface principal. O modelo não precisa acertar o esquema, e a superfície de alucinação
encolhe. O padrão de 2026 nas ferramentas de código maduras é o mesmo: **o LLM não consulta o
grafo, o LLM chama ferramentas que consultam o grafo.**

---

## 6. Por que GraphRAG foi descartado

GraphRAG constrói um grafo *a partir de texto não estruturado*, usando um LLM para extrair
entidades e relações. **Ele resolve a etapa que este projeto já resolveu por design** — nós
escrevemos o grafo à mão, com curadoria, tipos explícitos e ids estáveis. Rodar GraphRAG sobre
ele degradaria informação estruturada em informação inferida.

Quatro razões concretas:

- **Escala errada por três ordens de grandeza.** É para corpora que não cabem em contexto. O
  grafo inteiro daqui cabe, e a maioria das perguntas nem precisa dele todo.
- **Precisão importa mais que recall.** "Quais pendências bloqueiam a meta M2" tem *uma*
  resposta correta, por travessia determinística. Os ganhos típicos reportados vão de ~73%
  para ~88% de recall — e 88% em governança é pior que inútil, porque parece confiável.
- **Custo e não determinismo** na indexação a cada mudança, num projeto que commita várias
  vezes por semana.
- **Contradiz a tese.** Uma camada de resumos gerados por LLM insere afirmações **sem
  proveniência** no meio do fluxo.

No lugar: MCP com tools semânticas sobre SQL recursivo, um `contexto.md` gerado no build, e
busca full-text nos campos de texto. Registrado em `decisao:D09`.

---

## 7. Code graphs: só o último degrau interessa

"Code graph" não é uma coisa, é uma escada: AST → call graph → grafo de imports → CFG e
data-flow → Code Property Graph → **grafo de proveniência de artefatos**.

Os cinco primeiros modelam **o código**. O sexto modela **a execução e seus produtos**:

```
dado.csv → [limpeza.R] → limpo.rds → [modelo.R] → solucao.rds → [figura.R] → fig3.png → §4.2
```

Com 20 a 40 arquivos, o grafo do código-fonte **não paga o próprio custo** — qualquer um do
grupo carrega o grafo de imports na cabeça, e um `grep -r` responde quase tudo. O que paga é a
proveniência, porque essa informação *não está na cabeça de ninguém* e evapora: ninguém vai
lembrar, na semana 5, qual versão de `demanda.csv` gerou a Figura 3 da semana 2.

E existe um atalho: **`targets`**. `tar_network()` devolve `vertices` e `edges` como data
frames — o grafo de proveniência derivado da **execução real**, não de comentários que
envelhecem nem de análise estática que erra em linguagem dinâmica. Some `tar_meta()` (hashes,
timestamps, erros) e a camada de proveniência existe sem escrever um parser.

O mapeamento para o padrão canônico, o W3C PROV-O, é quase mecânico:

| `targets` | PROV-O | Aqui |
| --- | --- | --- |
| linha de `tar_meta()` com `command`, `seconds` | `prov:Activity` | `experimento` |
| alvo com `path` e hash | `prov:Entity` | `arquivo` |
| aresta `from → to` | `prov:used` / `wasGeneratedBy` | `USA` / `PRODUZ` |
| autor do commit | `prov:Agent` | `pessoa` |

**Só uma aresta exige um humano:** conclusão → experimento que a sustenta. E isso é o ponto —
obriga o grupo a declarar qual número sustenta qual afirmação do relatório. Esse ato de
declaração é a governança; o grafo é só o registro dela. É também o que torna a pergunta 4
respondível.

Bônus que nenhum code graph entrega: **`tar_outdated()`** diz qual figura do relatório foi
gerada por código que já mudou. Conclusão apoiada em resultado obsoleto é exatamente o defeito
que a Camada B existe para pegar.

### Declarados como overkill, com motivo

**Joern/CPG** (sem frontend R; feito para vulnerabilidade em C/C++/Java), **SCIP/LSIF** (LSIF
arquivado; sem indexador R; SCIP é formato para um servidor que não vamos operar), **CodeQL**
(sem suporte a R, e a licença do CLI proíbe uso sobre repositório privado), **embeddings sobre
o próprio código** (30 arquivos cabem no contexto).

---

## 8. A arquitetura inteira

```
governanca/data/**.yaml     ← FONTE DE VERDADE. Humano e IA editam. Git rastreia.
    │
    │   tools/validar.py       schema + integridade — falha o CI
    │   tools/build.py         YAML → tabelas node/edge
    ▼
governanca/build/grafo.duckdb  ← ARTEFATO. .gitignore. Reconstruível de qualquer commit.
    │
    ├──► tools/mcp.py       → servidor MCP READ-ONLY, tools semânticas
    │
    └──► tools/site.py      → NetworkX (métricas + layout determinístico)
                            → _site/index.html (Cytoscape.js inline)
                            → _site/registros/*.html
                            → GitHub Actions → GitHub Pages
```

**Escrita:** só por commit em `governanca/data/`. **Leitura:** MCP para a IA, site para
humanos.

### Sobre o GitHub Pages

O fluxo atual **não usa mais a branch `gh-pages`**. O workflow constrói o site, empacota como
artefato e publica pela API com autenticação OIDC. Isso importa especificamente aqui: **deploy
por branch commitaria a saída do build no histórico e inflaria artificialmente a métrica de
cadência**, que é justamente o que se quer medir com honestidade.

Um passo manual, uma vez: **Settings → Pages → Source = "GitHub Actions"**.

---

## 9. O modo de falhar

Existe um jeito de tudo isso dar errado mesmo com a infraestrutura funcionando: **construir o
grafo e nunca consultá-lo.** Acontece o tempo todo.

A defesa é a regra do começo. Se uma pergunta não tem consulta escrita, o nó correspondente
não deveria existir. Escrevam as consultas primeiro, apontem cada uma para uma das quatro
perguntas do §5.4, e deixem o esquema encolher até só sobrar o que responde alguma.

**Débito conhecido:** os tipos `referencia` e `conclusao` ainda não têm consulta escrita. Ou
escrevam, ou cortem — e registrem a decisão.
