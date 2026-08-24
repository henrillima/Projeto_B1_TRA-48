# G00 — Como trabalhar neste repositório

> **Leia antes de qualquer outro guia.** Este define o método; os outros nove definem o
> conteúdo de cada pacote de trabalho.

---

## 1. A ideia

Os guias `G01` a `G09` não são documentação do que já foi feito. São **roteiros de execução**:
cada um descreve um pacote de trabalho de forma detalhada o bastante para que uma sessão com
o Claude Code comece produzindo, em vez de começar perguntando o que fazer.

Cada guia tem sempre a mesma estrutura:

| Seção | O que traz |
| --- | --- |
| **Objetivo** | Uma frase. O que existe no mundo depois que este pacote termina |
| **Tarefas no grafo** | Os ids exatos que este guia executa |
| **Pré-requisitos** | O que precisa estar pronto antes. Se não estiver, pare e faça aquilo |
| **Insumos** | Arquivos, fontes, URLs, parâmetros de entrada |
| **Passo a passo** | A execução, com código quando ajuda |
| **Critério de pronto** | Lista verificável. Não é "achei que ficou bom" |
| **Armadilhas conhecidas** | O que dá errado, e como saber que deu |
| **O que registrar** | Decisões, fontes, experimentos e notas que precisam entrar no grafo |
| **Como isso vira relatório** | A seção do relatório de engenharia que este pacote alimenta |

A seção **O que registrar** é a que não pode ser pulada. Ela é a ponte entre a Camada A e a
Camada B, e é onde 25% da nota se decide.

---

## 2. O mapa dos guias

| Guia | Pacote | Tarefas | Responsável | Prazo |
| --- | --- | --- | --- | --- |
| [G01](G01-infraestrutura.md) | Infraestrutura de governança | T00, T01.1–T01.6 | Henri | 31/08 |
| [G02](G02-dados-od.md) | Pesquisa OD: ler, validar, agregar | T10, T10.1–T10.3, T11 | Pedro | 30/08 |
| [G03](G03-demanda-capturavel.md) | O filtro de demanda capturável | T12 | Pedro | 02/09 |
| [G04](G04-candidatos.md) | Conjunto de candidatos a vertiporto | T20, T20.1–T20.3 | Antônio | 02/09 |
| [G05](G05-tempos.md) | Matriz de tempos terrestres e de voo | T13, T13.1–T13.2 | Antônio | 02/09 |
| [G06](G06-formulacao.md) | A formulação matemática | T21 | Henri | 02/09 |
| [G07](G07-implementacao.md) | Pré-processamento, solver, validação | T22–T25 | Henri (T22–T23) · Pedro (T24) · Antônio (T25) | 09/09 |
| [G08](G08-analises.md) | As quatro análises de PL | T30–T34 | todos | 19/09 |
| [G09](G09-relatorio.md) | Relatório, site, apresentação, arguição | T35, T36 | todos | 23/09 |

O caminho crítico é **G02 → G03 → G06 → G07 → G08 → G09**. G04 e G05 correm em paralelo, mas
G07 depende dos dois. G01 bloqueia a Camada B inteira e por isso vem primeiro.

O G07 é o único guia com responsável dividido, e a divisão é deliberada: **quem valida o
modelo (T24) e quem implementa o baseline de comparação (T25) não são quem escreveu o modelo.**
Validação feita pelo autor tende a testar o que o autor já acreditava. É também o que faz a
contribuição individual aparecer em código, e não só em texto.

---

## 3. O ciclo de uma sessão

### 3.1 Abrir

```bash
git pull
uv run python governanca/tools/validar.py governanca/data governanca/schema/grafo.schema.json
```

O resumo do validador já diz o estado do projeto: contagem por tipo, o kanban, e quais tarefas
estão bloqueadas por pendência aberta.

Depois, abra o guia do pacote em que vai trabalhar e **mova a tarefa para `fazendo`** — isso é
editar o campo `status` no YAML da tarefa. Se duas pessoas estão em `fazendo` na mesma tarefa,
alguma coisa está errada na divisão.

### 3.2 Trabalhar

Siga o guia. Quando o guia estiver errado ou incompleto — e vai estar, porque foi escrito
antes de o trabalho começar — **corrija o guia no mesmo commit**. Guia desatualizado é pior
que guia ausente, porque parece confiável.

### 3.3 Registrar

Esta é a parte que todo mundo pula e que decide 25% da nota. Ao fim da sessão, pergunte:

- **Tomei alguma decisão metodológica?** → `decisao`, com justificativa e alternativas
  descartadas. Isso inclui escolhas pequenas: um limiar, uma forma de agregação, um pacote.
- **Usei alguma fonte nova?** → `fonte`, com origem, formato, cobertura e **limitações
  conhecidas**. Reconhecer a limitação do próprio dado vale mais, na avaliação, do que
  apresentar o dado sem ressalvas.
- **Rodei o modelo?** → `experimento`, com hipótese, parâmetros, commit, valor da FO, gap,
  tempo e **conclusão**.
- **Descobri algo que trava?** → `pendencia`, com aresta `BLOQUEIA` para o que ela trava.
- **Conversei com uma IA?** → `ia`, com `aceito` e **`critica_humana` não-vazia**.
- **A tarefa avançou?** → mudar `status` e acrescentar uma `nota` datada e assinada.

### 3.4 Validar e commitar

```bash
uv run python governanca/tools/validar.py governanca/data governanca/schema/grafo.schema.json
git add -A && git commit -m "..."
git push
```

