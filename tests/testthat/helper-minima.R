# A second, independently written implementation of the selection (the
# cumulative formulation), written by Clara Ribeiro de Santana and kept
# verbatim as a further oracle: same seed, same hits.
# nolint start
# Chromy com reposição mínima

#esperado é o vetor com os pis calculados
chromy_minima <- function(esperado) {
  
  if (!is.numeric(esperado) || !length(esperado) ||
      any(!is.finite(esperado)) || any(esperado < 0)) {
    stop("Os valores devem ser finitos e não negativos")
  }
  
  
  #somas os pis e arredonda para o inteiro mais próximo
  n <- round(sum(esperado))
  
  #verifica se a soma original está suficientemente próxima de n
  if (abs(sum(esperado) - n) > 1e-8) {
    stop("A soma dos valores esperados precisa ser inteira")
  }
  
  #conta quantas unidades existe
  N <- length(esperado)
  
  #se o total de seleção for zero não tem sorteio e cria vetor com zeros
  if (n == 0) return(integer(N))
  
  # sorteia o início proporcionalmente ao tamanho, soma acumulada e número aleatório
  inicio <- which(
    cumsum(esperado) > runif(1) * sum(esperado)
  )[1]
  
  # percorre a ordem de maneira circular
  ordem <- c(
    seq.int(inicio, N),
    if (inicio > 1) seq_len(inicio - 1)
  )
  
  acumulado <- cumsum(esperado[ordem])
  
  # corrige erros numéricos minúsculos perto de números inteiros.
  perto <- abs(acumulado - round(acumulado)) < 1e-12
  acumulado[perto] <- round(acumulado[perto])
  acumulado[N] <- n
  
  #gera N números aleatórios
  uniformes <- runif(N)
  #vetor de zeros para vermos quantas vezes a unidade foi selecionada
  vezes <- integer(N)
  
  total_anterior <- 0
  inteiro_anterior <- 0
  fracao_anterior <- 0
  
  for (i in seq_len(N)) {
    
    inteiro <- floor(acumulado[i])
    fracao <- acumulado[i] - inteiro
    
    if (total_anterior == inteiro_anterior) {
      
      if (fracao == 0 || fracao_anterior > fracao) {
        total <- inteiro
      } else {
        chance <- (fracao - fracao_anterior) /
          (1 - fracao_anterior)
        
        total <- inteiro + as.integer(uniformes[i] < chance)
      }
      
    } else {
      
      if (fracao == 0) {
        total <- inteiro
      } else if (fracao > fracao_anterior) {
        total <- inteiro + 1
      } else {
        chance <- fracao / fracao_anterior
        total <- inteiro + as.integer(uniformes[i] < chance)
      }
    }
    
    vezes[ordem[i]] <- total - total_anterior
    
    total_anterior <- total
    inteiro_anterior <- inteiro
    fracao_anterior <- fracao
  }
  
  # confere o total e a regra de reposição mínima.
  stopifnot(
    sum(vezes) == n,
    all(vezes >= 0),
    all(vezes >= floor(esperado)),
    all(vezes <= ceiling(esperado))
  )
  
  vezes
}


# nolint end
