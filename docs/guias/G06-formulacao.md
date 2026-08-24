# G06 — A formulação matemática

> Pacote de trabalho de **Henri Leonardo**. Prazo do pacote: **02/09/2026**.
> Leia `docs/guias/G00-como-trabalhar.md` e `CLAUDE.md` antes deste.

---

## Objetivo

Ao fim deste pacote existe, em LaTeX e pronta para colar no relatório, a formulação **completa e
inequívoca** do modelo P1 — conjuntos, parâmetros com unidade e procedência, variáveis, função
objetivo e restrições, **cada elemento acompanhado da justificativa da escolha** — mais a
justificativa da família escolhida contra as alternativas descartadas, a previsão teórica do
comportamento da curva de implantação, a extensão escolhida e a lista do que ficou fora do modelo
com o motivo de a omissão ser aceitável.

Note o que **não** está no objetivo: nenhuma linha de código, nenhum resultado numérico. Este
pacote produz texto matemático. Se ele estiver certo, o G07 é transcrição; se estiver errado, o
G07 implementa o modelo errado com perfeição.

---

## Tarefas no grafo

| Id | Título | Prazo | Est. |
| --- | --- | --- | --- |
| `tarefa:T21` | Escrever a formulação completa em notação matemática | 02/09 | 8 h |

`T21 REALIZA meta:M2`, `ATRIBUIDA_A pessoa:henri`, `DEPENDE_DE tarefa:T12` (a demanda capturável,
que dá `f_q`) e `DEPENDE_DE tarefa:T20` (os candidatos, que dão `J`).

**Bloqueio ativo:** `pendencia:P02` tem aresta `BLOQUEIA` para `tarefa:T21`. Vale entender
exatamente o que ela bloqueia, porque a leitura literal paralisaria o pacote sem necessidade.
P02 registra que Carvalho et al. (2026), Ribeiro et al. (2023), Brunelli et al. (2023) e Shin et
al. (2021) foram confirmados **apenas em metadado bibliográfico**. O que está bloqueado é uma
frase específica do relatório: *"a formulação de X é ..."*. **Escrever a nossa própria formulação
não depende de ler nenhum deles.** O que depende é o parágrafo de posicionamento na literatura, e
esse parágrafo pode ser escrito agora em versão que cita apenas o que foi lido, com o restante
marcado `[A CONFIRMAR]`.

Fechar T21 com P02 ainda aberta é legítimo. Fechar T21 tendo citado a formulação de um artigo que
ninguém abriu é exatamente o "palpite acelerado" que o enunciado condena, e é irreversível: já
está no PDF.

---

## Pré-requisitos

- [ ] **`decisao:D05` escrita em YAML** — MCLP de fluxo bilateral porta-a-porta, com as quatro
      alternativas descartadas já redigidas em `docs/03-encontro-26-08.md` §D5. Este guia detalha
      a decisão; ele não a substitui. O validador exige `alternativas_descartadas`.
- [ ] **`docs/01-revisao-literatura.md` lido inteiro**, em especial a §1 (as sete famílias
      clássicas, com a formulação de cada uma) e a §4 (o Caminho 1). Este guia assume as duas.
- [ ] **`docs/guias/G05-tempos.md` lido** — é lá que estão os quatro tempos que compõem
      `Δ_qjk`, e é de lá que vem a procedência de `τ_emb`, `τ_des` e `v_cruzeiro`.
- [ ] **`tarefa:T12` e `tarefa:T20` ao menos em rascunho.** A formulação pode ser escrita antes de
      os dados ficarem prontos — o que **não** pode ser escrito antes é a coluna "valor base" da
      tabela de parâmetros. Se T12 e T20 não fecharem até 02/09, escreva a formulação com
      `[A CONFIRMAR]` nessa coluna e feche T21 assim mesmo; a tabela é atualizável, o cronograma
      não.
- [ ] **`relatorio/` com LaTeX ou Quarto compilando**, com `amsmath`. Todo bloco matemático deste
      guia foi escrito para ser colado sem adaptação.

---

## Insumos

| Insumo | Onde | O que dá |
| --- | --- | --- |
| Caminho 1 da revisão | `docs/01-revisao-literatura.md` §4 | a formulação P1 de partida |
| Decisão de recorte D5 | `docs/03-encontro-26-08.md` §D5 | a justificativa e as alternativas |
| Famílias clássicas | `docs/01-revisao-literatura.md` §1 | as formulações contra as quais se compara |
| Lacunas L1, L2, L5 | `docs/01-revisao-literatura.md` §3 | o argumento de originalidade |
| Parâmetros de eVTOL | `docs/guias/G05-tempos.md` §"Insumos" | `τ_emb`, `τ_des`, `v_cruzeiro`, com DOI |
| Filtro de captura | `docs/guias/G03-demanda-capturavel.md` (`decisao:D03`) | a procedência de `f_q` |
| Quatro matrizes de tempo | `outputs/matrizes_tempo.rds` (T13) | `t^acc`, `t^egr`, `t^voo`, `T^ter` |
| Demanda capturável | `outputs/od_capturavel.rds` (T12) | `f_q` |
| Candidatos | `outputs/candidatos.rds` (T20) | `J` |

---

## Passo a passo

### 1. A formulação P1, completa, em LaTeX

O que segue vai inteiro para a seção de modelagem do relatório. Está escrito para satisfazer, item
a item, a lista do §4.2 do enunciado.

#### 1.1 Conjuntos e índices

$$
\begin{aligned}
I &: \text{conjunto de macrozonas de demanda, indexadas por } o, d.\\
J &: \text{conjunto de sítios candidatos a vertiporto, indexados por } j, k.\\
Q &\subseteq I\times I: \text{conjunto de pares OD \textbf{elegíveis}, } q=(o,d),\ o\neq d.\\
P_q &\subseteq J\times J: \text{conjunto de \textbf{pares de vertiportos viáveis} para o par } q.
\end{aligned}
$$

$Q$ e $P_q$ **não são o produto cartesiano** — são o resultado de um pré-processamento explícito,
e é nele que está toda a tratabilidade do modelo:

$$
Q=\big\{(o,d)\in I\times I:\ o\neq d,\ f_{(o,d)}>0,\ \text{filtro de captura de }
\texttt{decisao:D03}\big\}
$$

$$
P_q=\Big\{(j,k)\in J\times J:\ j\neq k,\ \ t^{\text{acc}}_{oj}\le\bar t,\ \
t^{\text{egr}}_{kd}\le\bar t,\ \ \Delta_{qjk}\ge\theta\Big\},\qquad q=(o,d)
$$

**Por que os conjuntos são estes.** $I$ é macrozona e não zona OD porque $|Q|$ cresce com o
**quadrado** de $|I|$ e o número de colunas do modelo é $|Q|\cdot\overline{|P_q|}$ (ver
`G05-tempos.md` §5). $Q$ é dirigido: $(o,d)$ e $(d,o)$ são pares distintos, com fluxos $f$
distintos, porque a matriz OD é assimétrica e porque os tempos de acesso e de egresso também são.
$P_q$ depende de $q$ e não só de $(j,k)$ porque a viabilidade de um par de vertiportos é uma
propriedade **do par OD que ele serve**, não dos vertiportos.

**O que o filtro de $P_q$ realmente é.** Ele é a materialização, como estrutura de dados, das duas
restrições que **não** aparecem no modelo: "o acesso terrestre não pode ser longo demais" e "a
viagem por eVTOL precisa economizar tempo". Escrevê-las como restrições do MILP seria correto e
seria muito pior: o modelo teria colunas que existem só para serem zeradas. Colocá-las no
pré-processamento é a técnica de Wu & Zhang (2021), *Engineering* 7(4), DOI
`10.1016/j.eng.2020.11.007`, e é o que os autores chamam de pré-processamento em dois estágios.

Consequência que precisa estar dita no relatório e que se esquece na hora da sensibilidade:
**$\bar t$ e $\theta$ não são coeficientes do modelo, são parâmetros da geração do modelo.** Mudar
$\bar t$ não muda um número numa matriz — muda quais colunas existem. Cada valor de $\bar t$ é um
modelo diferente, reconstruído do zero.

#### 1.2 Parâmetros

$$
\begin{aligned}
f_q &: \text{fluxo do par } q,\ \text{em viagens/dia.}\\
T^{\text{ter}}_q &: \text{tempo terrestre porta a porta do par } q \text{ — o \textbf{modo concorrente}, em min.}\\
t^{\text{acc}}_{oj} &: \text{tempo terrestre de acesso da zona } o \text{ ao vertiporto } j,\ \text{em min.}\\
t^{\text{egr}}_{kd} &: \text{tempo terrestre de egresso do vertiporto } k \text{ à zona } d,\ \text{em min.}\\
t^{\text{voo}}_{jk} &: \text{tempo de voo eVTOL de } j \text{ a } k,\ \text{em min.}\\
\tau_{\text{emb}},\ \tau_{\text{des}} &: \text{tempos de processamento no vertiporto de origem e de destino, em min.}\\
\bar t &: \text{tempo máximo admitido de acesso e de egresso, em min.}\\
\theta &: \text{economia de tempo mínima para o par ser considerado servível, em min.}\\
p &: \text{número de vertiportos a implantar (cardinalidade), adimensional.}
\end{aligned}
$$

