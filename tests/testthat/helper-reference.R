# The reference implementation this package was distilled from, kept
# verbatim as the oracle for the equivalence tests: given the same seed,
# the package must reproduce it draw for draw.
# nolint start
# Chromy

PMR <- function(lambda, Unif = runif(length(lambda)), prioridade = seq_along(lambda)) {

  N <- length(lambda)
  stopifnot(all(is.finite(lambda)), all(lambda >= 0), length(Unif) == N, all(Unif >= 0 & Unif < 1),
            length(prioridade) == N)
  tau <- 4 * .Machine$double.eps

  soma <- 0; comp <- 0
  for (x in lambda) {
    t <- soma + x
    if (abs(soma) >= abs(x)) comp <- comp + ((soma - t) + x) else comp <- comp + ((x - t) + soma)
    soma <- t
  }
  n <- round(soma + comp)
  eps_soma <- (soma - n) + comp
  stopifnot(abs(eps_soma) < 1e-8)

  k <- floor(lambda)
  r <- lambda - k

  j <- NA
  if (eps_soma != 0) {
    if (eps_soma > 0) cand <- which(r > eps_soma) else cand <- which(r > 0 & r - eps_soma < 1)
    stopifnot(length(cand) > 0)
    j <- cand[order(-r[cand], prioridade[cand])[1]]
    r[j] <- r[j] - eps_soma
  }

  V_I <- rep(0, N); V_F <- rep(0, N); T <- rep(0, N); n_i <- rep(0, N)
  F <- 0; cF <- 0
  divida <- 0; ajustes <- 0

  for (i in 1:N) {

    if (i == 1) {
      I_ant <- 0; F_ant <- 0; T_ant <- 0
    } else {
      I_ant <- V_I[i-1]; F_ant <- V_F[i-1]; T_ant <- T[i-1]
    }

    abate <- min(divida, r[i])
    r[i] <- r[i] - abate
    divida <- divida - abate

    s <- F + r[i]
    if (abs(F) >= abs(r[i])) cs <- cF + ((F - s) + r[i]) else cs <- cF + ((r[i] - s) + F)
    s_ef <- s + cs

    if (i < N && s_ef < 1 && s_ef >= 1 - tau) {
      divida <- divida + (1 - s_ef)
      r[i] <- r[i] + (1 - s_ef)
      s <- 1; cs <- 0; s_ef <- 1
      ajustes <- ajustes + 1
    }

    if (i == N) {
      cruza <- round(s_ef)
      r[i] <- cruza - F_ant
      F <- 0; cF <- 0
    } else {
      cruza <- as.integer(s_ef >= 1)
      F <- s - cruza; cF <- cs
    }

    V_I[i] <- I_ant + k[i] + cruza
    V_F[i] <- max(F + cF, 0)

    if (T_ant == I_ant) {
      if (cruza == 0) {
        P_T1 <- r[i] / (1 - F_ant)
      } else {
        P_T1 <- 0
      }
    } else {
      if (cruza == 0) {
        P_T1 <- 1
      } else if (F_ant > 0) {
        P_T1 <- V_F[i] / F_ant
      } else {
        P_T1 <- 0
      }
    }

    T[i] <- V_I[i] + (Unif[i] < P_T1)
    n_i[i] <- T[i] - T_ant
  }

  lambda_ef <- k + r
  zerados <- sum(lambda > 0 & lambda_ef <= 0)
  if (zerados > 0) stop(paste("PMR:", zerados, "unidade(s) com lambda > 0 ficaram sem probabilidade"))
  stopifnot(sum(n_i) == n)
  diag <- list(eps_soma = eps_soma, unidade_corrigida = j, cruzamentos_ajustados = ajustes,
               max_ajuste = max(abs(lambda_ef - lambda)), soma_hits = sum(n_i))
  if (diag$max_ajuste > 1e-12) warning(paste("PMR: lambda ajustado em até", signif(diag$max_ajuste, 3)))
  attr(n_i, "lambda_efetivo") <- lambda_ef
  attr(n_i, "diagnostico") <- diag
  n_i
}

#serpentina hierárquica
SERP <- function(controles, sort = "SERP") {

  postos <- list()
  for (j in 1:ncol(controles)) {
    v <- controles[[j]]
    if (is.numeric(v)) {
      postos[[j]] <- v
    } else {
      v <- as.character(v)
      postos[[j]] <- match(v, sort(unique(v), method = "radix"))
    }
  }
  stopifnot(!anyNA(unlist(postos)), sort %in% c("SERP", "NEST"))

  if (sort == "NEST" || length(postos) == 1) {
    return(do.call(order, c(postos, list(method = "radix"))))
  }

  ordem <- order(postos[[1]], method = "radix")
  N <- length(ordem)

  for (j in 2:length(postos)) {
    muda <- rep(FALSE, N)
    for (h in 1:(j-1)) {
      x <- postos[[h]][ordem]
      muda <- muda | c(TRUE, x[-1] != x[-N])
    }
    nivel <- cumsum(muda)
    sentido <- ifelse(nivel %% 2 == 1, 1, -1)
    ordem <- ordem[order(nivel, sentido * postos[[j]][ordem], method = "radix")]
  }
  ordem
}

