# G09 — Relatório, site, apresentação, arguição

> Pacote de trabalho **de todos os três**. Prazo do pacote: **23/09/2026** — a data da entrega.
> Leia `docs/guias/G00-como-trabalhar.md` e `CLAUDE.md` antes deste.
>
> Este pacote não produz conhecimento novo. Ele **compila** o que os oito guias anteriores
> produziram. Se em algum ponto você se pegar descobrindo alguma coisa aqui, ou o G08 não
> terminou, ou o registro não foi feito na hora — e nos dois casos o conserto é voltar, não
> improvisar na frente.

---

## Objetivo

Ao fim deste pacote existem quatro coisas, e as quatro são avaliadas:

1. **O relatório de engenharia** em PDF, com a estrutura exata do §6.1 do enunciado.
2. **O site publicado**, com as oito seções do §5.5, no ar e navegável offline.
3. **A apresentação oral**, cobrindo **as duas camadas** — o modelo e o processo.
4. **A arguição ensaiada**, incluindo a resposta preparada à pergunta garantida a todos os
   grupos, e o grupo pronto para o painel comparativo final.

E existe uma **auditoria limpa**: zero nós órfãos, toda decisão com meta, toda conclusão com
experimento, todo arquivo com decisão.

---

## Tarefas no grafo

| Id | Título | Responsável | Prazo | Est. | Depende de |
| --- | --- | --- | --- | --- | --- |
| `tarefa:T35` | Redigir o relatório de engenharia | `pessoa:pedro` | 22/09 | 16 h | `tarefa:T33` |
| `tarefa:T36` | Preparar a apresentação e a arguição | `pessoa:henri` | 23/09 | 6 h | `tarefa:T35` |

As duas `REALIZA meta:M3`.

**A dependência T36 → T35 é real e a ordem importa.** O deck sai do relatório, não em paralelo a
ele: um deck escrito antes do relatório vira a versão que o grupo decora, e aí a arguição
encontra divergência entre o que foi apresentado e o que foi escrito. Escreva o relatório
primeiro; o deck é a compressão dele.

**A estimativa de 16 h para T35 é otimista se o G08 não estiver fechado.** As 16 h supõem
compilação, não redação do zero — ver §2. Se em 19/09 ainda houver experimento rodando, a
estimativa correta é outra e isso é uma nota na tarefa, não um silêncio.

---

## Pré-requisitos

- [ ] **G08 concluído** — as quatro análises, a extensão, a tabela de indicadores, as nove
      figuras. Este pacote não começa antes.
- [ ] **O modelo congelado** desde 16/09, com a decisão de congelamento registrada.
- [ ] `targets::tar_outdated()` **vazio**. Nenhuma figura do relatório pode vir de código já
      alterado — é o defeito exato que a Camada B existe para pegar.
- [ ] O validador do grafo passando.
- [ ] O site já no ar desde a S0 e publicando a cada push. Se ele subir pela primeira vez agora,
      a métrica de cadência já registrou isso, e não há como consertar.
- [ ] Todos os `[A CONFIRMAR]` do repositório resolvidos ou convertidos em limitação declarada
      no relatório. Um `[A CONFIRMAR]` no PDF entregue é pior que a ausência do número.
- [ ] Os PDFs em texto integral das referências cujas formulações forem citadas. A regra 4 do
      `CLAUDE.md` é literal: **não se cita a formulação matemática de um artigo que ninguém
      abriu.** A revisão de literatura marca explicitamente quais estão confirmadas só em
      metadado — Shin et al. (2021), Brunelli et al. (2023), Ribeiro et al. (2023), Carvalho et
      al. (2026). Ou o PDF foi lido, ou a citação muda de "a formulação de X é" para "X trata
      de", ou a referência sai.

---

## Insumos

| Insumo | Onde | Para quê |
| --- | --- | --- |
| Estrutura do relatório | enunciado §6.1 | a seção 1 deste guia |
| Seções obrigatórias do site | enunciado §5.5 | a seção 3 |
| Indicadores comuns | enunciado §6.3 | o painel comparativo |
| Guias G02–G08, seção "Como isso vira relatório" | `docs/guias/` | **cada uma já diz onde deságua** |
| Revisão de literatura | `docs/01-revisao-literatura.md` | a seção de revisão do relatório |
| Catálogo de fontes | `docs/02-fontes-de-dados.md` | a seção de dados |
| Checklist de aderência | `docs/00-plano-5-semanas.md` §7 | a seção 9 deste guia |
| Convenções de citação e figuras | `docs/referencia/convencoes.md` §4.3 | nomes de arquivo das figuras |
| O grafo compilado | `governanca/build/grafo.duckdb` | todas as consultas SQL deste guia |

---

## Passo a passo

### 1. A estrutura exata do relatório (§6.1), seção por seção

O §6.1 do enunciado fixa a estrutura. **Não a reordene e não a renomeie** — quem corrige lê com a
lista ao lado, e uma seção com outro nome parece ausente.

O orçamento de páginas abaixo é **proposta do grupo**, não exigência do enunciado. Ele existe
para uma coisa só: impedir que a seção de dados coma o espaço da seção de análise, que é onde a
nota de modelagem está. Ajuste os totais se o professor fixar um limite; mantenha as
**proporções**.

| # | Seção | Págs. | De onde vem |
| --- | --- | --- | --- |
| 1 | Contexto e definição do problema, com o recorte adotado | 2–3 | `docs/03-encontro-26-08.md`, decisões de recorte |
| 2 | Revisão de literatura | 3–4 | `docs/01-revisao-literatura.md` |
| 3 | Dados | 4–5 | G02, G03, G04, G05 |
| 4 | Modelo | 4–5 | G06 |
| 5 | Tratabilidade | 1–2 | G07 |
| 6 | Resultados computacionais | 4–5 | G07, G08 |
| 7 | Relaxação linear, dual e análise de sensibilidade | 5–6 | **G08** |
| 8 | Limitações e trabalhos futuros | 2 | todos |
| 9 | Referências | 1–2 | `01-revisao-literatura.md` |
| | **Total** | **26–34** | |

**A seção 7 é a maior do relatório, e isso é deliberado.** É o vínculo com a matéria do bimestre
(§4.4) e é onde a nota de modelagem se decide. Se a seção 3 estiver maior que a 7, o relatório
está desbalanceado em relação ao que é avaliado.

#### 1.1 Contexto e definição do problema, com o recorte adotado

O que entra: o problema de UAM em São Paulo e por que a cidade é um caso relevante (maior frota
urbana de helicópteros do mundo, helipontos já construídos, congestionamento, desigualdade
espacial — a revisão registra isso em L4); **a pergunta que o trabalho responde**, em uma frase;
e o **recorte adotado**, que é a parte que o enunciado cobra explicitamente.

O recorte tem que dizer o que ficou **de fora** com a mesma clareza com que diz o que ficou
dentro: município de São Paulo ou RMSP, horizonte temporal, segmento de demanda, o que não é
modelado (tarifa, operação, frota, ruído). Cada exclusão com um motivo específico.

**Não escreva esta seção do zero.** Ela é a compilação das decisões de recorte já registradas
no grafo, e cada afirmação deve ter o `decisao:D__` ao lado. Se alguma afirmação não tiver, ou
falta registrar a decisão ou a afirmação não é do grupo.

#### 1.2 Revisão de literatura — os modelos estudados e como foram aproveitados

O enunciado pede as duas metades: **o que foi estudado** e **como foi aproveitado**. A segunda
metade é a que quase todo grupo esquece, e é a que diferencia revisão de lista.

Estrutura que funciona:

1. **As famílias clássicas** (p-mediana, p-centro, MCLP, LSCP, U/CFLP, hub location,
   flow interception), cada uma em um parágrafo com a formulação em uma linha e **o que ela
   captura e o que não captura** do problema de vertiportos. A tabela §1.8 da revisão é o
   fecho: nenhuma família isolada resolve.
