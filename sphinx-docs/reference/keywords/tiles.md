# {kwd}`tiles`

Sets up the tile map. Allows the setting of the size of the tile map with
`dim <width>,<height>` and the location of the data with
`at <map address>,<image address>`, all addresses must be at the start of an 8k
page.

The defaults are 64 x 32 for the tile map and `$24000` for the map - an array of
words and `$26000` for the images - an array of 8x8 byte graphics. Currently
only 8x8 tiles are supported.

```basic
100 tiles on
110 tiles off
120 tiles dim 42,32 at $24000,$26000 on
```
