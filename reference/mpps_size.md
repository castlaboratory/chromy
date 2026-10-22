# A maximal size measure over several auxiliary variables

A survey that must estimate more than one total has no single "size": a
unit may be large for one variable and negligible for another. The
maximal measure takes, for each unit, the largest of its shares across
the auxiliary variables, each share first scaled by how much sample that
variable is to command (Folsom, Potter and Williams, 1987). Selecting
proportional to the maximum guarantees every variable at least its
intended coverage.

## Usage

``` r
mpps_size(frame, variables, n_j = NULL)
```

## Arguments

- frame:

  Data frame with one row per unit.

- variables:

  Names of the auxiliary columns, non-negative numeric. Columns that sum
  to zero carry no information and are ignored.

- n_j:

  Relative sample size each variable is to command: a positive vector
  with one entry per variable, or `NULL` for equal shares.
  [`eqcv_allocation()`](https://castlaboratory.github.io/chromy/reference/eqcv_allocation.md)
  searches for the factors that equalise the anticipated coefficients of
  variation.

## Value

A numeric vector of sizes, one per row of `frame`. Units whose every
share is zero receive the smallest positive measure, so the frame keeps
full coverage.

## References

Folsom, R. E., Potter, F. J. and Williams, S. R. (1987). Notes on a
composite size measure for self-weighting samples in multiple domains.
*Proceedings of the American Statistical Association, Section on Survey
Research Methods*, 792–796.

## Examples

``` r
frame <- data.frame(pupils = c(120, 45, 300, 80), staff = c(10, 20, 12, 8))
mpps_size(frame, c("pupils", "staff"))
#> [1] 0.2201835 0.4000000 0.5504587 0.1600000
```
