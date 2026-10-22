# The bridge to the survey package --------------------------------------------

#' A chromy sample as a survey design
#'
#' Hands the sample to the `survey` package: one row per selected unit,
#' weighted by `hits / expected_hits`, so `survey::svytotal()` reproduces
#' [estimate_total()]'s point estimates and the whole of `survey`'s
#' toolbox — ratios, regressions, domains, calibration — applies.
#'
#' The variance `survey` reports under this design (`ids = ~1`) is the
#' with-replacement approximation: it ignores the implicit stratification
#' the serpentine order bought, so it tends to be more conservative than
#' the successive-difference variance of [estimate_total()], which reads
#' that order. Both are defensible reports; they answer slightly different
#' questions about the same sample.
#'
#' @param x A [chromy_sample()].
#' @param ... Passed on to [survey::svydesign()].
#' @return A `survey.design` object.
#' @export
#' @examplesIf requireNamespace("survey", quietly = TRUE)
#' set.seed(7)
#' frame <- data.frame(size = rlnorm(80, 3), y = rlnorm(80, 5))
#' s <- chromy_sample(frame, n = 25, size = "size")
#' d <- as_svydesign(s)
#' survey::svytotal(~y, d)
#' estimate_total(s, "y")
as_svydesign <- function(x, ...) {
  if (!inherits(x, "chromy_sample")) {
    cli::cli_abort("{.arg x} must be a {.cls chromy_sample}.")
  }
  rlang::check_installed("survey", reason = "to build a survey design.")
  survey::svydesign(ids = ~1, weights = weights(x), data = x$sample, ...)
}

#' Sampling weights of a chromy sample
#'
#' The weight each selected row carries in the multiplicity estimator:
#' `hits / expected_hits`. These are the weights [as_svydesign()] hands to
#' the `survey` package, and the ones to use in any weighted analysis of
#' the sample.
#'
#' @param object A [chromy_sample()].
#' @param ... Unused.
#' @return A numeric vector, one weight per row of `object$sample`.
#' @export
weights.chromy_sample <- function(object, ...) {
  object$sample$hits * object$sample$weight
}
