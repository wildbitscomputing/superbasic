# tiles

Sets up the tile map. Allows the setting of the size with `DIM <width>,<height>`
and the location of the data with `AT <map address>,<image address>`. All
addresses must be at the start of an 8KB page. Currently only 8×8 tiles are
supported.

```basic
100   tiles on
110   tiles off
120   tiles dim 42,32 at $24000,$26000 on
```
