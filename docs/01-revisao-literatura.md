# Revisão de Literatura — Localização de Vertiportos em São Paulo

> **Documento de trabalho — Projeto B1, TRA-48.**
> Levantamento produzido em 24/08/2026 com apoio de IA. **Registrar como interação no banco de
> governança, com crítica.** Pontos concretos a criticar antes de usar:
>
> - Itens marcados **[não confirmado]** têm metadado incompleto. Shin et al. (2021) está com
>   autoria parcial.
> - Formulação e instância de **Brunelli et al. (2023)**, **Ribeiro et al. (2023)**,
>   **Carvalho et al. (2026)** e **Shin et al. (2021)** foram confirmadas apenas em **metadados
>   bibliográficos** (Crossref/RePEc/OUCI) — ScienceDirect e INFORMS bloqueiam acesso automatizado.
>   **Obtenham os PDFs pela biblioteca do ITA antes de citar a formulação matemática de qualquer
>   um deles.**
> - O dimensionamento de instância na §4 é **estimativa de ordem de grandeza, não medição**.
>   Meçam `|Q|` e `Σ|P_q|` na prática antes de escrever o modelo.
> - A previsão da curva em S é **teórica**, derivada da estrutura da FO. Se o experimento não
>   produzir o S, isso é achado, não fracasso.

---

# Revisão de Literatura — Localização de Vertiportos em São Paulo (TRA‑48 / ITA)

**Escopo:** modelos de programação matemática (LP/MILP) para localização de vertiportos, com tratamento porta‑a‑porta, interdependência locacional (hub location) e massa crítica de rede.
**Regra de verificação:** toda referência abaixo foi confirmada por busca/fetch (Crossref, RePEc, Springer, MDPI, OUCI/Crossref‑refs, arXiv/ar5iv, repositórios institucionais). Itens com metadados parciais estão marcados **[não confirmado]** no campo específico.

---

## 1) FAMÍLIAS CLÁSSICAS DE LOCALIZAÇÃO

### Notação comum
- $I$: conjunto de zonas de demanda (nós de origem/destino).
- $J$: conjunto de sítios candidatos a instalação.
- $h_i$: peso/demanda da zona $i$.
- $d_{ij}$: custo/tempo/distância de $i$ a $j$.
- $y_j\in\{0,1\}$: abre instalação em $j$.
- $x_{ij}$: fração da demanda de $i$ atendida por $j$.

---

### 1.1 p‑Mediana

