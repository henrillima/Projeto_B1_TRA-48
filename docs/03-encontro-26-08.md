# Pacote do 1º Encontro — 26/08/2026

> **Registro esperado no marco (§7.1):** *"decisão do recorte; fontes registradas"*
> **Regra do encontro (§7.2):** *"o ponto de partida é o site do grupo, não uma apresentação
> preparada para a ocasião — se o processo estiver sendo alimentado, não há nada a preparar."*

O objetivo deste documento não é virar slide. É virar **registros no banco antes do encontro**,
para que o site do grupo já esteja falando por vocês quando a reunião começar.

---

## Parte 1 — As metas (registrar primeiro, tudo se pendura nelas)

O enunciado pede **2 a 4 metas**, às quais todo o resto se vincula. Proposta:

```bash
./gov meta "Estimar a demanda de mobilidade paulistana plausivelmente capturável por UAM,
            a partir da Pesquisa OD do Metro-SP, com hipoteses explicitas e justificadas"

./gov meta "Formular e resolver um modelo MILP de localizacao de vertiportos que trate a
            viagem porta-a-porta, a interdependencia entre localizacoes e a massa critica
            de rede"

./gov meta "Produzir uma recomendacao defensavel sobre quantos e onde implantar vertiportos
            em Sao Paulo, sustentada por relaxacao linear, duais, sensibilidade e curva de
            implantacao"

./gov meta "Manter o projeto integralmente rastreavel e reprodutivel: toda decisao ligada a
            uma meta, todo resultado a um experimento, todo arquivo a uma decisao"
```

As três primeiras são as camadas do trabalho técnico; a quarta é a Camada B, e existir como meta
explícita é a diferença entre governança como disciplina e governança como burocracia.

---

## Parte 2 — As cinco decisões de recorte

O enunciado é direto: *"O recorte metodológico de cada grupo deve ser escolhido e registrado
como decisão até o primeiro encontro de acompanhamento"* (§2.6). Cada decisão registrada **exige
justificativa e alternativas descartadas** (§5.3).

### D1 — Recorte espacial: município de São Paulo, zonas OD agregadas

**Decisão:** modelar o **município de São Paulo** (não a RMSP inteira), com as zonas OD 2017
agregadas de 517 para ~120 macrozonas.

**Justificativa:** o próprio título do projeto diz "cidade de São Paulo". A OD 2017 tem 342 das
517 zonas dentro do município. A agregação é exigência de tratabilidade (§4.5) — formulação
direta sobre a base completa não é resolvível. Camadas complementares críticas (GeoSampa:
zoneamento, uso do solo, edificações) **cobrem apenas a capital**, então estender à RMSP
sacrificaria qualidade de dado sem ganho de escopo.

**Alternativas descartadas:**
- *RMSP completa (39 municípios, 517 zonas)* — instância maior, dados urbanísticos incompletos fora da capital, e não é o que o enunciado pede.
- *Recorte por subprefeituras* — geografia não bate com a das zonas OD; exigiria compatibilização areal que introduz erro sem necessidade.
- *Só o quadrilátero central expandido* — enviesaria o resultado para a conclusão que se quer testar (UAM como infraestrutura de elite), em vez de deixá-la emergir do modelo.

**Registrar também:** o critério exato de agregação (contiguidade? similaridade de fluxo?
distrito?) — isso é uma sub-decisão e vai ser perguntado.

---

### D2 — Base de demanda: OD 2017 (microdados), calibrada pela OD 2023

**Decisão:** usar os **microdados da OD 2017** como base de modelagem, com os agregados da
**OD 2023** como fator de correção de nível.

**Justificativa:** a OD 2017 é a edição mais recente com **microdados publicados** (`.sav`/`.dbf`,
+ shapefiles das zonas, + layout de variáveis, no `OD-2017.zip`). A OD 2023 até agora publicou
relatório-síntese e anexos, sem banco desagregado identificável. Como a OD 2023 mostra queda
real de 42 → 35,6 mi viagens/dia (efeito pós-pandemia), usar 2017 sem correção superestimaria a
demanda.

**Alternativas descartadas:**
- *OD 2023 pura* — sem microdados não há matriz OD por par de zonas com atributos de renda/motivo/duração, que é o insumo do filtro de captura.
- *Ignorar a OD 2023* — desonesto quanto à mudança estrutural pós-pandemia; a divisão modal inverteu (individual motorizado superou o coletivo pela primeira vez).
- *Dados de ride-hailing / celular* — não são públicos nem verificáveis por terceiros, e o enunciado exige fonte verificável (§3.2).