HEAD <- function(lambda) {
  sample.int(length(lambda), 1, prob = lambda)
}

Chromy_SAS <- function(lambda, ordem, cabeca = "todas") {

  stopifnot(cabeca %in% c("todas", "residuais"), identical(sort(as.integer(ordem)), seq_along(lambda)))
  N <- length(ordem)
  if (cabeca == "todas") {
    elegiveis <- 1:N
  } else {
    elegiveis <- which(lambda[ordem] != floor(lambda[ordem]))
  }
  if (length(elegiveis) == 0) {
    return(list(cabeca = 1, lista = ordem, n_i = as.integer(lambda[ordem]), lambda_efetivo = lambda))
  }

  st <- elegiveis[HEAD(lambda[ordem[elegiveis]])]
  if (st == 1) {
    posicao <- 1:N
  } else {
    posicao <- c(st:N, 1:(st-1))
  }
  lista <- ordem[posicao]

  n_i <- rep(0, N)
  lambda_efetivo <- lambda
  if (cabeca == "todas") {
    sorteio <- PMR(lambda[lista], prioridade = posicao)
    n_i <- as.vector(sorteio)
    if (!is.null(attr(sorteio, "lambda_efetivo"))) lambda_efetivo[lista] <- attr(sorteio, "lambda_efetivo")
  } else {
    fixas <- lambda[lista] == floor(lambda[lista])
    n_i[fixas] <- lambda[lista][fixas]
    sorteio <- PMR(lambda[lista[!fixas]], prioridade = posicao[!fixas])
    n_i[!fixas] <- sorteio
    if (!is.null(attr(sorteio, "lambda_efetivo"))) lambda_efetivo[lista[!fixas]] <- attr(sorteio, "lambda_efetivo")
  }
  list(cabeca = st, lista = lista, n_i = n_i, lambda_efetivo = lambda_efetivo,
       diagnostico = attr(sorteio, "diagnostico"))
}

tamanho_MPPS <- function(X, n_j) {
  stopifnot(!anyNA(X), all(X >= 0), any(colSums(X) > 0), length(n_j) == ncol(X), all(n_j > 0))
  X_j <- colSums(X)
  use <- X_j > 0
  sh <- sweep(X[, use, drop = FALSE], 2, X_j[use], "/")
  sh <- sweep(sh, 2, n_j[use] / mean(n_j[use]), "*")
  S <- apply(sh, 1, max)
  S[S <= 0] <- min(S[S > 0])
  S
}

lambda_Chromy <- function(S, n, reposicao_minima = FALSE) {
  stopifnot(!anyNA(S), all(S >= 0), sum(S) > 0, n == round(n), n >= 1,
            reposicao_minima || n <= sum(S > 0))
  if (reposicao_minima) return(n * S / sum(S))
  if (n == sum(S > 0)) return(as.numeric(S > 0))

  N <- length(S)
  cert <- rep(FALSE, N)
  repeat {
    restante <- n - sum(cert)
    stopifnot(restante > 0 || all(cert))
    lambda <- rep(0, N)
    lambda[cert] <- 1
    if (restante > 0) lambda[!cert] <- restante * S[!cert] / sum(S[!cert])
    novas <- !cert & lambda >= 1
    if (!any(novas)) break
    cert <- cert | novas
  }
  pmin(lambda, 1)
}

nj_eqcv <- function(X, n, max_iter = 300, tol_cv = 1e-3, amortecimento = 0.5) {

  X_j <- colSums(X)
  use <- X_j > 0
  n_j <- rep(1, ncol(X)); names(n_j) <- colnames(X)
  sh <- sweep(X[, use, drop = FALSE], 2, X_j[use], "/")

  cv <- function(n_j) {
    pi <- lambda_Chromy(tamanho_MPPS(X, n_j), n)
    a <- pi * (1 - pi)
    if (sum(a) == 0) return(rep(0, ncol(sh)))
    A <- colSums((1 - pi) * sh) / sum(a)
    sqrt(colSums(a * (sh / pi - matrix(A, nrow(sh), ncol(sh), byrow = TRUE))^2))
  }

  cv_j <- cv(n_j)
  it <- 0
  while (it < max_iter) {
    pos <- cv_j > 0
    if (!any(pos) || max(cv_j[pos]) / min(cv_j[pos]) - 1 < tol_cv) break
    g <- exp(mean(log(cv_j[pos])))
    idx <- which(use)[pos]
    n_j[idx] <- n_j[idx] * (cv_j[pos] / g)^amortecimento
    n_j <- n_j / exp(mean(log(n_j[use])))
    cv_j <- cv(n_j)
    it <- it + 1
  }
  pos <- cv_j > 0
  if (any(pos) && max(cv_j[pos]) / min(cv_j[pos]) - 1 >= tol_cv) warning("nj_eqcv não convergiu")
  n_j
}

