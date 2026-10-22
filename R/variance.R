# Exact second-order probabilities and replicate weights --------------------

#' Exact joint inclusion probabilities of the sampled units
#'
#' Chromy's procedure run down a fixed list is the same design as ordered
#' pivotal sampling, and for that design the joint (second-order) inclusion
#' probabilities have closed forms (Chauvet and Le Gleut, 2021, Theorem 3);
#' with the random head the design is the mixture of the circular
#' rotations, each weighted by its unit's probability over the sample size
#' (their eq. 5.3) — precisely the head [chromy_sample()] draws. This
#' function evaluates those forms exactly for the sampled units, making
#' the Sen--Yates--Grundy variance of the Horvitz--Thompson total exact
#' rather than approximated; [as_svydesign()] with `variance = "pps"`
#' hands it to the `survey` package.
#'
#' Joint *inclusion* probabilities belong to the without-replacement
#' design: a sample drawn with `min_replacement = TRUE`, where a unit may
#' be selected more than once, is refused. The cost is of order `N`
#' (frame) times the square of the sample size.
#'
#' @param x A [chromy_sample()] drawn with `head = "all"` (the default)
#'   and `min_replacement = FALSE` (the default).
#' @return The symmetric matrix of joint inclusion probabilities of the
#'   sampled units, in the order of `x$sample`, with the first-order
#'   (effective) probabilities on the diagonal.
#' @references Chauvet, G. and Le Gleut, R. (2021). Properties of Chromy's
#'   sampling procedure. *Survey Methodology*, 47(2), 321--347.
#' @export
#' @examples
#' set.seed(9)
#' frame <- data.frame(size = rlnorm(40, 2))
#' s <- chromy_sample(frame, n = 10, size = "size")
#' p2 <- joint_inclusion(s)
#' all(abs(p2 - t(p2)) < 1e-12)
#' all(diag(p2) == s$sample$expected_hits)
joint_inclusion <- function(x) {
  if (!inherits(x, "chromy_sample")) {
    cli::cli_abort("{.arg x} must be a {.cls chromy_sample}.")
  }
  if (x$min_replacement) {
    cli::cli_abort(c(
      "Joint inclusion probabilities belong to the without-replacement design.",
      i = "A minimum-replacement sample has joint moments, not joint inclusion probabilities."
    ))
  }
  if (x$head != "all") {
    cli::cli_abort("The exact forms cover the default head ({.val all}).")
  }
  units <- x$sample$unit
  m <- joint_inclusion_rs(
    x$effective_hits, x$order - 1L, units - 1L,
    randomized = TRUE
  )
  matrix(m, nrow = length(units), byrow = TRUE,
    dimnames = list(units, units)
  )
}

#' Successive-difference replicate weights for a chromy sample
#'
#' Builds a replicate-weights design in the successive difference
#' replication scheme of Fay and Train (1995), the convention of the
#' American Community Survey: the rows whose selection was actually random
#' are perturbed, in list order, by factors `1 +- 2^(-3/2) * 2` read off
#' pairs of rows of a Hadamard matrix, so that the replicate variance
#' approximates the successive-difference variance of [estimate_total()]
#' while giving the `survey` package's whole replicate machinery —
#' quantiles, domains, calibration — a design to work with. Rows selected
#' with certainty keep their weight in every replicate, as they carry no
#' variance.
#'
#' @param x A [chromy_sample()].
#' @param replicates The number of replicates, or `NULL` for the smallest
#'   Hadamard order above the number of randomly selected rows.
#' @param ... Passed on to [survey::svrepdesign()].
#' @return A `svyrep.design` object with scale `4 / replicates`.
#' @references Fay, R. E. and Train, G. F. (1995). Aspects of survey and
#'   model-based postcensal estimation of income and poverty
#'   characteristics for states and counties. *Proceedings of the ASA,
#'   Government Statistics Section*, 154--159.
#' @export
#' @examplesIf requireNamespace("survey", quietly = TRUE)
#' set.seed(11)
#' frame <- data.frame(size = rlnorm(120, 2), y = rlnorm(120, 4))
#' s <- chromy_sample(frame, n = 30, size = "size")
#' r <- as_svrepdesign(s)
#' survey::svytotal(~y, r)
#' estimate_total(s, "y")
as_svrepdesign <- function(x, replicates = NULL, ...) {
  if (!inherits(x, "chromy_sample")) {
    cli::cli_abort("{.arg x} must be a {.cls chromy_sample}.")
  }
  rlang::check_installed("survey", reason = "to build a replicate design.")
  s <- x$sample
  base <- weights(x)
  random <- which(s$random_hits == 1)
  m <- length(random)
  if (m < 2) {
    cli::cli_abort("Successive difference replication needs at least two randomly selected rows; this sample has {m}.")
  }

  hadamard <- 2 * survey::hadamard(if (is.null(replicates)) m else replicates - 1) - 1
  n_rep <- ncol(hadamard)
  factors <- matrix(1, nrow(s), n_rep)
  for (j in seq_len(m)) {
    r1 <- (j - 1L) %% nrow(hadamard) + 1L
    r2 <- j %% nrow(hadamard) + 1L
    factors[random[j], ] <- 1 + 2^(-1.5) * (hadamard[r1, ] - hadamard[r2, ])
  }

  survey::svrepdesign(
    variables = s,
    weights = base,
    repweights = base * factors,
    type = "other",
    scale = 4 / n_rep,
    rscales = rep(1, n_rep),
    combined.weights = TRUE,
    ...
  )
}
