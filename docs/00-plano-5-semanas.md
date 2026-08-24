# Projeto B1 — TRA-48 · Plano de Ataque das 5 Semanas

> **Tema:** Localização de vertiportos na cidade de São Paulo (AAM/UAM)
> **Entrega final:** 23/09/2026 · **Hoje:** 24/08/2026 · **Restam:** 4 semanas e 3 dias

---

## 0. Leia isto antes de tudo

O enunciado tem **duas camadas avaliadas separadamente**, e a segunda derruba mais nota do que
a primeira porque é a que ninguém leva a sério até a última semana:

| Camada | O que é | Peso na nota do projeto |
|---|---|---|
| **A — substantiva** | O modelo de PO: onde ficam os vertiportos, quanta demanda capturam, o que se recomenda | **55%** (modelagem e resultados) |
| **B — metodológica** | Como o grupo conduziu, registrou e auditou o próprio trabalho, com IA | **25%** (governança e método) |
| Comunicação | Relatório, apresentação, site, arguição | **20%** |

A frase-chave do enunciado é literal e operacional:

> **"O que não estiver no banco, não aconteceu."**

A nota de processo é **lida do banco de governança**, com carimbo de data e vínculo com os
commits. Preencher o banco em bloco na semana da entrega é item explícito da lista "o que
compromete a nota" (§8.4). Cadência é métrica auditada e publicada no site.

**Consequência prática:** o registro não é overhead do projeto — é metade da entrega. Cada
sessão de trabalho fecha com `./gov` + commit. Sem exceção.

---

## 1. Bloqueador #1 — resolver ainda hoje

O enunciado diz (§5.2): *"Cada grupo recebe um repositório-modelo já funcionando — não precisa
construir a infraestrutura, precisa operá-la"*, com esta estrutura:

```
repositorio-do-grupo/
├── governanca/
│   ├── projeto.duckdb      <- fonte de verdade
│   ├── dump.sql            <- história legível, versionada
│   ├── schemas/
│   ├── scripts/            <- gov.py, grafo, painel, auditoria, MCP
│   └── dashboard/
├── app/                    <- dados, modelo e análises em R
├── docs/                   <- saída publicada no GitHub Pages
└── .github/workflows/      <- publicação automática
```

**O repositório `Projeto_B1_TRA-48` que existe hoje na sua máquina está vazio** (só um README de
19 bytes, um commit inicial). Ou seja: ou o repositório-modelo ainda não foi distribuído, ou foi
distribuído por outro canal (Google Classroom) e ninguém do grupo clonou.

