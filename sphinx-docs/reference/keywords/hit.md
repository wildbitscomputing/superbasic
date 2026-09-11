# {kwd}`hit()`

Tests whether two sprites overlap, using a bounding box test based on their size
(e.g., 8×8, 16×16, 24×24, or 32×32).

Returns zero if there is no collision, or the smaller of the two coordinate
differences from the center.

This function only works for sprites positioned using the graphics system; there
is no way to read sprite memory directly to determine their on-screen positions.

```basic
100 print hit(1,2)
```
