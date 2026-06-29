library(forecast)
library(fpp3)
library(ggplot2)
library(lmtest)
library(car)


# Obs: Mudar o caminho da pasta e o User. 
# Pelo o trabalho ser compartilhado em um one drive, facilitamos a inclusão do usuário para essa troca ser mais simples.

user = "BENT005"
setwd(sprintf("C:/Users/%s/Sony Music Entertainment/Rodrigues, Rubyson, Som Livre - 100 - TCC/5. Código_Análise", user))

#user = "NASC002"
#setwd(sprintf("C:/Users/%s/OneDrive - Sony Music Entertainment/SOM LIVRE/100 - TCC/5. Código_Análise", user))

drct<-getwd()
drct_files<-list.files(path = drct)

######################## Bases de Dados Importadas######################

# Se não realizar nenhum ajuste, pode puxar do mesmo sheet do original, apenas para facilitar. 

dados_cons_ajuste = readxl::read_xlsx(path = "0._BD.xlsx", 
                          sheet = "CONSUMO_AJUSTE")
dados_rec_ajuste = readxl::read_xlsx(path = "0._BD.xlsx", 
                                  sheet = "RECEITA_AJUSTE")

dados_cons_orig = readxl::read_xlsx(path = "0._BD.xlsx", 
                               sheet = "CONSUMO")
dados_rec_orig = readxl::read_xlsx(path = "0._BD.xlsx", 
                                     sheet = "RECEITA")

# Ajuste das séries para encaixar no modelo tsibble:

dados_cons_ajuste$mes <- as.Date(dados_cons_ajuste$'Mês de Consumo')
dados_cons_orig$mes <- as.Date(dados_cons_orig$'Mês de Consumo')

dados_ts_cons = dados_cons_ajuste %>% 
  tsibble(index = mes) %>% 
  mutate(mes = yearmonth(mes))

dados_rec_ajuste$mes <- as.Date(dados_rec_ajuste$'Mês de Consumo')
dados_rec_orig$mes <- as.Date(dados_rec_orig$'Mês de Consumo')

dados_ts_rec = dados_rec_ajuste %>% 
  tsibble(index = mes) %>% 
  mutate(mes = yearmonth(mes))


##################### Automatizações:##############################################

# Funções
Data = function(dados, column) {
  
  return(na.omit(select(dados, Ano, Mês, column)))
  
}

Infos = function(dados, horizon) {
  
  return( list(ano_i = dados[1,1], 
               mes_i = dados[1,2], 
               ano_f = dados[nrow(dados), 1],
               mes_f = dados[nrow(dados), 2], 
               ano_train_f = dados[nrow(dados) - horizon, 1],
               mes_train_f = dados[nrow(dados) - horizon, 2], 
               ano_test_i = dados[nrow(dados) - horizon + 1, 1],
               mes_test_i = dados[nrow(dados) - horizon + 1, 2]))
  
}



# Horizonte de projeção
h = 24


# Parceiro de análise

dsp = 'X'



##################### Etapa de puxar dados:##############################################
# Essa é uma etapa que puxa os dados de uma das colunas do banco de dados. 
  # Separamos os dados em coluna para facilitar a nossa organização, 
# já que são diversos dados que não estão organizados como deveriam ser uma base de dados 

###################### D1 - Dados Plays Empresa: #########################

plays = sprintf('%s_EMPRESA_PLAYS', dsp)

h_train = sum(!is.na(dados_ts_cons[[plays]]))*0.2


info_dados_plays_ajuste = Infos(Data(dados_ts_cons, plays), h_train)

plays_ajuste_ts = ts(data = Data(dados_ts_cons, plays)[[plays]], 
                      start = c(info_dados_plays_ajuste$ano_i, info_dados_plays_ajuste$mes_i),
                      frequency = 12, 
                      end = c(info_dados_plays_ajuste$ano_f, info_dados_plays_ajuste$mes_f))

