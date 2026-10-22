# Allocation that equalises anticipated coefficients of variation

For a multivariate design built on
[`mpps_size()`](https://castlaboratory.github.io/chromy/reference/mpps_size.md),
searches for the per-variable sample-size factors under which every
auxiliary variable's total is anticipated with the same coefficient of
variation, so no estimate is quietly sacrificed to another. At each step
the anticipated CVs are computed under the design the current factors
imply and the factors move against their spread, damped, until the
spread falls within tolerance.

## Usage

``` r
eqcv_allocation(
  frame,
  variables,
  n,
  max_iterations = 300,
  tolerance = 0.001,
  damping = 0.5
)
```

## Arguments

- frame:

  Data frame with one row per unit.

- variables:

  Names of the auxiliary columns, non-negative numeric. Columns that sum
  to zero carry no information and are ignored.

- n:

  The sample size, at most the number of units.

- max_iterations, tolerance, damping:

  The search: at most `max_iterations` steps, stopping when the largest
  anticipated CV exceeds the smallest by less than `tolerance`
  (relative), each step damped by the exponent `damping`.

## Value

A numeric vector of factors, one per variable, normalised to geometric
mean one over the informative variables, with attributes `cv` (the
anticipated CVs reached), `iterations` and `converged`. A `converged` of
`FALSE` warns but still returns the best factors reached.

## Examples

``` r
set.seed(1)
frame <- data.frame(a = rlnorm(100), b = rlnorm(100, sdlog = 2))
n_j <- eqcv_allocation(frame, c("a", "b"), n = 20)
n_j
#>         a         b 
#> 0.8886081 1.1253555 
#> attr(,"cv")
#>          a          b 
#> 0.08893883 0.08898617 
#> attr(,"iterations")
#> [1] 8
#> attr(,"converged")
#> [1] TRUE
attr(n_j, "cv")
#>          a          b 
#> 0.08893883 0.08898617 
```
