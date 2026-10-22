# Ordering the frame ----------------------------------------------------------

#' Order a frame for sequential selection
#'
#' A sequential procedure buys variance from the order of the list: units
#' that sit together are selected apart, so the sample spreads over whatever
#' the sort keys encode — implicit stratification. A plain nested sort
#' leaves a seam at every boundary where the last unit of one group meets
#' the first of the next and the two could not be less alike; the
#' hierarchical serpentine sort removes the seams by reversing direction at
#' each boundary, so the list meanders through the frame and every
#' neighbouring pair of units is actually similar.
#'
#' Character and factor keys are ranked by the byte order of their values
#' (the C locale), deliberately: a sort that followed the session's locale
#' would produce a different sample on a different machine.
#'
#' @param frame Data frame with one row per unit.
#' @param by Names of the sort key columns, outermost first.
#' @param method `"serpentine"` (the default) or `"nested"`. With a single
#'   key the two coincide.
#' @return An integer vector: the order in which to list the rows of
#'   `frame`, as `order()` would return it.
#' @references Williams, R. L. and Chromy, J. R. (1980). SAS sample
#'   selection macros. *Proceedings of the Fifth Annual SAS Users Group
#'   International Conference*, 392--396.
#' @export
#' @examples
#' frame <- data.frame(
#'   region = rep(c("north", "south"), each = 4),
#'   size   = c(4, 2, 3, 1, 30, 10, 40, 20)
#' )
#' frame[serpentine_order(frame, c("region", "size")), ]
serpentine_order <- function(frame, by, method = c("serpentine", "nested")) {
  method <- rlang::arg_match(method)
  if (!all(by %in% names(frame))) {
    cli::cli_abort("Sort key{?s} {.field {setdiff(by, names(frame))}} not found in {.arg frame}.")
  }
  keys <- lapply(frame[by], function(v) {
    if (is.factor(v)) v <- as.character(v)
    if (is.character(v)) v else as.double(v)
  })
  bad <- vapply(keys, anyNA, logical(1))
  if (any(bad)) {
    cli::cli_abort("Sort key{?s} {.field {by[bad]}} contain{?s/} missing values.")
  }
  frame_order_rs(keys, method) + 1L
}
