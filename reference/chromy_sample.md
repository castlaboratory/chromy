# Select a sample by Chromy's sequential method

Draws a probability-proportional-to-size sample by Chromy's (1979)
method of sequential random sampling with probability minimum
replacement: the frame is ordered, the head of the list is drawn with
probability proportional to size, and the selection then walks the
rotated list so that every unit's realised number of selections differs
from its expected number by less than one and the sample size is always
exact. This is the procedure behind `PROC SURVEYSELECT METHOD=PPS_SEQ`.

## Usage

``` r
chromy_sample(
  frame,
  n,
  size = NULL,
  variables = NULL,
  n_j = c("eqcv", "equal"),
  order_by = NULL,
  method = c("serpentine", "nested"),
  head = c("all", "residual"),
  min_replacement = FALSE,
  seed = NULL
)
```

## Arguments

- frame:

  Data frame with one row per unit.

- n:

  The sample size: the expected number of selections.

- size:

  Name of the size column, or `NULL`.

- variables:

  Names of auxiliary columns for the maximal size measure, or `NULL`. At
  most one of `size` and `variables`.

- n_j:

  How the auxiliary variables share the sample: `"eqcv"` (equalise
  anticipated CVs, the default), `"equal"`, or a numeric vector of
  factors, one per variable.

- order_by:

  Names of sort key columns for implicit stratification (may include
  `"chromy_size"`), or `NULL` to keep the frame's order.

- method:

  `"serpentine"` (the default) or `"nested"`; see
  [`serpentine_order()`](https://castlaboratory.github.io/chromy/reference/serpentine_order.md).

- head:

  Which units may be drawn as the head of the list: `"all"` (the
  default) randomises every hit; `"residual"` takes integer expected
  hits as fixed and randomises only the fractional remainder.

- min_replacement:

  Allow expected hits above one (units selected more than once) instead
  of resolving certainties; see
  [`expected_hits()`](https://castlaboratory.github.io/chromy/reference/expected_hits.md).

- seed:

  Seed passed to [`set.seed()`](https://rdrr.io/r/base/Random.html), or
  `NULL` to use the session's random state.

## Value

An object of class `chromy_sample`: a list with `sample` (a tibble of
the selected units: `unit` the frame row, `position` in the selection
list, `expected_hits`, `hits`, `weight` the sampling weight
`1 / expected_hits`, `fixed_hits`, `random_hits`, then the frame's
columns), `expected_hits` and `effective_hits` for the whole frame,
`size`, `n_j`, `order`, `head_position`, and `accounting` (the
floating-point adjustments the selection made, if any).

## Details

The size comes from one of three places: a `size` column; several
auxiliary `variables` combined by the maximal measure of
[`mpps_size()`](https://castlaboratory.github.io/chromy/reference/mpps_size.md),
with factors from
[`eqcv_allocation()`](https://castlaboratory.github.io/chromy/reference/eqcv_allocation.md)
(the default), equal, or supplied; or, with neither, equal sizes. With
`order_by` the frame is listed in hierarchical serpentine (or nested)
order first, so the selection is implicitly stratified by the keys; the
computed size is available to the sort as the column `chromy_size`.

All randomness comes from R's own generator — one
[`sample.int()`](https://rdrr.io/r/base/sample.html) for the head and
one [`runif()`](https://rdrr.io/r/stats/Uniform.html) per randomised
unit — so [`set.seed()`](https://rdrr.io/r/base/Random.html) (or `seed`)
makes the selection exactly reproducible.

## References

Chromy, J. R. (1979). Sequential sample selection methods. *Proceedings
of the American Statistical Association, Survey Research Methods
Section*, 401–406.

Chauvet, G. and Le Gleut, R. (2021). Properties of Chromy's sampling
procedure. *Survey Methodology*, 47(2), 321–347.

## Examples

``` r
set.seed(2026)
frame <- data.frame(
  region = rep(c("north", "east", "south", "west"), each = 25),
  pupils = rlnorm(100, 4), staff = rlnorm(100, 2)
)
s <- chromy_sample(frame,
  n = 20, variables = c("pupils", "staff"),
  order_by = c("region", "chromy_size")
)
s
#> <chromy_sample> 20 units, 20 hits, from a frame of 100
#> Head all at list position 79; without replacement.
#> Size: maximal measure over pupils, staff.
#> # A tibble: 20 × 11
#>     unit position expected_hits  hits weight fixed_hits random_hits region
#>    <int>    <int>         <dbl> <int>  <dbl>      <dbl>       <dbl> <chr> 
#>  1    96        3        0.358      1   2.80          0           1 west  
#>  2    87        5        0.294      1   3.40          0           1 west  
#>  3    89        6        0.285      1   3.50          0           1 west  
#>  4    95       21        0.0312     1  32.1           0           1 west  
#>  5    33       31        0.125      1   8.01          0           1 east  
#>  6    39       37        0.179      1   5.59          0           1 east  
#>  7    45       41        0.221      1   4.53          0           1 east  
#>  8    46       43        0.364      1   2.75          0           1 east  
#>  9    26       46        0.594      1   1.68          0           1 east  
#> 10    32       47        0.970      1   1.03          0           1 east  
#> 11    19       48        0.683      1   1.46          0           1 north 
#> 12    22       49        0.584      1   1.71          0           1 north 
#> 13     1       54        0.234      1   4.28          0           1 north 
#> 14    25       63        0.0924     1  10.8           0           1 north 
#> 15    15       72        0.0340     1  29.4           0           1 north 
#> 16    54       90        0.138      1   7.24          0           1 south 
#> 17    56       94        0.217      1   4.60          0           1 south 
#> 18    90       98        0.985      1   1.02          0           1 west  
#> 19    77       99        0.737      1   1.36          0           1 west  
#> 20    93      100        0.613      1   1.63          0           1 west  
#> # ℹ 3 more variables: pupils <dbl>, staff <dbl>, chromy_size <dbl>
estimate_total(s, c("pupils", "staff"))
#> # A tibble: 2 × 5
#>   variable total    se cv_pct random_draws
#>   <chr>    <dbl> <dbl>  <dbl>        <int>
#> 1 pupils   6868. 1130.   16.5           20
#> 2 staff    1560.  187.   12.0           20
```