# Modelo para análise de sensibilidade
t_forecast = 45

info_dados_plays_orig = Infos(Data(dados_cons_orig, plays), t_forecast)

plays_orig_ts = ts(data = Data(dados_cons_orig, plays)[[plays]], 
                           start = c(info_dados_plays_orig$ano_i, info_dados_plays_orig$mes_i),
                           frequency = 12, 
                           end = c(info_dados_plays_orig$ano_f, info_dados_plays_orig$mes_f))

###################### D2 - Dados Plays DSP: #########################

plays_dsp = sprintf('%s_PLAYS', dsp)

h_train = sum(!is.na(dados_ts_cons[[plays_dsp]]))*0.2

info_dados_plays_dsp_ajuste = Infos(Data(dados_ts_cons, plays_dsp), h_train)

plays_dsp_ajuste_ts = ts(data = Data(dados_ts_cons, plays_dsp)[[plays_dsp]], 
                     start = c(info_dados_plays_dsp_ajuste$ano_i, info_dados_plays_dsp_ajuste$mes_i),
                     frequency = 12, 
                     end = c(info_dados_plays_dsp_ajuste$ano_f, info_dados_plays_dsp_ajuste$mes_f))


# Modelo para análise de sensibilidade
t_forecast = 45

info_dados_plays_dsp_orig = Infos(Data(dados_cons_orig, plays_dsp), t_forecast)

plays_dsp_orig_ts = ts(data = Data(dados_cons_orig, plays_dsp)[[plays_dsp]], 
                   start = c(info_dados_plays_dsp_orig$ano_i, info_dados_plays_dsp_orig$mes_i),
                   frequency = 12, 
                   end = c(info_dados_plays_dsp_orig$ano_f, info_dados_plays_dsp_orig$mes_f))



###################### D3 - Dados Users DSP: #########################

users = sprintf('%s_USERS', dsp)

h_train = sum(!is.na(dados_ts_cons[[users]]))*0.2

info_dados_users_ajuste = Infos(Data(dados_ts_cons, users), h_train)

users_ajuste_ts = ts(data = Data(dados_ts_cons, users)[[users]], 
                         start = c(info_dados_users_ajuste$ano_i, info_dados_users_ajuste$mes_i),
                         frequency = 12, 
                         end = c(info_dados_users_ajuste$ano_f, info_dados_users_ajuste$mes_f))


# Modelo para análise de sensibilidade
t_forecast = 45

info_dados_users_orig = Infos(Data(dados_cons_orig, users), t_forecast)

users_orig_ts = ts(data = Data(dados_cons_orig, users)[[users]], 
                       start = c(info_dados_users_orig$ano_i, info_dados_users_orig$mes_i),
                       frequency = 12, 
                       end = c(info_dados_users_orig$ano_f, info_dados_users_orig$mes_f))



###################### D4 - Dados Receita Empresa: #########################

receita = sprintf('%s_EMPRESA_REC', dsp)

h_train = sum(!is.na(dados_ts_rec[[receita]]))*0.2

info_dados_receita_ajuste = Infos(Data(dados_ts_rec, receita), h_train)

receita_ajuste_ts = ts(data = Data(dados_ts_rec, receita)[[receita]], 
                     start = c(info_dados_receita_ajuste$ano_i, info_dados_receita_ajuste$mes_i),
                     frequency = 12, 
                     end = c(info_dados_receita_ajuste$ano_f, info_dados_receita_ajuste$mes_f))


# Modelo para análise de sensibilidade
t_forecast = 45

info_dados_receita_orig = Infos(Data(dados_rec_orig, receita), t_forecast)

receita_orig_ts = ts(data = Data(dados_rec_orig, receita)[[receita]], 
                   start = c(info_dados_receita_orig$ano_i, info_dados_receita_orig$mes_i),
                   frequency = 12, 
                   end = c(info_dados_receita_orig$ano_f, info_dados_receita_orig$mes_f))