Dois parâmetros derivados, e são os que a função objetivo consome:

$$
T^{\text{uam}}_{qjk}=t^{\text{acc}}_{oj}+\tau_{\text{emb}}+t^{\text{voo}}_{jk}+\tau_{\text{des}}
+t^{\text{egr}}_{kd}
\qquad\text{[min]}
$$

$$
\boxed{\ \Delta_{qjk}=T^{\text{ter}}_{q}-T^{\text{uam}}_{qjk}\ }
\qquad\text{[min economizados por passageiro]}
$$

$\Delta$ é onde o modelo é **porta a porta**. Ele não compara trechos aéreos: compara a viagem
inteira, do ponto de origem ao ponto de destino, contra fazer a mesma viagem de carro. A
alternativa "não fazer nada" está dentro da função objetivo, e é o carro.

#### 1.3 Variáveis de decisão

$$
\begin{aligned}
y_j&\in\{0,1\} && \text{1 se o vertiporto } j \text{ é implantado, 0 caso contrário.}\\
w_{qjk}&\in[0,1] && \text{fração do fluxo do par } q \text{ roteada pelo par de vertiportos } (j,k).
\end{aligned}
$$

$y$ é a decisão estratégica — é a resposta que o trabalho entrega. $w$ é a decisão de roteamento
implicada, e existe para que o modelo saiba **qual** par de vertiportos serve cada par OD, já que
$\Delta_{qjk}$ depende dos dois. Sem $w$ não haveria como escrever "a economia deste par é a
economia da melhor rota disponível".

#### 1.4 O modelo P1

$$
\begin{aligned}
\max\quad & Z=\sum_{q\in Q}\ \sum_{(j,k)\in P_q} f_q\,\Delta_{qjk}\,w_{qjk}
&& \text{[pax}\cdot\text{min/dia]}\\[6pt]
\text{s.a.}\quad
& \sum_{(j,k)\in P_q} w_{qjk}\ \le\ 1 && \forall q\in Q && (\alpha_q)\\[2pt]
& w_{qjk}\ \le\ y_j && \forall q\in Q,\ \forall (j,k)\in P_q && (\mu^{\text{o}}_{qjk})\\[2pt]
& w_{qjk}\ \le\ y_k && \forall q\in Q,\ \forall (j,k)\in P_q && (\mu^{\text{d}}_{qjk})\\[2pt]
& \sum_{j\in J} y_j\ \le\ p && && (\pi)\\[2pt]
& w_{qjk}\ \ge\ 0,\qquad y_j\in\{0,1\}
\end{aligned}
$$

**A unidade da função objetivo é `pax·min/dia`** — minutos de viagem economizados por dia, somados
sobre todos os passageiros. Ela precisa aparecer explicitada no relatório: é o "benefício na
métrica própria do grupo, com unidade explicitada" do §6.3 do enunciado, e é o indicador que entra
no painel comparativo entre grupos.

**O critério que a FO representa.** Maximizar economia agregada de tempo é um critério
**utilitarista**: um minuto economizado vale o mesmo para qualquer passageiro, e o modelo prefere
servir muitos passageiros com economia média a poucos com economia enorme. Isso é uma escolha, não
uma neutralidade. Duas alternativas defensáveis e o motivo de não terem sido adotadas:

- **Maximizar viagens capturadas** ($\sum f_q w_{qjk}$, sem o $\Delta$) trata como equivalentes
  uma viagem que economiza 60 min e uma que economiza 11 — e a segunda, para um serviço premium,
  provavelmente nem é vendida. Perde-se a única informação que distingue um bom vertiporto de um
  vertiporto qualquer.
- **Maximizar excedente monetizado** ($\sum f_q\,\text{VoT}\cdot\Delta\,w$, menos custo) é
  superior em tese e vira necessário se a extensão de custo fixo endógeno for adotada (§9.3). Fora
  disso, ela introduz o valor do tempo — um parâmetro que exige uma decisão registrada, com
  responsável e defesa na arguição (é literalmente a pergunta 1 do §7 do `G00`) — sem mudar a
  solução ótima, já que multiplicar a FO por uma constante positiva não muda o `argmax`.
  **Introduzir um parâmetro discutível que não muda a resposta é custo puro.**

#### 1.5 Os multiplicadores duais, nomeados

| Dual | Da restrição | Unidade | Leitura econômica |
| --- | --- | --- | --- |
| $\alpha_q$ | $\sum_{(j,k)\in P_q} w_{qjk}\le 1$ | pax·min/dia por par | valor de servir o par $q$ — dá o **ranking de corredores prioritários** |
| $\mu^{\text{o}}_{qjk}$ | $w_{qjk}\le y_j$ | pax·min/dia | valor de ter o vertiporto de **origem** aberto, atribuído àquela rota |
| $\mu^{\text{d}}_{qjk}$ | $w_{qjk}\le y_k$ | pax·min/dia | idem, para o de **destino** |
| $\pi$ | $\sum_j y_j\le p$ | pax·min/dia por vertiporto | **economia marginal de tempo-passageiro por vertiporto adicional** — é a inclinação da curva de implantação |

Duas advertências que evitam um erro sério no G08:

**Dual só existe em LP.** Um MILP não tem dual: a leitura acima vale para a **relaxação linear**
(ou, com cuidado explícito, para o LP final do nó ótimo). Reportar "o dual do MILP" é erro
conceitual e é o tipo de coisa que a arguição pega. O que se reporta é o dual da relaxação, e a
diferença entre ele e a inclinação empírica $Z^*(p)-Z^*(p-1)$ do MILP **é ela mesma um resultado**:
mede o quanto a integralidade custa.

**Convenção de sinal.** Em um problema de maximização com restrição $\le$, o dual é não-negativo
na convenção usual, mas cada solver reporta com a sua. Confira uma vez, num caso de sinal
conhecido ($\pi$ tem de ser $\ge 0$: mais vertiportos nunca pioram), e **registre a convenção
verificada** em vez de assumir.

$\mu^{\text{o}}$ e $\mu^{\text{d}}$ são numerosos (dois por coluna) e individualmente pouco
informativos. O agregado é que interessa: $\sum_{q,k}\mu^{\text{o}}_{qjk}+\sum_{q,k}
\mu^{\text{d}}_{qkj}$ é o valor total imputado ao vertiporto $j$ na solução da relaxação, e é a
resposta quantitativa a "por que este sítio e não aquele".

---

### 2. A tabela de parâmetros com unidade e procedência

Esta tabela é exigência textual do §4.2 ("parâmetros com unidade e procedência de cada valor") e
vai para o relatório como está. `[A DEFINIR]` significa que falta uma decisão registrada;
`[A CONFIRMAR]` significa que falta um dado com fonte. **Nenhum dos dois pode virar número sem
passar pelo grafo** — é a regra 3 do `CLAUDE.md`.

