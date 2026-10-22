# chromy

Chromy’s method of sequential random sampling with probability minimum
replacement, in the open. The procedure selects units one at a time down
an ordered list, each with probability proportional to its size, so that
every unit’s realised number of selections differs from its expected
number by less than one and the sample size is always exact. It is how
many large establishment and household surveys draw their samples, and
how `PROC SURVEYSELECT METHOD=PPS_SEQ` works; until now it lived only
inside proprietary software and one Stata module.

With the selection comes the apparatus it is used with in practice:

- **[`chromy_sample()`](https://castlaboratory.github.io/chromy/reference/chromy_sample.md)**
  — the whole design in one call: size, order, head, selection, weights;
- **[`serpentine_order()`](https://castlaboratory.github.io/chromy/reference/serpentine_order.md)**
  — hierarchical serpentine sorting of the frame, the implicit
  stratification that makes a sequential selection worth having;
- **[`mpps_size()`](https://castlaboratory.github.io/chromy/reference/mpps_size.md)**
  and
  **[`eqcv_allocation()`](https://castlaboratory.github.io/chromy/reference/eqcv_allocation.md)**
  — a maximal size measure over several auxiliary variables, and the
  allocation that equalises their anticipated coefficients of variation,
  for one sample that serves several estimates;
- **[`expected_hits()`](https://castlaboratory.github.io/chromy/reference/expected_hits.md)**
  — sizes into expected hits, certainties resolved by iteration, or
  units allowed several hits under minimum replacement;
- **[`estimate_total()`](https://castlaboratory.github.io/chromy/reference/estimate_total.md)**
  — the multiplicity estimator that matches the design, with the
  successive-difference variance.

The numerical engine is the Rust crate
[`chromy-core`](https://github.com/castlaboratory/chromy-core); the
Python binding is
[`pychromy`](https://github.com/castlaboratory/pychromy). All randomness
comes from R’s own generator, so
[`set.seed()`](https://rdrr.io/r/base/Random.html) makes a selection
exactly reproducible.

## Installation

``` r

# install.packages("pak")
pak::pak("castlaboratory/chromy")
```

A Rust toolchain (rustc ≥ 1.77) is needed to build from source; CRAN
binaries, once published, will not need one.

## A design in five lines

``` r

library(chromy)
set.seed(2026)

frame <- data.frame(
  region = sample(c("north", "east", "south", "west"), 300, replace = TRUE),
  pupils = round(rlnorm(300, 4.5)),
  outcome = rlnorm(300, 5)
)

s <- chromy_sample(frame, n = 40, size = "pupils",
                   order_by = c("region", "chromy_size"))
estimate_total(s, "outcome")
```

The sample size is exact, every unit’s hits are the floor or the ceiling
of its expected hits, and the weights on `s$sample` are ready for any
design-based analysis.
[`vignette("chromy")`](https://castlaboratory.github.io/chromy/articles/chromy.md)
walks through a full design;
[`vignette("method")`](https://castlaboratory.github.io/chromy/articles/method.md)
opens the procedure itself;
[`vignette("validation")`](https://castlaboratory.github.io/chromy/articles/validation.md)
checks the promises by simulation.

## Fidelity

The package was distilled from a reference implementation kept verbatim
in the test suite as an oracle: given the same seed,
[`chromy_sample()`](https://castlaboratory.github.io/chromy/reference/chromy_sample.md)
reproduces it draw for draw, across every design the two share. The
engine is pinned to the same reference by golden fixtures, integer
outputs exact and floating-point outputs at machine precision.
Floating-point drift in the expected hits is measured, assigned to a
single unit, and reported — never silently rescaled.

## References

- Chromy, J. R. (1979). Sequential sample selection methods.
  *Proceedings of the American Statistical Association, Survey Research
  Methods Section*, 401–406.
- Chauvet, G. and Le Gleut, R. (2021). Properties of Chromy’s sampling
  procedure. *Survey Methodology*, 47(2), 321–347.
- Folsom, R. E., Potter, F. J. and Williams, S. R. (1987). Notes on a
  composite size measure for self-weighting samples in multiple domains.
  *Proceedings of the ASA, Section on Survey Research Methods*, 792–796.

## License

GPL (≥ 3). A project of the [CAST Lab](https://castlab.org), UFPE.