###################### D5 - Dados RPP Empresa: #########################

rpp = sprintf('%s_EMPRESA_RPP', dsp)

h_train = sum(!is.na(dados_ts_rec[[rpp]]))*0.2

info_dados_rpp_ajuste = Infos(Data(dados_ts_rec, rpp), h_train)

rpp_ajuste_ts = ts(data = Data(dados_ts_rec, rpp)[[rpp]], 
                       start = c(info_dados_rpp_ajuste$ano_i, info_dados_rpp_ajuste$mes_i),
                       frequency = 12, 
                       end = c(info_dados_rpp_ajuste$ano_f, info_dados_rpp_ajuste$mes_f))


# Modelo para análise de sensibilidade
t_forecast = 45

info_dados_rpp_orig = Infos(Data(dados_rec_orig, rpp), t_forecast)

rpp_orig_ts = ts(data = Data(dados_rec_orig, rpp)[[rpp]], 
                     start = c(info_dados_rpp_orig$ano_i, info_dados_rpp_orig$mes_i),
                     frequency = 12, 
                     end = c(info_dados_rpp_orig$ano_f, info_dados_rpp_orig$mes_f))





########################################### PROGRAMA DE PREVISÃO:####
################# Nessa seção, escolher quais serão os dados projetados, se serão plays, receita, rpp...
################# E além disso, qual o tipo, se é rec (receita) ou cons (consumo) 
# Importante: colocar tudo em letra minúscula!!!
#Possibilidades:
#plays (cons) / plays_dsp (cons)
#users (cons)
#receita (rec)
#rpp (rec)

proj = 'plays'
type = 'cons'

orig_ts = get(sprintf('%s_orig_ts', proj))

info_dados_orig = get(sprintf('info_dados_%s_orig', proj))

ajuste_ts = get(sprintf('%s_ajuste_ts', proj))

info_dados_ajuste = get(sprintf('info_dados_%s_ajuste', proj))

dados_ts_type = get(sprintf('dados_ts_%s', type)) %>%
  select (all_of(c("Mês de Consumo", "Ano", "Mês", "mes", get(proj)))) %>%
  drop_na()

################# II. Coleta de Dados:######

# Gráfico ajustado - Definir se utilizaremos alguma modificação (Não acho necessário)

autoplot(orig_ts, xlab = "Tempo", ylab = sprintf("Qtd de %s", proj)) + 
  labs(
    title = sprintf("Qtd de %s", proj),
    y = proj,
    x = "Ano",
    color = "Forecasts"
  ) +
  coord_cartesian(ylim = c(0, NA)) + # Ajuste do eixo Y
  theme_minimal()


################# III. Análise Preliminar/Descritiva:######

# 2.1. Teste de variância ####

#Se p-valor >>>> alfa (normalmente delimitado como 0.05), não rejeito H0. Portanto, série Homocedástica
#Se p-valor < alfa (normalmente delimitado como 0.05), rejeito H0. Portanto, série Heterocedástica

data_regress = as.data.frame(dados_ts_type)
model_regress = lm(data_regress[[get(proj)]] ~ data_regress$mes)
model_regress

  # Teste de Breusch-Pagan
teste_bp = bptest(model_regress) 
teste_bp


# Condição para aplicar log ou não na coluna de proj
if (teste_bp$p.value < 0.05) {
  column_proj <- log(dados_ts_type[[get(proj)]]) 
  subtitle_1 <- sprintf("%s%s%s decomposition = trend + season_year + remainder", "log(", proj,")")
  labeller_name = sprintf("log(%s%s", proj, ")")
} else {
  column_proj <- dados_ts_type[[get(proj)]]  
  subtitle_1 <- sprintf("%s decomposition = trend + season_year + remainder", proj)
  labeller_name = sprintf("%s", proj)
}


# Tabela transformada (ou não - depende de column proj)