| Símbolo | Significado | Unidade | Valor base | Procedência | Faixa da sensibilidade |
| --- | --- | --- | --- | --- | --- |
| $f_q$ | fluxo diário do par OD $q$ | viagens/dia | medido em T12 | Pesquisa OD Metrô-SP 2017, expandida por `FE_viagem` e calibrada contra a OD 2023; filtro de captura de `decisao:D03` | não é eixo próprio — a sensibilidade correspondente são as quatro camadas de D03 |
| $T^{\text{ter}}_q$ | tempo terrestre porta a porta | min | medido em T13 | OSRM local sobre extrato Geofabrik do Sudeste (perfil `car.lua`), com fator de congestionamento calibrado contra a duração declarada da OD (G05 §3) | `fator_congestionamento` $\in\{1,\ \text{calibrado}\}$ |
| $t^{\text{acc}}_{oj}$ | acesso zona → vertiporto | min | medido em T13 | OSRM, mesma rede | idem |
| $t^{\text{egr}}_{kd}$ | egresso vertiporto → zona | min | medido em T13 | OSRM, calculado separadamente — **não** é a transposta do acesso (G05 §0) | idem |
| $t^{\text{voo}}_{jk}$ | tempo de voo eVTOL | min | derivado | distância euclidiana em EPSG:31983 ÷ $v_{\text{cruz}}$; a linha reta não é a rota real (HELICONTROL) — limitação declarada | via $v_{\text{cruz}}$ |
| $v_{\text{cruz}}$ | velocidade média de cruzeiro | km/h | **193** (120 mph) | Rimjha, Hotle, Trani, Hinze, Smith & Dollyhigh (2021), *AIAA Aviation Forum*, DOI `10.2514/6.2021-3209` | 160 / 193 / 240 `[A DEFINIR]` |
| $\tau_{\text{emb}}$ | processamento no vertiporto de origem | min | **5** | Rimjha et al. (2021), AIAA, mesma referência | 3 / 5 / 10 |
| $\tau_{\text{des}}$ | processamento no vertiporto de destino | min | **5** | idem | 3 / 5 / 10 |
| $\bar t$ | acesso e egresso máximos admitidos | min | **15** `[A DEFINIR — abrir decisão]` | escolha do grupo; ordem de grandeza compatível com os limiares de tempo/distância de Volakakis & Mahmassani (2025), *Infrastructures* 10(9) 242, DOI `10.3390/infrastructures10090242` | **10 / 15 / 20 / 30** |
| $\theta$ | economia mínima para servir o par | min | **10** `[A DEFINIR — abrir decisão]` | escolha do grupo; a regra determinística de utilidade de Wu & Zhang (2021) é o precedente da ideia, não do valor | **0 / 10 / 20 / 30** |
| $p$ | vertiportos a implantar | vertiportos | eixo da curva | escolha do grupo; Volakakis & Mahmassani (2025) reportam 5–12 para >95% de cobertura em Chicago — **ordem de grandeza alheia, não alvo** | **1 … 25** |
| $\Delta_{qjk}$ | economia porta a porta | min | derivado | $T^{\text{ter}}_q-T^{\text{uam}}_{qjk}$ | — |
| $C_j$ | capacidade do vertiporto $j$ (ext. §9.1) | pax/dia | `[A CONFIRMAR]` | sem fonte brasileira publicada — **abrir pendência antes de usar** | 2 a 4 valores |
| $m$ | throughput mínimo (ext. §9.2) | pax/dia | `[A DEFINIR]` | escolha do grupo; o mecanismo é o "limiar mínimo de demanda para abrir" de Volakakis & Mahmassani (2024), *Infrastructures* 9(12) 239, DOI `10.3390/infrastructures9120239` | 3 valores |
| $f^{\text{fix}}_j$ | custo fixo de implantação (ext. §9.3) | R$ | `[A CONFIRMAR]` | Ribeiro et al. (2023), *SCS* 98, DOI `10.1016/j.scs.2023.104797`, trata retrofit de heliponto vs. greenfield — **texto integral não lido, `pendencia:P02`** | retrofit vs. greenfield |
| VoT | valor do tempo (ext. §9.3) | R$/h | `[A DEFINIR]` | decisão do grupo, com responsável nomeado — é a **pergunta 1** do §7 do `G00` | 3 cenários |

Duas observações sobre a tabela, ambas para o relatório:

**Os parâmetros operacionais de eVTOL são norte-americanos.** $\tau_{\text{emb}}$,
$\tau_{\text{des}}$ e $v_{\text{cruz}}$ vêm de Rimjha et al. (2021), estudo de Dallas–Fort Worth.
Não existe parâmetro brasileiro publicado equivalente. Transplantá-los é a escolha certa — a
alternativa é inventar — mas é **limitação declarada**, não medição. O mesmo vale para os 5–12
vertiportos de Chicago: é ordem de grandeza para calibrar expectativa, jamais alvo a perseguir.

**$\bar t$ e $\theta$ não têm fonte, e isso é correto.** Eles são a proposta de valor do serviço,
que é uma hipótese de negócio, não um fato mensurável. Por isso são os dois eixos principais da
análise de sensibilidade. Um trabalho que apresentasse $\bar t=15$ com uma citação estaria
fabricando autoridade; um que o apresenta como decisão registrada e roda 10/15/20/30 está fazendo
Pesquisa Operacional.

---

### 3. A razão de existir de cada restrição

Uma frase por restrição, como o §4.2 exige. As frases abaixo vão para o relatório literalmente.

**(1) $\sum_{(j,k)\in P_q} w_{qjk}\le 1$ — restrição de fluxo do par.**
Cada par OD só pode ser servido uma vez, e por um único par de vertiportos: sem ela, o modelo
somaria a economia de todas as rotas viáveis do mesmo par e contaria o mesmo passageiro várias
vezes. O sinal $\le$ e não $=$ é o que torna a demanda **não obrigatória** — um par pode
simplesmente não ser servido, que é o caso normal num serviço premium e é o que distingue este
modelo de uma $p$-mediana.

**(2) $w_{qjk}\le y_j$ — vinculação ao vertiporto de origem.**
Não se pode embarcar num vertiporto que não existe.

**(3) $w_{qjk}\le y_k$ — vinculação ao vertiporto de destino.**
Nem desembarcar.

**(4) $\sum_j y_j\le p$ — cardinalidade.**
Representa o orçamento de implantação em sua forma mais simples — quantos vertiportos cabem — e é
a restrição cujo dual $\pi$ é a inclinação da curva de implantação, que é o objeto central do
trabalho. O sinal $\le$ e não $=$ permite ao modelo abrir menos que $p$ quando abrir mais não
ajuda; com $=$, o modelo seria forçado a colocar vertiportos inúteis em qualquer lugar e
$Z^*(p)$ deixaria de ser monotônica por construção — um artefato de formulação que se confundiria
com resultado.

#### 3.1 Por que são DUAS restrições, e não uma

Este é o parágrafo mais importante do guia. É o mecanismo de bilateralidade, é o que distingue o
modelo de um MCLP comum, e é a lacuna L1 da revisão de literatura transformada em duas linhas de
álgebra.

Num MCLP clássico (Church & ReVelle, 1974, DOI `10.1111/j.1435-5597.1974.tb00902.x`) a cobertura
é **unilateral**: $z_i\le\sum_{j\in N_i}y_j$ — a zona $i$ está coberta se **algum** vertiporto
estiver perto dela. Uma restrição, e um somatório com "ou" embutido.

Aqui a cobertura é **bilateral e conjuntiva**. A viagem por eVTOL não é um serviço prestado num
ponto: é um serviço prestado entre dois pontos, e ela não existe pela metade. A relação lógica não
é "$j$ **ou** $k$", é "$j$ **e** $k$", e a forma linear canônica de escrever
$w\le\min(y_j,y_k)$ é escrever as duas desigualdades separadamente:

$$
w_{qjk}\le\min\{y_j,\,y_k\}
\quad\Longleftrightarrow\quad
\big(w_{qjk}\le y_j\big)\ \wedge\ \big(w_{qjk}\le y_k\big)
$$

Três consequências, e cada uma vale um parágrafo do relatório:

**Fundir as duas em uma perde a bilateralidade.** A tentação é escrever
$w_{qjk}\le\tfrac12(y_j+y_k)$, que é uma única restrição e parece equivalente. Não é: com
$y_j=1,\ y_k=0$ ela permite $w=0{,}5$, isto é, permite **meia viagem partindo de um vertiporto que
existe e chegando a um que não existe**. Ela é uma relaxação válida da conjunção — é implicada
pelas duas, e por isso serve como restrição agregada (§5) —, mas não a implementa.

**É o mesmo mecanismo do FRLM, especializado.** Kuby & Lim (2005), *Socio-Economic Planning
Sciences* 39(2), DOI `10.1016/j.seps.2004.03.001`, formalizam "o serviço só existe se um
**conjunto** de instalações estiver aberto simultaneamente" com uma variável $v_h$ por combinação
$h$ e a restrição $v_h\le y_k$ para todo $k\in h$. Nosso caso é o FRLM com $|h|=2$: cada par
$(j,k)\in P_q$ **é** uma combinação de tamanho dois. Como toda combinação tem exatamente dois
elementos, a variável intermediária $v_h$ é dispensável e $w_{qjk}$ acumula os dois papéis —
"a combinação está disponível" e "o fluxo usa esta combinação". O modelo fica menor sem perder o
mecanismo. **Dizer isso no relatório é o que ancora a formulação na literatura clássica em vez de
fazê-la parecer improvisada.**

**É a origem de tudo o que vem depois.** As duas restrições são a razão de a FO deixar de ser
submodular (§8), de a relaxação linear deixar de ser quase-integral (§5), e de $Z^*(1)=0$. Massa
crítica de rede, neste modelo, não é uma narrativa: são estas duas linhas.

---

### 4. Por que $w$ é contínua e não binária

A pergunta certa não é "posso relaxar $w$?" e sim "**por que relaxar $w$ não custa nada?**". A
resposta é um teorema pequeno, e ele precisa ser argumentado — não assumido.

> **Proposição.** Fixe $y\in\{0,1\}^{|J|}$. O subproblema resultante em $w$ separa-se por par
> $q$ e admite solução ótima com $w\in\{0,1\}$. Em consequência,
> $$
> Z(y)=\sum_{q\in Q}\ \max\Big\{f_q\Delta_{qjk}\ :\ (j,k)\in P_q,\ y_j=y_k=1\Big\}^{+}
> $$
> com o máximo sobre conjunto vazio valendo $0$.

