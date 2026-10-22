#' @keywords internal
"_PACKAGE"

#' chromy: Chromy's sequential sampling with probability minimum replacement
#'
#' Selection of survey samples by Chromy's (1979) method of sequential
#' random sampling: [chromy_sample()] draws the sample, over a frame listed
#' by [serpentine_order()], with a size from [mpps_size()] and
#' [eqcv_allocation()] or from a single column, expected hits from
#' [expected_hits()], and totals estimated by [estimate_total()]. The
#' numerical engine is the Rust crate `chromy-core`; all randomness comes
#' from R's own generator, so `set.seed()` makes a selection exactly
#' reproducible.
#'
#' @name chromy-package
NULL
