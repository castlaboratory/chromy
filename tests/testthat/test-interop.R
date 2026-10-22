# The package next to its neighbours: the low-level selector for
# sampling-style pipelines, the survey bridge, and the agreement of the
# inclusion probabilities with the sampling package's.

test_that("pmr() consumes the generator exactly as chromy_sample()", {
  set.seed(10)
  frame <- data.frame(
    g = sample(letters[1:4], 60, replace = TRUE),
    size = rlnorm(60, 2)
  )
  listing <- serpentine_order(frame, c("g", "size"))
  lambda <- expected_hits(frame$size, 18)

  s <- chromy_sample(frame, n = 18, size = "size", order_by = c("g", "size"), seed = 5)
  hits <- pmr(lambda, order = listing, seed = 5)

  expect_equal(sum(hits), 18L)
  full <- integer(60)
  full[s$sample$unit] <- s$sample$hits
  expect_identical(hits, structure(full,
    effective_hits = attr(hits, "effective_hits"),
    head_position = attr(hits, "head_position")
  ))
  expect_equal(attr(hits, "effective_hits")[s$sample$unit], s$sample$expected_hits)
})

test_that("pmr() stands alone on a plain vector of expected hits", {
  hits <- pmr(c(2.4, 0.3, 0.8, 0.5), seed = 1)
  expect_equal(sum(hits), 4L)
  expect_true(hits[1] >= 2)
  expect_error(pmr(c(0.5, 0.6)), "integer")
  expect_error(pmr(c(0.5, 0.5), order = c(1L, 1L)), "permutation")
})

test_that("expected hits agree with sampling::inclusionprobabilities", {
  skip_if_not_installed("sampling")
  set.seed(3)
  size <- c(500, 300, rlnorm(60, 2))
  for (n in c(5, 12, 30)) {
    expect_equal(
      expected_hits(size, n),
      as.numeric(sampling::inclusionprobabilities(size, n)),
      tolerance = 1e-12
    )
  }
})

test_that("the survey bridge reproduces the totals", {
  skip_if_not_installed("survey")
  set.seed(7)
  frame <- data.frame(size = rlnorm(80, 3), y = rlnorm(80, 5), z = rlnorm(80, 2))
  s <- chromy_sample(frame, n = 25, size = "size")

  d <- as_svydesign(s)
  via_survey <- as.numeric(coef(survey::svytotal(~ y + z, d)))
  via_chromy <- estimate_total(s, c("y", "z"))$total
  expect_equal(via_survey, via_chromy)

  expect_equal(weights(s), s$sample$hits / s$sample$expected_hits)
  expect_error(as_svydesign(frame), "chromy_sample")
})
