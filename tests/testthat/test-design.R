# The method's own promises, independent of the reference.

test_that("the sample size is exact and hits stay within one of expectation", {
  set.seed(1)
  frame <- data.frame(size = rlnorm(200, 2))
  for (n in c(5, 37, 120)) {
    s <- suppressWarnings(chromy_sample(frame, n = n, size = "size", seed = n))
    expect_equal(sum(s$sample$hits), n)
    expect_true(all(
      s$sample$hits == floor(s$sample$expected_hits) |
        s$sample$hits == ceiling(s$sample$expected_hits)
    ))
    expect_equal(sum(s$expected_hits), n, tolerance = 1e-9)
  }
})

test_that("minimum replacement can select a unit more than once", {
  frame <- data.frame(size = c(1000, rep(1, 20)))
  s <- suppressWarnings(
    chromy_sample(frame, n = 10, size = "size", min_replacement = TRUE, seed = 4)
  )
  expect_gt(max(s$sample$hits), 1)
  expect_equal(sum(s$sample$hits), 10)
})

test_that("expected hits are recovered in expectation", {
  frame <- data.frame(size = c(5, 1, 3, 2, 8, 4, 6, 1))
  lambda <- expected_hits(frame$size, 4)
  hits <- matrix(0, 2000, nrow(frame))
  set.seed(99)
  for (r in seq_len(nrow(hits))) {
    s <- chromy_sample(frame, n = 4, size = "size")
    hits[r, s$sample$unit] <- s$sample$hits
  }
  observed <- colMeans(hits)
  se <- sqrt(lambda * (1 - pmin(lambda, 1)) / nrow(hits))
  expect_true(all(abs(observed - lambda) < 4 * pmax(se, 0.005)))
})

test_that("a selection is reproducible from its seed", {
  frame <- data.frame(
    g = rep(letters[1:4], 10), size = rlnorm(40, 1)
  )
  a <- chromy_sample(frame, n = 12, size = "size", order_by = "g", seed = 8)
  b <- chromy_sample(frame, n = 12, size = "size", order_by = "g", seed = 8)
  expect_identical(a$sample, b$sample)
})

test_that("input errors are caught with a clear message", {
  frame <- data.frame(size = c(1, 2, 3), chromy_size = 1)
  expect_error(chromy_sample(frame, 2, size = "size"), "chromy_size")

  frame <- data.frame(size = c(1, 2, 3))
  expect_error(chromy_sample(frame, 5, size = "size"), "positive size")
  expect_error(chromy_sample(frame, 2, size = "missing"), "not found")
  expect_error(serpentine_order(frame, "missing"), "not found")
  expect_error(
    serpentine_order(data.frame(k = c(1, NA)), "k"),
    "missing"
  )
  expect_error(expected_hits(c(0, 0), 1), "zero")
  expect_error(
    eqcv_allocation(data.frame(a = 1:3, b = 4:6), c("a", "b"), 10),
    "at most"
  )
})

test_that("a frame column clashing with a design name is kept under _frame", {
  frame <- data.frame(unit = sprintf("u%02d", 1:30), size = rlnorm(30, 2))
  expect_warning(
    s <- chromy_sample(frame, n = 8, size = "size", seed = 3),
    "_frame"
  )
  expect_true(all(c("unit", "unit_frame") %in% names(s$sample)))
  expect_identical(s$sample$unit_frame, frame$unit[s$sample$unit])
})

test_that("the printed objects describe themselves", {
  frame <- data.frame(size = rlnorm(30, 2))
  s <- suppressWarnings(chromy_sample(frame, n = 8, size = "size", seed = 2))
  expect_s3_class(s, "chromy_sample")
  expect_output(print(s), "chromy_sample")
  expect_output(print(summary(s)), "frame of 30")
  expect_s3_class(as.data.frame(s), "data.frame")
})