dados_ts_type |>
  summarise(proj = sum(!!sym(get(proj)), na.rm = F)) |>
  mutate(column_proj) |>
  pivot_longer(-mes) |>
  ggplot(aes(x = mes, y = value)) +
  geom_line() +
  facet_grid(name ~ ., scales = "free_y",
             labeller = as_labeller(c( 
               proj = proj,
               column_proj = labeller_name) ) ) +
  labs(y = "", title = sprintf("Qtd de %s", proj))

# 2.2. Função ggmonthplot do pacote forecast para identificar sazonalidade ####

ggmonthplot(ajuste_ts, main = "Média por mês - Histórico") + theme_minimal() 

menor_ano <- floor(min(time(ajuste_ts)[!is.na(ajuste_ts)]))
maior_ano <- floor(max(time(ajuste_ts)[!is.na(ajuste_ts)]))

ggseasonplot(ajuste_ts, year.labels = TRUE) + 
  labs(title = sprintf("Quebras Mensais - (%s-%s)", menor_ano, maior_ano),
       y = proj,
       x = "Mês") +
  geom_point() + theme_minimal()


################# IV. Escolha do Modelo/Fitting:######

# 3.1. Decomposição da série STL ####

#Observando o gráfico dos dados, podemos inferir sobre três componentes:

#a) Uma componente linear de crescimento dos dados bem suave
#b) Uma componente sazonal nos dados
#c) Uma componente aleatória nos dados

# trend(window): Determina o tamanho da janela para suavizar a tendência. 
  #Um valor maior resulta em uma tendência mais suave, capturando variações de longo prazo. 
  #Um valor menor permite que a tendência responda mais rapidamente a mudanças nos dados.

# season(window = ...): Controla a suavização da componente sazonal. 
  #Valores menores permitem que a sazonalidade varie mais ao longo do tempo, 
  #enquanto valores maiores (ou Inf) forçam uma sazonalidade constante.

# Dados com Sazonalidade Anual: Trend window = 13 ou 15./ Séries com mais ruído: Trend window = 21, 23 ou 25
# Dados com Sazonalidade estável: Seasonal window = periodic./ Sazonalidade mais variável: Seasonal window = 7,9 ou 11

#Para observar as três componentes, podemos decompor a série usando o seguinte comando:

stl_dcmp <- dados_ts_type %>%
  model(
    STL(column_proj ~ trend(window = 21) + season(window = 'periodic'), robust = TRUE)
  ) %>%
  components() %>%
  pivot_longer(cols = c(column_proj, trend, season_year, remainder), names_to = "component", 
               values_to = "value") %>%
  mutate(component = factor(
    ifelse(component == "column_proj", labeller_name, component),
    levels = c(labeller_name, "trend", "season_year", "remainder")
  )) 

stl_dcmp %>%
  ggplot(aes(x = mes, y = value)) +
  geom_line() +
  facet_grid(component ~ ., scales = "free_y") +
  labs(
    title = "STL decomposition",
    x = "Year/Month",
    subtitle = subtitle_1,
    y = proj
  )



# 3.2. Autocorrelação para analisar os ARIMA's ajustáveis (Teste KPSS - Unit Root Test):####

unit_root_seasonal <- dados_ts_type |> features(column_proj, unitroot_nsdiffs)
dif_seasonal = unit_root_seasonal$nsdiffs
altera_lag_max = 4

