# Catálogo de Fontes de Dados — Projeto B1, TRA-48

> Levantamento de 24/08/2026, com apoio de IA. **Nada aqui foi baixado e inspecionado por um
> humano ainda.** Itens marcados **[A CONFIRMAR]** não puderam ser verificados na origem
> (CAPTCHA em `gov.br`, `robots.txt` em DECEA/INDE, PDF acima do limite de fetch).
> Confirmar antes de virar premissa do projeto — dado não rastreável à fonte é item explícito
> de "o que compromete a nota" (§8.4).

---

## 1. Pesquisa Origem-Destino do Metrô-SP — a base obrigatória

### 1.1 Qual edição usar

| | OD 2023 | OD 2017 |
|---|---|---|
| Coleta de campo | ago/2023 – mai/2024 | 2017 |
| Domicílios válidos | 32 mil | 32 mil |
| Pessoas pesquisadas | 79 mil | — |
| Divulgação | fev/2025 | dez/2018 (prelim.) / ago/2019 (síntese) |
| Viagens diárias | **35,6 milhões** | **42 milhões** |
| Zonas OD | **[A CONFIRMAR]** | **517** (342 no município de SP) |
| Municípios | 38 *(LabCidade)* — ver ressalva | 39 (RMSP completa) |
| **Microdados públicos** | ❌ **não identificados** | ✅ **`.dbf` + `.sav` (SPSS)** |

**Conclusão operacional:** a base utilizável para modelagem desagregada hoje é a **OD 2017**,
com os agregados da **OD 2023** como fator de correção de nível. A OD 2023 registra queda real
de 42 → 35,6 mi viagens/dia e **inversão da divisão modal** (individual motorizado superou o
coletivo pela primeira vez; 12,2 mi no coletivo é o menor patamar desde 1997).

**Divergência aberta:** a RMSP tem 39 municípios e a OD 2017 cobriu os 39; o LabCidade fala em
38 para a OD 2023. **[A CONFIRMAR — abrir o e-book da OD 2023]**

### 1.2 URLs verificadas

**Páginas de entrada**
- OD 2023: `https://www.metro.sp.gov.br/pt_BR/pesquisa-od/`
- Histórico: `https://www.metro.sp.gov.br/pt_BR/metro/numeros-pesquisa/pesquisa-od/`
- Série 1977–2017 (CKAN): `https://transparencia.metrosp.com.br/dataset/pesquisa-origem-e-destino`

**Arquivos diretos**

| Arquivo | URL | Tamanho |
|---|---|---|
| **OD 2017 — banco completo** | `https://transparencia.metrosp.com.br/sites/default/files/OD-2017.zip` | **40,46 MB** |
| OD 2023 — anexos | `https://transparencia.metrosp.com.br/sites/default/files/Site_190225_PesquisaOD2023.zip` | n/d |
| OD 2023 — síntese (e-book) | `https://transparencia.metrosp.com.br/sites/default/files/MetroSP_OD2023_Ebook_Resultados_0.pdf` | >30 MB |

**Não encontrado no `dados.gov.br`.** Há registro no catálogo estadual:
`http://catalogo.governoaberto.sp.gov.br/dataset/869-pesquisa-origem-e-destino` **[A CONFIRMAR]**

### 1.3 O que tem dentro do `OD-2017.zip` (verificado)

79 arquivos em 4 diretórios:

1. **`Banco de Dados`** — `.dbf` e `.sav` (SPSS) + **planilha com o layout das variáveis** (o
   dicionário oficial) + **planilha de correspondência entre zonas 2007 e 2017**
2. **`Manual`** — documentação da pesquisa domiciliar (define viagem, motivo, modo principal)
3. **`Mapas`** — MAP/MIF/TAB (MapInfo) **e shapefiles** de distritos, municípios e zonas OD 2017
4. **`Tabelas`** — 30 arquivos `.xlsx` tabulados

### 1.4 Estrutura conceitual do banco

**Três níveis encadeados:** Domicílio → Pessoa/Família → Viagem. **Cada nível tem seu próprio
fator de expansão.** A tabela distribuída costuma vir "achatada" no nível viagem, repetindo
atributos de domicílio e pessoa.

**Blocos temáticos:**

