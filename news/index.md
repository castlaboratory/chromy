# Changelog

## chromy 0.2.0

- Exact second-order inclusion probabilities:
  [`joint_inclusion()`](https://castlaboratory.github.io/chromy/reference/joint_inclusion.md)
  evaluates the closed forms of Chauvet and Le Gleut (2021) for the
  without-replacement design under the random head, and
  `as_svydesign(variance = "pps")` hands them to
  [`survey::ppsmat()`](https://rdrr.io/pkg/survey/man/HR.html), making
  the Sen–Yates–Grundy variance exact.
- Successive difference replication:
  [`as_svrepdesign()`](https://castlaboratory.github.io/chromy/reference/as_svrepdesign.md)
  builds the Fay–Train replicate-weights design (the American Community
  Survey convention), certainty rows unperturbed.
- The selector alone:
  [`pmr()`](https://castlaboratory.github.io/chromy/reference/pmr.md)
  for pipelines in the `sampling` package’s idiom;
  [`as_svydesign()`](https://castlaboratory.github.io/chromy/reference/as_svydesign.md)
  and [`weights()`](https://rdrr.io/r/stats/weights.html) bridge to
  `survey`.
- Engine `chromy-core` 0.2.0, with minimum replacement verified as a
  runtime invariant on every selection.

## chromy 0.1.0

- First release:
  [`chromy_sample()`](https://castlaboratory.github.io/chromy/reference/chromy_sample.md),
  [`serpentine_order()`](https://castlaboratory.github.io/chromy/reference/serpentine_order.md),
  [`mpps_size()`](https://castlaboratory.github.io/chromy/reference/mpps_size.md),
  [`eqcv_allocation()`](https://castlaboratory.github.io/chromy/reference/eqcv_allocation.md),
  [`expected_hits()`](https://castlaboratory.github.io/chromy/reference/expected_hits.md)
  and
  [`estimate_total()`](https://castlaboratory.github.io/chromy/reference/estimate_total.md),
  on the engine `chromy-core` 0.1.0.
