# Select hits from expected hits

The selection itself, for pipelines that already have the expected hits
in hand — the idiom of the `sampling` package, where a vector of
inclusion probabilities goes in and a selection comes out. Give it the
expected hits (from
[`expected_hits()`](https://castlaboratory.github.io/chromy/reference/expected_hits.md),
from
[`sampling::inclusionprobabilities()`](https://rdrr.io/pkg/sampling/man/inclusionprobabilities.html),
or from anywhere else), optionally an order, and it draws the head with
probability proportional to the expected hits, rotates the list, and
selects sequentially with probability minimum replacement.
[`chromy_sample()`](https://castlaboratory.github.io/chromy/reference/chromy_sample.md)
is this plus the frame bookkeeping; the two consume R's generator
identically, so the same seed gives the same hits.

## Usage

``` r
pmr(expected, order = NULL, head = c("all", "residual"), seed = NULL)
```

## Arguments

- expected:

  Non-negative numeric vector of expected hits, one per unit, summing to
  a whole number — the sample size. Values above one mean the unit may
  be selected more than once.

- order:

  The order in which to list the units (as
  [`order()`](https://rdrr.io/r/base/order.html) returns it, e.g. from
  [`serpentine_order()`](https://castlaboratory.github.io/chromy/reference/serpentine_order.md)),
  or `NULL` for the frame's order.

- head:

  Which units may be drawn as the head of the list: `"all"` (the
  default) or `"residual"`; see
  [`chromy_sample()`](https://castlaboratory.github.io/chromy/reference/chromy_sample.md).

- seed:

  Seed passed to [`set.seed()`](https://rdrr.io/r/base/Random.html), or
  `NULL` to use the session's random state.

## Value

An integer vector of realised hits, one per unit, summing exactly to the
sample size, each within one of its expectation, with attributes
`effective_hits` (the expected hits the selection actually used, after
any floating-point adjustment — the denominators of the weights) and
`head_position` (where the rotated list started, as a position in
`order`).

## Examples

``` r
set.seed(2026)
pik <- expected_hits(c(50, 30, 20, 10, 5, 5, 3, 2), 3)
pmr(pik)
#> [1] 1 0 0 1 0 0 1 0
#> attr(,"effective_hits")
#> [1] 1.00000000 0.80000000 0.53333333 0.26666667 0.13333333 0.13333333 0.08000000
#> [8] 0.05333333
#> attr(,"head_position")
#> [1] 3

# Expected hits above one: the large unit repeats.
pmr(c(2.4, 0.3, 0.8, 0.5), seed = 1)
#> [1] 3 0 0 1
#> attr(,"effective_hits")
#> [1] 2.4 0.3 0.8 0.5
#> attr(,"head_position")
#> [1] 1
```
