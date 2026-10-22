# chromy 0.2.0

- Exact second-order inclusion probabilities: `joint_inclusion()` evaluates
  the closed forms of Chauvet and Le Gleut (2021) for the
  without-replacement design under the random head, and
  `as_svydesign(variance = "pps")` hands them to `survey::ppsmat()`, making
  the Sen--Yates--Grundy variance exact.
- Successive difference replication: `as_svrepdesign()` builds the
  Fay--Train replicate-weights design (the American Community Survey
  convention), certainty rows unperturbed.
- The selector alone: `pmr()` for pipelines in the `sampling` package's
  idiom; `as_svydesign()` and `weights()` bridge to `survey`.
- Engine `chromy-core` 0.2.0, with minimum replacement verified as a
  runtime invariant on every selection.

# chromy 0.1.0

- First release: `chromy_sample()`, `serpentine_order()`, `mpps_size()`,
  `eqcv_allocation()`, `expected_hits()` and `estimate_total()`, on the
  engine `chromy-core` 0.1.0.