**⚠️ Verificar antes de registrar como definitivo:** abrir o `Site_190225_PesquisaOD2023.zip` e
confirmar se há ou não microdados dentro. Se houver, D2 muda inteiramente. Se não houver, vale
abrir pedido via e-SIC ao Metrô-SP pedindo o banco 2023 e a tabela de correspondência de zonas
2017↔2023 — o prazo da LAI cabe no cronograma se pedido esta semana.

---

### D3 — Fatia capturável: filtro em quatro camadas

**Decisão:** considerar capturável por UAM a viagem que satisfaça simultaneamente:

| Camada | Critério | Por quê |
|---|---|---|
| Distância | ≥ 15 km em linha reta | Abaixo disso o tempo de solo consome o ganho do ar |
| Duração terrestre | ≥ 45–60 min declarados na OD | A duração declarada já embute congestionamento real de SP |
| Motivo | Trabalho / negócios | Maior valor do tempo; segmento com disposição a pagar |
| Renda | Faixas superiores da OD | UAM é serviço premium; ignorar isso é fingir mercado |

**Justificativa:** o enunciado não sugere critérios de propósito (§3.3) — a estratégia e sua
sustentação são parte do que se avalia. Este filtro se apoia em: Wu & Zhang (2021), que filtram
por ≥10 milhas / ≥30 min e chegam a **0,20% de adoção** sobre 266.734 viagens candidatas;
Rimjha et al. (2021), que usam distância mínima de voo de 10 milhas e concluem que a viabilidade
econômica exige tarifas irrealisticamente baixas. **A literatura converge para "a fatia é pequena
e muito sensível à tarifa"** — um filtro generoso produziria demanda fantasma.

**Alternativas descartadas:**
- *Toda a matriz OD* — "um modelo de localização construído sobre demanda inventada é um exercício de aritmética" (§3.1). Seria isso.
- *Só filtro de distância* — captura viagens periféricas longas de baixa renda que não são o mercado real da UAM; infla o resultado.
- *Logit calibrado de escolha modal* — correto em tese, mas **não existe logit calibrado para UAM no Brasil**. Transplantar β's de Munique ou da Califórnia introduziria um parâmetro sem procedência brasileira. Fica como extensão da S4 e, melhor, como cenário de sensibilidade.

**Registrar os limiares como parâmetros, não como constantes** — eles viram a análise de
sensibilidade da S3.

---

### D4 — Conjunto de candidatos: helipontos existentes como base

**Decisão:** `J` = helipontos cadastrados na cidade de São Paulo (lista ANAC de aeródromos
privados, cruzada com ROTAER/DECEA), filtrados por viabilidade, mais alguns sítios adicionais
identificados por análise GIS (terminais de transporte, áreas com viabilidade urbanística).

**Justificativa:** São Paulo é, mundialmente, o caso em que essa decisão é mais fácil de defender —
a cidade **já tem a infraestrutura fisicamente construída**. Isso remove a maior fonte de
arbitrariedade dos trabalhos de Chicago, Munique e Pequim, onde os candidatos são inventados por
clusterização. É também o caminho de Ribeiro et al. (2023), que trata explicitamente do
reaproveitamento de helipontos de SP como vertiportos, e permite custo fixo `f_j` diferenciado
(retrofit ≪ greenfield) se o grupo for para a versão de custo fixo endógeno.

**Alternativas descartadas:**
- *Grade regular sobre a cidade* (Chen et al. 2022) — ignora que a infraestrutura já existe e que o licenciamento em SP é restritivo.
- *k-means / fuzzy c-means sobre a demanda* (Lim & Hwang 2019; Rimjha et al. 2021) — gera candidatos onde há demanda, o que **circularmente** garante boa cobertura e esvazia o problema de localização.
- *Só os grandes aeroportos (CGH/GRU/VCP)* — vira problema de acesso aeroportuário, não de rede urbana. Fica como o baseline do Caminho 2.

**Ação:** contar os helipontos vocês mesmos a partir da lista ANAC filtrada por município, com
data de extração registrada. **Não citem "X helipontos" de fonte jornalística** — os números que
circulam (200, 214, ~400) são inconsistentes e sem rastro. O único número oficial que encontrei
é de um release da ANAC de **2009** (214 helipontos abertos ao tráfego), 17 anos defasado.

**Nota de completude conhecida:** o cadastro municipal (SMUL/CONTRU) é estruturalmente
incompleto — helipontos aprovados antes de 23/10/2009 só entram no registro na renovação da
licença. Ou seja, **os helipontos mais consolidados são justamente os que podem faltar.**
Registrar isso como limitação da fonte vale mais na avaliação do que apresentar o dado sem
ressalva (§3.2).