if (dif_seasonal > 0) {
  unit_root_ordinary <- dados_ts_type |> features(difference(column_proj, lag = 12*dif_seasonal), unitroot_ndiffs)
  dif_ordinary = unit_root_ordinary$ndiffs
  
  if (dif_ordinary > 0) {
    dados_ts_type %>%
      gg_tsdisplay(difference(column_proj, lag = 12*dif_seasonal) |> difference(differences = dif_ordinary), 
                   plot_type="partial", 
                   lag_max = 12*altera_lag_max) + 
      labs(title = "Autocorrelação - Double Differenced", y = "")
  } else {
    dados_ts_type %>%
      gg_tsdisplay(difference(column_proj, lag = 12*dif_seasonal), 
                   plot_type="partial", 
                   lag_max = 12*altera_lag_max) + 
      labs(title = "Autocorrelação - Seasonal Differenced", y = "")
  }
} else {
  unit_root_ordinary <- dados_ts_type |> features(column_proj, unitroot_ndiffs)
  dif_ordinary = unit_root_ordinary$ndiffs
  if (dif_ordinary > 0) {
    dados_ts_type %>%
      gg_tsdisplay(column_proj |> difference(differences = dif_ordinary), 
                   plot_type="partial", 
                   lag_max = 12*altera_lag_max) + 
      labs(title = "Autocorrelação - Differenced", y = "")
  } else {
    dados_ts_type %>%
      gg_tsdisplay(column_proj, 
                   plot_type="partial", 
                   lag_max = 12*altera_lag_max) + 
      labs(title = "Autocorrelação - No Differenced", y = "")
  }
}

sprintf('Diferenciação Sazonal (D): %s - Diferenciação Normal (d): %s', dif_seasonal, dif_ordinary)

# Análise de AR e MA
'Possibilidades de AR e MA segundo a PACF e ACF, com (d,D) = (x,y) - x pode ser igual a y:
MA q (parte não-sazonal do ACF) -> 0, 4
MA Q (parte sazonal do ACF - lags 12,24,36...) -> 0, 1

AR p (parte não-sazonal do PACF) -> 0, 4, 10
AR P (parte sazonal do PACF - lags 12,24,36...) -> 0, 1 , 2'
 


###################### V. Estimação e Validação dos Modelos #########

# 4.1. Modelo ARIMA: ####

' Com dois modelos iniciais, vamos compará-los com o modelo de auto arima para
identificar aquele que tem o menos AICc.'
' O modelo automatico utiliza um stepwise e uma approx = F para fazer o R encontrar um 
bom modelo que se encaixe aos dados, apesar de levar um tempo maior para rodar o 
modelo, isso não é um problema dado que estamos modelando apenas uma curva.'


#Alterar pdq e PDQ baseado na análise de autocorrelação 

proj_fit_arima = dados_ts_type |>
  model(
    arima1 = ARIMA(column_proj ~ 0 + pdq(0, 1, 0) + PDQ(0, 0, 0)),
    arima2 = ARIMA(column_proj ~ 0 + pdq(4, 1, 0) + PDQ(0, 0, 0)),
    auto_arima = ARIMA(column_proj ~ 0 + pdq(0:4, 1, 0:4) + PDQ(0:3, 0, 0:3),
                       stepwise = F, 
                       approximation = F)
  )


proj_fit_arima |> pivot_longer(everything(), names_to = "Model name",
                                 values_to = "Orders")


aic_comparison_arima <- 
  glance(proj_fit_arima) |> 
  arrange(AICc) |> 
  select(.model:BIC)
aic_comparison_arima

best_model_name_arima <- aic_comparison_arima |> 
  filter(AICc == min(AICc)) |> 
  pull(.model)


# Modelo com menor AICc.:
proj_fit_arima |> select(all_of(best_model_name_arima))


proj_fit_arima |> select(all_of(best_model_name_arima)) |> gg_tsresiduals(lag = 36)


#Análise dos resíduos do modelo escolhido:

best_model_info_arima <- proj_fit_arima %>%
  select(all_of(best_model_name_arima)) %>%
  pull() %>% 
  .[[1]]

p <- best_model_info_arima$fit$spec$p 
q <- best_model_info_arima$fit$spec$q 
P <- best_model_info_arima$fit$spec$P 
Q <- best_model_info_arima$fit$spec$Q
d <- best_model_info_arima$fit$spec$d
D <- best_model_info_arima$fit$spec$D