2. **A literatura específica de vertiportos** — a tabela-síntese §2.1, resumida. Não reproduza
   as 18 linhas; escolha as 6 ou 7 que sustentam alguma escolha do trabalho.
3. **A lacuna** — L1 (cobertura unilateral × bilateral), L2 (massa crítica declarada e não
   modelada), L5 (curva de implantação nunca ligada ao dual). São as três que este trabalho
   ataca, e dizê-lo explicitamente é o que transforma revisão em justificativa.
4. **Como foi aproveitado** — de onde vem cada peça do P1: a estrutura de cobertura máxima de
   Church & ReVelle (1974); a restrição de ligação em forma canônica de Kuby & Lim (2005); o
   pré-processamento geométrico como mecanismo de tratabilidade, de Wu & Zhang (2021); os
   parâmetros operacionais do eVTOL de Rimjha et al. (2021).

**Regra de higiene, e ela é inegociável:** referência confirmada só em metadado entra como
"trata de", nunca como "formula assim". A revisão já marca quais são. Repetir a marcação no
relatório não enfraquece o trabalho — declarar limitação do próprio material é critério de
avaliação, e citar formulação não lida é o "palpite acelerado" que o §1.2 do enunciado condena.

#### 1.3 Dados: fontes, tratamento, agregação, demanda capturável, hipóteses explicitadas

Cinco blocos, nesta ordem:

**Fontes.** Uma tabela: fonte, origem, formato, cobertura, **limitações conhecidas**, data de
extração. Direto dos nós `fonte` do grafo — se a tabela do relatório e o grafo divergirem, o
grafo está certo e o relatório está desatualizado.

**Tratamento.** Leitura da OD, fatores de expansão, e **a validação da expansão** contra os
totais do relatório-síntese. Este número é o que dá credibilidade a todo o resto: se a expansão
reproduz o total publicado, o leitor aceita a matriz.

**Agregação.** 517 zonas → ~120 macrozonas: o critério, e a **justificativa quantitativa**. Ela
existe e está no G05 §5: a tabela de tamanho de matriz com o contrafactual de 517×517. "Não
caberia no solver" alegado é fraco; quantificado é definitivo.

**Estimativa da demanda capturável.** As quatro camadas do filtro (distância, duração terrestre,
motivo, renda), cada uma com a literatura de apoio e o número de viagens que sobrevive a ela —
**a tabela de atrito camada a camada**. E, obrigatoriamente, a frase que o G03 já escreve: o
resultado é um **limite superior** da demanda, não uma previsão de adoção, porque não há segundo
estágio de escolha modal. Wu & Zhang (2021) mostram que esse segundo estágio reduz as viagens
candidatas em cerca de duas ordens de grandeza. **Dizer isso é força, não fraqueza** — e um
grupo que apresenta demanda capturável sem essa ressalva vai ouvi-la no painel comparativo, de
outro grupo.

**Hipóteses explicitadas.** Uma lista numerada, curta, cada item com o `decisao:D__`. Toda
hipótese que, se mudasse, mudaria o resultado. Esta lista é a que o professor lê para saber o
que perguntar — e é melhor que ela seja completa e sua do que incompleta e descoberta.

#### 1.4 Modelo: formulação completa, com justificativa de cada elemento

O §4.2 do enunciado exige **cada elemento com a razão de existir**. Escreva na ordem:

**Conjuntos e índices** — $I$, $J$, $Q$, $P_q$, com cardinalidade medida ao lado.

**Parâmetros, com unidade e procedência de cada valor.** Uma tabela: símbolo, nome no código,
unidade, valor, fonte ou decisão. Se algum valor não tiver procedência, ele não entra — regra 3
do `CLAUDE.md`, e primeiro item da lista do que compromete a nota.

**Variáveis de decisão, com significado.** $y_j$ binária, $w_{qjk}$ contínua em $[0,1]$ — e
**a justificativa de $w$ ser contínua**, que é uma pergunta garantida na arguição. Ver §7,
pergunta 17.

**Função objetivo, com o critério que representa.** $\sum_q\sum_{(j,k)\in P_q} f_q\Delta_{qjk}w_{qjk}$
maximiza economia agregada de tempo de deslocamento, em **pax·min/dia**. Diga por que este
critério e não custo, receita ou cobertura: o critério escolhido é o benefício social do tempo
poupado, que é o que uma decisão de infraestrutura pública maximiza.

**Restrições, cada uma com a razão de existir.** Uma frase por restrição:

- $\sum_{(j,k)\in P_q} w_{qjk} \le 1$ — cada par OD é servido no máximo uma vez; impede contar a
  mesma viagem duas vezes por rotas diferentes. É `≤` e não `=` porque um par pode simplesmente
  não ser atendido.
- $w_{qjk} \le y_j$ e $w_{qjk} \le y_k$ — **as duas juntas são o mecanismo de bilateralidade**, e
  são o que distingue este modelo de um MCLP comum: a viagem eVTOL só existe se houver
  vertiporto na origem **e** no destino.
- $\sum_j y_j \le p$ — o orçamento de implantação. É a restrição cujo dual $\pi$ dá a inclinação
  da curva de implantação, e por isso ela é `≤` com $p$ paramétrico.

**O que ficou fora do modelo, e por que a omissão é aceitável** — exigência textual do §4.3.
Candidatos: tarifa e disposição a pagar; capacidade de espaço aéreo e separação; ruído; frota e
escalonamento; competição entre operadores; variação horária da demanda. Para cada, uma frase de
por que a omissão não invalida o resultado **ou** em que direção ela o enviesa. A segunda forma
é mais forte.

#### 1.5 Tratabilidade: a redução da instância e sua justificativa

Curta e quantitativa. O §4.5 do enunciado exige a redução como decisão de engenharia
documentada.

O que entra: a cadeia de reduções com os números medidos em cada etapa — 517 zonas → ~120
macrozonas; $|I|^2$ pares brutos → $|Q|$ pares elegíveis; $|J|^2$ combinações → $\sum_q|P_q|$
arcos viáveis. E a observação que fecha: **o que torna o problema fácil não é o tamanho, são as
poucas binárias** ($|J|$ na casa das dezenas), o que preserva relaxação, duais e sensibilidade —
que é exatamente o vínculo com a matéria que o §4.4 exige. Toda a literatura que modela
interdependência corretamente cai em meta-heurística e perde isso.

Reporte também o que **não** foi reduzido e por quê, e o custo do pré-processamento em tempo.

#### 1.6 Resultados computacionais: solução, mapas, fronteira de implantação

Abre com a **tabela de indicadores comuns** (§6.3) — ela é a primeira coisa que o leitor procura,
e é a linha do grupo no painel final.

Depois: o mapa da solução recomendada (F7 do G08); a lista dos vertiportos com nome e coordenada;
a demanda atendida em absoluto **e** em participação da capturável, com o denominador nomeado; a
fronteira de implantação (F1) com as duas curvas sobrepostas; e o desempenho computacional —
valor da FO, tamanho da instância, tempo de solução — direto de `tabela_indicadores()`.

**Cada figura cita o `experimento:` que a gerou.** É o que responde "qual script gerou o mapa da
página 12" pela própria figura, sem depender de alguém lembrar.

#### 1.7 Relaxação linear, dual e análise de sensibilidade

A seção que vale mais. A estrutura interna está detalhada no **G08, "Como isso vira relatório"** —
siga aquela, não reinvente aqui.

O parágrafo que não pode faltar, e que amarra as três análises numa ideia só: **a relaxação
explica por que $\pi$ e a diferença finita divergem, e a divergência é maior no trecho convexo da
curva de implantação.** Um grupo que escreve esse parágrafo demonstra que entendeu as três; um
que apresenta as três em sequência sem ligá-las demonstra que executou as três.

