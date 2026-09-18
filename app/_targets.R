# =====================================================================
#  Projeto B1 — TRA-48 · Localização de vertiportos em São Paulo
#  Pipeline analítico. Esta é a ÚNICA fonte de orquestração do projeto.
#
#      targets::tar_make()          roda o que estiver desatualizado
#      targets::tar_visnetwork()    o grafo de dependências
#      targets::tar_outdated()      o que mudou e ainda não reexecutou
#      targets::tar_network()       vertices e edges -> grafo de proveniência
#
#  Por que `targets` e não scripts soltos: `tar_network()` devolve o grafo de
#  proveniência derivado da EXECUÇÃO REAL, não de comentários que envelhecem.
#  É o que responde "qual script gerou o mapa da página 12" (§5.4 do enunciado)
#  sem ninguém manter isso à mão. E `tar_outdated()` diz qual figura do
#  relatório foi gerada por código que já mudou — auditoria que nenhum grafo
#  de código entrega.
# =====================================================================

library(targets)

tar_option_set(
  packages = c("dplyr", "tidyr", "sf", "readr",
               "ompr", "ompr.roi", "ROI.plugin.highs", "Matrix", "highs",
               "ggplot2"),
  # Seed fixa e global. Nada aqui é estocástico hoje, mas se alguém acrescentar
  # uma amostragem amanhã, o resultado continua reprodutível sem ninguém lembrar.
  seed   = 20260824,
  format = "rds"
)

tar_source("R")

# ---------------------------------------------------------------------
#  PARÂMETROS — nunca constantes literais dentro das funções.
#  Regra 8 do CLAUDE.md: número mágico no meio do código é um experimento
#  que não vai poder ser rodado. Tudo aqui vira análise de sensibilidade.
# ---------------------------------------------------------------------
P <- list(
  # -- recorte e agregação (decisao:D01) -------------------------------
  n_macrozonas   = 60,      # [A DEFINIR] G02 sugere ~120; 60 é o corte de
                            # emergência para caber no prazo. Registrar a
                            # decisão que mudar isto.

  # -- filtro de demanda capturável (decisao:D03) ----------------------
  dist_min_km    = 15,      # distância mínima em linha reta
  dur_min_min    = 45,      # duração terrestre declarada mínima
  motivos        = c("trabalho", "negocios"),
  faixas_renda   = c(4, 5), # faixas superiores da OD

  # -- viabilidade da rota (decisao:D05) -------------------------------
  t_barra_min    = 15,      # [A DEFINIR] acesso/egresso máximo, em minutos
  theta_min      = 10,      # [A DEFINIR] economia mínima para o par valer

  # -- operação do eVTOL ----------------------------------------------
  # Fonte: Rimjha et al. (2021), TRA 148 — 120 mph ≈ 193 km/h,
  # 5 min de ingresso e 5 de egresso. Ver docs/01-revisao-literatura.md.
  vel_cruzeiro_kmh = 193,
  tau_emb_min      = 5,
  tau_des_min      = 5,

  # -- a curva de implantação ------------------------------------------
  p_grade        = 1:25,

  # -- geodésia ---------------------------------------------------------
  crs_metrico    = 31983    # SIRGAS 2000 / UTM 23S
)