**Ação imediata (hoje, 24/08):** perguntar no Classroom / ao professor onde está o
repositório-modelo. O marco de **19/08 já venceu** ("grupos formados; repositório clonado; site
no ar; metas e primeiras tarefas registradas"). Cada dia sem banco alimentado é um buraco na
métrica de cadência que **não pode ser reconstruído depois** — a auditoria lê o carimbo de data.

Se o repositório-modelo não vier a tempo, o plano B é montar a estrutura mínima à mão (DuckDB +
um script `gov` simples + GitHub Actions) e **registrar essa decisão como decisão**, com
justificativa. Melhor um banco improvisado alimentado desde o dia 1 do que um banco oficial
vazio até o dia 20.

---

## 2. A escolha de modelagem — decidir até 26/08

O recorte metodológico "deve ser escolhido e registrado como decisão até o primeiro encontro"
(§2.6). Então isto precisa estar fechado em dois dias.

### Recomendação: **Caminho 1 — MCLP de Fluxo Bilateral Porta-a-Porta**

É um híbrido de três famílias clássicas (cobertura máxima × interceptação de fluxo × p-hub
mediana) em que **a unidade de cobertura não é a zona, é o par origem-destino**, e um par só é
atendido se houver vertiporto **na origem E no destino**.

**Por que este e não outro:**

1. É a única formulação viável em 5 semanas que enfrenta simultaneamente as três coisas que o
   enunciado exige do modelo (§4.3): natureza porta-a-porta, interdependência entre localizações
   e massa crítica de rede.
2. **Continua sendo um MILP exato**, com poucas binárias (`|J| ≈ 40-60`). Isso preserva relaxação
   linear, duais e sensibilidade — as quatro análises obrigatórias (§4.4). Toda a literatura que
   modela interdependência corretamente cai em meta-heurística (GA, NSGA-III, VNS) e **perde
   dual e relaxação**, que é exatamente o vínculo com a matéria do bimestre.
3. Entrega a figura central do trabalho de graça: a **curva de implantação em S**. Ver §5 abaixo.

### As três alternativas, ordenadas

| | Caminho | Esforço | Qualidade | Veredito |
|---|---|---|---|---|
| **1º** | **MCLP de fluxo bilateral** | 2,5 sem | **Alta** | ⭐ **Entrega principal** |
| 2º | CFLP/hub capacitado (unilateral, acesso a CGH/GRU/VCP) | 1,5 sem | Média | **Baseline de comparação** — rode junto, é barato e rende seção de relatório |
| 3º | Hub location + demanda elástica (logit linearizado) | 3,5 sem | Muito alta | Só se sobrar tempo na S4. Risco: não há logit calibrado para UAM no Brasil |

**Estratégia recomendada:** implementar o Caminho 1 como entrega e o Caminho 2 como baseline no
mesmo dado. Comparar as duas soluções — quais vertiportos cada um escolhe e por quê — é material
de relatório de altíssimo valor e custa uma semana a mais de trabalho já quase todo feito.

### O modelo (P1)

**Conjuntos e parâmetros**

- `I` — zonas OD (agregadas). `J` — candidatos (helipontos existentes + sítios via GIS).
- `Q ⊆ I×I` — pares OD **elegíveis** (fluxo > 0 e distância ≥ ~15 km).
- `f_q` — viagens/dia do par `q = (o,d)`, da matriz OD do Metrô.
- `T_q^ter` — tempo terrestre porta-a-porta (o modo concorrente).
- `t_oj^acc`, `t_kd^egr` — tempos de acesso/egresso terrestres; `t_jk^voo` — tempo de voo.
- Tempo UAM porta-a-porta via par de vertiportos `(j,k)`:
  `T_qjk^uam = t_oj^acc + τ_emb + t_jk^voo + τ_des + t_kd^egr`
- **Economia:** `Δ_qjk = T_q^ter − T_qjk^uam`
- **Conjunto viável (o coração da tratabilidade):**
  `P_q = { (j,k) ∈ J×J : j≠k, t_oj^acc ≤ t̄, t_kd^egr ≤ t̄, Δ_qjk ≥ θ }`

**Variáveis**

- `y_j ∈ {0,1}` — abre vertiporto em `j`
- `w_qjk ∈ [0,1]` — fração do fluxo `q` roteada via `(j,k)`

**Formulação**

```
max   Z = Σ_q Σ_(j,k)∈P_q  f_q · Δ_qjk · w_qjk

s.a.  Σ_(j,k)∈P_q w_qjk  ≤  1        ∀q ∈ Q             (α_q)
      w_qjk              ≤  y_j      ∀q, (j,k) ∈ P_q    (μ^o_qjk)
      w_qjk              ≤  y_k      ∀q, (j,k) ∈ P_q    (μ^d_qjk)
      Σ_j y_j            ≤  p                            (π)
      w_qjk ≥ 0,  y_j ∈ {0,1}
```

As duas restrições `w ≤ y_j` **e** `w ≤ y_k` são o mecanismo de bilateralidade — é o que
distingue este modelo de um MCLP comum, e a justificativa de existir de cada uma cabe em uma
frase no relatório (o enunciado exige "cada restrição com a razão de existir", §4.2).

**Extensões de ~10 linhas cada — escolham 1 ou 2, não todas:**

- **Capacidade de FATO:** `Σ_q Σ_k f_q (w_qjk + w_qkj) ≤ C_j · y_j`  ∀j  → dual `γ_j` = preço-sombra da capacidade
- **Massa crítica por vertiporto:** `Σ_q Σ_k f_q (w_qjk + w_qkj) ≥ m · y_j`  ∀j → não abre vertiporto abaixo do throughput mínimo
- **Custo fixo (endogeneiza p):** troque `Σ_j y_j ≤ p` por `− Σ_j f_j^fix · y_j` na FO (converta Δ em R$ via valor do tempo)
- **Equidade:** `Σ_{j ∈ periferia} y_j ≥ ⌈ρ·p⌉`, parametrizando ρ — responde à crítica política óbvia de que UAM em SP vira infraestrutura do quadrilátero Itaim–Faria Lima

### Dimensionamento da instância

| Componente | Alvo |
|---|---|
| Zonas OD (agregar 517 → ~120 macrozonas) | \|I\| ≈ 120 |
| Candidatos | \|J\| = 40–60 |
| Pares OD brutos | ~14.400 |
| Pares elegíveis após filtro | \|Q\| ≈ 2.000–4.000 |
| \|P_q\| médio | 20–60 |
| Variáveis `w` | 4×10⁴ – 2×10⁵ |
| **Variáveis binárias** | **40–60** ← trivial para B&B |
| Tempo esperado (HiGHS) | segundos a poucos minutos |

**O que torna isso fácil não é o tamanho — são as poucas binárias.** A redução da instância é
decisão de engenharia exigida e documentada (§4.5): registrem no banco *por que* 120 macrozonas
e não 517, *por que* 15 km de corte, *por que* `t̄` e `θ` nesses valores.

⚠️ **Alerta de implementação:** `ompr` constrói o modelo em R puro e fica muito lento acima de
~10⁵ variáveis. Se a instância crescer, monte a matriz de restrições com `Matrix::sparseMatrix()`
e chame `highs::highs_solve()` direto. **Meçam `|Q|` e `Σ_q|P_q|` na semana 2, antes de escrever
o modelo.**

### Stack em R

```r
sf + dplyr                              # pré-processamento espacial, matrizes de tempo
ompr + ompr.roi + ROI.plugin.highs      # modelagem algébrica
highs                                   # solver (MIT, open source, entrega duais)
ggplot2 + tmap                          # curvas e mapas
odbr                                    # leitura da Pesquisa OD (ver 02-fontes-de-dados.md)
```

`lpSolve` só para protótipos didáticos — não escala e tem interface pobre para duais em MIP.

---

## 3. Cronograma semana a semana

### Semana 0 — 24/08 a 26/08 (**3 dias, corrida**)

| # | Tarefa | Responsável | Saída |
|---|---|---|---|
| 0.1 | Localizar/clonar o repositório-modelo; site no ar | todos | repo funcionando |
| 0.2 | Registrar as 2–4 **metas** do projeto | 1 pessoa | `./gov meta` |
| 0.3 | Registrar as **decisões de recorte** (ver `03-encontro-26-08.md`) | 1 pessoa | `./gov decisao` × 5 |
| 0.4 | Registrar as **fontes de dados** catalogadas | 1 pessoa | `./gov fonte` × ~8 |
| 0.5 | Registrar as **referências** de literatura | 1 pessoa | `./gov referencia` |
| 0.6 | Baixar `OD-2017.zip` e abrir o layout de variáveis | 1 pessoa | dicionário confirmado |
| 0.7 | Ler Carvalho et al. (2026) — artigo dos próprios professores | todos | ficha de leitura |
| 0.8 | **1º encontro** com o professor | todos | perguntas de `03-` respondidas |

> **Registrem a decisão de recorte ANTES do encontro, não depois.** O enunciado diz que o ponto
> de partida do encontro é o site do grupo, "não uma apresentação preparada para a ocasião".
> Chegar com o banco já vivo é a diferença entre "o grupo está operando" e "o grupo vai começar".

### Semana 1 — 26/08 a 02/09 · **Dados e demanda capturável**

Marco 02/09: *"Demanda capturável estimada; candidatos definidos; formulação escrita"*.

- Ler a OD 2017 em R (`odbr::read_od`), validar fatores de expansão contra os totais do
  relatório-síntese (42 mi viagens/dia, 517 zonas, 39 municípios).
- Construir a matriz OD agregada por par de zonas: `Σ FE_viagem GROUP BY zona_o, zona_d`.
- **Definir a fatia capturável** — a primeira decisão difícil do projeto (§3.3). Proposta de
  filtro em quatro camadas, cada uma uma decisão registrada:
  1. **Distância** — viagens ≥ 15 km em linha reta (abaixo disso o eVTOL não recupera o tempo de solo)
  2. **Duração terrestre** — ≥ 45–60 min declarados na OD (o dado da OD já embute congestionamento real)
  3. **Motivo** — trabalho/negócios (segmento com maior valor do tempo)
  4. **Renda** — faixas superiores da OD (UAM é serviço premium; ignorar isso é fingir mercado)
  Depois **calibrar o nível** contra a OD 2023 (35,6 mi viagens — queda pós-pandemia).
- Construir `J`: helipontos da lista ANAC filtrada por município = São Paulo, cruzada com o
  ROTAER. **Contem vocês mesmos e registrem a data de extração** — os números que circulam
  (200, 214, 400) são jornalísticos e inconsistentes.
- Matriz de tempos terrestres: OSRM self-hosted sobre extrato Geofabrik, validado por amostra
  de pares em horário de pico. Tempos de voo: grande círculo ÷ ~200 km/h + 5 min embarque + 5 min desembarque.
- **Escrever a formulação completa** em LaTeX — conjuntos, parâmetros com unidade e procedência,
  variáveis, FO, restrições, cada elemento com sua justificativa.

### Semana 2 — 02/09 a 09/09 · **Modelo rodando**

Marco 09/09: *"2º encontro: modelo rodando, primeiro resultado; experimentos registrados"*.

- Pré-processamento: construir `Q`, `P_q`, `Δ_qjk`. **Medir tamanho antes de modelar.**
- Implementar (P1) em `ompr`/HiGHS.
- **Validar com instância-brinquedo de 5 zonas e 3 candidatos resolvida à mão.** Um modelo que
  roda mas está errado é pior que um modelo que não roda — e não dá para descobrir isso na
  semana 4.
- Rodar o baseline CFLP no mesmo dado.
- Cada rodada é um `./gov experimento` com hipótese, parâmetros, commit, valor da FO, gap, tempo.

### Semana 3 — 09/09 a 16/09 · **As quatro análises**

Marco 16/09: *"Prova B1; modelo congelado; sensibilidade e dual; experimentos e conclusões validadas"*.

Atenção: **a Prova B1 é no dia 16/09.** Esta semana tem carga dupla. Planejem para que a semana 3
seja de análise sobre modelo já estável, não de conserto de modelo.

1. **Relaxação linear.** Comparar a formulação **desagregada** (`w ≤ y_j`, `w ≤ y_k`) com a
   **agregada** (`Σ_q w_qjk ≤ |Q|·y_j`). Reportar `Z_LP`, `Z_IP` e o gap das duas. Discutir por
   que a relaxação de MCLP puro é quase-integral e **por que a bilateralidade quebra essa
   propriedade** — as duas restrições criam soluções fracionárias `y_j = y_k = 0,5`. Isso sozinho
   vale uma seção.
2. **Dual.** `π` (dual de `Σ y_j ≤ p`) = **economia marginal de tempo-passageiro por vertiporto
   adicional** [pax·min/dia por vertiporto] — é literalmente a inclinação da curva de implantação.
   `γ_j` = preço-sombra da capacidade de `j` (justificativa econômica de um FATO extra).
   `α_q` = valor de servir o par `q` → ranking de corredores prioritários.
3. **Sensibilidade.** Variar `t̄` (10/15/20/30 min de acesso máximo) → mede quanto a UAM depende
   do first/last mile. Variar `θ` (0/10/20/30 min de economia mínima) → mede a fragilidade da
   proposta de valor. Variar capacidade e valor do tempo.
4. **Curva de implantação.** Resolver para `p = 1..25` e plotar `Z*(p)`.

### Semana 4 — 16/09 a 23/09 · **Extensão, relatório, apresentação**

- Implementar UMA extensão (massa crítica ou equidade) — não duas.
- Mapas em `sf`/`ggplot2`/`tmap`.
- Relatório de engenharia em PDF, com a estrutura exata do §6.1 do enunciado.
- Auditoria limpa: **zero nós órfãos**. Todo arquivo ligado a uma decisão, toda decisão ligada a
  uma meta, toda conclusão com experimento que a sustente.
- Preparar a resposta à **pergunta garantida**: *"Mostrem a decisão em que vocês discordaram da
  IA — e expliquem por que vocês estavam certos."*

---

## 4. O resultado central que vocês devem perseguir

Existe uma lacuna real e explorável na literatura, e ela cai no colo desta formulação:

**Toda a literatura aplicada de vertiportos que usa modelos lineares trata cobertura como
unilateral** — a zona está coberta se houver vertiporto perto. Mas a viagem eVTOL só existe se
houver vertiporto na origem **e** no destino. Os trabalhos que capturam isso corretamente ou usam
hub location com demanda inelástica, ou pagam com meta-heurística, que destrói dual e relaxação.
**Ninguém entrega um MILP compacto, exato, com cobertura bilateral e leitura de duais.**

A consequência analítica é bonita e demonstrável com o solver:

> Com cobertura **unilateral**, a função objetivo é submodular ⇒ **curva de implantação côncava**
> desde `p = 1` (retornos decrescentes desde o primeiro vertiporto).
>
> Com cobertura **bilateral**, `Z*(1) = 0` — um vertiporto sozinho não serve nenhum par — e o
> benefício é **superaditivo** no início ⇒ **curva em S**: convexa e depois côncava.

**Essa figura única — as duas curvas sobrepostas no mesmo dado — é a assinatura numérica da massa
crítica de rede, e é o resultado central do trabalho.** É o gráfico que sustenta a recomendação
final que o enunciado pede em §4.4: *a partir de quantos vertiportos o retorno deixa de
compensar?* Com curva em S a resposta tem duas partes — existe um `p` **mínimo** abaixo do qual
a rede não vale nada, e um `p` **de saturação** acima do qual não compensa. Nenhum modelo
unilateral produz a primeira metade dessa resposta.

---

## 5. Divisão de frentes

Independentemente do tamanho do grupo, há quatro frentes que rodam em paralelo. **Cada integrante
precisa aparecer como autor de registros no banco e de commits no repositório** (§7.3) — a
contribuição individual é visível e avaliada. E cada um deve saber defender **qualquer** linha do
modelo, não só a sua.

| Frente | O que faz | Quando é crítica |
|---|---|---|
| **Dados** | OD, fatores de expansão, agregação de zonas, matriz de tempos terrestres | S1 |
| **Candidatos & GIS** | ANAC/DECEA, GeoSampa, filtros de viabilidade urbanística, mapas | S1–S2 |
| **Modelo & solver** | Formulação, `ompr`/HiGHS, validação, experimentos | S2–S3 |
| **Governança & escrita** | Banco vivo, site, auditoria, relatório | **todas as semanas** |

A frente de governança não é a "sobra" — é 25% da nota e a única que não pode ser recuperada
depois.

---

## 6. Uso de IA — a regra que decide 25% da nota

O enunciado permite e incentiva IA, mas com três amarras que valem repetir:

1. **Toda interação relevante é registrada** (`./gov ia`).
2. **O campo `crítica humana` é obrigatório.** *"Não se registra uma interação sem crítica. Quem
   não consegue criticar a resposta não a entendeu, e portanto não pode assiná-la."*
3. **A taxa de aceite integral é publicada no site.** Perto de 100% não é eficiência — é ausência
   de revisão, e será examinada na arguição.

**Isto vale para esta própria sessão.** Este documento, a revisão de literatura e o catálogo de
fontes vieram de uma conversa com IA e devem entrar no banco como interação, com crítica. Coisas
concretas para criticar aqui:

- A revisão de literatura sinalizou explicitamente itens **[não confirmados]** — Shin et al.
  (2021) tem autoria incompleta, e formulação/instância de Brunelli (2023), Ribeiro (2023) e
  Carvalho (2026) foram confirmadas só em **metadados bibliográficos**, não em texto integral
  (paywall). **Peguem esses PDFs na biblioteca do ITA antes de citar a formulação de qualquer um
  deles.** Citar formulação que ninguém leu é exatamente o "palpite acelerado" do §1.2.
- O catálogo de fontes marca **microdados da OD 2023 como não publicados** — só relatório
  síntese e anexos. Isso precisa ser verificado por vocês antes de virar premissa do projeto.
- Os números de dimensionamento da instância (`|Q| ≈ 2.000-4.000`, `|P_q| ≈ 20-60`) são
  **estimativas de ordem de grandeza, não medições**. Meçam na semana 2 e corrijam.
- A previsão da curva em S é **teórica**. Se o experimento não produzir o S, isso não é fracasso
  — é achado, e mostrar o que não funcionou é critério explícito de excelência (§8.2).

Cada um desses itens é uma discordância fundamentada esperando para ser registrada.

---

## 7. Checklist de aderência ao enunciado

Para conferir na véspera da entrega — cada item é uma exigência textual do enunciado.

**Modelo (§4.2)** — cada elemento com justificativa da escolha:
- [ ] Conjuntos e índices definidos
- [ ] Parâmetros com **unidade e procedência de cada valor**
- [ ] Variáveis de decisão com significado
- [ ] Função objetivo com o critério que representa
- [ ] Restrições, **cada uma com a razão de existir**

**O que o modelo precisa enfrentar (§4.3):**
- [ ] Natureza porta a porta, não só o trecho aéreo
- [ ] Interdependência entre localizações
- [ ] Limitações operacionais da infraestrutura
- [ ] **O que ficou fora do modelo, e por que a omissão é aceitável**

**Análises (§4.4):**
- [ ] Relaxação linear, comparada com o modelo original
- [ ] Interpretação econômica do dual
- [ ] Análise de sensibilidade
- [ ] Curva de implantação

**Indicadores comuns a todos os grupos (§6.3)** — para o painel comparativo final:
- [ ] Número de vertiportos implantados e localização
- [ ] Demanda diária atendida e sua participação na demanda considerada capturável
- [ ] Benefício na métrica própria do grupo, **com unidade explicitada**
- [ ] Desempenho computacional: valor da FO, tamanho da instância, tempo de solução

**Governança (§5.3)** — entidades que precisam existir no banco:
- [ ] Metas (2 a 4) · Tarefas (com responsável e prazo) · Pendências
- [ ] Decisões (com justificativa **e alternativas descartadas**)
- [ ] Fontes de dados (origem, formato, cobertura, limitações)
- [ ] Arquivos · Referências · Experimentos · Interações com IA

**O que compromete a nota (§8.4)** — evitar ativamente:
- [ ] Nenhum dado inventado ou não rastreável à fonte
- [ ] Modelo roda; instância documentada
- [ ] Banco alimentado ao longo das 5 semanas, não em bloco
- [ ] Registros de IA **não** têm aceite integral em todas as interações
- [ ] Todo integrante sabe explicar o modelo
- [ ] Material de outro grupo, se usado, tem crédito registrado
