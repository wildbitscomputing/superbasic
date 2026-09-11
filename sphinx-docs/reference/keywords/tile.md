# {kwd}`tile` {kwd}`tile()`

{kwd}`tile` command manipulates the tile map. This allows you to set the scroll
offset (with `to xscroll,yscroll`) and draw on the time map using `at x,y` to
set the position and {kwd}`plot` followed by a list of tiles, with a repeat
option using {kwd}`line` to draw on it.

In the example below, lines 110 and 120 do the same thing.

```basic
100 tile to 12,0
110 tile at 4,5 plot 10,11,11,11,10
120 tile at 4,5 plot 10,11 line 3,10
```

{kwd}`tile()` function returns the tile at the given tile map position (not
screen position).

```basic
100 print tile(2,3)
```