#### 1.8 Limitações do modelo e trabalhos futuros

Esta seção **ganha nota**, não perde. O critério de excelência inclui literalmente "mostra o que
não funcionou, e por quê".

O que entra, e boa parte já está escrita nos guias anteriores:

- Ausência de segundo estágio de escolha modal — a demanda é limite superior; a varredura de
  $\theta$ é o substituto declarado, e é mais fraca que um logit calibrado. Não existe logit
  calibrado para UAM no Brasil, e essa é a razão registrada da omissão.
- OD 2017 com calibração de nível pela 2023; microdados da 2023 não publicados na data de
  extração.
- Matriz terrestre do OSRM em *free-flow*, corrigida por fator calibrado — **o parâmetro mais
  incerto do trabalho**, e a sensibilidade quantifica quanto ele importa.
- Parâmetros operacionais do eVTOL transplantados de contexto norte-americano.
- Validade local e não-unicidade dos duais sob degenerescência.
- Ausência de capacidade de espaço aéreo, ruído e tarifa.
- **Se o formato em S não apareceu:** o diagnóstico de densidade de $P_q$ entra aqui e em
  resultados. Nos dois lugares.

Trabalhos futuros: os que decorrem das limitações, na mesma ordem. Não invente linhas de pesquisa
genéricas — cada trabalho futuro deve ser a remoção de uma limitação listada acima.

#### 1.9 Referências

Formato consistente, com DOI. **Só entra o que foi visto.** Referência confirmada só em metadado
entra na lista, mas o texto que a cita não pode atribuir formulação a ela.

Se material de outro grupo tiver sido usado, o crédito é registrado — é item explícito da lista
do que compromete a nota.

---

### 2. Onde cada guia deságua — o mapa de compilação

Esta tabela é a razão de o relatório ser compilação e não redação. Cada guia anterior tem uma
seção **"Como isso vira relatório"**; releia-as antes de escrever a seção correspondente.

| Guia | Produz | Seção do relatório | O que exatamente vai |
| --- | --- | --- | --- |
| **G01** | infraestrutura de governança | *não vai ao relatório* — vai ao **site** e à seção de reprodutibilidade | o compilador, o validador, o CI |
| **G02** | OD lida, validada, agregada | **3. Dados** | fatores de expansão e sua validação; agregação 517 → 120; a tabela de macrozonas |
| **G03** | filtro de demanda capturável | **3. Dados** + **8. Limitações** | as quatro camadas com literatura; a tabela de atrito; a ressalva de limite superior |
| **G04** | conjunto $J$ de candidatos | **3. Dados** | origem dos candidatos, data de extração, filtros de viabilidade, o mapa de $J$ |
| **G05** | quatro matrizes de tempo | **3. Dados** + **5. Tratabilidade** | as matrizes e dimensões; a calibração do congestionamento e a discrepância entre as três âncoras; a tabela de tamanhos com o contrafactual 517×517 |
| **G06** | a formulação | **4. Modelo** | conjuntos, parâmetros com unidade e procedência, variáveis, FO, restrições com razão de existir, e o que ficou fora |
| **G07** | pré-processamento, solver, validação | **5. Tratabilidade** + **6. Resultados** | a cadeia de redução com números; a validação contra a instância-brinquedo; a primeira solução |
| **G08** | as quatro análises + extensão | **6. Resultados** + **7. Relaxação, dual e sensibilidade** | tabela de indicadores; F1–F9; a interpretação econômica; o núcleo robusto |
| **G09** | este pacote | **1**, **2**, **8**, **9** e a costura | recorte, revisão, limitações, referências |

**Como usar isto na prática.** Abra o relatório com os nove títulos vazios. Para cada um, abra o
guia da linha correspondente na seção "Como isso vira relatório", e cole o que já está escrito.
O que sobrar sem origem é o que realmente precisa ser redigido — e vai ser pouco. Se estiver
sendo muito, algum guia não foi mantido atualizado durante a execução, e vale registrar isso
como aprendizado de processo em vez de esconder.

---

### 3. O site publicado (§5.5) — as oito seções obrigatórias

O site **não é o relatório em HTML**. É o entregável da Camada B: é por ele que se lê o processo,
e o enunciado diz que ele é o ponto de partida dos encontros — "não uma apresentação preparada
para a ocasião". Parte da arguição será feita navegando nele.

Ele é gerado por `governanca/tools/site.py` a partir do DuckDB (G01 §5.5). **Nada aqui é digitado
à mão** — se alguma seção precisar de conteúdo que não está no grafo, o conserto é registrar no
grafo, não escrever HTML.

| # | Seção | O que precisa mostrar | Consulta que a alimenta |
| --- | --- | --- | --- |
| 1 | **Estado** | metas, próximas ações, últimas decisões, **selo de auditoria** | contagem por kind; tarefas `pronta`/`fazendo` por prazo; últimas `decisao` por `criado_em`; o resultado das quatro consultas de §8 |
| 2 | **Grafo executivo interativo** | o grafo navegável, **clique abrindo o registro** | `graph.json` do G01; cada nó com `url` para `registros/<id>.html` |
| 3 | **Trilha** | linha do tempo de decisões **com justificativas** | `decisao` ordenada por `criado_em`, com `descricao` e `alternativas_descartadas` |
| 4 | **Tarefas e pendências** | kanban com prazos, bloqueio marcado | `tarefa` por `status`; `pendencia` aberta com aresta `BLOQUEIA` |
| 5 | **Interações com IA** | **taxa de aceite** e as críticas humanas | distribuição de `aceito`; o texto de `critica_humana` visível |
| 6 | **Experimentos** | parâmetros e resultados de cada rodada | `experimento` com `parametros`, `obj`, `gap`, `segundos`, `commit` |
| 7 | **Resultados** | mapas, fronteira, sensibilidade | as figuras do G08, com link para o `experimento:` |
| 8 | **Reprodutibilidade** | **como rodar tudo do zero** | texto fixo + `renv.lock` + `_targets.R` + os comandos |

Três pontos que decidem se o site funciona:

**O selo de auditoria (seção 1) precisa mostrar os números ruins também.** Uma auditoria só verde
não é auditoria, e o critério de excelência inclui mostrar o que não funcionou. Publiquem prazo
vencido, tarefa parada, cadência com vale.

**A taxa de aceite (seção 5) será examinada.** O enunciado avisa que perto de 100% integral é
sinal de ausência de revisão. A distribuição saudável — alguns `integral`, muitos `parcial`,
alguns `descartado` — não se fabrica na véspera: ela é o subproduto de ter lido com atenção
durante cinco semanas. Se ela estiver ruim agora, a resposta honesta na arguição é dizer o que
aconteceu, não maquiar o banco.

**A seção 8 tem que ser verdadeira.** "Qualquer pessoa deve conseguir rodar o projeto do zero" é
exigência textual. **Teste**: clone o repositório em uma pasta nova, siga só o que está escrito
na seção 8, e veja se roda. Faça isso em **21/09**, não em 23/09.

O site precisa abrir **offline, de um pen drive**, sem CDN e sem XHR (G01 §5.5). Confirme isso
desligando a rede e abrindo o `index.html`. Se a arguição for feita navegando no site e o Wi-Fi
da sala cair, essa verificação vale a nota inteira da seção.

---

### 4. A apresentação oral

#### 4.1 O que se espera

Duas coisas, e a segunda é a que os grupos esquecem:

> Espera-se que a apresentação percorra **as duas camadas**: o modelo e o processo. Parte da
> arguição será feita **navegando no site**.