dof_arima <- best_model_info_arima$fit$spec$p +
  best_model_info_arima$fit$spec$q +
  best_model_info_arima$fit$spec$P +
  best_model_info_arima$fit$spec$Q

augment(proj_fit_arima) |>
  filter(.model == sprintf("%s", best_model_name_arima)) |>
  features(.innov, ljung_box, lag = 24, dof = dof_arima)

'O p-valor está bem acima de 0.05. Com isso, o p-valor é suficientemente alto para considerarmos os
resíduos um ruído branco'

# 4.2. Modelo ETS: ####

proj_fit_ets <- dados_ts_type %>% 
  model( 
    ets1 = ETS(column_proj ~ error("A") 
               + trend("N", alpha = 0.85) 
               + season("N")),
    ets_auto = ETS(column_proj)
  )



proj_fit_ets |> pivot_longer(everything(), names_to = "Model name",
                               values_to = "Orders")



aic_comparison_ets <- glance(proj_fit_ets) |> 
  arrange(AICc) |> 
  select(.model:BIC)

erro_comparison_ets <- proj_fit_ets |> 
  accuracy() |> 
  arrange(MAPE)|> 
  select(-ME, -MPE, -ACF1)

# Comparativo AICc
aic_comparison_ets
# Comparativo Erros
erro_comparison_ets

best_model_name_ets <- aic_comparison_ets |> 
  filter(AICc == min(AICc)) |> 
  pull(.model)

# ETS com menor AICc. :
proj_fit_ets |> select(all_of(best_model_name_ets))


proj_fit_ets |> select(all_of(best_model_name_ets)) |> gg_tsresiduals(lag = 36)

#Análise dos resíduos do modelo escolhido:

'Os resíduos apresentam spikes no lag 2 e 3 do ACF. 
Faremos o teste de ljung-box para validar o p-valor alto, 
com um grau de liberdade = 3 (phi + beta + gamma)'

best_model_info_ets <- proj_fit_ets %>%
  select(all_of(best_model_name_ets)) %>%
  pull() %>% 
  .[[1]]

params_ets <- best_model_info_ets %>% tidy()

dof_ets = 0
if (best_model_info_ets$fit$spec$trendtype != "N") {
  dof_ets <- dof_ets + 1
}

if (best_model_info_ets$fit$spec$seasontype != "N") {
  dof_ets <- dof_ets + 1
}

if (best_model_info_ets$fit$spec$damped == TRUE) {
  dof_ets <- dof_ets + 1
}


augment(proj_fit_ets) |>
  filter(.model == best_model_name_ets) |>
  features(.innov, ljung_box, lag = 24, dof = dof_ets)

'# Pelo teste de Ljung-box, o modelo do ETS falha
com um p-valor muito menor que 0.05, e não podemos considerar que os
resíduos são um ruído branco. No entanto, tivemos o menor AICc, e seguiremos com
esse modelo, mesmo que não passe em todos os testes.'

# 4.3. Treinamento dos modelos: ####

treinamento_proj = dados_ts_type |>
  mutate(column_proj = column_proj) |>
  filter(
    mes >= make_yearmonth(info_dados_ajuste$ano_i, info_dados_ajuste$mes_i) 
    & mes <= make_yearmonth(year = as.integer(info_dados_ajuste$ano_train_f),
                            month = as.integer(info_dados_ajuste$mes_train_f))
  )


teste_proj = dados_ts_type |>
  mutate(column_proj = column_proj) |>
  filter(
    mes >= make_yearmonth(info_dados_ajuste$ano_test_i, info_dados_ajuste$mes_test_i)  
    & mes <= make_yearmonth(info_dados_ajuste$ano_f, info_dados_ajuste$mes_f)
  )