- *Localização* — zona/município/subprefeitura/distrito do domicílio, da origem e do destino; coordenadas do domicílio **[A CONFIRMAR se estão no banco público e em qual projeção]**
- *Socioeconômico* — renda familiar (valor e faixa), moradores, autos/motos/bicicletas, instrução, ocupação, idade, sexo
- *Viagem* — zona de origem e destino, **motivo na origem e no destino**, **modo principal** (hierarquia sobre até 4 modos declarados), sequência de modos, hora e minuto de saída e de chegada, **duração em minutos**
- *Expansão* — fator de domicílio, de pessoa e **de viagem**

⚠️ **Nomes exatos das variáveis não verificados.** `FE_VIA`, `ZONA_O`, `ZONA_D`, `MODOPRIN`,
`MOTIVO_D`, `DURACAO`, `RENDA_FA`, `H_SAIDA` circulam na literatura, mas **nenhuma fonte
acessível os confirmou**. A documentação canônica é o layout dentro do ZIP.

**Atalho de 30 segundos** — o pacote R `odbr` devolve o dicionário completo:

```r
dic <- odbr::read_dictionary(city = "Sao Paulo", year = 2017, language = "pt")
# colunas: variable_name, description, categories, class
```

### 1.5 Fator de expansão — como usar (isto é o erro clássico)

A OD é amostra domiciliar **estratificada por cinco faixas de renda**. Cada registro carrega um
peso amostral. **Nenhum total pode ser lido da contagem de linhas** — todo total é soma ponderada.

```
Viagens diárias totais                = Σ  FE_viagem
Matriz OD por par de zonas            = Σ  FE_viagem  GROUP BY zona_o, zona_d
Matriz por modo/motivo/hora           = Σ  FE_viagem  GROUP BY zona_o, zona_d, modo, motivo, faixa_horaria
Duração média (ponderada)             = Σ (duração × FE_viagem) / Σ FE_viagem
Renda média por zona (nível pessoa)   = Σ (renda × FE_pessoa) / Σ FE_pessoa
Índice de mobilidade                  = Σ FE_viagem / Σ FE_pessoa
```

**Regras de ouro:**

- Use o fator do **nível correto**. FE de viagem para contar viagens, de pessoa para população,
  de domicílio para domicílios/frota. **Misturar níveis é o erro clássico.**
- **Nunca some FE de viagem para estimar população.**
- Médias e proporções são **sempre** ponderadas.

**Calibração oficial (verificado):** os fatores foram aferidos contra os totais de passageiros
transportados por Metrô, CPTM, EMTU e SPTrans. Ou seja, **os totais de transporte coletivo têm
âncora externa; os demais modos não.** Isso é uma limitação a registrar.

**Para o modelo:** a matriz relevante é `Σ FE_viagem` por par (zona_o, zona_d) filtrada por
motivo, renda e duração/distância — ver decisão D3 em `03-encontro-26-08.md`.

### 1.6 Incertezas explícitas

1. Microdados 2023 não confirmados como públicos — nenhuma data prometida de liberação
2. Conteúdo real do `Site_190225_PesquisaOD2023.zip` não inspecionado
3. Nomes exatos das variáveis dependem do layout interno
4. Zoneamento 2023: número de zonas não confirmado; se mudou frente às 517 de 2017, será
   necessária tabela de correspondência (a de 2007→2017 existe no ZIP; **a de 2017→2023 não**)
5. 38 vs 39 municípios na OD 2023
6. Coordenadas dos domicílios: se não estiverem no banco público, **a menor unidade espacial é a
   zona OD**, o que limita a precisão de sitação ao centroide de zona — relevante para a
   metodologia e para a seção de limitações
7. Licença do recurso OD 2023 aparece como **"License Not Specified"** no CKAN

---

## 2. Shapefile das zonas OD

| Opção | Onde | CRS | Nota |
|---|---|---|---|
| **A — dentro do `OD-2017.zip`** (pasta `Mapas`) | Metrô | **[A CONFIRMAR — checar o `.prj`]** | ⭐ **Recomendada.** Códigos de zona batem exatamente com os do banco |
| **B — GeoSampa**, camada "Zona Origem e Destino (OD)" | PMSP/SMUL | **EPSG:31983** (SIRGAS 2000 / UTM 23S) ✅ | Atualizada em 30/04/2025 — indício de que já reflete o zoneamento 2023 **[A CONFIRMAR]**. **Cobre só a capital** |
| **C — `odbr::read_map()`** | comunidade | objeto `sf` | Mais rápido para prototipar |
| D — IBGE | — | — | **Não publica zonas OD.** Só setores censitários/municípios/distritos, úteis como camada de apoio |