Um deck que só apresenta o modelo entrega metade. E "navegando no site" é literal: **deixe o site
aberto numa aba** antes de começar, com o grafo já carregado.

#### 4.2 Estrutura sugerida do deck

O tempo total **[A CONFIRMAR com o professor]**. A estrutura abaixo é dimensionada para **15
minutos de apresentação** e escala proporcionalmente. Se o tempo for menor, corte os slides 3 e
9 — não os 5, 6 e 7.

| # | Slide | min | O que mostra | Quem |
| --- | --- | --- | --- | --- |
| 1 | Problema e recorte | 1,0 | a pergunta em uma frase; o recorte e o que ficou fora | Pedro |
| 2 | Por que este modelo | 1,5 | a lacuna: cobertura unilateral × bilateral; a tabela §1.8 da revisão em uma linha | Pedro |
| 3 | Dados e demanda capturável | 1,5 | as quatro camadas e o atrito; **a ressalva de limite superior dita em voz alta** | Pedro |
| 4 | O modelo | 2,0 | a formulação inteira em um slide; **as duas restrições de ligação destacadas** | Henri |
| 5 | Resultado: o mapa | 1,5 | F7 — a solução recomendada, com nomes dos sítios | Antônio |
| 6 | **A figura central** | 2,5 | F1 — as duas curvas; a leitura em duas metades: massa crítica **e** saturação | Henri |
| 7 | Dual e sensibilidade | 2,0 | $\pi$ com unidade; o **núcleo robusto** do mapa de estabilidade (F6) | Antônio |
| 8 | A extensão | 1,0 | a formulação em duas linhas e a fronteira F9 | Antônio |
| 9 | Limitações | 1,0 | as três maiores, ditas sem rodeio | Pedro |
| 10 | **Como trabalhamos** | 1,0 | o site ao vivo: grafo, cadência, taxa de aceite de IA | Henri |
| | | **15** | | |

**Regras do deck:**

- **Slide 6 é o clímax.** Ensaiem-no separado. Se o S apareceu, a figura fala sozinha e o texto é
  a leitura em duas metades. Se não apareceu, o slide vira "a previsão, o resultado, e por quê" —
  e ainda é o melhor slide do deck, porque mostra método.
- **Slide 10 não é enfeite.** É 25% da nota aparecendo na tela. Navegue ao vivo, não com captura
  de tela: uma captura de tela do site é a demonstração de que o site não está no ar.
- **Um número por slide com unidade.** Todo número na tela tem unidade e vem de um
  `experimento:`.
- **Os três falam.** Contribuição individual é visível e avaliada. Um deck apresentado por uma
  pessoa é um sinal, e não é bom.
- **Nada no slide que quem apresenta não saiba defender.** Vale para figura, número e equação.

---

### 5. O painel comparativo final (§6.3)

Todos os grupos atacam o mesmo objeto, e a sessão termina comparando os resultados lado a lado.
A discussão final é sobre **por que os resultados convergiram ou divergiram partindo dos mesmos
dados**.

**A regra que o grupo precisa internalizar antes de entrar na sala:**

> Convergir não penaliza. Divergir não desqualifica. **O que se avalia é a defesa.**

O grupo que souber explicar por que seu modelo diverge do de outro demonstra domínio; o que
descobrir a divergência ao vivo e não souber explicá-la demonstra o contrário.

#### 5.1 Como se prepara

**Saibam de cor as quatro escolhas que mais deslocam o resultado.** Quase toda divergência entre
grupos vai vir de uma delas:

1. **O denominador da demanda capturável.** Um grupo com filtro estreito reporta participação
   alta sobre pouca demanda; outro com filtro largo reporta participação baixa sobre muita. **Os
   números absolutos podem ser iguais.** Levem sempre o absoluto ao lado do percentual.
2. **Unilateral × bilateral.** É a nossa escolha estrutural. Um grupo unilateral vai apresentar
   curva côncava e provavelmente $p$ menor. Não é erro dele — é outro modelo, e a diferença é
   explicável em uma frase: *"o modelo deles cobre zonas, o nosso cobre pares; um vertiporto
   isolado tem valor no deles e valor zero no nosso, e é daí que vem a diferença no $p$ mínimo."*
3. **O tratamento do tempo terrestre.** Free-flow contra congestionado muda $\Delta$, muda $P_q$,
   muda tudo. Se outro grupo usou tempo free-flow, o resultado dele é conservador contra a UAM —
   e nós temos a varredura que quantifica exatamente isso.
4. **A métrica da FO.** pax·min/dia, viagens cobertas, custo generalizado, receita. Duas soluções
   diferentes podem ser as duas ótimas, cada uma para sua métrica.

**Levem uma tabela de uma linha por grupo, em branco, para preencher durante o painel.** Os
quatro indicadores do §6.3 mais a métrica da FO e a definição do denominador. Chegar com a tabela
pronta para preencher é a diferença entre participar do painel e assistir a ele.

**Preparem duas frases:**

- **Convergência:** *"nosso resultado converge com o do grupo X no núcleo de vertiportos —
  $[\,\cdot\,]$ dos $[\,\cdot\,]$ sítios coincidem — mesmo com métricas de FO diferentes. Isso
  reforça a recomendação: esses sítios não dependem de qual critério se maximiza."*
- **Divergência:** *"divergimos do grupo Y em $[\,\cdot\,]$ e a razão é $[\,\cdot\,]$. É uma
  consequência prevista da nossa escolha de $[\,\cdot\,]$, e a nossa análise de sensibilidade
  mostra em que faixa de parâmetro as duas soluções coincidiriam."*

A segunda frase é a que impressiona, e ela só existe se a análise de estabilidade do G08 tiver
sido feita. **Levem o mapa de frequência de seleção (F6) impresso.** Discutir núcleo robusto é
mais informativo que discutir solução pontual, e quem tiver o núcleo pronto conduz a conversa.

---

### 6. A pergunta garantida a todos os grupos

> **"Mostrem a decisão em que vocês discordaram da IA — e expliquem por que vocês estavam
> certos."**

Ela é garantida. Prepará-la com registro, não com improviso, é a diferença entre uma resposta de
trinta segundos com evidência na tela e uma reconstrução de memória que soa exatamente como o
que é.

#### 6.1 A consulta

```sql
-- Todas as interações em que o grupo não aceitou integralmente.
SELECT n.id,
       n.titulo,
       n.criado_em,
       json_extract_string(n.props, '$.aceito')        AS aceito,
       json_extract_string(n.props, '$.critica_humana') AS critica
FROM node n
WHERE n.kind = 'ia'
  AND json_extract_string(n.props, '$.aceito') IN ('parcial', 'descartado')
ORDER BY n.criado_em;
```

E a marca `#discordancia` que o G00 §4.4 manda colocar nas notas quando a discordância acontece:

```sql
SELECT node_id, n.data, n.autor, n.texto
FROM nota
WHERE n.texto ILIKE '%#discordancia%'
ORDER BY n.data;
```

#### 6.2 Como escolher a melhor

**Não é a mais recente nem a mais fácil de contar. É a que teve consequência técnica real.**
Uma discordância que não mudou nada é uma opinião registrada; uma que mudou o modelo, o dado ou
uma conclusão é um episódio de engenharia.

Ordene as candidatas por consequência — quantos nós de `decisao`, `experimento` ou `conclusao`
estão ligados a cada interação:

