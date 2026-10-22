# The low-level selector ------------------------------------------------------

#' Select hits from expected hits
#'
#' The selection itself, for pipelines that already have the expected hits
#' in hand — the idiom of the `sampling` package, where a vector of
#' inclusion probabilities goes in and a selection comes out. Give it the
#' expected hits (from [expected_hits()], from
#' `sampling::inclusionprobabilities()`, or from anywhere else), optionally
#' an order, and it draws the head with probability proportional to the
#' expected hits, rotates the list, and selects sequentially with
#' probability minimum replacement. [chromy_sample()] is this plus the
#' frame bookkeeping; the two consume R's generator identically, so the
#' same seed gives the same hits.
#'
#' @param expected Non-negative numeric vector of expected hits, one per
#'   unit, summing to a whole number — the sample size. Values above one
#'   mean the unit may be selected more than once.
#' @param order The order in which to list the units (as [order()] returns
#'   it, e.g. from [serpentine_order()]), or `NULL` for the frame's order.
#' @param head Which units may be drawn as the head of the list: `"all"`
#'   (the default) or `"residual"`; see [chromy_sample()].
#' @param seed Seed passed to [set.seed()], or `NULL` to use the session's
#'   random state.
#' @return An integer vector of realised hits, one per unit, summing
#'   exactly to the sample size, each within one of its expectation, with
#'   attributes `effective_hits` (the expected hits the selection actually
#'   used, after any floating-point adjustment — the denominators of the
#'   weights) and `head_position` (where the rotated list started, as a
#'   position in `order`).
#' @export
#' @examples
#' set.seed(2026)
#' pik <- expected_hits(c(50, 30, 20, 10, 5, 5, 3, 2), 3)
#' pmr(pik)
#'
#' # Expected hits above one: the large unit repeats.
#' pmr(c(2.4, 0.3, 0.8, 0.5), seed = 1)
pmr <- function(expected, order = NULL, head = c("all", "residual"), seed = NULL) {
  head <- rlang::arg_match(head)
  expected <- as.double(expected)
  if (anyNA(expected)) cli::cli_abort("{.arg expected} contains missing values.")
  if (is.null(order)) {
    order <- seq_along(expected)
  } else {
    order <- as.integer(order)
    if (!identical(sort(order), seq_along(expected))) {
      cli::cli_abort("{.arg order} must be a permutation of the {length(expected)} units.")
    }
  }

  if (!is.null(seed)) {
    set.seed(seed,
      kind = "Mersenne-Twister", normal.kind = "Inversion",
      sample.kind = "Rejection"
    )
  }
  eligible <- eligible_rs(expected, order - 1L, head) + 1L
  if (length(eligible) == 0L) {
    start <- 0L
    unif <- double(0)
  } else {
    weights <- expected[order][eligible]
    start <- eligible[sample.int(length(eligible), 1L, prob = weights)] - 1L
    needed <- if (head == "all") length(expected) else length(eligible)
    unif <- stats::runif(needed)
  }
  s <- select_from_rs(expected, order - 1L, start, unif, head)

  hits <- integer(length(expected))
  hits[s$list + 1L] <- s$hits
  structure(hits,
    effective_hits = s$effective_lambda,
    head_position = s$head + 1L
  )
}