**GeoSampa — acessos**
- Portal: `https://geosampa.prefeitura.sp.gov.br`
- Metadado da camada OD: `https://metadados.geosampa.prefeitura.sp.gov.br/geonetwork/geoprodam/api/records/4ed47f83-653f-43ad-9883-4137dbbfaee1`
- WFS: `http://wfs.geosampa.prefeitura.sp.gov.br/geoserver/geoportal/wfs`
- WMS: `http://wms.geosampa.prefeitura.sp.gov.br/geoserver/geoportal/wms`

**Nota de EPSG para o projeto:**

- **`EPSG:31983`** — SIRGAS 2000 / UTM 23S, métrico. **Use este para área, buffer, distância e
  para a otimização.**
- `EPSG:4674` — SIRGAS 2000 geográficas (é o que o IBGE entrega)
- `EPSG:4326` — WGS 84 (é o que sai de OSM e APIs de rota). A diferença para SIRGAS 2000 é
  sub-métrica e irrelevante nesta escala, **mas declarem a decisão no relatório.**

---

## 3. Helipontos e infraestrutura aeronáutica

### 3.1 ANAC — cadastro civil

| Recurso | URL | Formato |
|---|---|---|
| **Lista de Aeródromos Privados V2** — cobre "aeródromos privados, helidecks e **helipontos**" | `https://www.anac.gov.br/acesso-a-informacao/dados-abertos/areas-de-atuacao/aerodromos/lista-de-aerodromos-privados-v2` | **CSV / JSON** (pub. 06/09/2023) |
| Versão legada | `https://www.anac.gov.br/acesso-a-informacao/dados-abertos/areas-de-atuacao/aerodromos/lista-de-aerodromos-privados/aerodromosprivados.xls` | XLS **[A CONFIRMAR]** |
| Lista de Aeródromos Civis Cadastrados | `https://www.gov.br/anac/pt-br/assuntos/regulados/aeroportos-e-aerodromos/lista-de-aerodromos-civis-cadastrados` | HTML → planilhas ⚠️ CAPTCHA |
| Camada geoespacial "Helipontos ANAC" na INDE | `https://metadados.inde.gov.br/geonetwork/srv/api/records/5BBB2266-DD04-4610-A0DD-2E09F68E95FB` | **[A CONFIRMAR — robots.txt]** |

⚠️ **Coordenadas:** o cadastro ANAC historicamente traz lat/long em **grau-minuto-segundo**
(formato `DDMMSSX`). **Validem os cabeçalhos antes de programar o parser** — o DMS exige
conversão para decimal.

### 3.2 DECEA — a camada que a ANAC não cobre

| Recurso | URL |
|---|---|
| AISWEB (portal) | `https://aisweb.decea.mil.br/?i=home&lingua=pt-br` |
| **ROTAER completo (PDF)** | `https://aisweb.decea.mil.br/download/?p=ROTAER_Completo&public=da1cd33d-ef8d-4320-9da05980326e1775.pdf` |
| ROTAER Cap. 1 e 2 (como ler / legenda) | `https://aisweb.decea.mil.br/download/?p=ROTAER_Cap__1_e_2&public=5707bb57-a5a8-400a-ba165571fbae90b4.pdf` |
| GeoAISWEB (visualizador de camadas) | `https://geoaisweb.decea.gov.br/` |
| API AISWEB | `https://aisweb.decea.mil.br/?i=publicacoes&p=api` — chave via `https://ajuda.decea.mil.br/base-de-conhecimento/como-solicitar-a-chave-da-api-aisweb/` |

**Por que o DECEA importa mais que a ANAC aqui:** a viabilidade de um vertiporto depende do
**espaço aéreo**. A TMA-SP é uma das mais congestionadas do mundo, e o tráfego de asas rotativas
na região metropolitana é gerido pelo **HELICONTROL**. Nenhum cadastro da ANAC captura isso —
e "limitações operacionais da infraestrutura" é exigência textual do §4.3.

