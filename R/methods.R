# Methods ----------------------------------------------------------------------

#' @export
print.chromy_sample <- function(x, ...) {
  drawn <- nrow(x$sample)
  hits <- sum(x$sample$hits)
  cat(sprintf(
    "<chromy_sample> %d units, %d hits, from a frame of %d\n",
    drawn, hits, length(x$expected_hits)
  ))
  cat(sprintf(
    "Head %s at list position %d; %s.\n",
    x$head, x$head_position,
    if (x$min_replacement) "minimum replacement" else "without replacement"
  ))
  if (!is.null(x$n_j)) {
    cat(sprintf(
      "Size: maximal measure over %s.\n",
      paste(names(x$n_j), collapse = ", ")
    ))
  }
  print(x$sample, ...)
  invisible(x)
}

#' @export
summary.chromy_sample <- function(object, ...) {
  s <- object$sample
  out <- list(
    frame_units = length(object$expected_hits),
    sampled_units = nrow(s),
    hits = sum(s$hits),
    certainties = sum(s$expected_hits >= 1),
    multiple_hits = sum(s$hits > 1),
    weight_range = range(s$weight),
    head = object$head,
    head_position = object$head_position,
    accounting = object$accounting
  )
  class(out) <- "summary.chromy_sample"
  out
}

#' @export
print.summary.chromy_sample <- function(x, ...) {
  cat(sprintf(
    "A Chromy sample: %d units carrying %d hits from a frame of %d.\n",
    x$sampled_units, x$hits, x$frame_units
  ))
  cat(sprintf(
    "%d certainties; %d units with more than one hit.\n",
    x$certainties, x$multiple_hits
  ))
  cat(sprintf(
    "Weights from %s to %s; head %s at position %d.\n",
    signif(x$weight_range[1], 4), signif(x$weight_range[2], 4),
    x$head, x$head_position
  ))
  if (!is.null(x$accounting) && x$accounting$max_adjustment > 0) {
    cat(sprintf(
      "Floating-point drift of %s absorbed by list position %d.\n",
      signif(x$accounting$eps_sum, 3), x$accounting$corrected_unit
    ))
  }
  invisible(x)
}

#' @export
as.data.frame.chromy_sample <- function(x, ...) {
  as.data.frame(x$sample, ...)
}