**Demonstração.** Com $y$ fixo, as restrições (2) e (3) tornam-se cotas superiores constantes:
$w_{qjk}\le\min(y_j,y_k)\in\{0,1\}$. As colunas com $\min(y_j,y_k)=0$ ficam fixadas em zero e
podem ser removidas. Restam, para cada $q$, as colunas de
$A_q(y)=\{(j,k)\in P_q: y_j=y_k=1\}$, sujeitas apenas a $w\ge 0$ e $\sum_{A_q(y)}w_{qjk}\le 1$ —
a única restrição que as acopla, e ela envolve **apenas** colunas do mesmo $q$. O problema
portanto se decompõe em $|Q|$ problemas independentes, cada um deles a maximização de uma função
linear sobre o simplex $\{w\ge 0,\ \sum w\le 1\}$. Todo problema linear sobre um politopo não
vazio e limitado atinge o ótimo num vértice, e os vértices desse simplex são a origem e os vetores
canônicos $e_{(j,k)}$. Logo existe ótimo com $w$ inteiro: $w=e_{(j,k)}$ para o
$(j,k)$ de maior coeficiente, se este for positivo, e $w=0$ caso contrário. $\blacksquare$

Quatro consequências práticas:

**Declarar $w$ binária não compra nada e custa muito.** Não compra porque a solução ótima já é
inteira. Custa porque transformaria de $10^4$ a $10^5$ colunas contínuas em variáveis inteiras,
e o *branch-and-bound* passaria a ter de decidir sobre elas. O modelo passa de "40 a 60 binárias,
trivial" para "intratável", sem que uma única solução nova apareça. **Este é o parágrafo que
justifica a linha `type = "continuous"` no código do G07** — e é exatamente o tipo de escolha que
o critério de excelência espera que qualquer integrante saiba defender.

**O que a proposição garante e o que não garante.** Ela garante integralidade de $w$ **dado $y$
inteiro**. Não garante nada sobre a relaxação linear completa, onde $y$ também é fracionário — e é
justamente lá que a bilateralidade produz $y_j=y_k=0{,}5$ e o *gap* de integralidade aparece
(§5). Confundir as duas coisas é o erro clássico: a integralidade natural do MCLP de ReVelle–Swain
é uma propriedade da matriz de restrições inteira, não do subproblema condicionado.

**A proposição vale para qualquer sinal de $\Delta$.** O argumento do vértice não usa
$\Delta\ge 0$; se todos os coeficientes de um $q$ fossem negativos, o vértice ótimo seria a
origem. O que $\theta\ge 0$ garante não é integralidade — é **significado**: só entram no modelo
rotas que de fato economizam tempo.

**A proposição é a ferramenta de trabalho do G07.** Ela dá uma função de avaliação exata em uma
linha: para qualquer conjunto de vertiportos abertos, o valor ótimo é um `max` por grupo sobre a
tabela de colunas. Sem chamar o solver. É com ela que se confere a instância-brinquedo, que se
avalia a solução do baseline unilateral com a régua bilateral, e que se constrói um guloso para
dar cota inferior inicial ao B&B.

**Onde a proposição deixa de valer, e isso importa.** A demonstração usa que a única restrição a
acoplar colunas está **dentro** de um mesmo $q$. As extensões de capacidade (§9.1) e de massa
crítica (§9.2) introduzem restrições que somam sobre **todos** os $q$ para um mesmo vertiporto — e
aí o problema deixa de se decompor. Com capacidade, $w$ fracionário passa a ser genuinamente ótimo
(o fluxo de um par se divide entre dois pares de vertiportos porque um deles saturou), e isso é
legítimo num modelo de dia típico: $w=0{,}3$ lê-se "30% das viagens desse par usam essa rota".
Se a extensão escolhida for uma dessas, **esse parágrafo muda** e a mudança precisa aparecer no
relatório.

---

### 5. Formulação desagregada vs. agregada

As duas formulações abaixo têm o **mesmo conjunto de soluções inteiras** e relaxações lineares
radicalmente diferentes. Comparar as duas é a primeira das quatro análises exigidas (§4.4), e é o
material do `tarefa:T30` / `G08`.

**Desagregada** — uma restrição por coluna e por lado:

$$
w_{qjk}\le y_j,\qquad w_{qjk}\le y_k
\qquad\forall q\in Q,\ \forall (j,k)\in P_q
$$

**Agregada** — uma restrição por vertiporto e por lado, com o *big-M* natural $|Q|$:

$$
\sum_{q\in Q}\ \sum_{k:(j,k)\in P_q} w_{qjk}\ \le\ |Q|\,y_j,
\qquad
\sum_{q\in Q}\ \sum_{j:(j,k)\in P_q} w_{qjk}\ \le\ |Q|\,y_k
\qquad\forall j,k \in J
$$

**Contagem.** Chame $N=\sum_{q}|P_q|$ o número de colunas $w$.

| | Restrições de vinculação | Ordem de grandeza esperada |
| --- | --- | --- |
| Desagregada | $2N$ | $10^5$ a $4\times10^5$ |
| Agregada | $2|J|$ | $80$ a $120$ |

A agregada é **três ordens de grandeza menor** no número de linhas. É por isso que ela existe.

**Por que a desagregada é muito mais forte.** Na relaxação linear da agregada, a variável $y_j$
só precisa ser grande o bastante para cobrir o **total** de fluxo que passa por $j$, dividido por
$|Q|$. Como cada $w\le 1$ e tipicamente só uma fração pequena dos pares usa $j$, basta
$y_j\approx(\text{fluxo em } j)/|Q|$, que é minúsculo. O LP então "abre" todos os vertiportos com
pesos infinitesimais, serve tudo, e a restrição $\sum_j y_j\le p$ mal morde. A cota superior fica
muito acima do ótimo inteiro, e o *branch-and-bound* passa a explorar uma árvore enorme.

Na desagregada, cada coluna individualmente exige $y_j\ge w_{qjk}$: para rotear metade do fluxo de
um par é preciso "meio vertiporto" **naquele par**, e o custo não se dilui num agregado. A cota é
muito mais apertada.

Formalmente: toda solução viável da relaxação desagregada é viável na agregada (somar as
desigualdades $w_{qjk}\le y_j$ sobre $q,k$ dá $\sum w\le n_j\,y_j\le|Q|y_j$, com $n_j\le|Q|$),
logo $Z_{LP}^{\text{desagr}}\le Z_{LP}^{\text{agr}}$ — e para um problema de máximo, cota menor é
cota melhor. A inclusão é estrita na prática, e medir *quão* estrita é o resultado a reportar.

**A restrição intermediária.** $\sum_{(j,k)\in P_q}w_{qjk}\le\tfrac12(y_j+y_k)$, mencionada na
revisão de literatura, fica entre as duas: é por par OD (não agrega sobre $Q$) mas mistura os dois
lados. Vale rodar como terceiro ponto da comparação, se o tempo permitir; não vale como
formulação principal, pelo motivo do §3.1.

**O que reportar em T30.** Para cada uma das formulações: $Z_{LP}$, $Z_{IP}$, o *gap* de
integralidade $(Z_{LP}-Z_{IP})/Z_{IP}$, o número de linhas e colunas, o número de nós de B&B e o
tempo. E a discussão que dá a nota: **por que a relaxação do MCLP puro é quase-integral e por que
a bilateralidade quebra essa propriedade.** A intuição é direta e cabe em um exemplo: com três
candidatos $A,B,C$, três pares OD servidos respectivamente por $(A,B)$, $(B,C)$ e $(C,A)$, e
$p=1$, o ótimo inteiro é **zero** — um vertiporto sozinho não serve par nenhum. A relaxação, no
entanto, faz $y_A=y_B=y_C=\tfrac13$, $w=\tfrac13$ em cada par, e captura um terço de cada um: um
valor estritamente positivo com orçamento que, inteiro, não compra nada. Esse ciclo ímpar é a
assinatura combinatória da bilateralidade, e não tem análogo no MCLP unilateral. (O G07 traz essa
instância como teste automatizado.)

---

### 6. Justificativa da escolha da família

O §4.2 exige justificativa da escolha de cada elemento; a escolha da **família** é a primeira
delas e a de maior consequência. As alternativas abaixo já estão registradas em `decisao:D05`;
aqui elas ganham o detalhe técnico que o relatório precisa.

#### 6.1 $p$-mediana — Hakimi (1964) / ReVelle & Swain (1970)

DOI `10.1287/opre.12.3.450` e `10.1111/j.1538-4632.1970.tb00142.x`.

Minimiza custo médio de acesso ponderado pela demanda, com $\sum_j x_{ij}=1$ para toda zona.
**Rejeitada por três motivos independentes**, e qualquer um bastaria: (i) a unidade de análise é a
zona isolada, não o par OD — não existe rede, e o problema de localizar vertiportos é um problema
de rede; (ii) a igualdade $\sum_j x_{ij}=1$ **obriga** a servir 100% da demanda, o que é falso
para um serviço premium cuja fatia capturável a própria literatura estima em fração de por cento
(Wu & Zhang 2021: 532 viagens em 266.734 candidatas); (iii) minimiza acesso terrestre, quando o
benefício do eVTOL está no tempo **total** porta a porta.

#### 6.2 MCLP clássico — Church & ReVelle (1974)

