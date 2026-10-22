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
as_svydesign(x, variance = c("replacement", "pps"), ...)
```

## Arguments

- x:

  A
  [`chromy_sample()`](https://castlaboratory.github.io/chromy/reference/chromy_sample.md).

- variance:

  `"replacement"` (the default) or `"pps"`.

- ...:

  Passed on to
  [`survey::svydesign()`](https://rdrr.io/pkg/survey/man/svydesign.html).

## Value

A `survey.design` object.

## Details

With `variance = "replacement"` (the default) the design is `ids = ~1`:
the with-replacement approximation, which ignores the implicit
stratification the serpentine order bought, so it tends to be more
conservative than the successive-difference variance of
[`estimate_total()`](https://castlaboratory.github.io/chromy/reference/estimate_total.md).
With `variance = "pps"` the exact joint inclusion probabilities of
[`joint_inclusion()`](https://castlaboratory.github.io/chromy/reference/joint_inclusion.md)
are handed to
[`survey::ppsmat()`](https://rdrr.io/pkg/survey/man/HR.html) and the
Sen–Yates–Grundy variance is exact for the design — available for the
default without-replacement sample.

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

exact <- as_svydesign(s, variance = "pps")
survey::svytotal(~y, exact)
#>   total     SE
#> y 23879 6712.5
```