# Condição para aplicar log ou não na coluna de train
if (teste_bp$p.value < 0.05) {
  column_train <- log(treinamento_proj[[get(proj)]])
  column_test <- log(teste_proj[[get(proj)]])
  
} else {
  column_train <- treinamento_proj[[get(proj)]]
  column_test <- teste_proj[[get(proj)]]
}


# 4.3.1. Treinamento do modelo ARIMA escolhido:####

arima_fit_train = treinamento_proj |>
  model(ARIMA(column_train ~ 0 + pdq(p, d, q) + PDQ(P, D, Q)))

arima_fit_train

report(arima_fit_train)


arima_fit_train |> gg_tsresiduals(lag_max = 36)

augment(arima_fit_train) |>
  features(.innov, ljung_box, lag = 24, dof = dof_arima)


# 4.3.2. Treinamento do modelo ETS escolhido:####

season_type <- best_model_info_ets$fit$spec$seasontype
trend_type <- best_model_info_ets$fit$spec$trendtype
error_type <- best_model_info_ets$fit$spec$errortype
damped_type <- best_model_info_ets$fit$spec$damped

alpha_model = params_ets %>% filter(term == "alpha") %>% pull(estimate)
beta_model = params_ets %>% filter(term == "beta") %>% pull(estimate)
phi_model = params_ets %>% filter(term == "phi") %>% pull(estimate)
gamma_model = params_ets %>% filter(term == "gamma") %>% pull(estimate)

if (trend_type == "N") {
  if (season_type == "N") {
    ets_fit_train = treinamento_proj |>
      model(ETS(column_train ~ error(error_type) 
                + trend(trend_type, alpha = alpha_model) 
                + season(season_type)))
  } else {
    ets_fit_train = treinamento_proj |>
      model(ETS(column_train ~ error(error_type) 
                + trend(trend_type, alpha = alpha_model) 
                + season(season_type, gamma = gamma_model)))
    }

} else if (season_type == "N" & trend_type != "N") {
  if (damped_type == TRUE) {
    trend_type_damped <- sprintf("%s%s", trend_type, "d")
    ets_fit_train = treinamento_proj |>
      model(ETS(column_train ~ error(error_type) 
                + trend(trend_type_damped, alpha = alpha_model, beta = beta_model, phi = phi_model) 
                + season(season_type)))
  
  } else {
    ets_fit_train = treinamento_proj |>
      model(ETS(column_train ~ error(error_type) 
                + trend(trend_type, alpha = alpha_model, beta = beta_model) 
                + season(season_type)))
  }
} else { 
  if (damped_type == TRUE) {
    trend_type_damped <- sprintf("%s%s", trend_type, "d")
    ets_fit_train = treinamento_proj |>
      model(ETS(column_train ~ error(error_type) 
                + trend(trend_type_damped, alpha = alpha_model, beta = beta_model, phi = phi_model) 
                + season(season_type, gamma = gamma_model)))
    
  } else {
    ets_fit_train = treinamento_proj |>
      model(ETS(column_train ~ error(error_type) 
                + trend(trend_type, alpha = alpha_model, beta = beta_model) 
                + season(season_type, gamma = gamma_model)))
  }
}


report(ets_fit_train)

ets_fit_train |> gg_tsresiduals(lag_max = 36)

augment(ets_fit_train) |>
  features(.innov, ljung_box, lag = 24, dof = dof_ets)


####################### VI. Comparação dos modelos treinados #########

# 5.1. Métricas de Erro dos treinos: ####
erros_treino <- bind_rows(
  arima_fit_train |> accuracy(),
  ets_fit_train |> accuracy(),
  arima_fit_train |> forecast(h = h_train) |> accuracy(teste_proj |> 
                                                   rename(column_train = column_proj)),
  ets_fit_train |> forecast(h = h_train) |> accuracy(teste_proj |> 
                                                 rename(column_train = column_proj))
) |>
  select(-ME, -MPE, -ACF1, -MASE, -RMSSE)
erros_treino

# 5.2. Comparação dos modelos de treinamento no gráfico (teste + ARIMA + ETS):####

