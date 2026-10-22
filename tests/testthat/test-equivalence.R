# The package against the reference implementation, draw for draw: the same
# seed must give the same sample, because the package consumes R's generator
# in the same order (one sample.int for the head, one runif per randomised
# unit) and the engine reproduces the reference arithmetic exactly.

make_frame <- function(n_units = 120, seed = 42) {
  set.seed(seed, kind = "Mersenne-Twister", sample.kind = "Rejection")
  data.frame(
    region = sample(c("north", "east", "south", "west"), n_units, replace = TRUE),
    district = sample(sprintf("d%02d", 1:12), n_units, replace = TRUE),
    area = rlnorm(n_units, 3),
    pupils = rlnorm(n_units, 4),
    staff = rlnorm(n_units, 2)
  )
}

expect_same_sample <- function(got, reference) {
  expect_equal(got$sample$unit, reference$amostra$unidade)
  expect_equal(got$sample$position, reference$amostra$posicao_lista)
  expect_equal(got$sample$hits, reference$amostra$NumberHits)
  expect_equal(got$sample$expected_hits, reference$amostra$ExpectedHits)
  expect_equal(got$sample$weight, reference$amostra$SamplingWeight)
  expect_equal(got$expected_hits, reference$lambda)
  expect_equal(got$effective_hits, reference$lambda_efetivo)
  expect_equal(got$order, reference$ordem)
}

test_that("a size-column selection reproduces the reference, seed for seed", {
  frame <- make_frame()
  for (seed in c(1, 123, 2026)) {
    reference <- suppressWarnings(
      amostra_Chromy(frame, n = 30, tamanho = "area", semente = seed)
    )
    got <- suppressWarnings(
      chromy_sample(frame, n = 30, size = "area", seed = seed)
    )
    expect_same_sample(got, reference)
  }
})

test_that("a serpentine-ordered selection reproduces the reference", {
  frame <- make_frame()
  reference <- suppressWarnings(amostra_Chromy(
    frame,
    n = 25, tamanho = "area",
    controles = c("region", "district", "tamanho_Chromy"), semente = 7
  ))
  got <- suppressWarnings(chromy_sample(
    frame,
    n = 25, size = "area",
    order_by = c("region", "district", "chromy_size"), seed = 7
  ))
  expect_same_sample(got, reference)
})

test_that("a nested-ordered selection reproduces the reference", {
  frame <- make_frame()
  reference <- suppressWarnings(amostra_Chromy(
    frame,
    n = 20, tamanho = "area",
    controles = c("region", "district"), ordenacao = "NEST", semente = 11
  ))
  got <- suppressWarnings(chromy_sample(
    frame,
    n = 20, size = "area",
    order_by = c("region", "district"), method = "nested", seed = 11
  ))
  expect_same_sample(got, reference)
})

test_that("the residual head reproduces the reference", {
  frame <- make_frame()
  reference <- suppressWarnings(amostra_Chromy(
    frame,
    n = 40, tamanho = "area", cabeca = "residuais", semente = 3
  ))
  got <- suppressWarnings(chromy_sample(
    frame,
    n = 40, size = "area", head = "residual", seed = 3
  ))
  expect_same_sample(got, reference)
})

test_that("minimum replacement reproduces the reference", {
  frame <- make_frame(n_units = 15)
  reference <- suppressWarnings(amostra_Chromy(
    frame,
    n = 30, tamanho = "area", reposicao_minima = TRUE, semente = 5
  ))
  got <- suppressWarnings(chromy_sample(
    frame,
    n = 30, size = "area", min_replacement = TRUE, seed = 5
  ))
  expect_same_sample(got, reference)
  expect_true(any(got$sample$hits > 1) || all(got$expected_hits < 1))
})

test_that("the multivariate equal-CV design reproduces the reference", {
  frame <- make_frame()
  reference <- suppressWarnings(amostra_Chromy(
    frame,
    n = 25, auxiliares = c("pupils", "staff"),
    controles = c("region", "tamanho_Chromy"), semente = 9
  ))
  got <- suppressWarnings(chromy_sample(
    frame,
    n = 25, variables = c("pupils", "staff"),
    order_by = c("region", "chromy_size"), seed = 9
  ))
  expect_same_sample(got, reference)
  expect_equal(unname(got$n_j), unname(reference$n_j))
})

test_that("estimation reproduces the reference", {
  frame <- make_frame()
  reference_sample <- suppressWarnings(
    amostra_Chromy(frame, n = 30, tamanho = "area", semente = 17)
  )
  reference <- estima_HT(frame[c("pupils", "staff")], reference_sample$amostra)

  got_sample <- suppressWarnings(
    chromy_sample(frame, n = 30, size = "area", seed = 17)
  )
  got <- estimate_total(got_sample, c("pupils", "staff"))

  expect_equal(got$total, reference$HT)
  expect_equal(got$se, reference$EP_dif_sucessivas)
  expect_equal(got$cv_pct, reference$CV_dif_sucessivas_pct)
  expect_equal(got$random_draws, reference$m_sorteadas)
})

test_that("the building blocks match the reference one by one", {
  frame <- make_frame(n_units = 60)

  # The serpentine and nested orders.
  expect_equal(
    serpentine_order(frame, c("region", "district", "area")),
    SERP(frame[, c("region", "district", "area")], "SERP")
  )
  expect_equal(
    serpentine_order(frame, c("region", "area"), method = "nested"),
    SERP(frame[, c("region", "area")], "NEST")
  )

  # The maximal size measure and the equal-CV factors.
  X <- as.matrix(frame[c("pupils", "staff")])
  expect_equal(
    mpps_size(frame, c("pupils", "staff"), c(1, 2)),
    tamanho_MPPS(X, c(1, 2))
  )
  expect_equal(
    as.numeric(suppressWarnings(eqcv_allocation(frame, c("pupils", "staff"), 15))),
    as.numeric(suppressWarnings(nj_eqcv(X, 15))),
    tolerance = 1e-9
  )

  # Expected hits, with and without certainties.
  S <- frame$area
  expect_equal(expected_hits(S, 10), lambda_Chromy(S, 10))
  expect_equal(
    expected_hits(S, 10, min_replacement = TRUE),
    lambda_Chromy(S, 10, reposicao_minima = TRUE)
  )

  # The selection itself, on fixed uniforms.
  lambda <- lambda_Chromy(S, 12)
  set.seed(31, kind = "Mersenne-Twister", sample.kind = "Rejection")
  unif <- runif(length(lambda))
  reference <- PMR(lambda, unif)
  got <- pmr_rs(lambda, unif, seq_along(lambda) - 1L)
  expect_equal(got$hits, as.vector(reference))
  expect_equal(got$effective_lambda, attr(reference, "lambda_efetivo"))
})