DOI `10.1111/j.1435-5597.1974.tb00902.x`.

É a família mais próxima e a base direta de P1: maximiza demanda coberta dado orçamento $p$, o
dual $\pi$ é a derivada da curva de implantação, e a demanda não coberta é permitida. **Rejeitado
na forma pura por um motivo só, e decisivo:** a cobertura é unilateral. $z_i\le\sum_{j\in N_i}y_j$
diz que basta **um** vertiporto perto da origem para a zona estar coberta. Aplicado a eVTOL, isso
afirma que uma viagem existe se houver de onde decolar — sem perguntar onde ela pousa. É o erro
que a literatura aplicada de vertiportos comete de forma sistemática (lacuna L1), e é o que P1
corrige mantendo todo o resto do MCLP intacto.

#### 6.3 $p$-hub mediana — O'Kelly (1987)

DOI `10.1016/S0377-2217(87)80007-3`; linearização em Campbell (1994), DOI
`10.1016/0377-2217(94)90318-2`.

É a **única família clássica que modela interdependência locacional**: o valor de abrir $k$ depende
de quais outros hubs existem. Conceitualmente é a mais próxima do que queremos, e a formulação de
alocação múltipla de Campbell tem exatamente o par de restrições $X_{ijkm}\le y_k$,
$X_{ijkm}\le y_m$ que inspira as nossas (2) e (3). **Rejeitada assim mesmo, por dois motivos:**

- **O desconto inter-hub $\alpha<1$ não existe em eVTOL.** Em hub location clássico, $\alpha$
  representa economia de escala na perna entre hubs: consolidar carga num avião maior barateia o
  km transportado. Em eVTOL o custo por assento-km é **maior**, não menor — a aeronave é pequena,
  o custo de energia e de manutenção por assento é alto, e não há consolidação. Manter $\alpha$
  seria importar uma hipótese econômica falsa para o caso. **O ganho real do eVTOL é em tempo, não
  em custo**, e é por isso que P1 é formulado em tempo generalizado e não em custo de transporte.
- **A demanda é inelástica e integralmente roteada.** $\sum_{k}Z_{ik}=1$ obriga toda a demanda a
  passar pela rede de hubs. Para UAM isso é falso por construção: o usuário só migra se houver
  economia, e a maior parte nunca migra.

Some-se a alocação única (todos da zona $i$ pelo mesmo hub) e a formulação quadrática original, e
o custo de adaptação supera o de escrever P1 diretamente.

#### 6.4 FRLM — Kuby & Lim (2005)

DOI `10.1016/j.seps.2004.03.001`.

**Não é uma alternativa rejeitada: é a inspiração aceita.** A restrição $v_h\le y_k$ para todo
$k\in h$ é o mecanismo canônico de **massa crítica em forma linear** — "o serviço só existe se
todo um conjunto de instalações estiver aberto". P1 é essa ideia especializada para conjuntos de
tamanho dois, como o §3.1 detalha. O que **não** se transporta do FRLM é o objeto "fluxo": lá o
fluxo é um caminho pré-definido na rede rodoviária e as estações interceptam esse caminho; aqui o
"caminho" é o próprio par OD, e o acesso e o egresso terrestres — a parte cara — precisam estar
explícitos, o que o FRLM não faz.

#### 6.5 Hub location com logit endógeno — Rath & Chow (2022); Hagspihl et al. (2025)

DOI `10.1016/j.jairtraman.2022.102294` e `10.1007/s00291-024-00801-y`.

**Tecnicamente superior a P1** e é honesto dizer isso no relatório. A demanda deixa de ser um
limiar determinístico ($\Delta\ge\theta$) e vira probabilidade de escolha, e o truque de
linearização — pré-calcular $P^{\text{uam}}_{qjk}$ fora do modelo, já que $(j,k)$ é enumerado —
mantém tudo como MILP puro. O custo de implementação é baixo.

**Rejeitada por um motivo que não é técnico:** os coeficientes $\beta_t,\beta_c$ não existem para
o Brasil. Transplantar os de Munique ou da Califórnia introduziria no modelo um parâmetro sem
procedência brasileira — que é precisamente o primeiro item da lista do que compromete a nota. O
caminho registrado em D5 e D03 é mantê-la como extensão da S4 e, melhor, como **cenário de
sensibilidade**: rodar os $\beta$ como faixa transforma o risco numa das quatro análises exigidas.

#### 6.6 Meta-heurística (GA, NSGA-III, VNS)

Jiang et al. (2025), DOI `10.1016/j.tra.2024.104353`; Chen et al. (2022), DOI
`10.1287/ijoc.2021.1109`; Volakakis & Mahmassani (2024), DOI `10.3390/infrastructures9120239`.

Resolveria instâncias maiores. **Rejeitada porque destrói exatamente as quatro análises que a
disciplina exige**: sem LP não há relaxação para comparar, sem dual não há preço-sombra, sem
otimalidade garantida a curva de implantação vira uma sequência de heurísticas cuja forma pode ser
artefato do algoritmo. É o caso em que a solução mais poderosa é a errada para o problema
avaliado.

#### 6.7 Síntese, para o relatório

| Família | Porta a porta | Interdependência | Massa crítica | Demanda elástica | Dual e relaxação |
| --- | --- | --- | --- | --- | --- |
| $p$-mediana | não | não | não | não | sim |
| MCLP clássico | não | não | não | parcial (cobre ou não) | sim |
| $p$-hub mediana | parcial | **sim** | parcial | não | sim |
| FRLM | não | **sim** | **sim** | não | sim |
| Hub + logit | **sim** | **sim** | parcial | **sim** | sim |
| Meta-heurística | — | — | — | — | **não** |
| **P1 (nosso)** | **sim** | **sim** | **sim** | limiar determinístico | **sim** |

A única coluna em que P1 perde para a fronteira é a de demanda elástica, e o motivo da perda está
registrado com nome e alternativas. Esse é o formato de uma escolha defensável.

---

### 7. A lacuna que a formulação explora

Três frases, e são a contribuição declarada do trabalho. Correspondem a L1, L2 e L5 da revisão.

**L1 — cobertura unilateral.** Praticamente toda a literatura aplicada de vertiportos que usa
modelos **lineares** trata cobertura como unilateral: a zona está coberta se houver um vertiporto
próximo. Mas a viagem eVTOL só existe se houver vertiporto na origem **e** no destino.

**L2 — massa crítica declarada, quase nunca modelada.** Os *surveys* apontam massa crítica de rede
como fator crítico, e na formulação matemática ela desaparece, ou reaparece degradada como limiar
mínimo de demanda por instalação. O mecanismo estrutural — o benefício é **superaditivo** nos
vertiportos abertos — existe em forma canônica desde Kuby & Lim (2005) e não foi transposto para
vertiportos.

**L5 — a curva de implantação nunca é tratada como objeto teórico.** Ela aparece como sequência de
cenários (Lim & Hwang 2019, 18 cenários por clusterização, sem ótimo garantido) ou como resultado
empírico ("5 a 12 vertiportos ⇒ >95% de cobertura"), nunca ligada ao dual da restrição de
cardinalidade — que é a leitura correta e a que TRA-48 exige.

**A síntese, que é a frase de abertura da seção de contribuição do relatório:**

> Os trabalhos que capturam a interdependência corretamente ou assumem demanda inelástica, ou caem
> em meta-heurística (GA, NSGA-III, VNS) e perdem dual e relaxação. **Ninguém entrega um MILP
> compacto, exato, com cobertura bilateral e leitura de duais.**

Escreva essa afirmação com a ressalva que ela merece: ela se apoia numa revisão de 18 trabalhos, e
quatro deles tiveram apenas o metadado confirmado (`pendencia:P02`). A forma honesta é
*"na literatura que revisamos, e ressalvados os quatro trabalhos cujo texto integral não obtivemos,
não encontramos ..."*. Custa uma linha e sobrevive à arguição.

---

### 8. A previsão teórica da curva em S

Este é o resultado central do trabalho, e neste guia ele é **previsão**, não achado. A distinção é
metodológica e precisa sobreviver até o relatório.

#### 8.1 A função de valor

Defina, para um conjunto $S\subseteq J$ de vertiportos abertos, o valor ótimo condicionado — que
pela Proposição do §4 tem forma fechada:

$$
Z(S)=\sum_{q\in Q}\ \max\Big\{f_q\Delta_{qjk}:\ (j,k)\in P_q,\ j\in S,\ k\in S\Big\}^{+}
\qquad\text{e}\qquad
Z^*(p)=\max_{|S|\le p} Z(S)
$$

#### 8.2 O caso unilateral: submodularidade

Num MCLP unilateral, a função de cobertura $Z^{\text{uni}}(S)=\sum_i h_i\,\mathbb{1}[N_i\cap
S\neq\emptyset]$ é uma **função de cobertura ponderada**, e funções de cobertura ponderadas são
submodulares e monótonas. A leitura da submodularidade é retornos decrescentes: o ganho marginal
de um vertiporto adicional não cresce à medida que a rede cresce. Em particular
$Z^{\text{uni}*}(1)>0$ — o primeiro vertiporto é o que mais rende, porque pega sozinho a zona de
maior demanda.

