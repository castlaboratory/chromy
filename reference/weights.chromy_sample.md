# Sampling weights of a chromy sample

The weight each selected row carries in the multiplicity estimator:
`hits / expected_hits`. These are the weights
[`as_svydesign()`](https://castlaboratory.github.io/chromy/reference/as_svydesign.md)
hands to the `survey` package, and the ones to use in any weighted
analysis of the sample.

## Usage

``` r
# S3 method for class 'chromy_sample'
weights(object, ...)
```

## Arguments

- object:

  A
  [`chromy_sample()`](https://castlaboratory.github.io/chromy/reference/chromy_sample.md).

- ...:

  Unused.

## Value

A numeric vector, one weight per row of `object$sample`.
