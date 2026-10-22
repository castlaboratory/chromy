# One sample for several estimates

A survey rarely serves one estimate. An establishment survey wants
revenue *and* employment; a school survey wants pupils *and* teachers. A
size measure proportional to one variable is a poor size for the other,
and drawing two samples costs twice. This vignette builds one sample
that serves both, with the two tools the practice of Chromy’s method
grew around it: the maximal size measure and the equal-CV allocation.

## The maximal size measure

For each unit take its share of each auxiliary variable’s total, scale
each share by how much sample that variable is to command, and let the
unit’s size be the *largest* of its scaled shares (Folsom, Potter and
Williams, 1987). Selecting proportional to the maximum guarantees every
variable at least its intended coverage: a unit that matters for any
variable is given the probability that variable needs.

``` r

library(chromy)
set.seed(2026)

frame <- data.frame(
  sector  = sample(c("manufacturing", "services", "trade"), 400,
                   replace = TRUE, prob = c(0.2, 0.5, 0.3)),
  revenue = rlnorm(400, meanlog = 6, sdlog = 1.4),
  workers = round(rlnorm(400, meanlog = 3, sdlog = 0.8))
)

size <- mpps_size(frame, c("revenue", "workers"))
head(cbind(frame, size))
#>     sector    revenue workers        size
#> 1    trade  220.33808      43 0.004073127
#> 2    trade  766.64788      17 0.001610306
#> 3 services  292.62948      20 0.001894478
#> 4 services   29.97168      30 0.002841716
#> 5    trade  268.93135      14 0.001326134
#> 6 services 4788.62088      17 0.010037309
```

## The equal-CV allocation

The factors — how much sample each variable commands — are the design’s
real lever.
[`eqcv_allocation()`](https://castlaboratory.github.io/chromy/reference/eqcv_allocation.md)
searches for the factors under which every variable’s total is
anticipated with the same coefficient of variation, so no estimate is
quietly sacrificed to another: at each step the anticipated CVs are
computed under the design the current factors imply, and the factors
move against their spread until it closes.

``` r

n_j <- eqcv_allocation(frame, c("revenue", "workers"), n = 60)
n_j
#>   revenue   workers 
#> 1.0902054 0.9172584 
#> attr(,"cv")
#>    revenue    workers 
#> 0.05797872 0.05793798 
#> attr(,"iterations")
#> [1] 5
#> attr(,"converged")
#> [1] TRUE
attr(n_j, "cv")
#>    revenue    workers 
#> 0.05797872 0.05793798
```

The anticipated CVs match. Compare the factors a naive equal split would
give — the skewed variable (`revenue`) needs more of the sample than the
tame one:

``` r

attr(suppressWarnings(
  eqcv_allocation(frame, c("revenue", "workers"), n = 60, max_iterations = 0)
), "cv")
#>    revenue    workers 
#> 0.06446797 0.05074703
```

## The design, in one call

[`chromy_sample()`](https://castlaboratory.github.io/chromy/reference/chromy_sample.md)
runs the allocation and the measure itself when given `variables`;
`n_j = "eqcv"` is the default.

``` r

s <- chromy_sample(
  frame,
  n = 60, variables = c("revenue", "workers"),
  order_by = c("sector", "chromy_size"),
  seed = 7
)
s$n_j
#>   revenue   workers 
#> 1.0902054 0.9172584
estimate_total(s, c("revenue", "workers"))
#> # A tibble: 2 × 5
#>   variable   total     se cv_pct random_draws
#>   <chr>      <dbl>  <dbl>  <dbl>        <int>
#> 1 revenue  443089. 36114.   8.15           55
#> 2 workers   10171.   770.   7.57           55
colSums(frame[c("revenue", "workers")])   # the true totals
#>  revenue  workers 
#> 477082.1  10557.0
```

Both totals are estimated from the one sample, each within its design’s
reach, and the realised CVs sit where the anticipation put them — close
to each other.

## Fixed factors

When the factors are policy rather than search — a variable that must
dominate, a historical allocation to keep — pass them directly:

``` r

s2 <- chromy_sample(
  frame,
  n = 60, variables = c("revenue", "workers"), n_j = c(2, 1),
  seed = 7
)
estimate_total(s2, c("revenue", "workers"))
#> # A tibble: 2 × 5
#>   variable   total     se cv_pct random_draws
#>   <chr>      <dbl>  <dbl>  <dbl>        <int>
#> 1 revenue  478627. 23041.   4.81           55
#> 2 workers   11008.  1216.  11.0            55
```

## References

Folsom, R. E., Potter, F. J. and Williams, S. R. (1987). Notes on a
composite size measure for self-weighting samples in multiple domains.
*Proceedings of the American Statistical Association, Section on Survey
Research Methods*, 792–796.
