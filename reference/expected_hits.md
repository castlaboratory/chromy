# Expected hits proportional to size

Turns a size measure into the expected hits Chromy's selection consumes.
In the usual case (`min_replacement = FALSE`) units whose proportional
share reaches one are made certainties and the remainder is re-shared
until no unit crosses one; the result is a vector of inclusion
probabilities in `[0, 1]`, and `n` may not exceed the number of units
with positive size. Under minimum replacement the expected hits are
simply `n` times the size shares, values above one meaning the unit may
be selected more than once — which Chromy's procedure handles natively,
and is the reason to use it.

## Usage

``` r
expected_hits(size, n, min_replacement = FALSE)
```

## Arguments

- size:

  Non-negative numeric vector, one entry per unit.

- n:

  The sample size: the expected number of selections.

- min_replacement:

  Allow expected hits above one instead of resolving certainties.

## Value

A numeric vector of expected hits summing to `n`.

## Examples

``` r
expected_hits(c(100, 50, 10, 5, 5), 3)
#> [1] 1.00 1.00 0.50 0.25 0.25
expected_hits(c(100, 50, 10, 5, 5), 3, min_replacement = TRUE)
#> [1] 1.76470588 0.88235294 0.17647059 0.08823529 0.08823529
```