**Limitação do ROTAER:** PDF não estruturado (extração exige parsing) e **ciclo AIRAC — a versão
muda a cada 28 dias**. Registrem a data da extração.

### 3.3 Quantos helipontos existem em São Paulo?

| Número | Fonte | Data | Veredito |
|---|---|---|---|
| **214** abertos ao tráfego aéreo | **ANAC**, release oficial — `https://www2.anac.gov.br/IMPRENSA/anacConvocaProprietariosDeHelipontos_SP.asp` | **09/02/2009** | Oficial, mas **17 anos defasado** |
| ~200 | Flight Consultoria, citando "dados da Prefeitura" | sem data | Secundária, atribuição indireta |
| ~400 helicópteros **em atividade** | Prefeitura de SP / SMUL | 18/03/2022 | Oficial, mas é **frota**, não infraestrutura |

**Recomendação:** **não citem "X helipontos" de fonte jornalística.** Derivem o número contando
registros na lista ANAC V2 filtrada por `município = São Paulo/SP`, cruzem com o ROTAER, e
reportem a data de extração. Os números redondos que circulam são mutuamente inconsistentes e
quase sempre sem rastro.

### 3.4 Licenciamento municipal — restrição regulatória a modelar

- **Marco legal:** Lei nº 15.723/2013, Decreto nº 58.094/2018, Portaria 20/2020-SEL/GAB
- **Órgão:** CONTRU / SMUL
- **Dois atos:** *Alvará de Instalação* (condições físicas e urbanísticas) + *Auto de Licença de
  Funcionamento*, **renovável a cada 5 anos** ou antes se a autorização da ANAC vencer primeiro
- Fonte: `https://prefeitura.sp.gov.br/web/licenciamento/w/noticias/326378`

⚠️ **Limitação estrutural do cadastro municipal, declarada pela própria fonte:** helipontos
aprovados **antes de 23/10/2009** só entram no registro público na renovação da licença. Ou seja,
**os helipontos mais antigos e consolidados são justamente os que podem faltar.**

**Implicação para o modelo:** um vertiporto em SP exige **tripla conformidade** — ANAC (registro
de aeródromo), DECEA (espaço aéreo/rotas) e Prefeitura (alvará + ALF + zoneamento). Essa cadeia
é, por si só, um critério de filtro do conjunto de candidatos `J`.

---

## 4. Malha viária e tempos de deslocamento

| Ferramenta | Licença | Limitação decisiva |
|---|---|---|
| **OSM via Geofabrik** (`https://download.geofabrik.de/south-america/brazil/sudeste.html`) | **ODbL** — grátis, exige atribuição, *share-alike* | Qualidade varia; sem dados de congestionamento |
| **OSRM self-hosted** (`https://project-osrm.org`) | BSD, grátis | ⚠️ **Roteia em free-flow — subestima o pico de SP, que é exatamente quando o eVTOL ganha.** Servidor demo tem rate limit severo |
| **Google Routes API** | Pago **por elemento** | Matriz 500×500 = 250 mil elementos → **estoura orçamento acadêmico**. Termos restringem cache e exigem exibição em mapa Google — atrito para publicar dados derivados |
| **HERE Matrix Routing** | Freemium | Otimizada para matrizes grandes (vantagem real aqui); cobertura de tráfego no Brasil menos densa que a do Google |

**Estratégia recomendada:** **OSRM self-hosted** sobre extrato Geofabrik para a matriz completa
zona-a-zona, **+ Google ou HERE apenas como amostra de validação** em algumas dezenas de pares em
horário de pico, para estimar um **fator de congestionamento** aplicado sobre os tempos
free-flow. Custa quase nada e é metodologicamente defensável.

**Terceira âncora, e talvez a melhor:** **os tempos declarados de viagem na própria OD já embutem
congestionamento real.** Cruzem as três fontes e registrem a discrepância — reconhecer a
limitação do próprio dado vale mais na avaliação do que apresentá-lo sem ressalva (§3.2).

---

## 5. Renda e socioeconomia

**Recomendação: usem a renda da própria OD**, não o Censo.

