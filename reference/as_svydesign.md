# A chromy sample as a survey design

Hands the sample to the `survey` package: one row per selected unit,
weighted by `hits / expected_hits`, so
[`survey::svytotal()`](https://rdrr.io/pkg/survey/man/surveysummary.html)
reproduces
[`estimate_total()`](https://castlaboratory.github.io/chromy/reference/estimate_total.md)'s
point estimates and the whole of `survey`'s toolbox — ratios,
regressions, domains, calibration — applies.

## Usage

``` r
as_svydesign(x, ...)
```

## Arguments

- x:

  A
  [`chromy_sample()`](https://castlaboratory.github.io/chromy/reference/chromy_sample.md).

- ...:

  Passed on to
  [`survey::svydesign()`](https://rdrr.io/pkg/survey/man/svydesign.html).

## Value

A `survey.design` object.

## Details

The variance `survey` reports under this design (`ids = ~1`) is the
with-replacement approximation: it ignores the implicit stratification
the serpentine order bought, so it tends to be more conservative than
the successive-difference variance of
[`estimate_total()`](https://castlaboratory.github.io/chromy/reference/estimate_total.md),
which reads that order. Both are defensible reports; they answer
slightly different questions about the same sample.

## Examples

``` r
set.seed(7)
frame <- data.frame(size = rlnorm(80, 3), y = rlnorm(80, 5))
s <- chromy_sample(frame, n = 25, size = "size")
d <- as_svydesign(s)
survey::svytotal(~y, d)
#>   total     SE
#> y 23879 7603.4
estimate_total(s, "y")
#> # A tibble: 1 × 5
#>   variable  total    se cv_pct random_draws
#>   <chr>     <dbl> <dbl>  <dbl>        <int>
#> 1 y        23879. 6865.   28.8           18
```
