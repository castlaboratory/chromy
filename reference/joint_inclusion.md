# Exact joint inclusion probabilities of the sampled units

Chromy's procedure run down a fixed list is the same design as ordered
pivotal sampling, and for that design the joint (second-order) inclusion
probabilities have closed forms (Chauvet and Le Gleut, 2021, Theorem 3);
with the random head the design is the mixture of the circular
rotations, each weighted by its unit's probability over the sample size
(their eq. 5.3) — precisely the head
[`chromy_sample()`](https://castlaboratory.github.io/chromy/reference/chromy_sample.md)
draws. This function evaluates those forms exactly for the sampled
units, making the Sen–Yates–Grundy variance of the Horvitz–Thompson
total exact rather than approximated;
[`as_svydesign()`](https://castlaboratory.github.io/chromy/reference/as_svydesign.md)
with `variance = "pps"` hands it to the `survey` package.

## Usage

``` r
joint_inclusion(x)
```

## Arguments

- x:

  A
  [`chromy_sample()`](https://castlaboratory.github.io/chromy/reference/chromy_sample.md)
  drawn with `head = "all"` (the default) and `min_replacement = FALSE`
  (the default).

## Value

The symmetric matrix of joint inclusion probabilities of the sampled
units, in the order of `x$sample`, with the first-order (effective)
probabilities on the diagonal.

## Details

Joint *inclusion* probabilities belong to the without-replacement
design: a sample drawn with `min_replacement = TRUE`, where a unit may
be selected more than once, is refused. The cost is of order `N` (frame)
times the square of the sample size.

## References

Chauvet, G. and Le Gleut, R. (2021). Properties of Chromy's sampling
procedure. *Survey Methodology*, 47(2), 321–347.

## Examples

``` r
set.seed(9)
frame <- data.frame(size = rlnorm(40, 2))
s <- chromy_sample(frame, n = 10, size = "size")
p2 <- joint_inclusion(s)
all(abs(p2 - t(p2)) < 1e-12)
#> [1] TRUE
all(diag(p2) == s$sample$expected_hits)
#> [1] TRUE
```
