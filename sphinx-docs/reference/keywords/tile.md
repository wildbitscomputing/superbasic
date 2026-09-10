# tile tile()

`tile` command manipulates the tile map. This allows you to set the scroll
offset (with `TO xscroll,yscroll`) and draw on the tile map using `AT x,y` to
set the position and `DRAW` followed by a list of tiles, with a repeat option
using `LINE`.

```basic
100   tile to 12,0
110   tile at 4,5 draw 10,11,11,11,10
120   tile at 4,5 draw 10,11 line 3,10
```

`tile()` function returns the tile at the given tile map position (not screen
position).

```basic
100   print tile(2,3)
```
