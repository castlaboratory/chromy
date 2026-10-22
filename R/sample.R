# The selection ----------------------------------------------------------------

#' Select a sample by Chromy's sequential method
#'
#' Draws a probability-proportional-to-size sample by Chromy's (1979) method
#' of sequential random sampling with probability minimum replacement: the
#' frame is ordered, the head of the list is drawn with probability
#' proportional to size, and the selection then walks the rotated list so
#' that every unit's realised number of selections differs from its
#' expected number by less than one and the sample size is always exact.
#' This is the procedure behind `PROC SURVEYSELECT METHOD=PPS_SEQ`.
#'
#' The size comes from one of three places: a `size` column; several
#' auxiliary `variables` combined by the maximal measure of [mpps_size()],
#' with factors from [eqcv_allocation()] (the default), equal, or supplied;
#' or, with neither, equal sizes. With `order_by` the frame is listed in
#' hierarchical serpentine (or nested) order first, so the selection is
#' implicitly stratified by the keys; the computed size is available to the
#' sort as the column `chromy_size`.
#'
#' All randomness comes from R's own generator — one `sample.int()` for the
#' head and one `runif()` per randomised unit — so `set.seed()` (or `seed`)
#' makes the selection exactly reproducible.
#'
#' @param frame Data frame with one row per unit.
#' @param n The sample size: the expected number of selections.
#' @param size Name of the size column, or `NULL`.
#' @param variables Names of auxiliary columns for the maximal size
#'   measure, or `NULL`. At most one of `size` and `variables`.
#' @param n_j How the auxiliary variables share the sample: `"eqcv"`
#'   (equalise anticipated CVs, the default), `"equal"`, or a numeric
#'   vector of factors, one per variable.
#' @param order_by Names of sort key columns for implicit stratification
#'   (may include `"chromy_size"`), or `NULL` to keep the frame's order.
#' @param method `"serpentine"` (the default) or `"nested"`; see
#'   [serpentine_order()].
#' @param head Which units may be drawn as the head of the list: `"all"`
#'   (the default) randomises every hit; `"residual"` takes integer
#'   expected hits as fixed and randomises only the fractional remainder.
#' @param min_replacement Allow expected hits above one (units selected
#'   more than once) instead of resolving certainties; see
#'   [expected_hits()].
#' @param seed Seed passed to [set.seed()], or `NULL` to use the session's
#'   random state.
#' @return An object of class `chromy_sample`: a list with `sample` (a
#'   tibble of the selected units: `unit` the frame row, `position` in the
#'   selection list, `expected_hits`, `hits`, `weight` the sampling weight
#'   `1 / expected_hits`, `fixed_hits`, `random_hits`, then the frame's
#'   columns — a frame column that clashes with one of these design names
#'   is kept under the suffix `_frame`, with a warning),
#'   `expected_hits` and `effective_hits` for the whole frame,
#'   `size`, `n_j`, `order`, `head_position`, and `accounting` (the
#'   floating-point adjustments the selection made, if any).
#' @references Chromy, J. R. (1979). Sequential sample selection methods.
#'   *Proceedings of the American Statistical Association, Survey Research
#'   Methods Section*, 401--406.
#'
#'   Chauvet, G. and Le Gleut, R. (2021). Properties of Chromy's sampling
#'   procedure. *Survey Methodology*, 47(2), 321--347.
#' @export
#' @examples
#' set.seed(2026)
#' frame <- data.frame(
#'   region = rep(c("north", "east", "south", "west"), each = 25),
#'   pupils = rlnorm(100, 4), staff = rlnorm(100, 2)
#' )
#' s <- chromy_sample(frame,
#'   n = 20, variables = c("pupils", "staff"),
#'   order_by = c("region", "chromy_size")
#' )
#' s
#' estimate_total(s, c("pupils", "staff"))
#'
#' # The frame is the first argument, so a design reads as a pipeline:
#' frame |>
#'   chromy_sample(n = 20, size = "pupils") |>
#'   estimate_total("staff")
chromy_sample <- function(frame, n, size = NULL, variables = NULL,
                          n_j = c("eqcv", "equal"), order_by = NULL,
                          method = c("serpentine", "nested"),
                          head = c("all", "residual"),
                          min_replacement = FALSE, seed = NULL) {
  method <- rlang::arg_match(method)
  head <- rlang::arg_match(head)
  if ("chromy_size" %in% names(frame)) {
    cli::cli_abort("{.arg frame} already has a {.field chromy_size} column; rename it.")
  }
  if (!is.null(size) && !is.null(variables)) {
    cli::cli_abort("Give {.arg size} or {.arg variables}, not both.")
  }

  # The size measure and the per-variable factors.
  factors <- NULL
  if (!is.null(variables)) {
    if (is.numeric(n_j)) {
      factors <- n_j
      if (length(factors) != length(variables)) {
        cli::cli_abort("{.arg n_j} needs one factor per variable: {length(variables)}, not {length(factors)}.")
      }
    } else {
      n_j <- rlang::arg_match(n_j)
      factors <- if (n_j == "eqcv") {
        as.numeric(eqcv_allocation(frame, variables, n))
      } else {
        rep(1, length(variables))
      }
    }
    s_measure <- mpps_size(frame, variables, factors)
  } else if (!is.null(size)) {
    if (!size %in% names(frame)) {
      cli::cli_abort("Size column {.field {size}} not found in {.arg frame}.")
    }
    s_measure <- as.double(frame[[size]])
  } else {
    s_measure <- rep(1, nrow(frame))
  }

  lambda <- expected_hits(s_measure, n, min_replacement)
  if (any(s_measure == 0)) {
    cli::cli_warn("{sum(s_measure == 0)} unit{?s} with size zero can never be selected: the sample does not cover {?it/them}.")
  }
  frame$chromy_size <- s_measure

  listing <- if (is.null(order_by)) {
    seq_len(nrow(frame))
  } else {
    serpentine_order(frame, order_by, method)
  }

  # All randomness from R's generator, in a fixed consumption order: one
  # head draw, then one uniform per randomised unit.
  if (!is.null(seed)) {
    set.seed(seed,
      kind = "Mersenne-Twister", normal.kind = "Inversion",
      sample.kind = "Rejection"
    )
  }
  eligible <- eligible_rs(lambda, listing - 1L, head) + 1L
  if (length(eligible) == 0L) {
    start <- 0L
    unif <- double(0)
  } else {
    weights <- lambda[listing][eligible]
    start <- eligible[sample.int(length(eligible), 1L, prob = weights)] - 1L
    needed <- if (head == "all") length(lambda) else length(eligible)
    unif <- stats::runif(needed)
  }
  s <- select_from_rs(lambda, listing - 1L, start, unif, head)

  if (s$max_adjustment > 1e-12) {
    cli::cli_warn("Expected hits adjusted by up to {signif(s$max_adjustment, 3)} to absorb floating-point drift; the {.field expected_hits} reported are the ones used.")
  }

  drawn <- which(s$hits > 0L)
  units <- s$list[drawn] + 1L
  effective <- s$effective_lambda
  design <- data.frame(
    unit = units,
    position = drawn,
    expected_hits = effective[units],
    hits = s$hits[drawn],
    weight = 1 / effective[units],
    fixed_hits = floor(effective[units]),
    random_hits = s$hits[drawn] - floor(effective[units])
  )
  carried <- frame[units, , drop = FALSE]
  clash <- names(carried) %in% names(design)
  if (any(clash)) {
    cli::cli_warn("Frame column{?s} {.field {names(carried)[clash]}} renamed with the suffix {.code _frame}: the sample reserves {?that name/those names} for the design.")
    names(carried)[clash] <- paste0(names(carried)[clash], "_frame")
  }
  sample <- tibble::as_tibble(cbind(design, carried))

  structure(
    list(
      sample = sample,
      expected_hits = lambda,
      effective_hits = effective,
      size = s_measure,
      n_j = if (is.null(factors)) NULL else stats::setNames(factors, variables),
      order = listing,
      head_position = s$head + 1L,
      accounting = if (s$randomised) {
        list(
          eps_sum = s$eps_sum,
          corrected_unit = if (s$corrected_unit < 0L) NA_integer_ else s$corrected_unit + 1L,
          adjusted_crossings = s$adjusted_crossings,
          max_adjustment = s$max_adjustment
        )
      } else {
        NULL
      },
      n = n,
      head = head,
      min_replacement = min_replacement
    ),
    class = "chromy_sample"
  )
}
