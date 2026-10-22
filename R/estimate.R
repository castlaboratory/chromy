# Estimation -------------------------------------------------------------------

#' Estimate totals from a Chromy sample
#'
#' The multiplicity (Hansen--Hurwitz form) estimator that matches the
#' design: each selected unit's value divided by its effective expected
#' hits — the ones the selection actually used — and weighted by the hits
#' it received. For the precision there is no unbiased variance under a
#' systematic-like design; the successive-difference estimator is the
#' working convention, computed in list order over the units whose
#' selection was actually random, so that it reads the local variation the
#' ordering left behind. Units selected with certainty contribute no
#' variance.
#'
#' @param sample A [chromy_sample()].
#' @param variables Names of the study columns to estimate, numeric columns
#'   of the sampled frame.
#' @return A tibble with one row per variable: `variable`, `total`, `se`
#'   (the successive-difference standard error; `NA` when only one hit was
#'   random), `cv_pct`, and `random_draws`, the number of units the
#'   variance is computed over.
#' @export
#' @examples
#' set.seed(7)
#' frame <- data.frame(size = rlnorm(80, 3), y = rlnorm(80, 5))
#' s <- chromy_sample(frame, n = 25, size = "size")
#' estimate_total(s, "y")
estimate_total <- function(sample, variables) {
  if (!inherits(sample, "chromy_sample")) {
    cli::cli_abort("{.arg sample} must be a {.cls chromy_sample}.")
  }
  rows <- sample$sample
  if (!all(variables %in% names(rows))) {
    cli::cli_abort("Study column{?s} {.field {setdiff(variables, names(rows))}} not found in the sampled frame.")
  }
  y <- as.matrix(rows[variables])
  storage.mode(y) <- "double"
  if (anyNA(y)) cli::cli_abort("The study columns contain missing values.")

  e <- estimate_rs(
    as.double(y), nrow(y),
    seq_len(nrow(y)) - 1L, rows$position - 1L,
    rows$expected_hits, as.integer(rows$hits)
  )
  variance <- ifelse(is.nan(e$sd_variance), NA_real_, e$sd_variance)
  se <- sqrt(variance)
  tibble::tibble(
    variable = variables,
    total = e$total,
    se = se,
    cv_pct = ifelse(e$total != 0, 100 * se / abs(e$total), NA_real_),
    random_draws = e$random_draws
  )
}