---

### D5 — Formulação: MCLP de fluxo bilateral porta-a-porta

**Decisão:** MILP híbrido — cobertura máxima × interceptação de fluxo × p-hub mediana — em que a
unidade de cobertura é o **par OD**, coberto apenas se houver vertiporto na origem **e** no
destino. Critério de otimalidade: **maximizar economia de tempo-passageiro por dia** [pax·min/dia].

**Justificativa:** é a única formulação viável em 5 semanas que enfrenta as três exigências do
§4.3 (porta-a-porta, interdependência, massa crítica) **sem sair do MILP exato** — preservando
relaxação linear, duais e sensibilidade, que são o vínculo obrigatório com o bimestre de PL
(§4.4). Toda a literatura que modela interdependência corretamente ou usa demanda inelástica ou
cai em meta-heurística (GA, NSGA-III, VNS), perdendo dual e relaxação.

**Alternativas descartadas:**
- *p-mediana / MCLP clássico* — cobertura unilateral: basta um vertiporto perto da origem. Falha central no caso vertiportos, porque a viagem exige os dois lados.
- *p-hub mediana clássico (O'Kelly 1987)* — captura interdependência, mas assume demanda inelástica e integralmente roteada pela rede, e o desconto inter-hub `α` pressupõe economia de escala que **não existe em eVTOL** (custo por assento-km é maior, não menor; o ganho real é em tempo).
- *Hub location com logit endógeno (Rath & Chow 2022; Hagspihl et al. 2025)* — tecnicamente superior, mas depende de calibração comportamental brasileira inexistente. Fica como extensão opcional da S4.
- *Meta-heurística (GA/NSGA-III)* — resolveria instâncias maiores, mas **destrói exatamente as análises que a disciplina exige**.

---

## Parte 3 — Fontes a registrar antes do encontro

Cada `./gov fonte` precisa de origem, formato, cobertura e **limitações conhecidas**. O catálogo
completo está em `02-fontes-de-dados.md`; estas são as que precisam existir no banco no dia 26:

| Fonte | Registrar como limitação |
|---|---|
| **OD 2017 — banco completo** (`OD-2017.zip`, 40 MB, Portal da Transparência Metrô) | Defasada frente ao pós-pandemia; nomes de variáveis exigem leitura do layout interno |
| **OD 2023 — relatório síntese + anexos** | Só agregados; microdados não identificados; licença "não especificada" no CKAN |
| **Shapefile de zonas OD** (dentro do ZIP 2017, ou GeoSampa, ou `odbr::read_map`) | GeoSampa cobre só a capital; verificar o `.prj` antes de qualquer cálculo métrico |
| **ANAC — lista de aeródromos privados V2** (inclui helipontos) | Coordenadas provavelmente em DMS (exige conversão); reflete cadastro, não operação real |
| **DECEA — ROTAER / AISWEB** | PDF não estruturado; ciclo AIRAC muda a cada 28 dias; API exige chave |
| **GeoSampa** (zoneamento, uso do solo, terminais) | Só município de SP; CAPTCHA impede automação; datas de atualização heterogêneas por camada |
| **OSM / Geofabrik + OSRM** | Roteia em free-flow — **subestima tempo de pico**, que é exatamente quando a UAM ganha |
| **Licenciamento SMUL/CONTRU** | Registro incompleto para helipontos anteriores a 23/10/2009 |

E o pacote R **`odbr`** (`github.com/hsvab/odbr`) — lê a OD direto da fonte oficial e devolve o
dicionário de variáveis completo em uma linha:

```r
dic <- odbr::read_dictionary(city = "Sao Paulo", year = 2017, language = "pt")
```

Registrar como fonte de terceiro, com a limitação de que **não cobre 2023** e que os dados devem
ser validados contra o original.

---

## Parte 4 — Referências a registrar

Prioridade máxima, nesta ordem:

1. **Carvalho, Gomes, Rodrigues, Murça, Guterres & Pamplona (2026).** *Data-driven framework for
   urban air mobility planning: Integrating socioeconomic and operational factors for optimal
   network design in São Paulo, Brazil.* **Case Studies on Transport Policy** 25, 101848.
   → **Murça e Guterres são os professores da disciplina.** Este artigo é o estado da arte do
   próprio departamento sobre exatamente este problema, nesta cidade. É leitura obrigatória e
   provavelmente a orientação metodológica implícita do enunciado. Leiam antes do encontro.
2. **Ribeiro, Borille, Caetano & Silva (2023).** *Repurposing urban air mobility infrastructure...
   vertiports in São Paulo, Brazil.* **Sustainable Cities and Society** 98, 104797.
   → Borille e Caetano também são do ITA. Base da decisão D4.
3. **Brunelli, Ditta & Postorino (2023).** Revisão sistemática sobre localização e capacidade de
   vertiportos. **JATM** 112, 102460. → referência obrigatória de enquadramento.
4. **Volakakis & Mahmassani (2024, 2025).** Chicago; equidade; a-CFLP e a-MCLP capacitado.
   → o único trabalho que compara as quatro famílias clássicas lado a lado no mesmo dataset.
5. **Wu & Zhang (2021)**, *Engineering* 7(4) — porta-a-porta com 6 modos de acesso; **Rath & Chow
   (2022)**, *JATM* 105 — hub location com demanda elástica linearizada.
6. Clássicos: **Church & ReVelle (1974)** MCLP · **Hakimi (1964)** / **ReVelle & Swain (1970)**
   p-mediana · **O'Kelly (1987)** hub location · **Kuby & Lim (2005)** FRLM (o mecanismo de massa
   crítica em forma linear).

