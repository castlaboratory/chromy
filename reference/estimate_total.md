# Estimate totals from a Chromy sample

The multiplicity (Hansen–Hurwitz form) estimator that matches the
design: each selected unit's value divided by its effective expected
hits — the ones the selection actually used — and weighted by the hits
it received. For the precision there is no unbiased variance under a
systematic-like design; the successive-difference estimator is the
working convention, computed in list order over the units whose
selection was actually random, so that it reads the local variation the
ordering left behind. Units selected with certainty contribute no
variance.

## Usage

``` r
estimate_total(sample, variables)
```

## Arguments

- sample:

  A
  [`chromy_sample()`](https://castlaboratory.github.io/chromy/reference/chromy_sample.md).

- variables:

  Names of the study columns to estimate, numeric columns of the sampled
  frame.

## Value

A tibble with one row per variable: `variable`, `total`, `se` (the
successive-difference standard error; `NA` when only one hit was
random), `cv_pct`, and `random_draws`, the number of units the variance
is computed over.

## Examples

``` r
set.seed(7)
frame <- data.frame(size = rlnorm(80, 3), y = rlnorm(80, 5))
s <- chromy_sample(frame, n = 25, size = "size")
estimate_total(s, "y")
#> # A tibble: 1 × 5
#>   variable  total    se cv_pct random_draws
#>   <chr>     <dbl> <dbl>  <dbl>        <int>
#> 1 y        23879. 6865.   28.8           18
```
