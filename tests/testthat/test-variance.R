# The exact second-order probabilities and the replicate weights.

test_that("the joint inclusion matrix satisfies the design identities", {
  set.seed(21)
  frame <- data.frame(size = rlnorm(50, 2))
  s <- chromy_sample(frame, n = 12, size = "size", seed = 2)

  p2 <- joint_inclusion(s)
  expect_true(all(abs(p2 - t(p2)) < 1e-12))
  expect_equal(unname(diag(p2)), s$sample$expected_hits)
  off <- p2[upper.tri(p2)]
  expect_true(all(off >= -1e-12 & off <= 1 + 1e-12))

  # The full-frame identity: rows of the complete matrix sum to
  # (n - 1) * pi.
  full <- joint_inclusion_rs(
    s$effective_hits, s$order - 1L, seq_along(s$effective_hits) - 1L, TRUE
  )
  full <- matrix(full, nrow = length(s$effective_hits), byrow = TRUE)
  rows <- rowSums(full) - diag(full)
  expect_equal(rows, 11 * s$effective_hits, tolerance = 1e-8)
})

test_that("a minimum-replacement or residual-head sample is refused", {
  frame <- data.frame(size = c(100, rlnorm(30, 1)))
  s_mr <- suppressWarnings(
    chromy_sample(frame, n = 8, size = "size", min_replacement = TRUE, seed = 1)
  )
  expect_error(joint_inclusion(s_mr), "without-replacement")
  s_res <- chromy_sample(frame, n = 8, size = "size", head = "residual", seed = 1)
  expect_error(joint_inclusion(s_res), "all")
})

test_that("the exact PPS variance is honest in repetition", {
  skip_if_not_installed("survey")
  skip_on_cran()
  set.seed(31)
  frame <- data.frame(size = rlnorm(40, 2))
  frame$y <- 20 + 5 * frame$size + rnorm(40, sd = 8)
  truth <- sum(frame$y)

  runs <- t(replicate(400, {
    s <- chromy_sample(frame, n = 10, size = "size")
    d <- as_svydesign(s, variance = "pps")
    est <- survey::svytotal(~y, d)
    c(total = as.numeric(coef(est)), var = as.numeric(survey::SE(est))^2)
  }))
  expect_equal(mean(runs[, "total"]), truth, tolerance = 0.02)
  ratio <- mean(runs[, "var"]) / var(runs[, "total"])
  expect_gt(ratio, 0.7)
  expect_lt(ratio, 1.4)
})

test_that("the pps design reproduces the point estimates", {
  skip_if_not_installed("survey")
  set.seed(5)
  frame <- data.frame(size = rlnorm(60, 2), y = rlnorm(60, 4))
  s <- chromy_sample(frame, n = 15, size = "size", seed = 3)
  d <- as_svydesign(s, variance = "pps")
  expect_equal(
    as.numeric(coef(survey::svytotal(~y, d))),
    estimate_total(s, "y")$total
  )
})

test_that("the replicate design carries the Fay-Train factors", {
  skip_if_not_installed("survey")
  set.seed(13)
  frame <- data.frame(size = rlnorm(120, 2), y = rlnorm(120, 4))
  s <- chromy_sample(frame, n = 30, size = "size", seed = 7)
  r <- as_svrepdesign(s)

  expect_s3_class(r, "svyrep.design")
  # The same total as the multiplicity estimator.
  expect_equal(
    as.numeric(coef(survey::svytotal(~y, r))),
    estimate_total(s, "y")$total
  )
  # Perturbation factors only take the three Fay-Train values, and
  # certainty rows are never perturbed.
  f <- as.matrix(r$repweights) / weights(s)
  values <- sort(unique(round(as.numeric(f), 6)))
  expect_true(all(values %in% round(c(1 - 2^-0.5, 1, 1 + 2^-0.5), 6)))
  certain <- s$sample$random_hits == 0
  if (any(certain)) expect_true(all(f[certain, ] == 1))
})

test_that("the replicate variance tracks the successive-difference variance", {
  skip_if_not_installed("survey")
  skip_on_cran()
  set.seed(17)
  frame <- data.frame(size = rlnorm(150, 2))
  frame$y <- 10 + 3 * frame$size + rnorm(150, sd = 4)

  ratios <- replicate(60, {
    s <- chromy_sample(frame, n = 40, size = "size")
    sdr <- as.numeric(survey::SE(survey::svytotal(~y, as_svrepdesign(s))))
    sd2 <- estimate_total(s, "y")$se
    (sdr / sd2)^2
  })
  expect_gt(mean(ratios), 0.6)
  expect_lt(mean(ratios), 1.7)
})
