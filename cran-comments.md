# cran-comments

## Resubmission of chromy 0.2.1 (new package)

Changes asked for by the CRAN reviewer on the 0.2.0 submission:

- Every reference in the Description now links: Chromy (1979) and
  Folsom, Potter and Williams (1987) by URL to the ASA proceedings
  archive (which serves over http only), Chauvet and Le Gleut (2021) by
  DOI.
- Single quotes are confined to software names ('SAS', 'Rust',
  'chromy-core'); the SAS procedure and method names are now unquoted.

The spelling NOTE flags Chromy, Chromy's, Chauvet and Gleut, which are
surnames.

## About the package

Chromy's (1979) method of sequential random sampling with probability
minimum replacement — the procedure of PROC SURVEYSELECT METHOD=PPS_SEQ —
with serpentine sorting, a composite size measure, equal-CV allocation and
the matching estimator. No implementation of the method exists on CRAN.

Beyond the selection, the package computes the exact second-order
inclusion probabilities of the design (Chauvet and Le Gleut, 2021) and
bridges to the survey package (svydesign, including exact PPS variance,
and successive-difference replicate weights).

The computational engine is the Rust crate chromy-core, written by the
package authors, vendored in src/rust/vendor.tar.xz with the extendr
bindings (inst/AUTHORS lists every crate, author and licence), following
the CRAN policy on Rust packages: offline build, two jobs, versions of
cargo and rustc reported at configure time.

## Test environments

- local: macOS (aarch64), R 4.6.0 — R CMD check --as-cran: 0 errors,
  0 warnings, 2 notes (new submission; HTML Tidy of the local system).
- GitHub Actions: ubuntu (devel, release, oldrel-1), windows (release),
  macos (release).

## Notes

- "CRAN incoming feasibility": new submission.
- "HTML version of manual": old HTML Tidy on the local system only.
