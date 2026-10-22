# The engine against a second, independently written implementation: the
# cumulative formulation of chromy_minima (helper-minima.R, by Clara
# Ribeiro de Santana). Replaying its
# exact consumption of R's generator — one uniform for the head by
# cumulative inversion, then one per unit — the engine must reproduce its
# hits, seed for seed. Two formulations written by different hands agreeing
# draw for draw is evidence the transition probabilities are right, not
# merely copied.

replay_minima <- function(expected, seed) {
  set.seed(seed, kind = "Mersenne-Twister", sample.kind = "Rejection")
  reference <- chromy_minima(expected)

  set.seed(seed, kind = "Mersenne-Twister", sample.kind = "Rejection")
  start <- which(cumsum(expected) > runif(1) * sum(expected))[1]
  ordering <- c(
    seq.int(start, length(expected)),
    if (start > 1) seq_len(start - 1)
  )
  unif <- runif(length(expected))
  got <- pmr_rs(expected[ordering], unif, ordering - 1L)
  hits <- integer(length(expected))
  hits[ordering] <- got$hits

  list(reference = as.integer(reference), hits = hits)
}

test_that("the engine reproduces the cumulative implementation, seed for seed", {
  set.seed(42, kind = "Mersenne-Twister", sample.kind = "Rejection")
  size <- rlnorm(80, 2)

  for (n in c(1, 7, 25)) {
    lambda <- expected_hits(size, n, min_replacement = TRUE)
    for (seed in c(1, 77, 2026, 55501)) {
      r <- replay_minima(lambda, seed)
      expect_identical(r$hits, r$reference,
        label = sprintf("hits (n = %d, seed = %d)", n, seed)
      )
    }
  }
})

test_that("the cumulative implementation agrees on a frame with certainties", {
  size <- c(500, 300, rlnorm(40, 1))
  lambda <- expected_hits(size, 10, min_replacement = TRUE)
  for (seed in c(3, 19, 404)) {
    r <- replay_minima(lambda, seed)
    expect_identical(r$hits, r$reference)
    expect_true(max(r$hits) > 1) # the large units really repeat
  }
})