list(

  # ===================================================================
  #  M1 — demanda capturável
  # ===================================================================

  tar_target(arq_od,        "data/raw/OD-2017.zip",  format = "file"),
  tar_target(arq_zonas,     "data/raw/zonas_od_2017.gpkg", format = "file"),

  tar_target(od_bruta,      ler_od(arq_od)),
  tar_target(od_expandida,  expandir_viagens(od_bruta)),

  # Portão de qualidade: tem que reproduzir os 42 milhões de viagens/dia do
  # relatório-síntese de 2017. Se não bater, o erro é de nível — quase sempre
  # FE de pessoa somado no lugar de FE de viagem. Falhar aqui é barato;
  # descobrir na semana da entrega, não.
  tar_target(ok_expansao,   validar_expansao(od_expandida)),

  tar_target(zonas,         ler_zonas_od(arq_zonas, crs = P$crs_metrico)),
  tar_target(macrozonas,    agregar_zonas(zonas, od_expandida,
                                          n_alvo = P$n_macrozonas)),
  tar_target(ok_agregacao,  validar_agregacao(macrozonas, od_expandida)),

  tar_target(od_capturavel, filtrar_captura(od_expandida, macrozonas,
                                            dist_min_km  = P$dist_min_km,
                                            dur_min_min  = P$dur_min_min,
                                            motivos      = P$motivos,
                                            faixas_renda = P$faixas_renda)),

  # Sanity check do G03: se sobrar muito mais que 1–2% das viagens, o filtro
  # está frouxo frente à literatura — Wu & Zhang chegam a 0,20% de adoção.
  tar_target(resumo_captura, resumir_captura(od_capturavel, od_expandida)),

  # ===================================================================
  #  M2 — candidatos, tempos e modelo
  # ===================================================================

  tar_target(arq_anac,      "data/raw/anac_aerodromos_privados.csv", format = "file"),
  tar_target(helipontos,    ler_helipontos_anac(arq_anac)),
  tar_target(ok_coords,     validar_coordenadas(helipontos)),
  tar_target(candidatos,    construir_candidatos(helipontos, crs = P$crs_metrico)),

  tar_target(tempos,        matriz_tempos(macrozonas, candidatos,
                                          vel_kmh = P$vel_cruzeiro_kmh,
                                          tau_emb = P$tau_emb_min,
                                          tau_des = P$tau_des_min)),

  # O pré-processamento é o coração da tratabilidade: o filtro geométrico é o
  # que torna o problema resolvível (Wu & Zhang fazem isso em dois estágios).
  tar_target(colunas,       construir_colunas(od_capturavel, tempos,
                                              t_barra_min = P$t_barra_min,
                                              theta_min   = P$theta_min,
                                              tau_emb_min = P$tau_emb_min,
                                              tau_des_min = P$tau_des_min)),

  # MEDIR ANTES DE MODELAR. As estimativas do plano (|Q| entre 2.000 e 4.000)
  # são ordem de grandeza, não medição. Se passar de 2e5 variáveis, apertar
  # t_barra e theta ou agregar mais — e registrar a decisão.
  tar_target(instancia,     medir_instancia(colunas, od_capturavel, candidatos)),

  # ===================================================================
  #  M3 — solução e as quatro análises
  # ===================================================================

  tar_target(mod_bilateral,   montar_matriz_p1(colunas, candidatos, p = 12)),
  tar_target(sol_bilateral,   resolver(mod_bilateral, inteiro = TRUE)),
  tar_target(sol_unilateral,  resolver_mclp_unilateral(od_capturavel, candidatos,
                                                       tempos, p = 12)),

  # As quatro análises do §4.4. São o vínculo obrigatório com o bimestre de PL.
  tar_target(relaxacao,     tabela_relaxacao(colunas, candidatos, p = 12)),

  # Atenção (G08 §T31): duais NÃO saem do MIP. Saem do LP relaxado, ou do LP
  # restrito com as binárias fixadas na solução ótima — e pi não sai do
  # restrito. `verificar_pi` confere pi(p) contra a diferença finita
  # Z*(p+1) - Z*(p): se não baterem, a leitura econômica está errada.
  tar_target(duais,         verificar_pi(colunas, candidatos, p_grade = P$p_grade)),

  tar_target(grade_sensib,  expand.grid(t_barra = c(10, 15, 20, 30),
                                        theta   = c(0, 10, 20, 30))),
  tar_target(sensibilidade, varrer_limiares(colunas, candidatos, grade_sensib, p = 12)),
  tar_target(nucleo,        estabilidade(sensibilidade)),

  tar_target(curva,         curva_implantacao(colunas, candidatos,
                                              p_max = max(P$p_grade))),
  tar_target(forma_s,       testar_s(curva)),

  tar_target(indicadores,   tabela_indicadores(sol_bilateral, colunas,
                                               od_capturavel, candidatos)),

  # ===================================================================
  #  Figuras
  # ===================================================================

  tar_target(fig_candidatos, plotar_candidatos(candidatos, macrozonas),
             format = "file"),
  tar_target(fig_curva,      plotar_curva(curva), format = "file"),
  tar_target(fig_solucao,    plotar_solucao(sol_bilateral, candidatos, macrozonas),
             format = "file"),
  tar_target(fig_sensib,     plotar_sensibilidade(sensibilidade), format = "file")
)