O push dispara o CI, que revalida, compila o grafo e republica o site.

---

## 4. Trabalhando com o Claude Code neste repositório

### 4.1 Como abrir uma sessão

Aponte o Claude para o guia e para a tarefa. Uma abertura que funciona:

```
Vamos executar o G03 (filtro de demanda capturável, tarefa:T12).
Leia docs/guias/G03-demanda-capturavel.md e CLAUDE.md primeiro.
O T11 já está feito e a saída está em app/outputs/od_macrozonas.rds.
```

Uma abertura que não funciona: *"me ajuda com a demanda"*. O Claude vai perguntar as mesmas
coisas que o guia já responde, e você gasta contexto reconstruindo o que já está escrito.

### 4.2 O que exigir dele

- **Que leia antes de escrever.** `CLAUDE.md`, o guia do pacote, e os YAML das tarefas
  relevantes. As regras invioláveis do `CLAUDE.md` valem para ele também.
- **Que não invente número nem referência.** Se não tem fonte, `[A CONFIRMAR]` e uma
  pendência. Isto é o primeiro item da lista do que compromete a nota.
- **Que escreva o rascunho do próprio registro de interação, com autocrítica.** Ele consegue
  apontar o que na resposta dele foi estimativa e não medição, o que foi confirmado só em
  metadado, e onde outra escolha seria defensável. Você revisa, corrige e assina.
- **Que rode o validador antes de dizer que terminou.**

### 4.3 O que NÃO delegar

Três coisas. Não porque a IA faça mal, mas porque o enunciado avalia especificamente a
capacidade de vocês de sustentá-las:

1. **A escolha dos limiares e hipóteses.** A IA pode listar opções e a literatura de apoio. A
   escolha é registrada em nome de uma pessoa, e essa pessoa vai defendê-la na arguição.
2. **A crítica no registro de IA.** Se a crítica foi escrita pela IA e aceita sem revisão, o
   registro documenta a ausência exata de revisão que ele deveria comprovar.
3. **A interpretação econômica do dual.** É o coração da nota de PL. Ler `π` como "economia
   marginal de tempo-passageiro por vertiporto adicional" é o tipo de frase que só significa
   alguma coisa se a pessoa que fala entende.

### 4.4 Sobre a taxa de aceite

O site publica a distribuição dos registros de IA entre aceite integral, parcial e descarte, e
o enunciado avisa que aceite próximo de 100% será examinado na arguição.

Isso não é um pedido para fabricar discordância. É um pedido para **prestar atenção**: quando
você lê com cuidado uma resposta longa, quase sempre encontra uma estimativa apresentada como
medição, uma referência confirmada só em metadado, ou uma escolha que tinha alternativa igual
de boa. Registrar isso como `parcial` é honesto e é a distribuição que aparece naturalmente
em quem revisa.

E lembre da pergunta garantida a todos os grupos na arguição:

> *"Mostrem a decisão em que vocês discordaram da IA — e expliquem por que vocês estavam
> certos."*

Ela é respondida com registro, não com improviso. Quando a discordância acontecer, marque a
nota com um `#discordancia` para achar depois.

---

## 5. Divisão do trabalho

| Frente | Responsável | Guias | Pico |
| --- | --- | --- | --- |
| Modelo, solver, infraestrutura | **Henri** | G01, G06, G07 | S0, S2–S3 |
| Dados, demanda, validação | **Pedro** | G02, G03 | S1 |
| Candidatos, GIS, sensibilidade | **Antônio** | G04, G05 | S1–S2 |
| Análises, relatório, apresentação | **todos** | G08, G09 | S3–S4 |

**Cada integrante precisa aparecer como autor de registros no banco e de commits** — a
contribuição individual é visível e será considerada. Isso tem uma consequência prática: não
deixem uma pessoa registrar em nome dos outros. Cada um edita os próprios YAML e faz os
próprios commits.

E cada um deve saber defender **qualquer** linha do modelo, não só a da sua frente. A coluna
`revisao` do kanban existe para isso: quem revisa precisa entender.

---

## 6. Quando o plano estiver errado

Ele vai estar. O cronograma foi escrito em 24/08, antes de qualquer dado ter sido aberto.

**Não conserte em silêncio.** Um plano que muda e um registro que explica por que é sinal de
maturidade; um plano que muda sem registro é o que a auditoria detecta como incoerência entre
o que foi dito e o que foi feito.

Se a estimativa estourar, se o filtro de captura não produzir demanda suficiente, se a
instância não couber no solver: abra uma pendência, registre a decisão de mudar de rota com as
alternativas consideradas, e ajuste o guia. O critério de excelência do enunciado inclui
literalmente **"mostra o que não funcionou, e por quê"**.

---

## 7. As quatro perguntas que o grafo tem que responder

Do §5.4 do enunciado. São o requisito funcional de tudo em `governanca/`. Se em algum momento
uma delas não tiver resposta em uma consulta, o grafo tem um buraco:

1. Por que o valor do tempo adotado é este, **e quem decidiu**?
2. Qual script gerou o mapa da página 12 do relatório?
3. Se a fonte de dados de acesso terrestre for substituída, **quais decisões e resultados
   dependem dela**?
4. Quais conclusões ainda **não têm experimento** que as sustente?

A quarta é a mais fácil de esquecer e a mais fácil de responder errado, porque a resposta é
uma **ausência**. Vale rodar a consulta dela toda semana, não só na véspera.