**Seminal:** Hakimi, S.L. (1964). *Optimum Locations of Switching Centers and the Absolute Centers and Medians of a Graph*. **Operations Research** 12(3), 450–459. DOI [10.1287/opre.12.3.450](https://doi.org/10.1287/opre.12.3.450).
**Formulação MILP:** ReVelle, C.S. & Swain, R.W. (1970). *Central Facilities Location*. **Geographical Analysis** 2(1), 30–42. DOI [10.1111/j.1538-4632.1970.tb00142.x](https://doi.org/10.1111/j.1538-4632.1970.tb00142.x).

$$
\begin{aligned}
\min\quad & Z=\sum_{i\in I}\sum_{j\in J} h_i\, d_{ij}\, x_{ij}\\
\text{s.a.}\quad & \sum_{j\in J} x_{ij}=1 && \forall i\in I \qquad (\lambda_i)\\
& x_{ij}\le y_j && \forall i\in I,\ j\in J \qquad (\mu_{ij})\\
& \sum_{j\in J} y_j = p && (\pi)\\
& x_{ij}\ge 0,\quad y_j\in\{0,1\}
\end{aligned}
$$

**Captura:** custo médio de acesso ponderado pela demanda; trade‑off eficiência/número de instalações; a relaxação LP de ReVelle–Swain é notoriamente "quase‑integral" (muitos casos resolvem inteiro no LP) — ótimo para a análise de relaxação exigida pela disciplina.
**NÃO captura para vertiportos:** (i) trata cada zona isoladamente — não há **par** origem‑destino, logo não há rede; (ii) minimiza acesso terrestre, mas o benefício do eVTOL está no **tempo total porta‑a‑porta** (acesso + voo + egresso) comparado ao modo terrestre; (iii) não há elasticidade: 100% da demanda é servida por hipótese, o que é falso quando o eVTOL só é escolhido se houver economia de tempo; (iv) não há custo fixo nem capacidade de FATO/gate.

---

### 1.2 p‑Centro

**Seminal:** Hakimi (1964), mesma referência (o "absolute center" do grafo). Formulação MILP consolidada em Daskin, M.S., *Network and Discrete Location* (Wiley) — **[edição/ano específicos não confirmados nesta busca]**.

$$
\begin{aligned}
\min\quad & L\\
\text{s.a.}\quad & L \ \ge\ \sum_{j\in J} d_{ij}\,x_{ij} && \forall i\in I\\
& \sum_{j\in J} x_{ij}=1,\quad x_{ij}\le y_j,\quad \sum_{j\in J}y_j=p\\
& x_{ij}\in\{0,1\},\ y_j\in\{0,1\},\ L\ge 0
\end{aligned}
$$

**Captura:** equidade *minimax* — nenhuma zona fica pior que $L$. Relevante para o debate de **equidade de acesso à UAM** (ver §2, Volakakis & Mahmassani 2024).
**NÃO captura:** objetivo minimax é dominado por outliers (Parelheiros, extremos da RMSP) e produz soluções economicamente absurdas para um serviço premium; ignora completamente demanda e interdependência de rede. Em UAM, serve melhor como **restrição** (raio máximo de acesso) do que como FO.

---

### 1.3 Maximal Covering Location Problem (MCLP)

**Seminal:** Church, R. & ReVelle, C. (1974). *The Maximal Covering Location Problem*. **Papers in Regional Science / Papers of the Regional Science Association** 32, 101–118. DOI [10.1111/j.1435-5597.1974.tb00902.x](https://doi.org/10.1111/j.1435-5597.1974.tb00902.x) (também indexado como [10.1007/BF01942293](https://doi.org/10.1007/BF01942293)).
Extensão com custo fixo: Church, R.L. & Davis, R.R. (1992). *The Fixed Charge Maximal Covering Location Problem*. **Papers in Regional Science** 71, 199–215. DOI [10.1111/j.1435-5597.1992.tb01843.x](https://doi.org/10.1111/j.1435-5597.1992.tb01843.x).

Seja $N_i=\{j\in J: d_{ij}\le S\}$ o conjunto cobridor de $i$, e $z_i\in\{0,1\}$ indicando $i$ coberta.

$$
\begin{aligned}
\max\quad & \sum_{i\in I} h_i\, z_i\\
\text{s.a.}\quad & z_i \ \le\ \sum_{j\in N_i} y_j && \forall i\in I \qquad (\alpha_i)\\
& \sum_{j\in J} y_j \le p && (\pi)\\
& z_i\in[0,1],\ y_j\in\{0,1\}
\end{aligned}
$$

**Captura:** natureza *premium/nichada* da UAM — não se pretende servir todos, mas **maximizar demanda capturada** dado orçamento $p$. O dual $\pi$ da restrição de cardinalidade é exatamente a **derivada da curva de implantação** (demanda marginal por vertiporto adicional). Objetivo submodular ⇒ curva côncava, retornos decrescentes.
**NÃO captura:** cobertura é **unilateral** — basta um vertiporto perto da origem. Em UAM a viagem só existe se houver vertiporto **na origem E no destino**. Essa é a falha central do MCLP puro no caso vertiportos, e é justamente onde a variante recomendada em §4 se diferencia.

---

### 1.4 Set Covering (LSCP)

**Seminal:** Toregas, C., Swain, R., ReVelle, C. & Bergman, L. (1971). *The Location of Emergency Service Facilities*. **Operations Research** 19(6), 1363–1373. DOI [10.1287/opre.19.6.1363](https://doi.org/10.1287/opre.19.6.1363).

$$
\begin{aligned}
\min\quad & \sum_{j\in J} c_j\, y_j\\
\text{s.a.}\quad & \sum_{j\in N_i} y_j \ \ge\ 1 && \forall i\in I \qquad (\alpha_i)\\
& y_j\in\{0,1\}
\end{aligned}
$$

**Captura:** número/custo **mínimo** de vertiportos para garantir padrão de serviço universal (ex.: toda zona OD a ≤ 15 min de um vertiporto). Útil como **limite inferior de infraestrutura** e para calibrar o eixo $p$ da curva de implantação. Duais $\alpha_i$ = preço‑sombra de exigir cobertura da zona $i$.
**NÃO captura:** cobertura universal é irrealista e cara em SP (a RMSP tem 517 zonas OD em 39 municípios); ignora demanda, custos operacionais e rede. Frequentemente inviável quando se impõem restrições de airspace/ruído.

---

### 1.5 Uncapacitated / Capacitated Facility Location (custo fixo)

**Seminal (UFLP):** Balinski, M.L. (1965). *Integer Programming: Methods, Uses, Computations*. **Management Science** 12(3), 253–313. DOI [10.1287/mnsc.12.3.253](https://doi.org/10.1287/mnsc.12.3.253) (formulação de "simple plant location").

**UFLP:**
$$
\begin{aligned}
\min\quad & \sum_{j\in J} f_j y_j + \sum_{i\in I}\sum_{j\in J} h_i c_{ij} x_{ij}\\
\text{s.a.}\quad & \sum_{j} x_{ij}=1\ \ \forall i;\qquad x_{ij}\le y_j\ \ \forall i,j;\qquad x_{ij}\ge0,\ y_j\in\{0,1\}
\end{aligned}
$$

**CFLP** — acrescenta capacidade $Q_j$ (movimentos/hora, gates, FATOs):
$$
\sum_{i\in I} h_i x_{ij} \ \le\ Q_j\, y_j \qquad \forall j \qquad (\gamma_j)
$$

**Captura:** endogeneiza **quantos** vertiportos abrir (não fixa $p$); $f_j$ modela CAPEX diferenciado (rooftop vs. heliponto existente vs. greenfield); $\gamma_j$ é o **preço‑sombra de capacidade** — leitura direta de congestionamento de FATO. A desagregação $x_{ij}\le y_j$ dá relaxação LP forte; a agregação $\sum_i x_{ij}\le |I| y_j$ dá relaxação fraca — comparação pedagógica perfeita.
**NÃO captura:** ainda é **um lado só** da viagem (alocação zona→instalação). Não há voo, não há par OD, não há efeito de rede. É o modelo usado, com adaptações, por Volakakis & Mahmassani (2024, 2025).

---

### 1.6 Hub Location

#### (a) p‑hub mediana — formulação quadrática original
**Seminal:** O'Kelly, M.E. (1987). *A quadratic integer program for the location of interacting hub facilities*. **European Journal of Operational Research** 32(3), 393–404. DOI [10.1016/S0377-2217(87)80007-3](https://doi.org/10.1016/S0377-2217(87)80007-3).

Com $w_{ij}$ = fluxo de $i$ para $j$, $Z_{ik}=1$ se nó $i$ é alocado ao hub $k$, e fatores $\chi$ (coleta), $\alpha<1$ (desconto inter‑hub), $\delta$ (distribuição):

$$
\begin{aligned}
\min\quad & \sum_{i}\sum_{j} w_{ij}\Big[\sum_{k}\chi c_{ik}Z_{ik}+\sum_{m}\delta c_{jm}Z_{jm}+\alpha\sum_{k}\sum_{m}c_{km}Z_{ik}Z_{jm}\Big]\\
\text{s.a.}\quad & \sum_{k} Z_{ik}=1\ \ \forall i;\qquad Z_{ik}\le Z_{kk}\ \ \forall i,k;\qquad \sum_{k}Z_{kk}=p;\qquad Z_{ik}\in\{0,1\}
\end{aligned}
$$

#### (b) Linearização e famílias derivadas
**Seminal:** Campbell, J.F. (1994). *Integer programming formulations of discrete hub location problems*. **EJOR** 72(2), 387–405. DOI [10.1016/0377-2217(94)90318-2](https://doi.org/10.1016/0377-2217(94)90318-2).

Formulação de **alocação múltipla** com 4 índices, $X_{ijkm}$ = fração do fluxo $i\!\to\! j$ roteada via hubs $k$ depois $m$:

$$
\begin{aligned}
\min\quad & \sum_{i,j,k,m} w_{ij}\big(\chi c_{ik}+\alpha c_{km}+\delta c_{mj}\big) X_{ijkm}\\
\text{s.a.}\quad & \sum_{k,m} X_{ijkm}=1 && \forall i,j\\
& X_{ijkm}\le y_k,\qquad X_{ijkm}\le y_m && \forall i,j,k,m\\
& \sum_{k} y_k=p,\qquad X_{ijkm}\ge0,\ y_k\in\{0,1\}
\end{aligned}
$$

#### (c) Hub covering
**Seminal:** Kara, B.Y. & Tansel, B.Ç. (2003). *The single‑assignment hub covering problem: Models and linearizations*. **Journal of the Operational Research Society** 54(1), 59–64. DOI [10.1057/palgrave.jors.2601473](https://doi.org/10.1057/palgrave.jors.2601473).
Substitui a FO de custo por: cobrir todo par $(i,j)$ cujo tempo de percurso via hubs seja $\le \beta$ (cobertura de **serviço**, não de distância) — exatamente o critério "porta‑a‑porta competitivo" da UAM.

#### (d) Hub location com custo fixo
**Seminal:** O'Kelly, M.E. (1992). *Hub facility location with fixed costs*. **Papers in Regional Science** 71(3), 293–306. DOI [10.1111/j.1435-5597.1992.tb01848.x](https://doi.org/10.1111/j.1435-5597.1992.tb01848.x).
Troca $\sum_k y_k=p$ por $+\sum_k f_k y_k$ na FO.

#### (e) Versão capacitada (alocação única)
**Seminal:** Ernst, A.T. & Krishnamoorthy, M. (1999). *Solution algorithms for the capacitated single allocation hub location problem*. **Annals of Operations Research** 86, 141–159. DOI [10.1023/A:1018994432663](https://doi.org/10.1023/A:1018994432663). Formulação com variáveis de fluxo agregadas (3 índices) — reduz drasticamente o tamanho vs. Campbell.
Restrição típica: $\sum_i O_i Z_{ik}\le \Gamma_k Z_{kk}$.

**Survey de referência:** Campbell, J.F. & O'Kelly, M.E. (2012). *Twenty‑Five Years of Hub Location Research*. **Transportation Science** 46(2), 153–169. DOI [10.1287/trsc.1120.0410](https://doi.org/10.1287/trsc.1120.0410).

**Captura para vertiportos:** é a **única família clássica que modela interdependência locacional** — o valor de abrir $k$ depende de quais outros hubs existem, pois o fluxo $i\!\to\! j$ precisa de dois nós de rede. Captura naturalmente massa crítica e o efeito "rede de dois lados". $\alpha$ mapeia diretamente o ganho de velocidade do eVTOL vs. o modo terrestre.
**NÃO captura (na forma clássica):** (i) o desconto $\alpha$ assume economia de escala inter‑hub — em eVTOL o custo por assento‑km é **maior**, não menor; o "desconto" real é em **tempo**, não em custo, e o modelo precisa ser reformulado em tempo generalizado; (ii) demanda $w_{ij}$ é **inelástica e integralmente roteada** pela rede de hubs — irreal: o usuário só migra se houver economia; (iii) alocação única força todos da zona $i$ ao mesmo vertiporto; (iv) o custo de acesso $\chi c_{ik}$ agrega modo terrestre sem escolha modal; (v) não há capacidade de FATO nem restrição de airspace/ruído.

---

### 1.7 Flow Interception / Flow Refueling

#### (a) Flow‑Capturing Location‑Allocation (FCLM)
**Seminal:** Hodgson, M.J. (1990). *A Flow‑Capturing Location‑Allocation Model*. **Geographical Analysis** 22(3), 270–279. DOI [10.1111/j.1538-4632.1990.tb00210.x](https://doi.org/10.1111/j.1538-4632.1990.tb00210.x).
**Paralelo independente:** Berman, O., Larson, R.C. & Fouska, N. (1992). *Optimal Location of Discretionary Service Facilities*. **Transportation Science** 26(3), 201–211. DOI [10.1287/trsc.26.3.201](https://doi.org/10.1287/trsc.26.3.201).

Seja $Q$ o conjunto de fluxos (caminhos OD), $f_q$ o volume do fluxo $q$, $N_q\subseteq J$ os nós do caminho $q$, $z_q\in\{0,1\}$ se $q$ é interceptado:

$$
\begin{aligned}
\max\quad & \sum_{q\in Q} f_q\, z_q\\
\text{s.a.}\quad & z_q \ \le\ \sum_{j\in N_q} y_j \quad \forall q\in Q;\qquad \sum_{j\in J} y_j = p;\qquad z_q\in[0,1],\ y_j\in\{0,1\}
\end{aligned}
$$

#### (b) Flow‑Refueling Location Model (FRLM)
**Seminal:** Kuby, M. & Lim, S. (2005). *The flow‑refueling location problem for alternative‑fuel vehicles*. **Socio‑Economic Planning Sciences** 39(2), 125–145. DOI [10.1016/j.seps.2004.03.001](https://doi.org/10.1016/j.seps.2004.03.001).

Seja $H$ o conjunto de **combinações** de estações que conseguem abastecer o caminho $q$ (dada autonomia), $b_{qh}=1$ se a combinação $h$ serve $q$, e $v_h\in\{0,1\}$ se todas as estações de $h$ estão abertas:

$$
\begin{aligned}
\max\quad & \sum_{q\in Q} f_q\, z_q\\
\text{s.a.}\quad & z_q \ \le\ \sum_{h\in H} b_{qh}\, v_h && \forall q\in Q\\
& v_h \ \le\ y_k && \forall h\in H,\ \forall k\in h\\
& \sum_{k\in J} y_k = p;\qquad v_h, z_q\in[0,1],\ y_k\in\{0,1\}
\end{aligned}
$$

**Captura para vertiportos:** o FRLM é a família clássica que formaliza **"o serviço só existe se um CONJUNTO de instalações estiver aberto simultaneamente"** — combinatória exatamente análoga a "preciso de vertiporto na origem *e* no destino". A restrição $v_h\le y_k$ é o mecanismo de **massa crítica** em forma linear. Também é o modelo natural para **infraestrutura de recarga de eVTOL** (autonomia limitada, ~100–150 km).
**NÃO captura:** fluxos são caminhos pré‑definidos na rede rodoviária; em UAM o "caminho" é o próprio par OD e o acesso/egresso terrestre é a parte cara — precisa ser explicitado. E não há escolha modal.

---

### 1.8 Síntese crítica: o que falta em TODAS as famílias clássicas

| Requisito TRA‑48 / vertiportos | p‑med | p‑cen | MCLP | LSCP | U/CFLP | Hub | FCLM/FRLM |
|---|---|---|---|---|---|---|---|
| Viagem porta‑a‑porta (acesso+voo+egresso) | ✗ | ✗ | ✗ | ✗ | ✗ | parcial | ✗ |
| Interdependência locacional (par OD) | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ | ✓ (FRLM) |
| Massa crítica / efeito rede | ✗ | ✗ | ✗ | ✗ | ✗ | parcial | ✓ (FRLM) |
| Demanda elástica / escolha modal | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ |
| Custo fixo endógeno | ✗ | ✗ | ✓ (FCMCLP) | ✓ | ✓ | ✓ | ✗ |
| Capacidade (FATO/gate) | ✗ | ✗ | ✗ | ✗ | ✓ | ✓ | ✗ |

**Nenhuma família clássica isolada resolve o problema.** A literatura de vertiportos é, essencialmente, o esforço de costurar Hub Location + Cobertura + escolha discreta.

---

## 2) ARTIGOS ESPECÍFICOS DE VERTIPORTOS / UAM

### 2.1 Tabela‑síntese

| # | Referência | Formulação | FO | Demanda | Instância / Solver |
|---|---|---|---|---|---|
| 1 | Wu & Zhang (2021), *Engineering* | IP p‑mediana hub‑and‑spoke + escolha modal | min custo generalizado total | limiar de valor‑do‑tempo sobre 266.734 viagens (TBRPM) | 100 candidatos, Tampa Bay; **Gurobi 9.0**, 245 s (+2h34 pré‑proc.) |
| 2 | Rath & Chow (2022), *JATM* | p‑hub mediana **alocação única** + logit binário linearizado | max ridership **ou** max receita | logit binário (custo, tempo) sobre 20M viagens FHV | 149 zonas NYC, 3 aeroportos; LP/MILP |
| 3 | Willey & Salmon (2021), *TRC* | Hub location + **isomorfismo de subgrafos** | min custo de rede / topologia | fluxos OD agregados | rede urbana; heurística de matching |
| 4 | Chen, Wandelt, Dai & Sun (2022), *INFORMS JoC* | Hub location misto discreto‑contínuo em grade | min custo total de transporte | 185.077 viagens Pequim | grades $n_b$ = 3…34; **VNS** vs. CPLEX (10 h) |
| 5 | Jiang, Li, Wang & Xue (2025), *TRA* | Multiobjetivo (cobertura RS + ODM) | max cobertura multidimensional | modelo de escolha, dois segmentos (ODM/RS) | Pequim; **NSGA‑III** (meta‑heurística) |
| 6 | Shin et al. (2021), *Computers & OR* | Skyport location problem | — **[detalhes não confirmados]** | — | — |
| 7 | Volakakis & Mahmassani (2024), *Infrastructures* | LSCP / MCLP / p‑med / p‑cen + UVLP/CVLP | min custo fixo+variável; equidade | TNC + táxi, limiares tempo/distância | Chicago; **GA** + IP/LP comparativos |
| 8 | Volakakis & Mahmassani (2025), *Infrastructures* | **a‑CFLP** e **a‑MCLP capacitado** (MILP) | min custo fixo+operacional / max cobertura | 6.124 pedidos/dia, acesso aeroportuário | Chicago; k‑means capacitado + guloso + MILP; 5–12 vertiportos ⇒ >95% cobertura |
| 9 | Hagspihl, Kolisch & Schiffels (2025), *OR Spectrum* | **UHLP alocação múltipla + logit linearizado** (MILP) | max nº de passageiros que escolhem air taxi | MNL endógeno (4 tipos de itinerário) | 1.125 CEPs Bavária, 24 candidatos, 7.376.700 pax/ano; solver **[não confirmado]** |
| 10 | Jin, Ng & Zhang (2024), *JATRS* | **Otimização robusta** de localização + escolha modal | min custo sob incerteza | escolha modal com incerteza poliédrica | — |
| 11 | Kitthamkesorn & Chen (2024), *TR‑E* | **Maximum Capture Problem** (localização competitiva) | max captura de demanda | modelo weibit/logit | — |
| 12 | Brunelli, Ditta & Postorino (2023), *JATM* | *Systematic review* — localização e capacidade | — | — | — |
| 13 | Fadhil (2018), MSc TUM | **GIS multicritério** (não‑MILP) | ranking de sítios | camadas socioeconômicas | Munique |
| 14 | Rimjha, Hotle, Trani & Hinze (2021), *TRA* | Demanda + viabilidade (não é modelo de localização) | — | logit condicional, análise de sensibilidade a tarifa e nº de vertiportos | Norte da Califórnia |
| 15 | Rimjha et al. (2021), *AIAA Aviation* | **Fuzzy C‑means** para candidatos + logit | — | 2 logits condicionais (business/não‑business) | 4.801 census block groups, 12 condados DFW; 45.070 viagens/dia |
| 16 | Ribeiro, Borille, Caetano & Silva (2023), *SCS* | Estudo de caso / reaproveitamento de helipontos | — | — | **São Paulo** |
| 17 | Carvalho, Gomes, Rodrigues, Murça, Guterres & Pamplona (2026), *CSTP* | Framework data‑driven: localização + rotas + previsão OD | otimização de rede | socioeconômico + operacional | **RMSP** |
| 18 | Lopes & Silva (2023), *JAIRM* | Survey de percepção (não‑OR) | — | — | **RMSP** |

---

### 2.2 Fichas detalhadas

**[1] Wu, Z. & Zhang, Y. (2021).** *Integrated Network Design and Demand Forecast for On‑Demand Urban Air Mobility.* **Engineering** 7(4), 473–487. DOI [10.1016/j.eng.2020.11.007](https://doi.org/10.1016/j.eng.2020.11.007)
- **Formulação:** programação inteira, rede hub‑and‑spoke tipo p‑mediana, com escolha de modo de acesso/egresso embutida como variável de decisão.
- **FO:** minimizar o **custo generalizado de viagem total** (tempo monetizado + custo direto) sobre todos os viajantes, terrestres e multimodais UAM.
- **Demanda capturável:** derivada de dados desagregados simulados do Tampa Bay Regional Planning Model — 266.734 viagens candidatas filtradas por ≥10 milhas / ≥30 min. **Sem logit**: o usuário migra se o valor do tempo economizado supera o custo adicional (regra determinística de utilidade). Resultado: apenas 532 viagens efetivamente UAM (≈0,20% de adoção) — **evidência forte de que a demanda capturável é pequena e altamente sensível à tarifa.**
- **Acesso terrestre:** explicitamente modelado com **seis modos** (auto próprio, ônibus, a pé, TNC, bike‑sharing, patinete), com variáveis distintas por perna e restrição de modo único por perna.
- **Instância/solver:** 100 candidatos identificados por análise GIS 3D de LiDAR, 5 condados da Flórida. **Gurobi 9.0** via Python; pré‑processamento em dois estágios (elimina combinações viagem‑vertiporto inviáveis) — 2h34min de pré‑proc. + 245 s de otimização.
- **Por que importa para vocês:** é o modelo mais próximo do que TRA‑48 pede (porta‑a‑porta + MILP + p‑mediana de hubs), e demonstra que **o pré‑processamento geométrico é o que torna o problema tratável**.

**[2] Rath, S. & Chow, J.Y.J. (2022).** *Air taxi skyport location problem with single‑allocation choice‑constrained elastic demand for airport access.* **Journal of Air Transport Management** 105, 102294. DOI [10.1016/j.jairtraman.2022.102294](https://doi.org/10.1016/j.jairtraman.2022.102294) — preprint: [arXiv:1904.01497](https://arxiv.org/abs/1904.01497)
- **Formulação:** **p‑hub mediana de alocação única modificado**, com restrições de escolha derivadas de um **logit binário** (táxi terrestre vs. air taxi). Os autores enumeram caminhos ótimos origem–skyport–aeroporto e **reformulam em modelo linear**, contornando a não‑convexidade típica de formulações logit.
- **FO:** duas variantes alternativas — (a) **max ridership**; (b) **max receita**.
- **Demanda:** logit binário sobre custo e comprimento da viagem, calibrado com >20 milhões de viagens FHV para aeroportos.
- **Acesso terrestre:** explícito — tempo/distância de acesso $(c_{ik}, d_{ik})$, alternativa terrestre direta $(c_{ij}, d_{ij})$, egresso $(d'_{kj})$, e tempos de transferência $\alpha_1$ (acesso/embarque) e $\alpha_2$ (egresso) somados à tarifa total: $f_{ikj}=f_{ik}+t_k+f_{kj}$.
- **Instância:** 149 zonas de táxi de NYC, 3 aeroportos (JFK, EWR, LGA). Resultado: **mínimo de 9 skyports** entre Manhattan, Queens e Brooklyn. Solver: abordagem de LP após linearização.
- **Por que importa:** é o *template* canônico de "hub location + demanda elástica linearizada". Se vocês quiserem ambição, é este o caminho.

**[3] Willey, L.C. & Salmon, J.L. (2021).** *A method for urban air mobility network design using hub location and subgraph isomorphism.* **Transportation Research Part C: Emerging Technologies** 125, 102997. DOI [10.1016/j.trc.2021.102997](https://doi.org/10.1016/j.trc.2021.102997)
- Combina hub location com **isomorfismo de subgrafos** para casar topologias de rede desejadas com a malha urbana. Interessante conceitualmente (design de topologia), mas de difícil replicação em 5 semanas. **[detalhes de instância/solver não confirmados]**

**[4] Chen, L., Wandelt, S., Dai, W. & Sun, X. (2022).** *Scalable Vertiport Hub Location Selection for Air Taxi Operations in a Metropolitan Region.* **INFORMS Journal on Computing** 34(2), 834–856. DOI [10.1287/ijoc.2021.1109](https://doi.org/10.1287/ijoc.2021.1109) — código: [GitHub](https://github.com/ScalableVertiportLocationProblem/ScalableVertiportHLP)
- **Formulação:** problema de localização **misto discreto‑contínuo** sobre grade $n_b\times n_b$, com células proibidas (áreas restritas, água, lazer, infraestrutura protegida).
- **FO:** minimizar custo total de transporte da rede de air taxi.
- **Demanda:** 185.077 registros de viagem de Pequim, com coordenadas OD; matrizes $c_{ij}$ e $w_{ij}$ disponibilizadas publicamente.
- **Instância/solver:** grades de $n_b$=3 até 34. **Variable Neighborhood Search** resolve grades 12×12 em segundos com gap 0%, enquanto **CPLEX leva até 10 horas**. Benchmarks AP e URAND no suplemento.
- **Por que importa:** é a evidência dura de que **MILP exato de hub location em grade urbana explode rapidamente** — dado crítico para dimensionar a instância de vocês.

**[5] Jiang, Y., Li, Z., Wang, Y. & Xue, Q. (2025).** *Vertiport location for eVTOL considering multidimensional demand of urban air mobility: An application in Beijing.* **Transportation Research Part A: Policy and Practice** 192, 104353. DOI [10.1016/j.tra.2024.104353](https://doi.org/10.1016/j.tra.2024.104353)
- Distingue **dois segmentos**: on‑demand mobility (ODM) e regular shuttle (RS), avaliados por *choice modeling*. Framework **multiobjetivo resolvido por NSGA‑III**, testando três estratégias de localização. A estratégia de "desenvolvimento equilibrado" atinge **84,4% de cobertura da demanda RS e 44,4% da ODM**.
- *Nota:* o pedido original mencionava "Wu & Zhang (Beijing)". Os autores confirmados do artigo de Pequim com demanda multidimensional são **Jiang, Li, Wang & Xue** — Wu & Zhang é o artigo de Tampa Bay [1].
- **Limitação para TRA‑48:** meta‑heurística, não MILP — não permite relaxação linear nem dual.

**[6] Shin et al. (2021).** *Skyport location problem for urban air mobility system.* **Computers & Operations Research** 138, 105611. DOI [10.1016/j.cor.2021.105611](https://doi.org/10.1016/j.cor.2021.105611)
- Confirmado via listas de referências de Jin et al. (2024) e Zhao & Feng (2024). **Lista completa de autores, formulação e instância: [não confirmados]** — o texto integral está atrás de paywall e o ScienceDirect bloqueia acesso automatizado. Provável vínculo com o CSDLab/KAIST (Prof. Taesik Lee). **Recomendo que o grupo obtenha este PDF pela biblioteca do ITA** — é o artigo mais diretamente alinhado ao título do projeto.

**[7] Volakakis, V. & Mahmassani, H.S. (2024).** *Vertiport Infrastructure Location Optimization for Equitable Access to Urban Air Mobility.* **Infrastructures** 9(12), 239. DOI [10.3390/infrastructures9120239](https://doi.org/10.3390/infrastructures9120239)
- **Formulação:** minimiza custo total (fixo de abertura + variável de serviço) e tempo médio de viagem. Variáveis: $\psi_i$ (abrir instalação $i$), $\zeta_{ij}$ (atribuição), $m_{ijz}$ (fração da demanda da zona atendida).
- **Restrições:** demanda totalmente servida; raio máximo de serviço; **orçamento**; e **limiar mínimo de demanda para abrir** — este último é exatamente o mecanismo de **massa crítica** por instalação.
- **Equidade:** compara LSCP, MCLP, p‑mediana e p‑centro; discute proximidade a pontos de ônibus como métrica de acesso.
- **Demanda:** dados de TNC e táxi da região metropolitana de Chicago, filtrados por limiares de tempo/distância.
- **Solver:** GA para UVLP/CVLP; IP/LP para LSCP, MCLP e p‑mediana; heurística para p‑centro.
- **Por que importa:** é o artigo de **equidade** pedido no enunciado, e o único que compara **as quatro famílias clássicas lado a lado** no mesmo dataset de vertiportos. Modelo de comparação ideal para o relatório de vocês.

**[8] Volakakis, V. & Mahmassani, H.S. (2025).** *Strategic Vertiport Placement for Airport Access: Utilizing Urban Air Mobility for Accelerated and Reliable Transportation.* **Infrastructures** 10(9), 242. DOI [10.3390/infrastructures10090242](https://doi.org/10.3390/infrastructures10090242)
- **Formulação:** **a‑CFLP** (capacitated facility location adaptado) e **a‑MCLP** (maximal covering com capacidade), este último em MILP.
- **Demanda:** identifica demanda UAM potencial a partir de auto, transporte público, táxi e ride‑hailing por limiares de tempo/distância. Cenário moderado: 6.124 solicitações/dia em Chicago.
- **Acesso terrestre:** foco em acesso/egresso aeroportuário; constata **maior sensibilidade ao tempo no acesso do que no egresso** — assimetria relevante para SP (CGH/GRU/VCP).
- **Resultado‑chave:** **5 a 12 vertiportos bastam para >95% de cobertura da demanda** — ordem de grandeza diretamente transferível para o caso de SP.
- **Solver:** k‑means capacitado adaptado, heurística gulosa e MILP.

**[9] Hagspihl, T., Kolisch, R. & Schiffels, S. (2025).** *Planning an airport shuttle network with air taxis using choice‑based optimization.* **OR Spectrum** 47, 1–35. DOI [10.1007/s00291-024-00801-y](https://doi.org/10.1007/s00291-024-00801-y)
- **Formulação:** **MILP com restrições de logit multinomial linearizadas**; problema de **hub location não‑capacitado com alocação múltipla e demanda endógena**.
- **FO:** maximizar o número de passageiros que escolhem itinerários com air taxi para acesso aeroportuário.
- **Demanda:** MNL sobre 4 tipos de itinerário — carro direto, transporte público direto, carro→air taxi, TP→air taxi. **Demanda endógena**: depende das localizações via probabilidades de escolha.
- **Instância:** 1.125 CEPs na Baviera, **24 vertiportos candidatos**, 7.376.700 pax/ano.
- **Solver: [não confirmado]** (contexto sugere CPLEX).
- **Por que importa:** demonstra que uma instância com ~1.100 origens × 24 candidatos é **resolvível exatamente** — ordem de grandeza perfeitamente compatível com 517 zonas OD de SP × 40–80 candidatos.

**[10] Jin, Z., Ng, K.K.H. & Zhang, C. (2024).** *Robust optimisation for vertiport location problem considering travel mode choice behaviour in urban air mobility systems.* **Journal of the Air Transport Research Society**, 100006. DOI [10.1016/j.jatrs.2024.100006](https://doi.org/10.1016/j.jatrs.2024.100006)
- Otimização robusta (incerteza poliédrica) sobre localização de vertiportos com comportamento de escolha modal. Base bibliográfica excelente (48 referências mapeadas via [OUCI](https://ouci.dntb.gov.ua/en/works/ldOdoBD4/)). **[detalhes de instância/solver não confirmados]**

**[11] Kitthamkesorn, S. & Chen, A. (2024).** *Maximum capture problem for urban air mobility network design.* **Transportation Research Part E: Logistics and Transportation Review**, 103569. DOI [10.1016/j.tre.2024.103569](https://doi.org/10.1016/j.tre.2024.103569)
- Traz o **Maximum Capture Problem** (localização competitiva) para UAM. Os mesmos autores publicaram a versão park‑and‑ride com modelo weibit combinatório pareado (TR‑B 179, 102855). **[FO, instância e solver não confirmados]**

**[12] Brunelli, M., Ditta, C.C. & Postorino, M.N. (2023).** *New infrastructures for Urban Air Mobility systems: A systematic review on vertiport location and capacity.* **Journal of Air Transport Management** 112, 102460. DOI [10.1016/j.jairtraman.2023.102460](https://doi.org/10.1016/j.jairtraman.2023.102460)
- Revisão sistemática; conclui que "posição e capacidade do vertiporto, com seus fatores relevantes, estão entre os aspectos mais críticos da UAM, que podem limitar fortemente seu desenvolvimento". **É a referência obrigatória de enquadramento.** Conclusões detalhadas sobre modelos e lacunas **[não confirmadas — texto integral em paywall]**.

**[13] Fadhil, D.N. (2018).** *A GIS‑based Analysis for Selecting Ground Infrastructure Locations for Urban Air Mobility.* Dissertação de Mestrado, **Technical University of Munich**. *(Confirmada via lista de referências de Jin et al. 2024; existe versão em conferência/RG com o mesmo título — vínculo editorial exato **não confirmado**.)*
- Abordagem **multicritério GIS**, não‑MILP: cruza camadas socioeconômicas, uso do solo e restrições de airspace para ranquear sítios. Serve como **gerador de candidatos** $J$ — exatamente o papel que deve ter no trabalho de vocês (pré‑processamento espacial em `sf`, não a otimização em si).

**[14] Rimjha, M., Hotle, S., Trani, A. & Hinze, N. (2021).** *Commuter demand estimation and feasibility assessment for Urban Air Mobility in Northern California.* **Transportation Research Part A** 148, 506–524. DOI [10.1016/j.tra.2021.03.020](https://doi.org/10.1016/j.tra.2021.03.020)
- Não é modelo de localização — é **estimação de demanda e viabilidade**. Análise de sensibilidade a **preço por passageiro‑milha e número/distribuição de vertiportos**. Conclusões duras: demanda economicamente viável exige tarifas irrealisticamente baixas dado o custo imobiliário; confiabilidade precisa igualar a do automóvel; padrões de *commute* fortemente direcionais (Financial District de SF como hub dominante). Recomendam incluir propósitos além de *commuting*.

**[15] Rimjha, M., Hotle, S., Trani, A., Hinze, N., Smith, J. & Dollyhigh, S. (2021).** *Urban Air Mobility: Airport Ground Access Demand Estimation.* **AIAA Aviation 2021 Forum**. DOI [10.2514/6.2021-3209](https://doi.org/10.2514/6.2021-3209) — [PDF VTechWorks](https://vtechworks.lib.vt.edu/server/api/core/bitstreams/e1f86645-229e-4046-a515-30fc7c364f3d/content)
- **Demanda:** dois logits condicionais (negócios / não‑negócios) com variáveis genéricas (tempo, custo, distância).
- **Localização:** **Fuzzy C‑means** — (i) estima potencial UAM por *census block group*; (ii) clusteriza para gerar candidatos; (iii) remove clusters em airspace inviável; (iv) seleciona subconjunto maximizando *membership*.
- **Parâmetros operacionais explícitos e reutilizáveis:** distância mínima de voo 10 milhas; caminhada ≤0,1 milha ao vertiporto; ride‑share para distâncias maiores; **5 min de ingresso/egresso**; velocidade média 120 mph; load factor 60% (2,4 pax/veículo).
- **Instância:** 4.801 census block groups, 12 condados de Dallas‑Fort Worth, 6,82M hab. (2015); 45.070 viagens UAM‑elegíveis/dia.
- **Nota:** o pedido mencionava "Chicago". Confirmei **Norte da Califórnia** [14] e **DFW** [15] em Rimjha et al.; os estudos de Chicago são de **Volakakis & Mahmassani** [7,8]. Há ainda um artigo de 2026 no *JATM* sobre "mobile location data" para Chicago **[autoria não confirmada]**.

**[16] Ribeiro, J.K., Borille, G.M.R., Caetano, M. & Silva, E.J. (2023).** *Repurposing urban air mobility infrastructure for sustainable transportation in metropolitan cities: A case study of vertiports in São Paulo, Brazil.* **Sustainable Cities and Society** 98, 104797. DOI [10.1016/j.scs.2023.104797](https://doi.org/10.1016/j.scs.2023.104797)
- **Referência brasileira central** (Borille e Caetano são do ITA). Trata do **reaproveitamento de helipontos existentes de SP** como vertiportos — isto é, define naturalmente o conjunto $J$ de candidatos com custo fixo $f_j$ diferenciado (retrofit ≪ greenfield). **[formulação matemática e instância não confirmadas — paywall]**

**[17] Carvalho, L.O., Gomes, I.G., Rodrigues, J.F., Murça, M.C.R., Guterres, M.X. & Pamplona, D.A. (2026).** *Data‑driven framework for urban air mobility planning: Integrating socioeconomic and operational factors for optimal network design in São Paulo, Brazil.* **Case Studies on Transport Policy** 25, 101848. DOI [10.1016/j.cstp.2026.101848](https://doi.org/10.1016/j.cstp.2026.101848) — preprint SSRN [10.2139/ssrn.6240121](https://doi.org/10.2139/ssrn.6240121); divulgação [INFRA‑ITA](https://infraita.wordpress.com/2026/05/15/publicado-estudo-sobre-mobilidade-aerea-urbana-na-grande-sao-paulo/)
- **É literalmente o estado da arte do seu próprio departamento.** Três eixos: **localização de vertiportos, otimização de rotas e previsão de demanda OD** na RMSP, integrando fatores socioeconômicos e operacionais. **Leitura obrigatória e provável orientação metodológica do professor.** Detalhes de formulação/instância **[não confirmados — paywall]**.
- *Correção:* a página do INFRA‑ITA descreve o periódico por sigla; o *container‑title* confirmado no Crossref é **Case Studies on Transport Policy**.

**[18] Lopes, D. & Silva, J. (2023).** *Urban air mobility (UAM) in the metropolitan region of São Paulo: Potential and threats.* **Journal of Airline and Airport Management**, pp. 1–11. DOI [10.3926/jairm.345](https://doi.org/10.3926/jairm.345) — [texto integral, UPCommons](https://upcommons.upc.edu/entities/publication/826b78db-37b9-49ff-ad58-683a8296ec72)
- Survey de percepção de potenciais clientes na RMSP, espelhando estudo europeu para comparação. Não é OR, mas **fornece os parâmetros comportamentais brasileiros** (disposição a pagar, medos, restrições) que faltam para calibrar qualquer logit em SP. **[volume/número: a fonte indica "vol. 23, n.1" — provável erro de metadados; não confirmado]**

### 2.3 Referências complementares confirmadas (úteis mas secundárias)
- **Ale‑Ahmad, H. & Mahmassani, H.S. (2021).** *Capacitated Location‑Allocation‑Routing Problem with Time Windows for On‑Demand Urban Air Taxi Operation.* **Transportation Research Record** 2675, 1092. DOI [10.1177/03611981211014892](https://doi.org/10.1177/03611981211014892)
- **Rajendran et al. (2019).** *Insights on strategic air taxi network infrastructure locations using an iterative constrained clustering approach.* **TR‑E** 128, 470–490. DOI [10.1016/j.tre.2019.06.003](https://doi.org/10.1016/j.tre.2019.06.003) **[coautoria não confirmada]**
- **Sinha et al. (2021).** *A novel two‑phase location analytics model for determining operating station locations of emerging air taxi services.* **Decision Analytics Journal** 2, 100013. DOI [10.1016/j.dajour.2021.100013](https://doi.org/10.1016/j.dajour.2021.100013) **[autoria não confirmada]**
- **Kai et al. (2022).** *Vertiport planning for urban aerial mobility: An adaptive discretization approach.* **M&SOM** 24. DOI [10.1287/msom.2022.1148](https://doi.org/10.1287/msom.2022.1148) **[autoria completa não confirmada]**
- **Jeong et al. (2021).** *Selection of vertiports using k‑means algorithm and noise analyses for UAM in the Seoul metropolitan area.* **Applied Sciences** 11, 5729. DOI [10.3390/app11125729](https://doi.org/10.3390/app11125729) **[autoria completa não confirmada]** — *nota: não é o "Jeong/Roy/Chow" mencionado no pedido; não localizei publicação com essa tripla autoria.*
- **Lim, E. & Hwang, H. (2019).** *The Selection of Vertiport Location for On‑Demand Mobility and Its Application to Seoul Metro Area.* **IJASS** 20, 260–272. DOI [10.1007/s42405-018-0117-0](https://doi.org/10.1007/s42405-018-0117-0) — **k‑means + silhueta**, não otimização; 18 cenários com 2 a 36 vertiportos, comparando tempo de viagem ODM vs. terrestre. **Este é o precedente mais próximo de "curva de implantação" na literatura** — e é fraco justamente por não ser um modelo de otimização.
- **Holden, J. & Goel, N. (2016).** *Fast‑Forwarding to a Future of On‑Demand Urban Air Transportation.* Uber Elevate white paper. [PDF](https://evtol.news/__media/PDFs/UberElevateWhitePaperOct2016.pdf)
- **Voom (Airbus/A³)** — serviço de helicóptero sob demanda operado em **São Paulo** a partir de 2017, encerrado em 2020. Fonte jornalística: [AIN](https://www.ainonline.com/aviation-news/business-aviation/2018-02-14/airbus-helicopters-rolling-out-air-taxi-booking-service), [Vertical Mag](https://verticalmag.com/news/airbus-helicopter-voom-ceases-operations/). **Não há white paper acadêmico da Voom com dados abertos** — não use como fonte de demanda.

### 2.4 Dados brasileiros para instanciar o modelo
- **Pesquisa Origem‑Destino Metrô‑SP 2017:** **517 zonas OD**, **39 municípios**, **42 milhões de viagens/dia** (28,3M motorizadas: 15,3M coletivo, 13,0M individual; 13,7M não‑motorizadas). [Relatório síntese (PDF)](https://www.mobilize.org.br/midias/pesquisas/pesquisa-origem-destino-2017-da-rmsp.pdf) · [Portal da Transparência Metrô](https://transparencia.metrosp.com.br/dataset/pesquisa-origem-e-destino) (ZIPs 1977/1987/1997/2007/2017).
- **Pesquisa OD 2023:** 32.000 domicílios, ~79.000 pessoas (campo ago/2023–mai/2024). [Metrô‑SP](https://www.metro.sp.gov.br/pt_BR/pesquisa-od/). Contagem de zonas para 2023 **[não confirmada]**.
- **Shapefile de zonas OD:** [GeoSampa / metadados PRODAM](https://metadados.geosampa.prefeitura.sp.gov.br/geonetwork/geoprodam/api/records/4ed47f83-653f-43ad-9883-4137dbbfaee1).
- **Helipontos:** ~**200 helipontos** na cidade de São Paulo; frota brasileira ≈2.125 helicópteros (ABRAPHE, 2020). Fonte secundária: [Flight Consultoria](https://flightconsultoria.com.br/helicopteros-e-helipontos-em-numeros-brasil/). **Para o trabalho, use a fonte primária: cadastro de aeródromos/helipontos da ANAC e do DECEA (AIP‑Brasil / ROTAER)** — a contagem de ~200 é jornalística e **não confirmada oficialmente**.

---

## 3) LACUNA — o que a literatura NÃO resolve bem

**L1. Cobertura unilateral vs. bilateral (a lacuna mais explorável).**
Praticamente toda a literatura aplicada de vertiportos que usa modelos *lineares* (Volakakis & Mahmassani 2024, 2025; adaptações de MCLP/CFLP) trata cobertura como **unilateral**: a zona está coberta se houver um vertiporto próximo. Mas a viagem eVTOL só existe se houver vertiporto **na origem E no destino**. Os trabalhos que capturam isso corretamente ou usam hub location clássico com demanda **inelástica** (Chen et al. 2022; Willey & Salmon 2021) ou pagam com meta‑heurísticas que **destroem a análise de dualidade e relaxação** (Jiang et al. 2025; Volakakis & Mahmassani 2024 usam GA). **Ninguém entrega um MILP compacto, exato, com cobertura bilateral e leitura de duais.**

**L2. Massa crítica é declarada, quase nunca modelada.**
Brunelli et al. (2023) e todos os *surveys* apontam massa crítica de rede como crítica. Mas na formulação matemática ela quase sempre desaparece, ou aparece de forma degradada como limiar mínimo de demanda por instalação (Volakakis & Mahmassani 2024). O mecanismo estrutural de massa crítica — **o benefício é superaditivo nos vertiportos abertos** — existe em forma canônica na literatura clássica (FRLM de Kuby & Lim 2005, restrição $v_h\le y_k$) e **nunca foi transposto para vertiportos**. Consequência analítica: com cobertura bilateral a FO **deixa de ser submodular**, e a **curva de implantação vira um S** (convexa no início, côncava depois) em vez de côncava. Isso é demonstrável numericamente com o solver e é uma contribuição defensável e original em nível de graduação.

**L3. Porta‑a‑porta é assimétrico e quase sempre simplificado.**
Wu & Zhang (2021) modelam 6 modos de acesso, mas o fazem com regra determinística de valor do tempo. Rimjha et al. (2021) usam logit calibrado, mas escolhem vertiportos por *fuzzy c‑means*, sem otimização. Volakakis & Mahmassani (2025) constatam que a sensibilidade ao tempo **difere entre acesso e egresso**, mas o modelo não a explora. **Não há trabalho que combine (a) otimização exata, (b) acesso e egresso assimétricos e (c) o modo terrestre concorrente explicitado como alternativa "não fazer nada".**

**L4. Ausência quase total do contexto brasileiro em modelos matemáticos.**
Os três trabalhos sobre SP são: reaproveitamento de helipontos (Ribeiro et al. 2023, estudo de caso), survey de percepção (Lopes & Silva 2023) e o framework data‑driven do próprio ITA (Carvalho et al. 2026). São Paulo é o caso mais interessante do mundo para UAM — **maior frota urbana de helicópteros do planeta, ~200 helipontos já construídos, congestionamento extremo e desigualdade espacial brutal** — e a literatura internacional de otimização praticamente não a usa. O conjunto de candidatos $J$ já existe fisicamente, o que remove a maior fonte de arbitrariedade dos trabalhos de Chicago/Munique/Pequim.

**L5. Curva de implantação nunca é analisada como objeto teórico.**
Lim & Hwang (2019) rodam 18 cenários de 2 a 36 vertiportos, mas por clusterização, sem ótimo garantido e sem interpretação econômica. Volakakis & Mahmassani (2025) reportam "5 a 12 vertiportos ⇒ >95% cobertura" como resultado empírico, não como curva com preço‑sombra. **Ninguém liga a curva de implantação ao dual da restrição de cardinalidade**, que é a leitura correta e a que TRA‑48 explicitamente exige.

**L6. Equidade tratada como métrica ex‑post.**
Volakakis & Mahmassani (2024) é o melhor trabalho de equidade, mas compara famílias clássicas *a posteriori*. Não há modelo que internalize equidade como restrição (ex.: fração mínima de vertiportos fora do quadrante sudoeste; ou $\varepsilon$‑constraint sobre p‑centro). Em SP — onde a UAM tem risco real de ser infraestrutura pública para o Itaim/Faria Lima — isso é politicamente e academicamente relevante.

### Onde um grupo de graduação se diferencia
> **Um MILP compacto de "cobertura bilateral de fluxo porta‑a‑porta com massa crítica", aplicado aos helipontos reais de São Paulo com a matriz OD do Metrô, resolvido exatamente, com relaxação LP, duais interpretados e curva de implantação em S demonstrada numericamente.**

É defensável, é original o suficiente, é honesto sobre suas limitações e — crucialmente — é **totalmente executável em 5 semanas em R**.

---

## 4) RECOMENDAÇÃO — 3 caminhos de formulação (R, 5 semanas)

**Stack recomendado:** `sf` + `dplyr` (pré‑processamento espacial e matrizes de tempo), `ompr` + `ompr.roi` + `ROI.plugin.highs` (modelagem algébrica), `highs` (solver, MIT/open‑source, com **duais e valores de relaxação**), `ggplot2` para as curvas.
⚠️ **Alerta prático de engenharia:** `ompr` constrói o modelo em R puro e fica **muito lento** acima de ~$10^5$ variáveis. Se a instância crescer, monte a matriz de restrições diretamente com `Matrix::sparseMatrix()` e chame `highs::highs_solve()`. Planeje isso desde a semana 1. `lpSolve` só para protótipos didáticos pequenos (não escala e tem interface pobre para duais em MIP).

---

### CAMINHO 1 — **MCLP de Fluxo Bilateral Porta‑a‑Porta** ⭐ *melhor relação esforço/qualidade*

**Ideia:** híbrido MCLP × Flow‑Interception × p‑hub mediana. A unidade de cobertura não é a zona, é o **par OD**; e um par só é coberto se **dois** vertiportos estiverem abertos.

**Conjuntos e parâmetros**
- $I$: zonas OD (RMSP). $J$: candidatos (helipontos ANAC/DECEA + sítios GIS).
- $Q\subseteq I\times I$: pares OD **elegíveis** (pré‑filtrados: $f_q>0$ e distância euclidiana $\ge 15$ km).
- $f_q$: viagens/dia do par $q=(o,d)$ (matriz OD Metrô 2017/2023).
- $T^{\text{ter}}_q$: tempo terrestre porta‑a‑porta (modo concorrente).
- $t^{\text{acc}}_{oj}$, $t^{\text{egr}}_{kd}$: tempos de acesso/egresso terrestres; $t^{\text{voo}}_{jk}$: tempo de voo + $\tau_{\text{proc}}$ (embarque/desembarque, ~5 min cada, cf. Rimjha et al. 2021).
- Tempo porta‑a‑porta via par de vertiportos $(j,k)$:
$$T^{\text{uam}}_{qjk}=t^{\text{acc}}_{oj}+\tau_{\text{emb}}+t^{\text{voo}}_{jk}+\tau_{\text{des}}+t^{\text{egr}}_{kd}$$
- **Economia**: $\Delta_{qjk}=T^{\text{ter}}_q-T^{\text{uam}}_{qjk}$.
- **Conjunto viável** (pré‑processamento — o coração da tratabilidade, à la Wu & Zhang 2021):
$$P_q=\{(j,k)\in J\times J:\ j\ne k,\ t^{\text{acc}}_{oj}\le \bar t,\ t^{\text{egr}}_{kd}\le \bar t,\ \Delta_{qjk}\ge \theta\}$$

**Variáveis**
- $y_j\in\{0,1\}$: abre vertiporto $j$.
- $w_{qjk}\in[0,1]$: fração do fluxo $q$ roteada via $(j,k)$.

**Modelo (P1)**
$$
\begin{aligned}
\max\quad & Z=\sum_{q\in Q}\ \sum_{(j,k)\in P_q} f_q\,\Delta_{qjk}\,w_{qjk} \\[4pt]
\text{s.a.}\quad
& \sum_{(j,k)\in P_q} w_{qjk} \ \le\ 1 && \forall q\in Q && (\alpha_q)\\
& w_{qjk} \ \le\ y_j && \forall q,\ (j,k)\in P_q && (\mu^{\text{o}}_{qjk})\\
& w_{qjk} \ \le\ y_k && \forall q,\ (j,k)\in P_q && (\mu^{\text{d}}_{qjk})\\
& \sum_{j\in J} y_j \ \le\ p && && (\pi)\\
& w_{qjk}\ge 0,\qquad y_j\in\{0,1\}
\end{aligned}
$$

**Extensões de 10 linhas cada (escolham 1–2):**
- **Capacidade de FATO:** $\displaystyle\sum_{q}\sum_{k} f_q\,(w_{qjk}+w_{qkj}) \le C_j\,y_j\quad\forall j\qquad(\gamma_j)$
- **Massa crítica por vertiporto:** $\displaystyle\sum_{q}\sum_{k} f_q(w_{qjk}+w_{qkj}) \ge m\,y_j\quad\forall j$ — não abre vertiporto abaixo do throughput mínimo viável.
- **Custo fixo (endogeneiza $p$):** troque $\sum_j y_j\le p$ por $-\sum_j f^{\text{fix}}_j y_j$ na FO (converta $\Delta$ em R$ via valor do tempo).
- **Equidade:** $\sum_{j\in J_{\text{periferia}}} y_j \ge \lceil \rho p\rceil$, e parametrize $\rho$.

**Tamanho da instância (dimensionamento real para SP)**
| Componente | Valor |
|---|---|
| Zonas OD (agregadas de 517 para ~120 macrozonas) | $|I|\approx 120$ |
| Candidatos (helipontos + GIS) | $|J| = 40$–$60$ |
| Pares OD brutos | $120^2 \approx 14.400$ |
| Pares elegíveis após filtro ($\ge$15 km, $f_q>0$) | $|Q|\approx 2.000$–$4.000$ |
| $|P_q|$ médio após filtro de $\bar t$ e $\theta$ | $\approx 20$–$60$ |
| **Variáveis $w$** | $\approx 4\times10^4$–$2\times10^5$ |
| **Variáveis binárias** | **40–60** ← trivial para B&B |
| **Tempo esperado (HiGHS)** | **segundos a poucos minutos** |

O que torna isso fácil não é o tamanho: são as **poucas binárias**. Com $|J|\le 60$, HiGHS resolve confortavelmente. Se `ompr` engasgar na construção, use `sparseMatrix`.

**As 4 análises da disciplina:**
1. **Relaxação linear.** Compare a formulação **desagregada** acima com a **agregada** $\sum_{(j,k)\in P_q} w_{qjk}\le \tfrac{1}{2}(y_j+y_k)$ ou $\sum_q w_{qjk}\le |Q|\,y_j$. Reporte $Z_{LP}$, $Z_{IP}$ e o *gap* de integralidade das duas. A desagregada é muito mais forte — essa comparação sozinha vale uma seção do relatório. Discuta por que a relaxação de MCLP puro é quase‑integral e por que a **cobertura bilateral quebra essa propriedade** (as duas restrições $w\le y_j$, $w\le y_k$ criam soluções fracionárias $y_j=y_k=0{,}5$).
2. **Dual.** $\pi$ (dual de $\sum y_j\le p$) = **economia marginal de tempo‑passageiro por vertiporto adicional** [pax·min/dia por vertiporto] — a inclinação da curva de implantação. $\gamma_j$ = **preço‑sombra da capacidade do vertiporto $j$** (justificativa econômica para um FATO extra). $\alpha_q$ = valor de servir o par $q$ (ranking de corredores prioritários). Extraia com `ROI::solution(sol, "dual")` sobre a relaxação LP.
3. **Sensibilidade.** Varie: $\bar t$ (raio máximo de acesso: 10/15/20/30 min) → mede quanto a UAM depende do *first/last mile*; $\theta$ (economia mínima aceita: 0/10/20/30 min) → mede a fragilidade da proposta de valor; $C_j$; valor do tempo; e o custo tarifário se usar a versão monetária. Faça a curva $Z^*(\bar t)$ e $Z^*(\theta)$.
4. **Curva de implantação.** Resolva para $p=1,2,\dots,25$ e plote $Z^*(p)$. **Previsão teórica:** por causa da cobertura bilateral, $Z^*(1)=0$ (um vertiporto sozinho não serve nenhum par) e a curva será **convexa no início** e côncava depois — o formato em **S** que é a assinatura da **massa crítica de rede**. Compare com a curva de um MCLP unilateral rodado no mesmo dado, que será côncava desde $p=1$. Essa figura única é o resultado central do trabalho.

---

### CAMINHO 2 — **CFLP/Hub capacitado com custo fixo** *(baseline seguro, menor risco)*

Réplica adaptada de Volakakis & Mahmassani (2025): a‑CFLP + a‑MCLP capacitado, mas em versão **unilateral** (alocação zona → vertiporto), aplicada a acesso a **CGH/GRU/VCP** — problema de *airport access*, não de rede ponto‑a‑ponto.

$$
\begin{aligned}
\min\quad & \sum_{j\in J} f_j\,y_j + \sum_{i\in I}\sum_{j\in J} h_i\,c_{ij}\,x_{ij}\\
\text{s.a.}\quad & \sum_{j\in N_i} x_{ij}=1\ \ \forall i;\quad x_{ij}\le y_j;\quad \sum_i h_i x_{ij}\le C_j y_j\ (\gamma_j);\quad \sum_j f_j y_j\le B\ (\beta)
\end{aligned}
$$

- **Instância tratável:** $|I|=517$ zonas OD (sem agregar!), $|J|=60$, ~31.000 variáveis contínuas + 60 binárias. Resolve em segundos.
- **Prós:** menor risco, resultados garantidos, literatura de referência direta e recente, permite todas as 4 análises (duais $\gamma_j$ e $\beta$ são muito limpos; a curva de implantação sai variando $B$).
- **Contras:** **não captura interdependência nem massa crítica** — que é exatamente o que o enunciado de TRA‑48 pede. Use como **baseline de comparação** dentro do Caminho 1, não como entrega principal. Rodar os dois e comparar as soluções é, aliás, excelente material de relatório.
- **Esforço:** ~1,5 semana. **Qualidade relativa:** média. **Relação:** boa, mas teto baixo.

---

### CAMINHO 3 — **Hub location com demanda elástica (logit linearizado)** *(ambicioso, alto risco)*

Réplica de Rath & Chow (2022) / Hagspihl et al. (2025): a demanda deixa de ser um limiar determinístico e passa a ser **endógena**, via probabilidade logit de escolher UAM contra o modo terrestre.

$$
P^{\text{uam}}_{qjk}=\frac{e^{V^{\text{uam}}_{qjk}}}{e^{V^{\text{uam}}_{qjk}}+e^{V^{\text{ter}}_{q}}},\qquad
V^{\text{uam}}_{qjk}=\beta_t T^{\text{uam}}_{qjk}+\beta_c c^{\text{uam}}_{qjk}
$$

$$
\max\ \sum_{q}\sum_{(j,k)} f_q\, P^{\text{uam}}_{qjk}\, w_{qjk}
\quad\text{s.a. as mesmas restrições de (P1)}
$$

- **Truque de linearização** (é o que Rath & Chow fazem): **pré‑calcule** $P^{\text{uam}}_{qjk}$ fora do modelo, já que $(j,k)$ é enumerado. O modelo permanece **MILP puro** — a não‑linearidade some no pré‑processamento. Só há não‑convexidade real se você quiser *tarifa endógena* ou *sobreposição de alternativas* (não façam isso em 5 semanas).
- **Instância:** mesma do Caminho 1. Custo adicional: apenas o pré‑cálculo das probabilidades.
- **Risco real:** **calibração de $\beta_t,\beta_c$.** Não há logit calibrado para UAM no Brasil. Opções: (a) transplantar coeficientes de Rimjha et al. (2021) ou Fu et al. (2019, Munique, TRR 2673, 427, DOI [10.1177/0361198119843858](https://doi.org/10.1177/0361198119843858)) e declarar isso como limitação; (b) usar Lopes & Silva (2023) para ancorar disposição a pagar brasileira; (c) rodar $\beta$'s como cenários de sensibilidade. **A opção (c) transforma o risco em uma das quatro análises exigidas** — é a jogada certa.
- **Análises:** idênticas ao Caminho 1, com bônus: a curva de implantação agora é **suave e diferenciável** na demanda, e a análise de sensibilidade em $\beta_c$ vira **curva tarifa × demanda capturada**, que responde diretamente à conclusão pessimista de Rimjha et al. (2021).
- **Esforço:** Caminho 1 + ~1 semana. **Recomendação:** implemente o Caminho 1 primeiro e completo; só acrescente o logit se sobrar tempo na semana 4.

---

### Ordenação final e cronograma

| Ordem | Caminho | Esforço | Qualidade | Relação |
|---|---|---|---|---|
| **1º** | **MCLP de fluxo bilateral (P1)** | Média (2,5 sem.) | **Alta** — única que entrega porta‑a‑porta + interdependência + massa crítica em MILP exato | ★★★★★ |
| **2º** | CFLP/hub capacitado (baseline) | Baixa (1,5 sem.) | Média | ★★★★☆ |
| **3º** | Hub + logit elástico | Alta (3,5 sem.) | Muito alta | ★★★☆☆ |

**Cronograma sugerido (5 semanas):**
- **S1** — Dados: matriz OD Metrô (`sf`, agregação 517→~120 macrozonas), cadastro de helipontos ANAC/DECEA, matriz de tempos terrestres (OSRM local ou impedância da própria OD), tempos de voo (grande círculo / velocidade de cruzeiro eVTOL ~200 km/h). Leitura obrigatória: Carvalho et al. (2026), Ribeiro et al. (2023), Brunelli et al. (2023).
- **S2** — Pré‑processamento: construir $Q$, $P_q$, $\Delta_{qjk}$. **Meça $|Q|$ e $\sum_q|P_q|$ antes de escrever o modelo** — se passar de $2\times10^5$, aperte $\bar t$ e $\theta$ ou agregue mais zonas.
- **S3** — Implementar (P1) em `ompr`/HiGHS. Rodar o baseline CFLP (Caminho 2) no mesmo dado. Validar com instância‑brinquedo de 5 zonas resolvida à mão.
- **S4** — As 4 análises: relaxação (desagregada vs. agregada), duais ($\pi,\gamma_j,\alpha_q$), sensibilidade ($\bar t,\theta$, VoT, capacidade), curva de implantação $p=1..25$ e a demonstração do formato em S.
- **S5** — Extensão (massa crítica ou equidade), redação, mapas em `sf`/`ggplot2`.

---

## Sources

- [Hakimi (1964), Operations Research](https://doi.org/10.1287/opre.12.3.450) · [ReVelle & Swain (1970)](https://onlinelibrary.wiley.com/doi/pdf/10.1111/j.1538-4632.1970.tb00142.x) · [Church & ReVelle (1974)](https://doi.org/10.1111/j.1435-5597.1974.tb00902.x) · [Toregas et al. (1971)](https://doi.org/10.1287/opre.19.6.1363) · [Balinski (1965)](https://pubsonline.informs.org/doi/10.1287/mnsc.12.3.253)
- [O'Kelly (1987)](https://doi.org/10.1016/s0377-2217(87)80007-3) · [O'Kelly (1992)](https://onlinelibrary.wiley.com/doi/pdf/10.1111/j.1435-5597.1992.tb01848.x) · [Campbell (1994)](https://doi.org/10.1016/0377-2217(94)90318-2) · [Kara & Tansel (2003)](https://doi.org/10.1057/palgrave.jors.2601473) · [Ernst & Krishnamoorthy (1999)](https://link.springer.com/article/10.1023/A:1018994432663) · [Campbell & O'Kelly (2012)](https://pubsonline.informs.org/doi/abs/10.1287/trsc.1120.0410)
- [Hodgson (1990)](https://doi.org/10.1111/j.1538-4632.1990.tb00210.x) · [Berman, Larson & Fouska (1992)](https://pubsonline.informs.org/doi/10.1287/trsc.26.3.201) · [Kuby & Lim (2005)](https://doi.org/10.1016/j.seps.2004.03.001)
- [Wu & Zhang (2021), Engineering](https://www.engineering.org.cn/engi/EN/10.1016/j.eng.2020.11.007) · [Rath & Chow, ar5iv](https://ar5iv.labs.arxiv.org/html/1904.01497) · [Willey & Salmon (2021)](https://ui.adsabs.harvard.edu/abs/2021TRPC..12502997W/abstract) · [Chen et al. (2022), RePEc](https://ideas.repec.org/a/inm/orijoc/v34y2022i2p834-856.html) + [código](https://github.com/ScalableVertiportLocationProblem/ScalableVertiportHLP) · [Jiang et al. (2025), RePEc](https://ideas.repec.org/a/eee/transa/v192y2025ics0965856424004014.html)
- [Volakakis & Mahmassani (2024), MDPI](https://www.mdpi.com/2412-3811/9/12/239) · [Volakakis & Mahmassani (2025), MDPI](https://www.mdpi.com/2412-3811/10/9/242) · [Hagspihl et al. (2025), OR Spectrum](https://link.springer.com/article/10.1007/s00291-024-00801-y) · [Jin, Ng & Zhang (2024), OUCI](https://ouci.dntb.gov.ua/en/works/ldOdoBD4/) · [Kitthamkesorn & Chen (2024), OUCI](https://ouci.dntb.gov.ua/en/works/96nEMmr9/) · [Brunelli et al. (2023), RePEc](https://ideas.repec.org/a/eee/jaitra/v112y2023ics0969699723001035.html)
- [Rimjha et al. (2021), TRA — RePEc](https://ideas.repec.org/a/eee/transa/v148y2021icp506-524.html) · [Rimjha et al. (2021), AIAA — VTechWorks PDF](https://vtechworks.lib.vt.edu/server/api/core/bitstreams/e1f86645-229e-4046-a515-30fc7c364f3d/content) · [Lim & Hwang (2019), Springer](https://link.springer.com/article/10.1007/s42405-018-0117-0) · [Uber Elevate white paper](https://evtol.news/__media/PDFs/UberElevateWhitePaperOct2016.pdf)
- **Brasil/SP:** [Ribeiro et al. (2023) — Crossref](https://api.crossref.org/works/10.1016/j.scs.2023.104797) · [Carvalho et al. (2026), SSRN](https://doi.org/10.2139/ssrn.6240121) e [divulgação INFRA‑ITA](https://infraita.wordpress.com/2026/05/15/publicado-estudo-sobre-mobilidade-aerea-urbana-na-grande-sao-paulo/) · [Lopes & Silva (2023), UPCommons](https://upcommons.upc.edu/entities/publication/826b78db-37b9-49ff-ad58-683a8296ec72) · [Pesquisa OD 2017 (PDF)](https://www.mobilize.org.br/midias/pesquisas/pesquisa-origem-destino-2017-da-rmsp.pdf) · [Portal da Transparência Metrô](https://transparencia.metrosp.com.br/dataset/pesquisa-origem-e-destino) · [Pesquisa OD 2023](https://www.metro.sp.gov.br/pt_BR/pesquisa-od/) · [GeoSampa — zonas OD](https://metadados.geosampa.prefeitura.sp.gov.br/geonetwork/geoprodam/api/records/4ed47f83-653f-43ad-9883-4137dbbfaee1)

**Ressalva metodológica:** ScienceDirect e INFORMS bloqueiam acesso automatizado (robots.txt), de modo que os detalhes de formulação de Shin et al. (2021), Brunelli et al. (2023), Ribeiro et al. (2023) e Carvalho et al. (2026) foram confirmados apenas quanto a **metadados bibliográficos** (via Crossref/RePEc/OUCI), não quanto ao conteúdo integral. Recomendo obter esses quatro PDFs pela biblioteca do ITA antes de citar sua formulação matemática no relatório.agentId: a9406ddb84bae248c (use SendMessage with to: 'a9406ddb84bae248c', summary: '<5-10 word recap>' to continue this agent)
<usage>subagent_tokens: 151056
tool_uses: 100
duration_ms: 1974310</usage>