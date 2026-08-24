# Checklist de entrega

Cada item corresponde a uma exigência textual do enunciado, com a seção entre parênteses.
Rodar isto na semana de 16/09, não no dia 22 — vários itens levam horas para corrigir.

Marque com a data em que foi verificado, não só com um `x`. Item verificado em 30/08 e não
revisto até a entrega não vale nada.

---

## 1. O modelo (§4.2) — cada elemento com justificativa da escolha

- [ ] Conjuntos e índices claramente definidos
- [ ] **Parâmetros com unidade e procedência de cada valor** — a tabela do G06 §2
- [ ] Variáveis de decisão, com o significado de cada uma
- [ ] Função objetivo, com o critério que ela representa e a **unidade explicitada**
- [ ] Restrições, **cada uma com a razão de existir** em pelo menos uma frase
- [ ] Justificativa da escolha da família de formulação, com as alternativas rejeitadas e o
      motivo específico de cada rejeição

> Armadilha: "cada restrição com a razão de existir" é fácil de confundir com "cada restrição
> explicada". A razão de existir responde *o que aconteceria de errado se ela não existisse*.

---

## 2. O que o modelo precisa enfrentar (§4.3)

- [ ] A natureza **porta a porta** da viagem, e não apenas o trecho aéreo
- [ ] A **interdependência** entre as localizações escolhidas
- [ ] As **limitações operacionais** da infraestrutura
- [ ] **O que ficou fora do modelo, e por que essa omissão é aceitável**

> O quarto item é o mais esquecido e o mais barato de fazer bem. G06 §9 tem a lista com a
> direção do viés de cada omissão — dizer *para que lado* a omissão empurra o resultado vale
> mais que apenas listá-la.

---

## 3. As quatro análises (§4.4) — o vínculo obrigatório com o bimestre

- [ ] **Relaxação linear** resolvida e comparada com o modelo original, com discussão do que
      a diferença revela
- [ ] **Interpretação do dual** em linguagem de decisão: que recurso é escasso, e quanto vale
      relaxá-lo
- [ ] **Análise de sensibilidade** sobre os parâmetros que o grupo assumiu
- [ ] **Curva de implantação**: benefício em função do número de vertiportos, sustentando a
      recomendação final

Verificações numéricas que precisam ter sido feitas:

- [ ] `π(p)` conferido contra a diferença finita `Z*(p+1) − Z*(p)`
- [ ] Gap de integralidade reportado para a formulação desagregada **e** para a agregada
- [ ] Ponto de inflexão da curva detectado por segunda diferença, não a olho

---

## 4. Tratabilidade (§4.5)

- [ ] A redução da instância está **explícita, justificada e documentada**
- [ ] `|Q|`, `Σ|P_q|`, número de variáveis e de binárias **medidos e reportados** — não
      estimados
- [ ] O que se decidiu ignorar está dito, com o motivo

---

## 5. Indicadores comuns a todos os grupos (§6.3)

Para o painel comparativo final. Calculados sobre a solução final, qualquer que tenha sido o
critério otimizado.

- [ ] Número de vertiportos implantados **e sua localização**
- [ ] Demanda diária atendida **e sua participação na demanda considerada capturável pelo
      grupo**
- [ ] O benefício na métrica própria do grupo, **com a unidade explicitada**
- [ ] Desempenho computacional: valor da FO, tamanho da instância, tempo de solução

---

## 6. O relatório de engenharia (§6.1)

PDF, com mapas e memórias de cálculo, contendo:

- [ ] Contexto e definição do problema, com o recorte adotado
- [ ] Revisão de literatura: os modelos estudados e **como foram aproveitados**
- [ ] Dados: fontes, tratamento, agregação e estimativa da demanda capturável, com as
      hipóteses explicitadas
- [ ] Modelo: formulação completa em notação matemática
- [ ] Tratabilidade: a redução da instância e sua justificativa
- [ ] Resultados computacionais: solução, mapas, fronteira de implantação
- [ ] Relaxação linear, dual e análise de sensibilidade
- [ ] Limitações do modelo e trabalhos futuros
- [ ] Referências

Conferências de integridade do texto:

- [ ] **Todo número no texto tem procedência rastreável.** Nenhum "aproximadamente 200
      helipontos" sem fonte e data de extração
- [ ] **Nenhuma formulação matemática de artigo é citada sem o texto integral ter sido lido.**
      Metadado confirmado no Crossref não autoriza descrever a formulação
- [ ] Toda figura tem legenda que diz o que está no eixo e qual é a unidade
- [ ] Toda figura foi gerada pelo pipeline, não colada de uma rodada manual

---

## 7. Repositório e site público (§6.2)

- [ ] Banco de governança alimentado **ao longo de todo o bimestre**
- [ ] Código reprodutível de ponta a ponta, a partir dos dados brutos
- [ ] Site publicado no GitHub Pages, com grafo executivo, trilha de decisões, registro de
      interações com IA, experimentos e resultados
- [ ] **Instruções de reprodução: qualquer pessoa deve conseguir rodar o projeto do zero**

Teste real, não presumido:

- [ ] Alguém que não escreveu o código clonou o repositório em uma máquina limpa e rodou
      `renv::restore()` e `targets::tar_make()` até o fim

---

## 8. Auditoria do grafo — precisa sair limpa

- [ ] `validar.py` passa sem nenhum problema
- [ ] **Zero nós órfãos**
- [ ] Toda tarefa alcança uma meta
- [ ] Toda decisão vinculada a uma meta
- [ ] **Toda conclusão do relatório tem experimento que a sustente** — a consulta que responde
      por ausência
- [ ] Todo arquivo vinculado a uma decisão
- [ ] Nenhuma pendência aberta sem justificativa de por que continua aberta
- [ ] `tar_outdated()` sai vazio — nenhuma figura do relatório foi gerada por código que já
      mudou

---

## 9. Registros de IA (§5.6)

- [ ] Toda interação relevante registrada
- [ ] **Nenhum registro com `critica_humana` vazia ou genérica.** "Boa resposta" não é crítica
- [ ] A distribuição entre `integral`, `parcial` e `descartado` **não é 100% integral**
- [ ] Existe pelo menos uma discordância fundamentada, com consequência técnica real,
      pronta para a pergunta garantida da arguição

---

## 10. O que compromete a nota (§8.4) — verificar ativamente

- [ ] Nenhum dado inventado ou não rastreável à fonte
- [ ] O modelo roda, e a instância está documentada
- [ ] O banco **não** foi preenchido em bloco na semana da entrega — conferir o gráfico de
      cadência no próprio site
- [ ] Os registros de IA **não** têm aceite integral em todas as interações
- [ ] **Cada integrante sabe explicar o modelo inteiro**, não só a própria frente
- [ ] Material de outro grupo, se usado, tem crédito registrado na governança

---

## 11. Preparação da arguição

- [ ] As 34 perguntas de ensaio do G09 rodadas em voz alta, com o responsável de cada uma
- [ ] A resposta à pergunta garantida escolhida e ensaiada, apontando para o registro no site
- [ ] O site navegável ao vivo: cada um sabe onde clicar para achar uma decisão, um
      experimento e a trilha
- [ ] Resposta pronta para **"qual é a maior fraqueza do trabalho de vocês?"** — a resposta
      honesta pontua mais que a evasiva

---

## 12. Véspera

- [ ] `git status` limpo
- [ ] Nada de `build/`, `_targets/` ou `data/interim/` no histórico
- [ ] O site publicado reflete o último commit
- [ ] O PDF do relatório compila do zero
- [ ] Os três integrantes aparecem como autores de registros no banco **e** de commits