**Uma precisão que vale fazer**, porque a formulação preguiçosa aparece na revisão de literatura e
é falsa como teorema: submodularidade **não implica**, por si só, que a curva ótima $Z^*(p)$ seja
exatamente côncava em $p$. O que ela sustenta é a expectativa de retornos decrescentes, que é o
que se vai medir. Escrever "submodular $\Rightarrow$ côncava" como se fosse teorema é o tipo de
frase que a arguição desmonta com uma pergunta.

#### 8.3 O caso bilateral: a submodularidade quebra

> **Proposição.** $Z(\cdot)$ não é submodular.

**Demonstração.** Submodularidade exige $Z(S\cup\{k\})-Z(S)\ \ge\ Z(T\cup\{k\})-Z(T)$ para todo
$S\subseteq T$. Tome $S=\emptyset$, $T=\{j\}$ e um $k$ tal que $(j,k)\in P_q$ para algum $q$ com
$f_q\Delta_{qjk}>0$. Então $Z(\{k\})-Z(\emptyset)=0-0=0$, porque um único vertiporto não completa
par nenhum. E $Z(\{j,k\})-Z(\{j\})\ \ge\ f_q\Delta_{qjk}>0$. O ganho marginal de $k$ **cresce**
quando o conjunto cresce, que é o oposto de retornos decrescentes. $\blacksquare$

O que se tem no início é **superaditividade**, e é o nome técnico de massa crítica de rede.

#### 8.4 A previsão

Três afirmações, com estatutos diferentes, e é essencial não misturá-los no relatório:

1. **$Z^*(0)=Z^*(1)=0$.** Isto é **teorema**, e trivial: com um só vertiporto aberto, todo par
   $(j,k)$ com $j\ne k$ tem um dos lados fechado, logo $A_q(y)=\emptyset$ para todo $q$.
2. **A curva começa convexa.** As primeiras diferenças são $Z^*(1)-Z^*(0)=0$ e
   $Z^*(2)-Z^*(1)=Z^*(2)\ge 0$, tipicamente $>0$. A diferença **não decresce** no primeiro passo,
   o que é impossível numa curva côncava com $Z^*(1)>0$. Isto é consequência direta de (1).
3. **A curva termina côncava.** $Z^*(p)$ é não decrescente e limitada superiormente por
   $\overline Z=\sum_q\max_{(j,k)\in P_q}f_q\Delta_{qjk}$ (servir todo par elegível pela sua
   melhor rota), valor atingido quando $p=|J|$. Uma sequência monótona e limitada tem de achatar.

Convexa no começo e achatada no fim é a forma em **S**. Mas note o que continua sendo empírico e
não se deduz de nada acima: **onde** está a inflexão, **quão** abrupta ela é, e se a região convexa
tem mais de um passo. Essas três perguntas é que a curva de implantação responde, e são elas que
sustentam a recomendação final do §4.4 do enunciado — que com curva em S tem **duas** partes: um
$p$ **mínimo**, abaixo do qual a rede não vale nada, e um $p$ de **saturação**, acima do qual não
compensa. Nenhum modelo unilateral produz a primeira metade da resposta.

#### 8.5 O compromisso metodológico

**Se o S não aparecer, isso é achado, não fracasso.** Registre esta frase agora, antes de rodar, e
mantenha-a. Hipóteses plausíveis para um S ausente, todas verificáveis: a demanda de SP está
concentrada em poucos corredores e dois vertiportos já capturam quase tudo (a região convexa tem
um passo só e some no gráfico); $\bar t$ está folgado a ponto de quase todo candidato servir quase
toda zona; ou os candidatos são geograficamente redundantes. Cada uma dessas explicações é uma
seção de discussão melhor do que a confirmação da previsão teria sido, e "mostra o que não
funcionou, e por quê" é critério explícito de excelência do enunciado.

O que **não** se faz: ajustar $\bar t$ ou $\theta$ até o S aparecer. Isso é escolher o parâmetro
pela conclusão, e é detectável no histórico de experimentos — que é público no site.

---

### 9. As extensões — escolher UMA

O plano é explícito: **uma extensão, não duas**. A escolha é decisão registrada, com alternativas
descartadas. Cada uma abaixo vem com a formulação pronta e com o que ela custa.

#### 9.1 Capacidade de FATO

$$
\sum_{q\in Q}\ \sum_{k\in J:\,(j,k)\in P_q} f_q\,w_{qjk}
\ +\ \sum_{q\in Q}\ \sum_{k\in J:\,(k,j)\in P_q} f_q\,w_{qkj}
\ \le\ C_j\,y_j
\qquad\forall j\in J\qquad(\gamma_j)
$$

**Razão de existir:** um vertiporto tem um número finito de FATOs e de posições de embarque; sem
esta restrição o modelo concentra a rede inteira em dois sítios, o que é fisicamente impossível e
visivelmente errado no mapa.

Os dois somatórios contam o vertiporto $j$ como **origem** (primeiro termo) e como **destino**
(segundo), porque $C_j$ limita movimentos totais, não movimentos de partida. Note o $y_j$ do lado
direito: ele faz a restrição valer como capacidade quando o vertiporto existe e como
"fluxo zero" quando não existe — dispensando as restrições (2) e (3)? **Não dispensa.** Ela é uma
forma agregada e, sozinha, sofre da fraqueza de relaxação do §5. Mantenha as duas.

**Prós:** $\gamma_j$ é o dual mais limpo do modelo — preço-sombra de capacidade, em pax·min/dia por
pax/dia de FATO adicional, que é a justificativa econômica direta de um FATO extra. É o que o
enunciado pede como "limitações operacionais da infraestrutura" (§4.3).
**Contras:** exige $C_j$, e **não há fonte brasileira publicada** para capacidade de vertiporto.
Antes de adotar, abra pendência. Além disso, quebra a Proposição do §4 (ver §4, último parágrafo)
— o que não é defeito, mas muda o texto do relatório.

#### 9.2 Massa crítica por vertiporto

$$
\sum_{q}\sum_{k:(j,k)\in P_q} f_q\,w_{qjk}
\ +\ \sum_{q}\sum_{k:(k,j)\in P_q} f_q\,w_{qkj}
\ \ge\ m\,y_j
\qquad\forall j\in J
$$

**Razão de existir:** um vertiporto abaixo de um throughput mínimo não é operável — não paga
tripulação, manutenção nem controle. A restrição impede o modelo de abrir sítios simbólicos.

É o mecanismo que Volakakis & Mahmassani (2024) usam como "limiar mínimo de demanda para abrir".
**Prós:** é a extensão mais alinhada ao tema do trabalho — massa crítica no título, massa crítica
na formulação, em dois níveis (a bilateralidade dá a massa crítica *de rede*; esta dá a massa
crítica *de sítio*). **Contras:** o dual é menos interpretável que $\gamma_j$; e cuidado com a
armadilha de modelagem — se $m$ for alto demais o modelo simplesmente fecha vertiportos e
$Z^*(p)$ satura antes, o que é comportamento correto mas se parece com bug.

#### 9.3 Custo fixo endógeno

Troca-se a restrição de cardinalidade por um termo na FO, e a FO passa a ser monetária:

$$
\max\quad \sum_{q\in Q}\sum_{(j,k)\in P_q}
\underbrace{\frac{\text{VoT}}{60}}_{\text{R\$/min}}\ f_q\,\Delta_{qjk}\,w_{qjk}\ \cdot\ D
\ -\ \sum_{j\in J} f^{\text{fix}}_j\,y_j
\qquad\text{[R\$]}
$$

sujeito às restrições (1), (2), (3), **sem** (4).

**Razão de existir:** endogeneiza *quantos* vertiportos abrir, em vez de fixar $p$. Responde
diretamente "a partir de quantos vertiportos o retorno deixa de compensar" sem precisar ler a
curva.

**O detalhe que se esquece e que invalida o resultado:** o primeiro termo é um **fluxo diário** e o
segundo é um **estoque de capital**. Somá-los sem anualizar é erro de unidade grosseiro. $D$ acima
é o fator de conversão — dias úteis por ano vezes o horizonte, ou o inverso do fator de
recuperação de capital —, e ele é uma decisão registrada por si só. **Prós:** é a extensão
economicamente mais rica, e a que mais se aproxima de uma recomendação de política. **Contras:**
exige VoT, $f^{\text{fix}}_j$ **e** $D$ — três parâmetros, dois deles `[A CONFIRMAR]` e um deles
(`VoT`) já é pergunta obrigatória do grafo. É a extensão de maior risco de virar número inventado.

#### 9.4 Equidade

$$
\sum_{j\in J_{\text{periferia}}} y_j\ \ge\ \big\lceil \rho\,p\big\rceil,
\qquad \rho\in[0,1]
$$

com $J_{\text{periferia}}=J\setminus J_{\text{centro expandido}}$ definido geograficamente.

