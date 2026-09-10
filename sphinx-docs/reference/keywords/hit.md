# hit()

Tests if two sprites overlap. This is done using a box test based on the size of
the sprite (e.g. 8×8, 16×16, 24×24, 32×32). The value returned is zero for no
collision, or the lower of the two coordinate differences from the centre,
approximately. This only works if sprites are positioned via the graphics
system.

```basic
100   print hit(1,2)
```