**Por quê:** a variável de renda familiar está no banco da OD, com fator de expansão, **já na
geografia de zona OD** — evita cruzar geografias diferentes e introduzir erro de compatibilização
areal. O Censo 2022 **não coletou rendimento no universo** com a granularidade do Censo 2010; os
Agregados por Setores 2022 privilegiam o questionário básico, e renda detalhada sai em recorte
mais agregado **[A CONFIRMAR quais variáveis de rendimento estão nos Agregados 2022]**.

A alternativa — Censo 2010 por setor censitário — traz granularidade espacial melhor ao custo de
**16 anos de defasagem**. Registrem a escolha e a justificativa.

**Malhas do IBGE** (camada de apoio, útil de todo modo):
- `https://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_de_setores_censitarios__divisoes_intramunicipais/` (FTP direto, bom para automação)
- Censo 2022: 468.097 setores, 5.570 municípios; **SIRGAS 2000 geográficas, UTF-8**

---

## 6. Transporte público

| Fonte | Acesso | Limitação |
|---|---|---|
| **SPTrans** — GTFS + API Olho Vivo | `https://www.sptrans.com.br/desenvolvedores/` — **exige cadastro e chave** | Cobre **só ônibus municipais de SP** — não metrô, não CPTM, não EMTU |
| Estações de metrô/CPTM/monotrilho, terminais | via **GeoSampa** | Só município de SP |

---

## 7. Tabela de catalogação — pronta para o `./gov fonte`

