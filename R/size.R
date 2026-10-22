# Size measures ----------------------------------------------------------------

#' A maximal size measure over several auxiliary variables
#'
#' A survey that must estimate more than one total has no single "size": a
#' unit may be large for one variable and negligible for another. The
#' maximal measure takes, for each unit, the largest of its shares across
#' the auxiliary variables, each share first scaled by how much sample that
#' variable is to command (Folsom, Potter and Williams, 1987). Selecting
#' proportional to the maximum guarantees every variable at least its
#' intended coverage.
#'
#' @param frame Data frame with one row per unit.
#' @param variables Names of the auxiliary columns, non-negative numeric.
#'   Columns that sum to zero carry no information and are ignored.
#' @param n_j Relative sample size each variable is to command: a positive
#'   vector with one entry per variable, or `NULL` for equal shares.
#'   [eqcv_allocation()] searches for the factors that equalise the
#'   anticipated coefficients of variation.
#' @return A numeric vector of sizes, one per row of `frame`. Units whose
#'   every share is zero receive the smallest positive measure, so the
#'   frame keeps full coverage.
#' @references Folsom, R. E., Potter, F. J. and Williams, S. R. (1987).
#'   Notes on a composite size measure for self-weighting samples in
#'   multiple domains. *Proceedings of the American Statistical
#'   Association, Section on Survey Research Methods*, 792--796.
#' @export
#' @examples
#' frame <- data.frame(pupils = c(120, 45, 300, 80), staff = c(10, 20, 12, 8))
#' mpps_size(frame, c("pupils", "staff"))
mpps_size <- function(frame, variables, n_j = NULL) {
  x <- auxiliary_matrix(frame, variables)
  if (is.null(n_j)) n_j <- rep(1, ncol(x))
  if (length(n_j) != ncol(x)) {
    cli::cli_abort("{.arg n_j} needs one factor per variable: {length(variables)}, not {length(n_j)}.")
  }
  mpps_rs(as.double(x), nrow(x), as.double(n_j))
}

#' The auxiliary columns as a double matrix, validated.
#' @noRd
auxiliary_matrix <- function(frame, variables) {
  if (!all(variables %in% names(frame))) {
    cli::cli_abort("Auxiliary column{?s} {.field {setdiff(variables, names(frame))}} not found in {.arg frame}.")
  }
  x <- as.matrix(frame[variables])
  storage.mode(x) <- "double"
  if (anyNA(x)) cli::cli_abort("The auxiliary columns contain missing values.")
  x
}
