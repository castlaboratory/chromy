# chromy: Chromy's Sequential Sampling with Probability Minimum Replacement

Selection of survey samples by Chromy's method of sequential random
sampling with probability minimum replacement, the procedure behind
'PROC SURVEYSELECT' 'METHOD=PPS_SEQ': each unit's realised number of
selections differs from its expected number by less than one, and the
sample size is always exact. With it, the apparatus the method is used
with in practice: hierarchical serpentine sorting of the frame for
implicit stratification; a maximal size measure over several auxiliary
variables; the allocation that equalises anticipated coefficients of
variation across variables; expected hits with certainty units resolved
by iteration or, under minimum replacement, units selected more than
once; and the multiplicity estimator with the successive-difference
variance. The computational engine is the Rust crate 'chromy-core'. The
methods follow Chromy (1979) and Chauvet and Le Gleut (2021)
[doi:10.48550/arXiv.1912.10896](https://doi.org/10.48550/arXiv.1912.10896)
for the selection, and Folsom, Potter and Williams (1987) for the
composite size measure.

Selection of survey samples by Chromy's (1979) method of sequential
random sampling:
[`chromy_sample()`](https://castlaboratory.github.io/chromy/reference/chromy_sample.md)
draws the sample, over a frame listed by
[`serpentine_order()`](https://castlaboratory.github.io/chromy/reference/serpentine_order.md),
with a size from
[`mpps_size()`](https://castlaboratory.github.io/chromy/reference/mpps_size.md)
and
[`eqcv_allocation()`](https://castlaboratory.github.io/chromy/reference/eqcv_allocation.md)
or from a single column, expected hits from
[`expected_hits()`](https://castlaboratory.github.io/chromy/reference/expected_hits.md),
and totals estimated by
[`estimate_total()`](https://castlaboratory.github.io/chromy/reference/estimate_total.md).
The numerical engine is the Rust crate `chromy-core`; all randomness
comes from R's own generator, so
[`set.seed()`](https://rdrr.io/r/base/Random.html) makes a selection
exactly reproducible.

## See also

Useful links:

- <https://castlaboratory.github.io/chromy/>

- <https://github.com/castlaboratory/chromy>

- Report bugs at <https://github.com/castlaboratory/chromy/issues>

## Author

**Maintainer**: André Leite <leite@castlab.org>
([ORCID](https://orcid.org/0000-0002-4718-9766))

Authors:

- André Leite <leite@castlab.org>
  ([ORCID](https://orcid.org/0000-0002-4718-9766))

- Raydonal Ospina <raydonal@castlab.org>
  ([ORCID](https://orcid.org/0000-0002-9884-9090))

- Cristiano Ferraz <cferraz@castlab.org>
  ([ORCID](https://orcid.org/0000-0002-6838-6734))

- David Eloi dos Santos Bitencourt <profdavidsb@gmail.com>

- Clara Ribeiro de Santana <clara.rsantana@ufpe.br>

Other contributors:

- The authors of the dependency Rust crates (see inst/AUTHORS file for
  details) \[contributor\]