```sql
-- A vizinhança não-dirigida, usada por várias consultas deste guia.
CREATE OR REPLACE VIEW viz AS
SELECT src AS a, dst AS b, rel FROM edge
UNION ALL
SELECT dst AS a, src AS b, rel FROM edge;

-- Discordâncias ordenadas por consequência técnica.
SELECT i.id,
       i.titulo,
       i.criado_em,
       json_extract_string(i.props, '$.aceito') AS aceito,
       count(*) FILTER (WHERE d.kind IN ('decisao', 'experimento', 'conclusao')) AS consequencias,
       string_agg(DISTINCT d.id, ', ') FILTER (
           WHERE d.kind IN ('decisao', 'experimento', 'conclusao')) AS nos_ligados
FROM node i
LEFT JOIN viz  v ON v.a = i.id
LEFT JOIN node d ON d.id = v.b
WHERE i.kind = 'ia'
  AND json_extract_string(i.props, '$.aceito') <> 'integral'
GROUP BY 1, 2, 3, 4
ORDER BY consequencias DESC, i.criado_em;
```

**A candidata ideal tem quatro propriedades:** a IA propôs algo específico; o grupo apontou um
defeito concreto; a correção mudou um artefato rastreável; e o grupo consegue mostrar o antes e o
depois no site em dois cliques.

Candidatas naturais a este projeto, se acontecerem — não fabriquem, mas reconheçam quando
ocorrerem:

- A revisão de literatura apresentou formulações de artigos confirmados só em metadado; o grupo
  se recusou a citá-las até ler o PDF, e isso mudou o que a seção 2 do relatório afirma.
- Os números de dimensionamento da instância foram apresentados como se fossem medições; são
  estimativas de ordem de grandeza, e a medição da S2 os corrigiu.
- A previsão do formato em S é teórica e foi apresentada com confiança maior do que a evidência
  sustentava.
- Uma escolha de limiar sugerida pela IA foi trocada por outra com sustentação em literatura
  brasileira ou em dado do projeto.

#### 6.3 A forma da resposta

Quatro frases, nesta ordem, com o site aberto:

1. **O que a IA propôs**, concretamente.
2. **O que estava errado ou incompleto**, com o motivo específico — não "achamos melhor".
3. **O que mudou** no repositório: o nó, o commit, o arquivo.
4. **Como sabemos que estávamos certos**: o experimento, a fonte, ou o teste que decidiu.

A quarta é a que a pergunta realmente cobra, e é onde as respostas fracas param. *"Estávamos
certos porque preferimos assim"* não é resposta. *"Estávamos certos porque medimos e o número
era outro"* é.

---

### 7. Ensaio de arguição — 30 perguntas prováveis

Façam o ensaio **em 22/09**, com uma pessoa fazendo o papel de arguidor e cronômetro de 60
segundos por resposta. Quem trava, anota e volta ao material.

A coluna "quem" indica o **primeiro a responder**, não o único — mas o combinado é: quem começa,
começa. Divergência entre integrantes na frente do arguidor é pior que uma resposta imperfeita.

E vale lembrar que **cada um deve saber defender qualquer linha do modelo**, não só a da sua
frente. As perguntas marcadas com ✦ podem cair em qualquer um dos três: sorteiem no ensaio.

#### Camada A — dados e demanda

| # | Pergunta | Quem | O eixo da resposta |
| --- | --- | --- | --- |
| 1 | ✦ **Por que 120 macrozonas e não as 517 zonas da OD?** | Pedro | Tratabilidade, **quantificada**: a matriz de tempos 517×517 e o número de arcos que ela geraria (G05 §5). E o custo declarado: a agregação perde resolução espacial intrazonal, e por isso os pares intrazonais foram tratados de tal forma. Não diga "para simplificar" |
| 2 | Como vocês expandiram a amostra, e contra o que validaram? | Pedro | `FE_viagem`; a validação reproduz o total publicado no relatório-síntese |
| 3 | Por que a OD 2017 e não a 2023? | Pedro | Microdados da 2023 não publicados na data de extração; calibração de nível pela 2023 |
| 4 | **O que acontece se os microdados da OD 2023 saírem?** | Pedro | O pipeline é `targets`: troca-se o alvo de leitura e tudo a jusante recomputa. **O que muda substantivamente**: nível pós-pandemia, composição por motivo, e possivelmente o filtro de renda. **O que provavelmente não muda**: a geografia dos corredores longos. A pendência já está registrada, e a consulta de impacto é a de §8 |
| 5 | Por que o corte de 15 km? | Pedro | Abaixo disso o eVTOL não recupera o tempo de solo; é parâmetro, e a sensibilidade mostra a faixa |
| 6 | Só trabalho/negócios e renda alta — isso não é profecia autorrealizável? | Pedro | **Sim, parcialmente, e está declarado.** UAM é serviço premium; ignorar isso é fingir mercado. O contraponto é a extensão de equidade (se for essa) ou a limitação declarada (se não for) |
| 7 | Quanta demanda sobra depois do filtro? Isso é previsão? | Pedro | O número, e a frase obrigatória: **limite superior, não previsão**. Wu & Zhang (2021): o segundo estágio reduz em ~2 ordens de grandeza |
| 8 | **Por que não usaram logit?** | Pedro | Não existe logit calibrado para UAM no Brasil; calibrar um seria o trabalho inteiro. Descartado com registro. **A varredura de $\theta$ é o substituto declarado**, e é mais fraca — diga isso |
| 9 | **Por que este valor do tempo?** | Pedro | A fonte, a decisão, **e quem assinou**. É uma das quatro perguntas que o grafo tem que responder (G00 §7). Mostre o registro. E: a solução do P1 em minutos não depende dele; só a leitura monetária depende |
| 10 | A duração declarada na OD é confiável? | Pedro | É declarada, não medida — mas embute congestionamento real, que é justamente o que falta ao OSRM. Por isso ela é âncora da calibração |

#### Camada A — candidatos, GIS e tempos

| # | Pergunta | Quem | O eixo da resposta |
| --- | --- | --- | --- |
| 11 | De onde vêm os candidatos, e quantos são? | Antônio | ANAC/DECEA + ROTAER, contados pelo grupo, com **data de extração**. Os números que circulam na imprensa são inconsistentes |
| 12 | Por que helipontos existentes e não sítios novos? | Antônio | Remove a maior fonte de arbitrariedade (revisão, L4); é o que torna o caso SP diferente de Chicago/Munique. Custo: herda a geografia desigual existente |
| 13 | Espaço aéreo e ruído entraram? | Antônio | Não. **Em que direção a omissão enviesa**: infla a viabilidade dos sítios centrais |
| 14 | Como trataram o tempo intrazonal? | Antônio | A decisão registrada em G05, e por que a alternativa foi descartada |
| 15 | **O OSRM roteia em free-flow. Quanto isso muda o resultado?** | Antônio | A calibração, as três âncoras, e **o número da varredura $f=1$ × calibrado**. Sem o número, a resposta é fraca |
| 16 | Por que linha reta para o voo? | Antônio | Aproximação declarada; a rota real depende de corredores aéreos que não temos. Compare euclidiana × geodésica com o número medido |

#### Camada A — modelo e análises

