# Dados brutos — o que baixar e de onde

Nada aqui é versionado, exceto este arquivo. São insumos grandes e imutáveis:
baixar, conferir o hash, e nunca editar à mão.

## 1. `OD-2017.zip` — Pesquisa Origem-Destino do Metrô-SP  (obrigatório)

    https://transparencia.metrosp.com.br/sites/default/files/OD-2017.zip

40,46 MB. É a edição mais recente com **microdados** publicados (`decisao:D02`).
Contém quatro diretórios: `Banco de Dados` (`.sav`/`.dbf` + a planilha de layout
das variáveis + a correspondência de zonas 2007–2017), `Manual`, `Mapas`
(shapefiles das zonas OD) e `Tabelas` (30 `.xlsx`).

**Primeiro passo, antes de qualquer código:** abrir a planilha de layout e
preencher o mapa de variáveis no `app/R/ler_od.R`. Os nomes que circulam na
literatura (`FE_VIA`, `ZONA_O`, `MODOPRIN`) **não foram confirmados** — o layout
dentro do ZIP é a única autoridade.

Atalho equivalente, se preferir:

    dic <- odbr::read_dictionary(city = "Sao Paulo", year = 2017, language = "pt")

## 2. `zonas_od_2017.gpkg` — malha das zonas  (obrigatório)

Sai da pasta `Mapas` do próprio ZIP — preferível ao GeoSampa porque os códigos
de zona batem exatamente com os do banco. **Conferir o `.prj` antes de qualquer
cálculo métrico** e reprojetar para **EPSG:31983** (SIRGAS 2000 / UTM 23S).

## 3. `anac_aerodromos_privados.csv` — helipontos  (obrigatório)

    https://www.anac.gov.br/acesso-a-informacao/dados-abertos/areas-de-atuacao/aerodromos/lista-de-aerodromos-privados-v2

Cobre aeródromos privados, helidecks e **helipontos**. Filtrar por
`município = São Paulo/SP`.

⚠️ Coordenadas historicamente em **grau-minuto-segundo** (`DDMMSSX`) — validar o
cabeçalho antes de rodar o parser. `converter_dms()` está em `app/R/candidatos.R`.

⚠️ O portal `gov.br` tem CAPTCHA: baixar à mão. **Renomear com a data de
extração** e registrar essa data — a contagem de helipontos tem que ser derivada
por vocês, não citada de fonte jornalística (os números que circulam — 200, 214,
~400 — são inconsistentes entre si).

## 4. Opcional, se sobrar tempo

- **OD 2023, anexos** — `https://transparencia.metrosp.com.br/sites/default/files/Site_190225_PesquisaOD2023.zip`
  Verificar se contém microdados. É a `pendencia:P01`.
- **GeoSampa** — camadas de zoneamento e uso do solo, para o filtro
  urbanístico dos candidatos. Cortado do escopo em 18/09 por prazo.
- **ROTAER / DECEA** — cruzamento aeronáutico dos helipontos. Também cortado.

## Registro

Toda fonte usada vira um nó `fonte` no grafo, com **origem, formato, cobertura e
limitações conhecidas**. O campo `limitacoes` é o que mais vale nota: reconhecer
a limitação do próprio dado vale mais, na avaliação, do que apresentar o dado sem
ressalvas (§3.2 do enunciado).

    uv run python governanca/tools/gov.py fonte od2017 "Pesquisa OD 2017 — banco completo" \
      --origem "Metrô-SP, Portal da Transparência, <url>" \
      --formato ".sav, .dbf, SHP, .xlsx" \
      --cobertura "RMSP, 39 municípios, 517 zonas, 32 mil domicílios" \
      --limitacoes "Defasada frente ao pós-pandemia: a OD 2023 registra 35,6 mi de viagens/dia contra 42 mi em 2017. Nomes de variáveis exigem leitura do layout interno."