| Fonte | Órgão | URL | Formato | Cobertura | Limitações conhecidas |
|---|---|---|---|---|---|
| **OD 2017 — banco completo** | Metrô-SP | `transparencia.metrosp.com.br/sites/default/files/OD-2017.zip` | ZIP 40,46 MB (`.sav`, `.dbf`, `.xlsx`, SHP, MapInfo) | RMSP, 39 municípios, 517 zonas, 32 mil domicílios | Base mais recente **com microdados**. Defasada frente ao pós-pandemia (42 → 35,6 mi viagens). Nomes de variáveis exigem leitura do layout interno |
| OD 2023 — Relatório Síntese | Metrô-SP | `transparencia.metrosp.com.br/sites/default/files/MetroSP_OD2023_Ebook_Resultados_0.pdf` | PDF >30 MB | RMSP, campo ago/2023–mai/2024 | Só agregados. Licença "não especificada". Nº de zonas e cobertura municipal a confirmar |
| OD 2023 — Anexos | Metrô-SP | `transparencia.metrosp.com.br/sites/default/files/Site_190225_PesquisaOD2023.zip` | ZIP | RMSP 2023 | **Conteúdo não inspecionado.** Não confirmado se contém microdados |
| Pacote R `odbr` | Comunidade (rOpenSci) | `github.com/hsvab/odbr` | Pacote R (CSV.gz + `sf`) | SP, 1977–2017 | **Não cobre 2023.** `harmonize=TRUE` indisponível. Terceiro — validar contra o original |
| Zonas OD (malha) | Metrô, via PMSP/SMUL | `metadados.geosampa.prefeitura.sp.gov.br/geonetwork/geoprodam/api/records/4ed47f83-653f-43ad-9883-4137dbbfaee1` | SHP/GPKG/GeoJSON/KML; WMS/WFS; **EPSG:31983** | **Só município de SP** | Não cobre a RMSP. Ano de referência a confirmar |
| GeoSampa (500+ camadas) | PMSP/SMUL/Prodam | `geosampa.prefeitura.sp.gov.br` | SHP, GPKG, GeoJSON, KML — EPSG:31983 | Município de SP | Só a capital. CAPTCHA impede automação. Datas de atualização heterogêneas por camada |
| Setores censitários | IBGE | `geoftp.ibge.gov.br/.../malhas_de_setores_censitarios.../` | SHP, GPKG, KML — EPSG:4674 | Brasil; 2022 = 468.097 setores | Geografia distinta das zonas OD — exige compatibilização |
| Censo 2022 — Agregados por Setores | IBGE | `ibge.gov.br/biblioteca/visualizacao/livros/liv102071.pdf` | PDF (doc.) + CSV | Brasil | **Renda detalhada limitada em 2022** frente a 2010 |
| Aeródromos Privados V2 (inclui helipontos) | ANAC | `anac.gov.br/acesso-a-informacao/dados-abertos/areas-de-atuacao/aerodromos/lista-de-aerodromos-privados-v2` | CSV / JSON (06/09/2023) | Brasil | URL do arquivo e schema a confirmar. Coordenadas provavelmente em DMS. Reflete **cadastro, não operação real** |
| Helipontos ANAC (camada geo) | ANAC / INDE | `metadados.inde.gov.br/geonetwork/srv/api/records/5BBB2266-DD04-4610-A0DD-2E09F68E95FB` | geoespacial | Brasil | Não acessada (robots.txt) |
| ROTAER | DECEA / FAB | `aisweb.decea.mil.br/download/?p=ROTAER_Completo&public=da1cd33d-ef8d-4320-9da05980326e1775.pdf` | PDF | Brasil | Não estruturado — exige parsing. **Ciclo AIRAC: muda a cada 28 dias** |
| API AISWEB | DECEA | `aisweb.decea.mil.br/?i=publicacoes&p=api` | XML/JSON | Brasil | Requer chave (`apiKey`+`apiPass`); schema não verificado |
| Licenciamento de helipontos | PMSP/SMUL/CONTRU | `prefeitura.sp.gov.br/web/licenciamento/w/noticias/326378` | HTML / consulta web | Município de SP | **Registro incompleto**: helipontos anteriores a 23/10/2009 só entram na renovação |
| Nº de helipontos em SP (214) | ANAC (release) | `www2.anac.gov.br/IMPRENSA/anacConvocaProprietariosDeHelipontos_SP.asp` | HTML | Cidade de SP | **Dado de 2009** — usar só como referência histórica |
| OSM — extrato Sudeste | Geofabrik / OSM | `download.geofabrik.de/south-america/brazil/sudeste.html` | `.osm.pbf`, `.shp.zip` | Sudeste | **ODbL** (share-alike + atribuição). Sem tráfego |
| OSRM | Projeto OSRM | `project-osrm.org` | API `/table`, `/route` | conforme extrato OSM | **Free-flow: subestima o pico.** Matrizes grandes exigem self-host |
| Google Routes API | Google | `developers.google.com/maps/documentation/routes/usage-and-billing` | REST/JSON | Global | **Pago por elemento** — inviável para matriz grande. Termos restringem cache e reuso |
| HERE Matrix Routing | HERE | `developer.here.com/documentation/matrix-routing-api/dev_guide/index.html` | REST/JSON | Global | Freemium com limites a confirmar. Tráfego no Brasil menos denso |
| SPTrans — GTFS + Olho Vivo | SPTrans | `sptrans.com.br/desenvolvedores/` | GTFS + REST/JSON | Ônibus municipais de SP | **Exige cadastro + chave.** Não cobre metrô/CPTM/EMTU |
| Relatório-Síntese OD 2017 (espelho) | Metrô, via Mobilize | `mobilize.org.br/midias/pesquisas/pesquisa-origem-destino-2017-da-rmsp.pdf` | PDF | RMSP 2017 | Espelho de terceiro — **citar o original do Metrô no relatório** |

---

## 8. Próximos passos, em ordem de quanto destravam

1. **Baixar e abrir o `OD-2017.zip`** — extrair a planilha de layout de variáveis. Resolve de uma
   vez os `[A CONFIRMAR]` das §1.4 e §1.5. Ou, em 30 segundos: `odbr::read_dictionary()`.
2. **Baixar o `Site_190225_PesquisaOD2023.zip`** e verificar se há microdados. Se não houver,
   **abrir pedido e-SIC ao Metrô-SP** pedindo o banco 2023 e a correspondência de zonas
   2017↔2023 — o prazo da LAI cabe no cronograma **se pedido esta semana**.
3. **Conferir o `.prj`** dos shapefiles do ZIP antes de qualquer cálculo métrico; reprojetar tudo
   para **EPSG:31983**.
4. **Extrair a contagem própria de helipontos** da lista ANAC filtrada por município, com data de
   extração registrada.
5. **Registrar a decisão sobre renda** — OD (coerente com a geografia de zonas) vs. Censo (mais
   fino espacialmente, mas exige compatibilização e provavelmente 2010).