| # | Pergunta | Quem | O eixo da resposta |
| --- | --- | --- | --- |
| 17 | **Por que $w$ é contínua e não binária?** | Henri | $w$ é fração de fluxo, não decisão discreta. **E há um argumento estrutural**: com $y$ fixo e sem capacidade, o subproblema separa por $q$ e o ótimo escolhe um único melhor arco — a solução sai naturalmente inteira, e declarar $w$ binária só acrescentaria ramificação. **Com capacidade ativa**, fracionar é ótimo e realista (o fluxo se divide entre vertiportos). Rodem com $w$ binária uma vez e comparem $Z$ e tempo: isso vira experimento e a resposta passa a ser medida |
| 18 | Por que $\sum w \le 1$ e não $= 1$? | Henri | Um par pode não ser atendido; com `=` o modelo ficaria infactível sempre que $P_q$ não tivesse arco com as duas pontas abertas |
| 19 | Por que duas restrições de ligação e não uma agregada? | Henri | A tabela de T30: gap medido × número de linhas. As alternativas estão registradas com o motivo numérico |
| 20 | **Qual é o gap de integralidade, e por que não é zero?** | Henri | O número, e o mecanismo: a bilateralidade permite $y_j=y_k=0{,}5$ comprando meia cobertura. **O exemplo mínimo de três candidatos é a melhor resposta possível** — ele cabe no quadro |
| 21 | ✦ **O que exatamente é $\pi$, e em que unidade?** | qualquer | Economia marginal de tempo-passageiro por vertiporto adicional, em **pax·min/dia por vertiporto**; é a inclinação da curva de implantação. **Os três precisam responder isto sem consultar nada** |
| 22 | Duais existem em MIP? | Henri | Não. LP relaxado, LP restrito com $y$ fixo, e diferença finita — as três coisas diferentes do G08 §2.1, e para que serve cada uma |
| 23 | Por que $\pi$ e a diferença finita divergem? | Henri | $\pi_{LP}$ é a inclinação da envoltória côncava; a curva inteira não é côncava. A divergência **é** o gap visto pela derivada |
| 24 | **Como vocês sabem que o modelo está certo?** | Henri | Quatro evidências, nesta ordem: (1) a instância-brinquedo de 5 zonas e 3 candidatos resolvida à mão bate; (2) $Z^*(1)=0$ no bilateral, como a teoria exige; (3) $\pi_{LP}$ bate com a diferença finita do LP; (4) as instâncias-brinquedo de relaxação reproduzem os valores calculados a mão. **"Roda sem erro" não é resposta** |
| 25 | O S apareceu? | Henri | Se sim: os três pontos e a leitura em duas metades. Se não: a densidade de $|P_q|$, a rodada com $\bar t$ apertado, e a frase de que a previsão está correta em mecanismo e insuficiente em magnitude |
| 26 | Por que só uma extensão? | Antônio | Escolha registrada, com a outra descartada e o motivo. Uma bem feita vale mais que duas pela metade — e mostre a varredura do parâmetro novo como prova de que esta está inteira |
| 27 | Tamanho da instância e tempo de solução? | Henri | Da tabela de indicadores: $\vert Q\vert$, $\vert J\vert$, $\sum_q\vert P_q\vert$, linhas, colunas, não-zeros, segundos. E **por que é fácil**: poucas binárias |
| 28 | ✦ **Qual é a maior fraqueza do trabalho de vocês?** | qualquer | **Combinem uma resposta e digam a mesma.** A candidata mais forte é a ausência de segundo estágio de escolha modal: a demanda é limite superior e o nível absoluto não é previsão. A segunda é o `fator_congestionamento`. **Não respondam "nenhuma" e não respondam "faltou tempo"** — a pergunta testa se o grupo conhece o próprio trabalho |

#### Camada B — processo

| # | Pergunta | Quem | O eixo da resposta |
| --- | --- | --- | --- |
| 29 | **Mostrem a decisão em que discordaram da IA.** | quem viveu o episódio | As quatro frases de §6.3, com o site aberto |
| 30 | ✦ Qual script gerou o mapa da página 12? | qualquer | A legenda cita o `experimento:`; o site liga ao `arquivo:`; o `arquivo:` liga ao commit. **Faça ao vivo, em três cliques** |
| 31 | Se a fonte de tempos terrestres for substituída, o que cai? | Henri | A consulta recursiva de §8.5, rodada na hora |
| 32 | Quais conclusões ainda não têm experimento? | Henri | A consulta de §8.3 — e a resposta esperada é **nenhuma**, porque a auditoria foi limpa antes de entregar |
| 33 | Por que a taxa de aceite de IA é essa? | todos | A distribuição real e o que ela significa. Se estiver alta, diga por quê **honestamente**; maquiar é pior |
| 34 | A cadência tem um vale na semana X. O que aconteceu? | quem estava na frente | A verdade, com a nota datada que registra. Prova B1, feriado, bloqueio por pendência. Um vale explicado é normal; um vale negado é o problema |

*(São 34 entradas para cobrir folgadamente as 25–30 do ensaio; as marcadas ✦ contam dupla porque
são sorteadas entre os três.)*

---

### 8. Auditoria limpa antes de entregar

Rode **21/09**, não na véspera. Cada consulta abaixo tem que devolver **zero linhas** (ou a
exceção precisa estar explicada no relatório).

Todas assumem a view `viz` de §6.2 e o esquema `node` / `edge` / `nota` do G01.

> **Nota sobre os nomes de `rel`:** o enum fechado está em
> `governanca/schema/grafo.schema.json`. As consultas abaixo são escritas **direção-agnósticas**
> (via `viz`) e por tipo de nó, de propósito: assim continuam corretas se o nome exato da relação
> entre `conclusao` e `experimento` for outro. **Confira o enum uma vez e, se preferir, aperte as
> consultas filtrando por `rel`.**

#### 8.1 Zero nós órfãos

```sql
-- Nó sem nenhuma aresta, em qualquer direção.
SELECT n.id, n.kind, n.titulo, n.criado_em
FROM node n
WHERE NOT EXISTS (SELECT 1 FROM edge e WHERE e.src = n.id OR e.dst = n.id)
ORDER BY n.kind, n.id;
```

Órfão é um registro que ninguém consegue alcançar a partir de uma meta: existe no banco e não
existe no projeto. As causas típicas são erro de digitação em um id e nó criado e esquecido.

#### 8.2 Toda decisão alcança uma meta

```sql
-- Decisões que não alcançam nenhuma meta, seguindo arestas para a frente.
WITH RECURSIVE alcanca(origem, no, profundidade) AS (
    SELECT id, id, 0 FROM node WHERE kind = 'decisao'
  UNION
    SELECT a.origem, e.dst, a.profundidade + 1
    FROM alcanca a
    JOIN edge e ON e.src = a.no
    WHERE a.profundidade < 6
)
SELECT d.id, d.titulo, d.criado_em
FROM node d
WHERE d.kind = 'decisao'
  AND NOT EXISTS (
      SELECT 1 FROM alcanca a JOIN node m ON m.id = a.no
      WHERE a.origem = d.id AND m.kind = 'meta')
ORDER BY d.criado_em;
```

O limite de profundidade não é otimização: é proteção contra ciclo. Um `SUPERSEDE` mal apontado
cria ciclo, e sem o limite a consulta não termina.

A mesma consulta, trocando `'decisao'` por `'tarefa'`, verifica a regra 5 do `CLAUDE.md` — toda
tarefa se vincula a uma meta. O validador já barra isso, mas rodar aqui confirma que o banco
compilado reflete o que o validador viu.

#### 8.3 Toda conclusão tem experimento

```sql
-- Conclusões sem nenhum experimento vizinho. A quarta pergunta do G00 §7,
-- e a mais fácil de errar, porque a resposta certa é uma ausência.
SELECT c.id, c.titulo, c.criado_em
FROM node c
WHERE c.kind = 'conclusao'
  AND NOT EXISTS (
      SELECT 1
      FROM viz v JOIN node x ON x.id = v.b
      WHERE v.a = c.id AND x.kind = 'experimento')
ORDER BY c.criado_em;
```

**Rode esta toda semana, não só agora.** É a consulta que pega a conclusão escrita antes de a
rodada terminar — e a semana da prova é quando isso mais acontece.

#### 8.4 Todo arquivo tem decisão

```sql
-- Arquivos que não se ligam a nenhuma decisão.
SELECT f.id, f.titulo
FROM node f
WHERE f.kind = 'arquivo'
  AND NOT EXISTS (
      SELECT 1
      FROM viz v JOIN node d ON d.id = v.b
      WHERE v.a = f.id AND d.kind = 'decisao')
ORDER BY f.id;
```

