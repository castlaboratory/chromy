# Order a frame for sequential selection

A sequential procedure buys variance from the order of the list: units
that sit together are selected apart, so the sample spreads over
whatever the sort keys encode — implicit stratification. A plain nested
sort leaves a seam at every boundary where the last unit of one group
meets the first of the next and the two could not be less alike; the
hierarchical serpentine sort removes the seams by reversing direction at
each boundary, so the list meanders through the frame and every
neighbouring pair of units is actually similar.

## Usage

``` r
serpentine_order(frame, by, method = c("serpentine", "nested"))
```

## Arguments

- frame:

  Data frame with one row per unit.

- by:

  Names of the sort key columns, outermost first.

- method:

  `"serpentine"` (the default) or `"nested"`. With a single key the two
  coincide.

## Value

An integer vector: the order in which to list the rows of `frame`, as
[`order()`](https://rdrr.io/r/base/order.html) would return it.

## Details

Character and factor keys are ranked by the byte order of their values
(the C locale), deliberately: a sort that followed the session's locale
would produce a different sample on a different machine.

## References

Williams, R. L. and Chromy, J. R. (1980). SAS sample selection macros.
*Proceedings of the Fifth Annual SAS Users Group International
Conference*, 392–396.

## Examples

``` r
frame <- data.frame(
  region = rep(c("north", "south"), each = 4),
  size   = c(4, 2, 3, 1, 30, 10, 40, 20)
)
frame[serpentine_order(frame, c("region", "size")), ]
#>   region size
#> 4  north    1
#> 2  north    2
#> 3  north    3
#> 1  north    4
#> 7  south   40
#> 5  south   30
#> 8  south   20
#> 6  south   10
```