Lista completa com DOIs em `01-revisao-literatura.md`.

> ⚠️ Itens 1, 2, 3 e Shin et al. (2021) foram confirmados apenas em **metadados bibliográficos** —
> os textos integrais estão em paywall. **Peguem os PDFs pela biblioteca do ITA antes de citar a
> formulação matemática de qualquer um deles.**

---

## Parte 5 — Perguntas para levar ao professor

Ordenadas por quanto travam o projeto se ficarem sem resposta.

**Bloqueadores de infraestrutura**

1. **Onde está o repositório-modelo com `governanca/`, `gov.py`, DuckDB e os workflows?** O marco
   de 19/08 previa "repositório clonado, site no ar" e o que temos é um repo vazio.
2. Se ele ainda não foi distribuído: **podemos montar a estrutura mínima à mão e registrar isso
   como decisão**, ou é melhor esperar? (Cada dia sem banco alimentado é perda irrecuperável de
   cadência, que é métrica auditada.)
3. O servidor MCP incluído no repositório já está configurado, ou cada grupo configura?

**Dados**

4. **O Metrô liberou os microdados da OD 2023?** Se não, a orientação é usar a OD 2017 e calibrar
   pelo nível de 2023, ou trabalhar só com os agregados de 2023?
5. Existe alguma base de tempos de deslocamento já tratada que o professor recomende, ou cada
   grupo constrói a sua? (O enunciado permite compartilhar matrizes de tempo entre grupos com
   crédito registrado — vale coordenar com a turma e economizar uma semana de todo mundo.)

**Modelagem**

6. **O recorte no município de São Paulo, em vez da RMSP, é aceitável?** O título diz "cidade de
   São Paulo", mas a base OD é metropolitana.
7. Maximizar **economia de tempo-passageiro** [pax·min/dia] é um critério de otimalidade
   aceitável, ou o professor prefere ver o critério monetizado por valor do tempo?
8. Para a "curva de implantação" (§4.4), o eixo de benefício deve ser o valor da FO própria do
   grupo, ou há preferência por uma métrica comum a toda a turma?

**Avaliação**

9. Rodar um **baseline unilateral** (CFLP) junto com o modelo principal, para comparar as duas
   curvas de implantação, conta como profundidade de análise ou dispersa o foco?
10. Sobre a pergunta garantida na arguição — "mostrem a decisão em que discordaram da IA" — o
    esperado é uma decisão técnica do modelo, ou vale também discordância sobre método/processo?

---

## Parte 6 — O que fazer nos próximos 3 dias, em ordem

```
HOJE (24/08)
  [ ] Perguntar no Classroom onde está o repositório-modelo        <- destrava tudo
  [ ] Baixar OD-2017.zip e abrir o layout de variáveis
  [ ] Dividir as 4 frentes entre os integrantes

25/08
  [ ] Registrar metas, as 5 decisões de recorte e as fontes no banco
  [ ] Ler Carvalho et al. (2026) — todos
  [ ] Extrair a lista ANAC de helipontos de São Paulo e contar
  [ ] git push -> site no ar

26/08
  [ ] Conferir que o site reflete o banco
  [ ] 1º encontro, com as perguntas da Parte 5 na mão
  [ ] Registrar, no mesmo dia, as decisões que o encontro mudar
```