O cabeçalho de proveniência (`@decisao`) de cada arquivo em `app/R/` é o que alimenta essa
aresta. Arquivo sem decisão é código que ninguém sabe por que existe — e o compilador do grafo
lê o cabeçalho, então o conserto é no cabeçalho, não no banco.

#### 8.5 As outras verificações que valem a pena

```sql
-- (a) Tarefa com prazo vencido e não concluída.
SELECT id, titulo, json_extract_string(props, '$.prazo') AS prazo, status
FROM node
WHERE kind = 'tarefa' AND status <> 'feita'
  AND CAST(json_extract_string(props, '$.prazo') AS DATE) < current_date
ORDER BY 3;

-- (b) Pendência ainda aberta, e o que ela bloqueia.
SELECT p.id, p.titulo, string_agg(e.dst, ', ') AS bloqueia
FROM node p LEFT JOIN edge e ON e.src = p.id AND e.rel = 'BLOQUEIA'
WHERE p.kind = 'pendencia' AND p.status <> 'fechada'
GROUP BY 1, 2;

-- (c) Interação de IA com crítica vazia ou trivial.
SELECT id, titulo, json_extract_string(props, '$.aceito') AS aceito,
       length(json_extract_string(props, '$.critica_humana')) AS n_car
FROM node
WHERE kind = 'ia'
  AND coalesce(length(json_extract_string(props, '$.critica_humana')), 0) < 40
ORDER BY 4;

-- (d) Distribuição do aceite — o número que o site publica.
SELECT json_extract_string(props, '$.aceito') AS aceito, count(*) AS n
FROM node WHERE kind = 'ia' GROUP BY 1 ORDER BY 2 DESC;

-- (e) Cadência: nós criados por semana ISO. O vale aparece aqui.
SELECT strftime(criado_em, '%G-W%V') AS semana, count(*) AS n
FROM node WHERE criado_em IS NOT NULL GROUP BY 1 ORDER BY 1;

-- (f) Autoria: registros por pessoa. Contribuição individual é avaliada.
SELECT e.dst AS pessoa, n.kind, count(*) AS n
FROM edge e JOIN node n ON n.id = e.src
WHERE e.rel = 'ASSINADA_POR'
GROUP BY 1, 2 ORDER BY 1, 3 DESC;

-- (g) Impacto de substituir uma fonte: o que depende dela, transitivamente.
--     Responde à terceira pergunta do G00 §7 — e à pergunta 31 da arguição.
WITH RECURSIVE depende(no, profundidade) AS (
    SELECT 'fonte:osrm', 0
  UNION
    SELECT v.b, d.profundidade + 1
    FROM depende d JOIN viz v ON v.a = d.no
    WHERE d.profundidade < 6
)
SELECT n.kind, n.id, n.titulo, min(d.profundidade) AS salto
FROM depende d JOIN node n ON n.id = d.no
WHERE n.kind IN ('decisao', 'experimento', 'conclusao', 'arquivo')
GROUP BY 1, 2, 3 ORDER BY 4, 1;
```

A consulta (g) é a que deve estar **salva e pronta para rodar ao vivo** na arguição. Trocar
`'fonte:osrm'` pelo id de qualquer fonte responde a pergunta para aquela fonte.

#### 8.6 A verificação que não é SQL

```bash
# Do lado do pipeline de análise:
Rscript -e 'targets::tar_make()'
Rscript -e 'targets::tar_outdated()'    # tem que sair VAZIO

# Do lado do grafo:
uv run python governanca/tools/validar.py governanca/data governanca/schema/grafo.schema.json
uv run python governanca/tools/build.py  --src governanca/data --out governanca/build/grafo.duckdb
uv run python governanca/tools/site.py   --db  governanca/build/grafo.duckdb --out _site/
```

`tar_outdated()` não-vazio significa **figura do relatório gerada por código que já mudou**.
É o defeito exato que a Camada B existe para pegar, e é trivial de detectar do lado de quem
corrige. Não entregue com ele sujo.

E o teste do clone limpo:

```bash
git clone <url> /tmp/teste-do-zero && cd /tmp/teste-do-zero
# seguir SÓ a seção 8 do site. Se não rodar, a seção 8 está errada.
```

---

### 9. Checklist final de aderência, item por item

Cada item é exigência textual do enunciado. Marque com o número da página do relatório ou o id do
nó ao lado — assim ele deixa de ser checklist e vira índice.

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
- [ ] Curva de implantação, com a recomendação de a partir de quantos vertiportos o retorno
      deixa de compensar

**Indicadores comuns a todos os grupos (§6.3):**
- [ ] Número de vertiportos implantados e localização
- [ ] Demanda diária atendida e sua participação na demanda considerada capturável
- [ ] Benefício na métrica própria do grupo, **com unidade explicitada**
- [ ] Desempenho computacional: valor da FO, tamanho da instância, tempo de solução

**Relatório (§6.1)** — as nove seções, na ordem:
- [ ] 1. Contexto e definição do problema, com o recorte adotado
- [ ] 2. Revisão de literatura: modelos estudados **e como foram aproveitados**
- [ ] 3. Dados: fontes, tratamento, agregação, demanda capturável, **hipóteses explicitadas**
- [ ] 4. Modelo: formulação completa em notação matemática, com justificativas
- [ ] 5. Tratabilidade: a redução da instância e sua justificativa
- [ ] 6. Resultados computacionais: solução, mapas, fronteira de implantação
- [ ] 7. Relaxação linear, dual e análise de sensibilidade
- [ ] 8. Limitações do modelo e trabalhos futuros
- [ ] 9. Referências

**Site (§5.5)** — as oito seções:
- [ ] Estado: metas, próximas ações, últimas decisões, selo de auditoria
- [ ] Grafo executivo interativo, com clique abrindo o registro
- [ ] Trilha: linha do tempo de decisões com justificativas
- [ ] Tarefas e pendências, com prazos
- [ ] Interações com IA, com taxa de aceite e as críticas humanas
- [ ] Experimentos, com parâmetros e resultados
- [ ] Resultados: mapas, fronteira, sensibilidade
- [ ] Reprodutibilidade: como rodar tudo do zero — **testado em clone limpo**

**Governança (§5.3)** — entidades que precisam existir no banco:
- [ ] Metas (2 a 4) · Tarefas (com responsável e prazo) · Pendências
- [ ] Decisões, com justificativa **e alternativas descartadas**
- [ ] Fontes de dados, com origem, formato, cobertura e limitações
- [ ] Arquivos · Referências · Experimentos · Interações com IA

**As quatro perguntas que o grafo tem que responder (§5.4):**
- [ ] Por que o valor do tempo adotado é este, **e quem decidiu**
- [ ] Qual script gerou o mapa da página 12
- [ ] Se a fonte de acesso terrestre for substituída, quais decisões e resultados dependem dela
- [ ] Quais conclusões ainda não têm experimento

**O que compromete a nota (§8.4)** — evitar ativamente:
- [ ] Nenhum dado inventado ou não rastreável à fonte; nenhum `[A CONFIRMAR]` no PDF
- [ ] Modelo roda; instância documentada
- [ ] Banco alimentado ao longo das cinco semanas, não em bloco
- [ ] Registros de IA **não** têm aceite integral em todas as interações
- [ ] Todo integrante sabe explicar o modelo
- [ ] Material de outro grupo, se usado, tem crédito registrado

---

## Critério de pronto

**Relatório (T35)**
- [ ] As nove seções do §6.1 existem, com os nomes do enunciado, na ordem do enunciado.
- [ ] Todo número no texto tem fonte rastreável ou `experimento:` ao lado.
- [ ] Toda figura tem legenda com unidade nos eixos e o `experimento:` que a gerou.
- [ ] Nenhum `[A CONFIRMAR]` sobrou; os que sobrariam viraram limitação declarada.
- [ ] Nenhuma formulação é atribuída a artigo não lido em texto integral.
- [ ] A seção 7 é a maior do relatório.
- [ ] A seção 8 lista limitações concretas, não genéricas, e cada trabalho futuro remove uma
      limitação listada.