**Razão de existir:** UAM em São Paulo tem risco concreto de virar infraestrutura do quadrilátero
Itaim–Faria Lima. A restrição internaliza equidade **no modelo**, em vez de medi-la depois — que é
a lacuna L6 da revisão.

**Prós:** é a extensão mais barata (uma linha, nenhum parâmetro novo com procedência externa —
$\rho$ é explicitamente política, e ser política declarada é aceitável) e produz a análise mais
elegante: a **curva de preço da equidade**, $Z^*(\rho)$, que mede em pax·min/dia quanto custa
exigir dispersão. **Contras:** $J_{\text{periferia}}$ exige um recorte geográfico que é, ele
mesmo, uma decisão discutível — defina-o a partir de um limite oficial e não desenhado à mão, e
registre.

#### 9.5 Recomendação

Se a extensão for escolhida por **valor de relatório por hora de trabalho**, a ordem é
**9.4 (equidade) > 9.2 (massa crítica) > 9.1 (capacidade) > 9.3 (custo fixo)**. A equidade não
depende de nenhum parâmetro sem fonte e produz uma curva nova; o custo fixo depende de três
parâmetros e é onde o risco de dado inventado é maior. Esta ordenação é uma recomendação, não a
decisão — a decisão é do grupo e vai para o grafo com as descartadas.

---

### 10. O que fica fora do modelo, e por que a omissão é aceitável

Exigência textual do §4.3. A regra ao escrever cada item: dizer **o que foi omitido**, **por que a
omissão é aceitável** e **em que direção ela enviesa o resultado**. O terceiro é o que separa uma
seção de limitações honesta de uma lista de desculpas.

**1. Escolha modal probabilística.** O modelo usa uma regra determinística — o par é servível se
$\Delta\ge\theta$, e então é servido integralmente. Na realidade a migração é probabilística e
parcial. *Aceitável porque:* não existe logit de UAM calibrado para o Brasil, e transplantar
coeficientes estrangeiros introduziria parâmetro sem procedência (`decisao:D03`, `decisao:D05`).
*Viés:* **superestima** a demanda capturada. $Z$ deve ser lido como **limite superior**, não como
previsão de adoção. Wu & Zhang (2021) medem a diferença: o segundo estágio de escolha reduziu as
viagens candidatas em cerca de duas ordens de grandeza.

**2. Tarifa endógena.** Não há preço no modelo, logo não há elasticidade-preço nem interação entre
preço e localização. *Aceitável porque:* tarifa endógena torna o problema não convexo e o coloca
fora do alcance de cinco semanas, e porque a literatura já responde qualitativamente — Rimjha et
al. (2021) concluem que a viabilidade econômica exige tarifas irrealisticamente baixas. *Viés:*
**superestima**, pela mesma razão do item 1.

**3. Espaço aéreo, TMA e separação.** Não há restrição de rota, de setor, de TMA de Congonhas ou
Guarulhos, nem capacidade de espaço aéreo. O voo é linha reta a velocidade média. *Aceitável
porque:* os corredores do HELICONTROL e as regras de TMA não estão disponíveis em formato
processável para um trabalho de cinco semanas, e porque a aproximação é a mesma que Rimjha et al.
(2021) fazem. *Viés:* **subestima** $T^{\text{uam}}$, logo **superestima** $\Delta$. É a mesma
direção dos itens anteriores, e a soma delas precisa estar dita: as omissões do modelo são
**todas** favoráveis à UAM, e o resultado é um teto.

**4. Ruído.** Não há restrição nem penalidade de ruído, apesar de ser o principal fator de
resistência social a UAM em área densa. *Aceitável porque:* modelar ruído exige curvas de emissão
da aeronave (que não existem publicamente para as aeronaves em certificação) e população exposta
por horário. *Viés:* **superestima** a viabilidade dos sítios centrais, que são justamente os mais
densos. Este item merece figurar na recomendação final, não só na lista.

**5. Bateria, autonomia e recarga.** Não há estado de carga, tempo de recarga nem restrição de
alcance. *Aceitável porque:* na escala do município de São Paulo, praticamente todo par
candidato–candidato está dentro da autonomia típica citada para eVTOL (ordem de 100–150 km), e o
filtro de distância mínima de 15 km atua no outro extremo. *Viés:* pequeno neste recorte;
**seria decisivo** se o recorte fosse metropolitano ou interurbano — o que liga esta limitação
diretamente à `pendencia:P03`, sobre o recorte espacial.

**6. Congestionamento aéreo e fila em vertiporto.** Sem a extensão 9.1, não há capacidade nenhuma;
com ela, há capacidade mas não há fila — a restrição é um teto de volume diário, não um modelo de
espera. *Aceitável porque:* fila exige modelo estocástico ou de filas, que é outro trabalho.
*Viés:* **subestima** $T^{\text{uam}}$ (não há espera), portanto superestima $\Delta$.

**7. Dinâmica temporal.** O modelo é de um **dia típico agregado**, não tem hora do dia, nem
direcionalidade de pico, nem sazonalidade. Um vertiporto que satura às 8h e fica vazio às 14h
aparece no modelo como um vertiporto com carga média. *Aceitável porque:* a matriz OD é uma
matriz de dia típico, e desagregar por faixa horária multiplicaria $|Q|$ pelo número de faixas —
o que colide com o limite de tratabilidade medido em T22. *Viés:* **subestima** a necessidade de
capacidade e **superestima** o aproveitamento da infraestrutura. É a limitação mais fácil de
transformar em trabalho futuro, e vale escrevê-la assim.

**8. Efeitos de rede de segunda ordem.** O modelo captura massa crítica de primeira ordem — um par
precisa dos dois lados. Não captura: baldeação entre vertiportos (todo par usa exatamente um
salto), efeito de frequência (mais rede ⇒ mais voos ⇒ menos espera ⇒ mais demanda), nem indução de
demanda. *Aceitável porque:* baldeação em eVTOL urbano é improvável dada a penalidade fixa de
$\tau_{\text{emb}}+\tau_{\text{des}}=10$ min por embarque, e o efeito de frequência exigiria
demanda endógena, que é o item 1. *Viés:* **subestima** o benefício de redes grandes, o que atenua
a curva em S — é o único viés da lista que joga **contra** a hipótese central do trabalho, e por
isso é o mais importante de declarar.

---

## Critério de pronto

- [ ] Os quatro conjuntos ($I$, $J$, $Q$, $P_q$) definidos em LaTeX, com a regra de construção de
      $Q$ e de $P_q$ escrita como conjunto, não como prosa.
- [ ] Todos os parâmetros na tabela do §2, **com unidade e procedência preenchidas**, e todo
      `[A CONFIRMAR]` / `[A DEFINIR]` com pendência ou decisão correspondente no grafo.
- [ ] As duas variáveis com significado escrito, e o domínio de cada uma.
- [ ] A FO com a unidade `pax·min/dia` explicitada e o critério que ela representa em prosa.
- [ ] As quatro restrições, **cada uma com a razão de existir em uma frase**.
- [ ] O parágrafo do §3.1 — por que duas restrições e não uma — escrito no relatório.
- [ ] Os quatro duais nomeados, com unidade e leitura econômica, e a ressalva "dual é da
      relaxação, não do MILP".
- [ ] O argumento do §4 sobre $w$ contínua escrito como proposição com demonstração.
- [ ] As duas formulações do §5 (desagregada e agregada) escritas, com a contagem de linhas de
      cada uma e a expectativa sobre a força da relaxação.
- [ ] A justificativa da família com as **cinco** alternativas descartadas e o motivo específico de
      cada rejeição (não "X é melhor", mas o defeito concreto de cada uma).
- [ ] A previsão da curva em S escrita **como previsão**, com o que é teorema separado do que é
      expectativa.
- [ ] **Uma** extensão escolhida, formulada, e as outras três registradas como descartadas.
- [ ] A lista do §10 completa, cada item com a direção do viés.
- [ ] `decisao:D05` em YAML, assinada por `pessoa:henri`, com `alternativas_descartadas`.
- [ ] O validador do grafo passa.

---

## Armadilhas conhecidas

**Escrever $\bar t$ e $\theta$ como restrições do modelo.** Elas são filtros de
pré-processamento — definem quais colunas existem. Escrevê-las como restrições produz um modelo
maior e mais lento que faz exatamente a mesma coisa. E gera a confusão de §1.1: quem as vê como
restrições espera que a sensibilidade em $\bar t$ seja um `set_rhs` e uma re-otimização; ela é um
**rebuild** completo.

**Tratar $Q$ como não dirigido.** $(o,d)$ e $(d,o)$ são pares distintos: os fluxos são diferentes
na matriz OD e os tempos de acesso e egresso também. Se em algum ponto o grupo decidir simetrizar,
isso é uma decisão registrada, e a extensão de capacidade (§9.1) precisa ser reescrita — o termo
$w_{qkj}$ existe justamente porque $Q$ é dirigido.