treinamento_ts <- ts(
  data = column_train,
  start = c(year(min(treinamento_proj$mes)), 
            month(min(treinamento_proj$mes))),  
  frequency = 12
)

teste_ts <- ts(
  data = column_test,
  start = c(year(min(teste_proj$mes)), 
            month(min(teste_proj$mes))),  
  frequency = 12
)

previsao_train_arima = forecast(arima_fit_train, h = h_train)|> as_tsibble(index = mes)

previsao_train_arima_ts <- ts(
  data = previsao_train_arima$.mean,
  start = c(year(min(previsao_train_arima$mes)), 
            month(min(previsao_train_arima$mes))),  
  frequency = 12
)

previsao_train_ets = forecast(ets_fit_train, h = h_train)|> as_tsibble(index = mes)

previsao_train_ets_ts <- ts(
  data = previsao_train_ets$.mean,
  start = c(year(min(previsao_train_ets$mes)), 
            month(min(previsao_train_ets$mes))),  
  frequency = 12
)

autoplot(treinamento_ts, xlab = "Tempo", ylab = sprintf("Qtd de %s", proj)) + 
  autolayer(previsao_train_arima_ts, series = "Previsão Treinamento ARIMA",
            linetype = "dashed", na.rm = TRUE, size = 0.7) +
  autolayer(teste_ts, series = "Teste Real", na.rm = TRUE, color = "black") +
  autolayer(previsao_train_ets_ts, series = "Previsão Treinamento ETS", 
            linetype = "dashed", na.rm = TRUE, size = 0.8) +
  labs(
    title = sprintf("Quantidade de %s", proj),
    y = sprintf("%s", proj),
    x = "Ano-Mês",
    color = "Forecasts"
  ) +
  coord_cartesian(ylim = c(NA, NA)) + # Ajuste do eixo Y
  theme_minimal()


####################### VII. Projeção #########

# Baseado no erro do teste, aquele com menor erro no teste, será escolhido como o modelo projetado.
if (teste_bp$p.value < 0.05) {
  if (erros_treino$MAPE[4] < erros_treino$MAPE[3]) { 
    # Previsão Modelo ETS
    forecast(proj_fit_ets, h = h) |>
      filter(.model == best_model_name_ets) |>
      mutate(column_proj = exp(column_proj)) |>
      autoplot(dados_ts_type |> mutate (column_proj = exp(column_proj)), level = c(30, 60, 90)) + 
      labs(title = sprintf("Quantidade de %s %s", proj, "(ETS)"),
           y = sprintf("%s", proj),
           x="year/Month")
  } else {
    # Previsão Modelo ARIMA
    forecast(proj_fit_arima, h = h) |>
      filter(.model == best_model_name_arima) |>
      mutate(column_proj = exp(column_proj)) |>
      autoplot(dados_ts_type |> mutate(column_proj = exp(column_proj)), level = c(30, 60, 90)) + 
      labs(title = sprintf("Quantidade de %s %s", proj, "(ARIMA)"),
           y= sprintf("%s", proj))
    
  }
} else {
  if (erros_treino$MAPE[4] < erros_treino$MAPE[3]) { 
    # Previsão Modelo ETS
    forecast(proj_fit_ets, h = h) |>
      filter(.model == best_model_name_ets) |>
      autoplot(dados_ts_type, level = c(30, 60, 90)) + 
      labs(title = sprintf("Quantidade de %s %s", proj, "(ETS)"),
           y = sprintf("%s", proj),
           x="year/Month")
  } else {
    # Previsão Modelo ARIMA
    forecast(proj_fit_arima, h = h) |>
      filter(.model == best_model_name_arima) |>
      autoplot(dados_ts_type, level = c(30, 60, 90)) + 
      labs(title = sprintf("Quantidade de %s %s", proj, "(ARIMA)"),
           y= sprintf("%s", proj))
  }
}