- [ ] O PDF compila do zero, do `relatorio/`, sem passo manual.

**Site**
- [ ] As oito seções do §5.5 estão no ar.
- [ ] O grafo é navegável e o clique abre o registro.
- [ ] A auditoria publica também os números ruins.
- [ ] Abre **offline**, com a rede desligada, de uma pasta local.
- [ ] A seção de reprodutibilidade foi **testada em clone limpo** em 21/09.

**Apresentação e arguição (T36)**
- [ ] O deck existe, cobre as duas camadas e cabe no tempo confirmado.
- [ ] Os três falam.
- [ ] O ensaio de §7 foi feito, cronometrado, com as ✦ sorteadas.
- [ ] A resposta à pergunta garantida está escolhida, com o nó `ia:` e o antes/depois
      localizáveis em dois cliques.
- [ ] A tabela em branco do painel comparativo está impressa.
- [ ] F1, F6 e F7 estão impressas — e o site aberto numa aba.

**Auditoria**
- [ ] As quatro consultas de §8.1–§8.4 devolvem zero linhas.
- [ ] `tar_outdated()` vazio; validador passa; build e site geram sem erro.
- [ ] Nenhum arquivo de `build/`, `_targets/`, `data/interim/` ou `_site/` no diff final.

---

## Armadilhas conhecidas

**Escrever o relatório do zero.** Se a redação estiver custando muito mais que as 16 h estimadas,
o problema não é a escrita — é que as seções "Como isso vira relatório" dos guias anteriores não
foram mantidas. O conserto agora é compilar o que existe e registrar o aprendizado; o conserto
estrutural é para o próximo bimestre.

**Preencher o banco em bloco nesta semana.** É item **explícito** da lista do que compromete a
nota, e é detectável em uma consulta de três linhas — a de cadência, §8.5(e). Um pico de nós
criados em 22/09 é visível para quem corrige antes de ser visível para quem escreveu.

**Deck escrito antes do relatório.** Vira a versão que o grupo decora, e a arguição encontra
divergência entre o dito e o escrito.

**Números diferentes no relatório, no site e no deck.** A causa é sempre a mesma: alguém copiou
um número de uma rodada e outra rodada foi feita depois. **Todo número vem da tabela de
indicadores gerada pelo pipeline, com o id do experimento ao lado.** Se o número mudou, a tabela
regenera e os três lugares mudam juntos.

**Figura sem unidade no eixo.** É o defeito mais fácil de corrigir e o mais frequente. Passe uma
vez por todas as figuras só olhando os eixos.

**Confundir demanda capturável com demanda atendida, ou o denominador da participação.** É a
divergência número um do painel comparativo. Absoluto ao lado do percentual, sempre, e o
denominador nomeado.

**Ensaiar só o que se sabe.** O ensaio existe para encontrar a pergunta que trava. Se o ensaio
correu liso, ele foi mal feito — acrescentem as ✦ sorteadas e as perguntas 24 e 28.

**Deixar a pergunta garantida para improvisar.** Ela é garantida. Improvisá-la soa exatamente
como improviso, e a diferença entre a resposta preparada e a improvisada é de trinta segundos
de preparo.

**Responder "nenhuma" à pergunta da maior fraqueza.** A pergunta testa se o grupo conhece o
próprio trabalho. Combinem a resposta e digam a mesma os três.

**Site que só abre com internet.** Se a arguição for navegando no site e a rede cair, um CDN
esquecido custa a seção inteira. Teste offline.

**Publicar o site pela primeira vez agora.** A cadência já foi registrada. Se isso acontecer, a
resposta na arguição é a verdade sobre o que atrasou — nunca uma tentativa de fazer parecer que
esteve no ar desde agosto.

**Citar formulação de artigo não lido.** Regra 4 do `CLAUDE.md`, e é a citação que a arguição
mais provavelmente escolhe para verificar, porque o professor conhece a literatura.

**Commitar `_site/` ou `governanca/build/` no aperto final.** Os dois são gitignored por decisão
registrada. Confira o diff antes do último push.

---

## O que registrar

**Decisões**

- **Estrutura e orçamento de páginas do relatório**, se divergirem do §6.1 em qualquer ponto —
  e o motivo.
- **A extensão da revisão de literatura**: quais dos 18 trabalhos da tabela-síntese entram no
  relatório e quais ficam de fora, com o critério.
- **O tratamento das referências confirmadas só em metadado** — citadas como "trata de",
  removidas, ou lidas em texto integral antes da entrega. Registre qual, para cada uma.
- **A escolha da discordância** apresentada na arguição, e por que essa e não outra.

**Conclusões** — se a redação produzir alguma afirmação que ainda não tem nó, ela **não é uma
descoberta de última hora**: é uma conclusão que faltava registrar. Crie o nó, ligue ao
experimento que a sustenta, e se não houver experimento, **a afirmação sai do relatório**. Esta
é a regra mais importante deste pacote.

**Tarefas** — T35 e T36 percorrem `fazendo` → `revisao` → `feita`. **A coluna `revisao` não se
pula**, nem no aperto: o relatório é revisado por quem não o escreveu, e o deck por quem não o
montou. É a defesa contra o item "integrante que não sabe explicar o próprio modelo".

**Notas em tarefa** — o resultado do teste de clone limpo, com a data; o que travou no ensaio de
arguição e quem travou; a conferência offline do site; a lista de `[A CONFIRMAR]` resolvidos e
como.

**Pendências** — o que ficou por fazer e vai para trabalhos futuros pode ser registrado como
pendência fechada com motivo, em vez de desaparecer. Uma pendência que fecha com "não foi feito,
está na seção 8 do relatório" é honesta e rastreável.

**Interação de IA** — se este pacote for conduzido com IA, `critica_humana` não-vazia, como
todos os outros. Candidatos honestos a crítica **neste** pacote: o orçamento de páginas é uma
convenção do grupo apresentada em forma de tabela, o que a faz parecer mais autoritativa do que
é; a estrutura de deck supõe 15 minutos, que **não** foi confirmada com o professor; as consultas
SQL de §8 são escritas direção-agnósticas justamente porque os nomes exatos de `rel` para
conclusão→experimento e arquivo→decisão não foram verificados contra o schema; e a lista de 34
perguntas é uma antecipação plausível, não um conjunto de perguntas que alguém tenha ouvido.

---

## Como isso vira relatório

Este pacote **é** o relatório — mas há uma parte dele que se dobra sobre si mesma e merece ser
dita:

**A seção de limitações ganha um parágrafo sobre o próprio método.** O enunciado avalia como o
grupo conduziu o trabalho, e a honestidade sobre o processo vale o mesmo que a honestidade sobre
o dado. Se a cadência teve um vale, se um guia ficou desatualizado, se uma análise foi feita
mais tarde do que o planejado — dizer isso, com o registro ao lado, é exatamente o
comportamento que a Camada B recompensa. O plano foi escrito em 24/08, antes de qualquer dado
ter sido aberto; ele estar errado em alguns pontos é o esperado, e o G00 §6 já dizia isso.

**A seção de reprodutibilidade do site é o que sustenta a frase "qualquer pessoa deve conseguir
rodar o projeto do zero".** Ela não é documentação — é a evidência de uma afirmação que o
enunciado exige. Por isso o teste de clone limpo é critério de pronto e não sugestão.

**E o site é a metade da entrega que continua existindo depois da apresentação.** O relatório é
lido uma vez; o grafo publicado é o que responde, meses depois, por que o valor do tempo é
aquele e quem decidiu.
