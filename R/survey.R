# The bridge to the survey package --------------------------------------------

#' A chromy sample as a survey design
#'
#' Hands the sample to the `survey` package: one row per selected unit,
#' weighted by `hits / expected_hits`, so `survey::svytotal()` reproduces
#' [estimate_total()]'s point estimates and the whole of `survey`'s
#' toolbox — ratios, regressions, domains, calibration — applies.
#'
#' With `variance = "replacement"` (the default) the design is `ids = ~1`:
#' the with-replacement approximation, which ignores the implicit
#' stratification the serpentine order bought, so it tends to be more
#' conservative than the successive-difference variance of
#' [estimate_total()]. With `variance = "pps"` the exact joint inclusion
#' probabilities of [joint_inclusion()] are handed to
#' [survey::ppsmat()] and the Sen--Yates--Grundy variance is exact for
#' the design — available for the default without-replacement sample.
#'
#' @param x A [chromy_sample()].
#' @param variance `"replacement"` (the default) or `"pps"`.
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
#'
#' exact <- as_svydesign(s, variance = "pps")
#' survey::svytotal(~y, exact)
as_svydesign <- function(x, variance = c("replacement", "pps"), ...) {
  if (!inherits(x, "chromy_sample")) {
    cli::cli_abort("{.arg x} must be a {.cls chromy_sample}.")
  }
  variance <- rlang::arg_match(variance)
  rlang::check_installed("survey", reason = "to build a survey design.")
  if (variance == "replacement") {
    return(survey::svydesign(ids = ~1, weights = weights(x), data = x$sample, ...))
  }
  if (any(x$sample$hits != 1L)) {
    cli::cli_abort(c(
      "The exact PPS variance needs a without-replacement sample with single hits.",
      i = "This sample has repeated or fixed multiple hits; use {.code variance = \"replacement\"}."
    ))
  }
  prob <- x$sample$expected_hits
  survey::svydesign(
    ids = ~1, fpc = ~prob, data = cbind(x$sample, prob = prob),
    pps = survey::ppsmat(joint_inclusion(x)), variance = "YG", ...
  )
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
