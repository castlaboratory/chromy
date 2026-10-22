# Successive-difference replicate weights for a chromy sample

Builds a replicate-weights design in the successive difference
replication scheme of Fay and Train (1995), the convention of the
American Community Survey: the rows whose selection was actually random
are perturbed, in list order, by factors `1 +- 2^(-3/2) * 2` read off
pairs of rows of a Hadamard matrix, so that the replicate variance
approximates the successive-difference variance of
[`estimate_total()`](https://castlaboratory.github.io/chromy/reference/estimate_total.md)
while giving the `survey` package's whole replicate machinery —
quantiles, domains, calibration — a design to work with. Rows selected
with certainty keep their weight in every replicate, as they carry no
variance.

## Usage

``` r
as_svrepdesign(x, replicates = NULL, ...)
```

## Arguments

- x:

  A
  [`chromy_sample()`](https://castlaboratory.github.io/chromy/reference/chromy_sample.md).

- replicates:

  The number of replicates, or `NULL` for the smallest Hadamard order
  above the number of randomly selected rows.

- ...:

  Passed on to
  [`survey::svrepdesign()`](https://rdrr.io/pkg/survey/man/svrepdesign.html).

## Value

A `svyrep.design` object with scale `4 / replicates`.

## References

Fay, R. E. and Train, G. F. (1995). Aspects of survey and model-based
postcensal estimation of income and poverty characteristics for states
and counties. *Proceedings of the ASA, Government Statistics Section*,
154–159.

## Examples

``` r
set.seed(11)
frame <- data.frame(size = rlnorm(120, 2), y = rlnorm(120, 4))
s <- chromy_sample(frame, n = 30, size = "size")
r <- as_svrepdesign(s)
survey::svytotal(~y, r)
#>   total     SE
#> y 13671 4124.2
estimate_total(s, "y")
#> # A tibble: 1 × 5
#>   variable  total    se cv_pct random_draws
#>   <chr>     <dbl> <dbl>  <dbl>        <int>
#> 1 y        13671. 4188.   30.6           27
```
