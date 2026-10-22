# From sizes to expected hits -------------------------------------------------

#' Expected hits proportional to size
#'
#' Turns a size measure into the expected hits Chromy's selection consumes.
#' In the usual case (`min_replacement = FALSE`) units whose proportional
#' share reaches one are made certainties and the remainder is re-shared
#' until no unit crosses one; the result is a vector of inclusion
#' probabilities in `[0, 1]`, and `n` may not exceed the number of units
#' with positive size. Under minimum replacement the expected hits are
#' simply `n` times the size shares, values above one meaning the unit may
#' be selected more than once — which Chromy's procedure handles natively,
#' and is the reason to use it.
#'
#' @param size Non-negative numeric vector, one entry per unit.
#' @param n The sample size: the expected number of selections.
#' @param min_replacement Allow expected hits above one instead of
#'   resolving certainties.
#' @return A numeric vector of expected hits summing to `n`.
#' @export
#' @examples
#' expected_hits(c(100, 50, 10, 5, 5), 3)
#' expected_hits(c(100, 50, 10, 5, 5), 3, min_replacement = TRUE)
expected_hits <- function(size, n, min_replacement = FALSE) {
  if (anyNA(size)) cli::cli_abort("{.arg size} contains missing values.")
  if (length(n) != 1L || is.na(n) || n != round(n) || n < 1) {
    cli::cli_abort("{.arg n} must be a single whole number of selections.")
  }
  expected_hits_rs(as.double(size), as.integer(n), isTRUE(min_replacement))
}

#' Allocation that equalises anticipated coefficients of variation
#'
#' For a multivariate design built on [mpps_size()], searches for the
#' per-variable sample-size factors under which every auxiliary variable's
#' total is anticipated with the same coefficient of variation, so no
#' estimate is quietly sacrificed to another. At each step the anticipated
#' CVs are computed under the design the current factors imply and the
#' factors move against their spread, damped, until the spread falls within
#' tolerance.
#'
#' @inheritParams mpps_size
#' @param n The sample size, at most the number of units.
#' @param max_iterations,tolerance,damping The search: at most
#'   `max_iterations` steps, stopping when the largest anticipated CV
#'   exceeds the smallest by less than `tolerance` (relative), each step
#'   damped by the exponent `damping`.
#' @return A numeric vector of factors, one per variable, normalised to
#'   geometric mean one over the informative variables, with attributes
#'   `cv` (the anticipated CVs reached), `iterations` and `converged`.
#'   A `converged` of `FALSE` warns but still returns the best factors
#'   reached.
#' @export
#' @examples
#' set.seed(1)
#' frame <- data.frame(a = rlnorm(100), b = rlnorm(100, sdlog = 2))
#' n_j <- eqcv_allocation(frame, c("a", "b"), n = 20)
#' n_j
#' attr(n_j, "cv")
eqcv_allocation <- function(frame, variables, n, max_iterations = 300,
                            tolerance = 1e-3, damping = 0.5) {
  x <- auxiliary_matrix(frame, variables)
  if (length(n) != 1L || is.na(n) || n != round(n) || n < 1) {
    cli::cli_abort("{.arg n} must be a single whole number of selections.")
  }
  if (n > nrow(x)) {
    cli::cli_abort(c(
      "Equalising CVs needs {.arg n} at most the number of units: {n} > {nrow(x)}.",
      i = "With {.arg n} beyond the frame use minimum replacement and equal or fixed factors."
    ))
  }
  a <- eqcv_rs(
    as.double(x), nrow(x), as.integer(n),
    as.integer(max_iterations), as.double(tolerance), as.double(damping)
  )
  if (!a$converged) {
    cli::cli_warn("The equal-CV search did not meet its tolerance in {a$iterations} iteration{?s}; returning the factors it reached.")
  }
  structure(
    stats::setNames(a$n_j, variables),
    cv = stats::setNames(a$cv, variables[a$used]),
    iterations = a$iterations,
    converged = a$converged
  )
}
