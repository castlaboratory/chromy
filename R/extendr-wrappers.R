# Edited by hand (rextendr's install-time documentation fails on CRAN
# Windows); keep in step with src/rust/src/lib.rs.
# nolint start

#' @usage NULL
#' @useDynLib chromy, .registration = TRUE
NULL

#' Probability-minimum-replacement selection down a list. `priority` is
#' 0-based; one uniform in [0, 1) per unit. Returns hits and accounting.
#' @noRd
pmr_rs <- function(lambda, unif, priority) .Call(wrap__pmr_rs, lambda, unif, priority)

#' Serpentine or nested order over a list of keys (numeric or character
#' vectors). Returns the 0-based order.
#' @noRd
frame_order_rs <- function(keys, method) .Call(wrap__frame_order_rs, keys, method)

#' Maximal size measure over the column-major matrix `x` with `nrow` rows.
#' @noRd
mpps_rs <- function(x, nrow, n_j) .Call(wrap__mpps_rs, x, nrow, n_j)

#' Expected hits proportional to size, certainties resolved by iteration
#' unless `min_replacement`.
#' @noRd
expected_hits_rs <- function(size, n, min_replacement) .Call(wrap__expected_hits_rs, size, n, min_replacement)

#' Equal-CV allocation over the column-major matrix `x`.
#' @noRd
eqcv_rs <- function(x, nrow, n, max_iterations, tolerance, damping) .Call(wrap__eqcv_rs, x, nrow, n, max_iterations, tolerance, damping)

#' List positions (0-based) eligible to be the head.
#' @noRd
eligible_rs <- function(lambda, order, head) .Call(wrap__eligible_rs, lambda, order, head)

#' The full selection from a drawn head. `order` and `start` are 0-based;
#' the uniforms feed the sequential selection.
#' @noRd
select_from_rs <- function(lambda, order, start, uniforms, head) .Call(wrap__select_from_rs, lambda, order, start, uniforms, head)

#' Multiplicity estimator with successive-difference variance. `y` is
#' column-major with `nrow` rows; `units` and `positions` are 0-based.
#' @noRd
estimate_rs <- function(y, nrow, units, positions, expected, hits) .Call(wrap__estimate_rs, y, nrow, units, positions, expected, hits)

#' The version of the computational engine.
#' @noRd
core_version_rs <- function() .Call(wrap__core_version_rs)

# nolint end