amostra_Chromy <- function(dados, n, tamanho = NULL, auxiliares = NULL, controles = NULL,
                           ordenacao = "SERP", reposicao_minima = FALSE, cabeca = "todas",
                           regra_nj = "eqcv", semente = NULL) {

  stopifnot(!("tamanho_Chromy" %in% names(dados)), ordenacao %in% c("SERP", "NEST"),
            cabeca %in% c("todas", "residuais"), is.numeric(regra_nj) || regra_nj %in% c("eqcv", "iguais"))

  if (!is.null(auxiliares)) {
    X <- as.matrix(dados[auxiliares]); storage.mode(X) <- "double"
    if (is.numeric(regra_nj)) {
      n_j <- regra_nj
    } else if (regra_nj == "eqcv") {
      if (n > nrow(X)) stop("eqcv precisa de n <= N; com n > N use regra_nj = 'iguais' ou um vetor de n_j")
      n_j <- nj_eqcv(X, n)
    } else {
      n_j <- rep(1, ncol(X))
    }
    S <- tamanho_MPPS(X, n_j)
  } else {
    n_j <- NULL
    if (is.null(tamanho)) S <- rep(1, nrow(dados)) else S <- as.numeric(dados[[tamanho]])
  }

  lambda <- lambda_Chromy(S, n, reposicao_minima)
  if (any(S == 0)) warning(paste(sum(S == 0), "unidades com tamanho zero: lambda = 0, fora da cobertura da amostra"))
  dados$tamanho_Chromy <- S

  if (is.null(controles)) {
    ordem <- 1:nrow(dados)
  } else {
    ordem <- SERP(dados[, controles, drop = FALSE], ordenacao)
  }

  if (!is.null(semente)) set.seed(semente, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
  s <- Chromy_SAS(lambda, ordem, cabeca)

  sample.pos <- which(s$n_i > 0)
  u <- s$lista[sample.pos]
  lam <- s$lambda_efetivo
  amostra <- data.frame(unidade = u, posicao_lista = sample.pos,
                        ExpectedHits = lam[u], NumberHits = s$n_i[sample.pos],
                        SamplingWeight = 1 / lam[u],
                        hits_fixos = floor(lam[u]),
                        hits_aleatorios = s$n_i[sample.pos] - floor(lam[u]),
                        dados[u, , drop = FALSE], row.names = NULL, check.names = FALSE)

  list(amostra = amostra, lambda = lambda, lambda_efetivo = lam, tamanho = S, n_j = n_j,
       ordem = ordem, cabeca = s$cabeca, diagnostico = s$diagnostico)
}

estima_HT <- function(Y, amostra) {
  Y <- as.matrix(Y)
  if (is.null(colnames(Y))) colnames(Y) <- paste0("y", 1:ncol(Y))
  stopifnot(is.numeric(Y), all(is.finite(Y)), max(amostra$unidade) <= nrow(Y))
  a <- amostra[order(amostra$posicao_lista), ]
  y_l <- Y[a$unidade, , drop = FALSE] / a$ExpectedHits
  HT <- colSums(y_l * a$NumberHits)

  z <- y_l[a$hits_aleatorios == 1, , drop = FALSE]
  m <- nrow(z)
  if (m > 1) {
    v_SD <- m / (2 * (m - 1)) * colSums(diff(z)^2)
  } else if (m == 0) {
    v_SD <- rep(0, ncol(y_l))
  } else {
    v_SD <- rep(NA, ncol(y_l))
  }

  data.frame(variavel = colnames(y_l), HT = HT, m_sorteadas = m,
             EP_dif_sucessivas = sqrt(v_SD),
             CV_dif_sucessivas_pct = ifelse(HT != 0, 100 * sqrt(v_SD) / abs(HT), NA),
             row.names = NULL)
}

# res <- amostra_Chromy(base, n = 200, tamanho = "area",
#                       controles = c("regiao", "municipio", "tamanho_Chromy"), semente = 123)
# estima_HT(base[c("producao", "receita")], res$amostra)
# nolint end