**Esquecer $j\ne k$.** Sem essa condição em $P_q$, o modelo admite "voar de $j$ para $j$", com
$t^{\text{voo}}=0$, e captura $\Delta=T^{\text{ter}}-t^{\text{acc}}-t^{\text{egr}}-10$ — um valor
grande e completamente fictício. O sintoma é cobertura alta demais e vertiportos escolhidos em
lugares estranhos.

**Deixar $\Delta$ negativo entrar.** Só é possível com $\theta<0$. A Proposição do §4 continua
valendo (o ótimo seria $w=0$), então o modelo não quebra — ele simplesmente carrega colunas
inúteis. Mas se alguém depois calcular "economia média por par" sobre a tabela de colunas em vez
de sobre a solução, o número sai errado. Mantenha $\theta\ge 0$ e faça o `stopifnot`.

**Confundir os limiares de D03 com $\bar t$ e $\theta$.** D03 filtra **viagens** (≥ 15 km, ≥ 45–60
min declarados, motivo, renda) e produz $Q$. $\bar t$ e $\theta$ filtram **rotas** e produzem
$P_q$. São quatro parâmetros diferentes com nomes parecidos, e trocá-los na seção de sensibilidade
é um erro que passa despercebido porque as duas curvas têm formato parecido.

**Assumir que a relaxação é quase-integral porque MCLP é.** A quase-integralidade da relaxação de
ReVelle–Swain é uma propriedade da estrutura unilateral. A bilateralidade a quebra, e o exemplo do
ciclo de três candidatos do §5 é a prova. Escrever no relatório que "esperamos gap pequeno, como é
usual em MCLP" é errar a previsão e o motivo ao mesmo tempo.

**Reportar "o dual do MILP".** Não existe. Ver §1.5.

**Apresentar $Z$ como demanda atendida.** $Z$ está em pax·min/dia. A "demanda diária atendida e sua
participação na demanda capturável" — indicador comum do §6.3 — é outra quantidade,
$\sum_q\sum_{(j,k)}f_q w_{qjk}$ em viagens/dia. **São dois indicadores, e os dois são exigidos.**
Deixe as duas fórmulas escritas na formulação para não haver improviso na hora de tabular.

**Escrever a formulação com os números do plano.** $|Q|\approx 2.000$–$4.000$ e
$\overline{|P_q|}\approx 20$–$60$ são **estimativas de ordem de grandeza, não medições**. Na seção
de modelagem, o tamanho da instância é `[A MEDIR — T22]`. Colocar a estimativa como se fosse
dimensionamento é precisamente o defeito que o G07 existe para corrigir.

---

## O que registrar

**Decisões**

- **`decisao:D05`** — a família. Já existe em `governanca/data/decisoes/D05.yaml`, com quatro
  alternativas descartadas. Confira se as cinco alternativas discutidas no §6 deste guia estão
  todas lá; se faltar alguma, acrescente em vez de criar decisão nova.
- **`decisao:` para $\bar t$** — valor base e faixa da sensibilidade. Alternativas descartadas:
  raio fixo em km em vez de tempo (rejeitado porque o que o usuário sente é tempo, e a mesma
  distância em SP varia em dezenas de minutos); e ausência de limiar (rejeitado porque produz
  colunas com acesso de duas horas, que ninguém usaria).
- **`decisao:` para $\theta$** — idem. Alternativa descartada: $\theta$ proporcional
  ($\Delta/T^{\text{ter}}\ge\theta\%$) em vez de absoluto, que é defensável e talvez melhor —
  registre por que não.
- **`decisao:` para o critério da FO** — economia de tempo agregada em vez de viagens capturadas
  ou de excedente monetizado, com os motivos do §1.4.
- **`decisao:` para a formulação desagregada como principal**, com a agregada como objeto de
  comparação de T30 e não como alternativa rejeitada.
- **`decisao:` para a extensão escolhida**, com as outras três do §9 como descartadas.
- **`decisao:` para o sentido de $Q$** (dirigido), se ficar diferente do assumido aqui.

**Referências** — os nós que este pacote consome, no padrão `referencia:<autor><ano>`:
`referencia:hakimi1964`, `referencia:revelle1970`, `referencia:church1974`,
`referencia:okelly1987`, `referencia:campbell1994`, `referencia:kuby2005`,
`referencia:hodgson1990`, `referencia:wu2021`, `referencia:rath2022`, `referencia:rimjha2021`,
`referencia:volakakis2024`, `referencia:volakakis2025`, `referencia:hagspihl2025`,
`referencia:chen2022`, `referencia:jiang2025`. Cada um com DOI **e** com o campo que diz se o
texto integral foi lido ou se só o metadado foi confirmado. Este campo é o que impede a
`pendencia:P02` de virar letra morta.

**Pendências**

- `pendencia:` para $C_j$, se a extensão 9.1 for escolhida — não há fonte brasileira de capacidade
  de vertiporto, e a extensão não pode ser implementada com número inventado.
- `pendencia:` para VoT e $f^{\text{fix}}_j$, se a extensão 9.3 for escolhida.
- `pendencia:P02` permanece aberta até os quatro PDFs chegarem. Ela deixa de bloquear T21 quando o
  parágrafo de posicionamento estiver escrito só com o que foi lido.

**Notas em tarefa** — em `tarefa:T21`, uma nota datada registrando qual extensão foi escolhida e
por quê, e outra registrando os valores base de $\bar t$ e $\theta$ com o nome de quem decidiu. A
pergunta 1 do §7 do `G00` — *"por que o valor do tempo adotado é este, e quem decidiu"* — tem
irmãs, e estas duas são elas.

**Interação de IA** — `critica_humana` não vazia. Candidatos honestos a crítica neste pacote, e
todos são reais:

- A revisão de literatura afirma "objetivo submodular ⇒ curva côncava". **Isso não é teorema** (ver
  §8.2): submodularidade sustenta retornos decrescentes, não concavidade exata da curva de valor
  ótimo em $p$. Este guia corrige a afirmação. É uma discordância fundamentada, é registrável com
  `#discordancia`, e é candidata direta à pergunta garantida da arguição.
- A tabela do §6.7 classifica P1 como "sim" em massa crítica e interdependência com base na
  estrutura da formulação, não em resultado medido. Até T23 rodar, é previsão.
- Os valores base de $\bar t=15$ e $\theta=10$ aparecem neste guia como **proposta**, sem fonte.
  Se forem adotados sem uma decisão registrada com responsável, o guia terá funcionado como fonte
  de autoridade que ele não é.
- O §6.5 afirma que hub location com logit é "tecnicamente superior". É uma avaliação, não um
  fato — e sustentar essa avaliação exige ter lido Rath & Chow (2022) e Hagspihl et al. (2025) em
  texto integral, não só as fichas da revisão.

---

## Como isso vira relatório

**Seção de modelagem (§4.2 do enunciado) — este pacote É a seção.** Cole, nesta ordem: os
conjuntos (§1.1), a tabela de parâmetros (§2), as variáveis (§1.3), o modelo P1 (§1.4), a razão de
existir de cada restrição (§3) e o quadro dos duais (§1.5). O §3.1 vira uma subseção própria, com
título — é a contribuição, e enterrá-la numa lista de restrições seria desperdiçá-la.

**Seção "o que o modelo enfrenta" (§4.3).** Três itens, todos já escritos: porta a porta é o §1.2
($\Delta$ inclui acesso, embarque, voo, desembarque, egresso, contra o modo concorrente);
interdependência é o §3.1; limitações operacionais é a extensão escolhida no §9. E o quarto item
do §4.3 — o que ficou fora e por que a omissão é aceitável — é o §10 inteiro.

**Seção de revisão e posicionamento.** O §6 vira a comparação com as famílias clássicas, e a
tabela do §6.7 é a figura-síntese dela. O §7 vira o parágrafo de contribuição, com a ressalva
sobre P02.

**Seção de análises (§4.4).** Este pacote não produz resultado, mas escreve as **hipóteses** das
quatro análises, e escrever hipótese antes de rodar é o que distingue experimento de rodada: o §5
é a hipótese de T30 (a desagregada tem relaxação muito mais forte); o §1.5 é a de T31 (o que cada
dual deve significar); o §2 lista os eixos de T32; o §8 é a hipótese de T33/T34 (a curva em S), e
é a mais importante — porque está escrita, datada e commitada **antes** do experimento que a
testa. Se o S aparecer, a previsão registrada em 02/09 vale muito mais que a mesma frase escrita
em 20/09.

**Arguição.** A pergunta mais provável sobre este pacote é *"por que duas restrições em vez de
uma?"*, e a segunda é *"por que $w$ não é binária?"*. As duas têm resposta pronta nos §3.1 e §4, e
as duas são perguntas em que a resposta certa dita devagar demonstra que o grupo entende o próprio
modelo. A terceira, mais difícil, é *"sua curva em S não é consequência de ter escolhido $\theta$
alto?"* — e a resposta boa é a análise de sensibilidade em $\theta$ do §2, que existe exatamente
para responder isso.
