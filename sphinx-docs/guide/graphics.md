# Graphics

## Introduction

The graphics subsystem consists of three components, which is a subset of the full capabilities of the Wildbits machines.

| Layer | Description |
|---|---|
| Tile Map | 8×8 pixel tile grid, up to 256×256 tiles, scrollable |
| Bitmap | 320×240 pixel screen drawn on top of the tile layer |
| Sprites | Hardware sprites drawn on top of the bitmap |

The graphics are much more complex than this; the system allows up to three tile maps for example. Those can be done in BASIC if you wish, by directly accessing the system registers, as covered in the hardware reference guide.

## Bitmap Graphics

Bitmap graphics can be done in one of three ways.

- Firstly, they can be done using BASIC commands like `line`, `plot` and `text` — these are the easiest.
- Secondly, they can be done by directly accessing the graphics library via the `gfx` command.
- Thirdly, you can "hit the hardware" directly using `poke` and `pokw` or the indirection operators.

The latter is the most flexible. BASIC simplifies the graphics system to some extent to make it easier to use; for example, the Wildbits/K2 can have up to three bitmaps, but only one is supported using BASIC commands.

## Graphics Modifiers and Actions

Following drawing commands `plot`, `line`, `rect`, `circle`, `sprite`, `char` and `image` there are actions and modifiers which either change or cause the command to be done (e.g. draw the line, draw the string, etc.). Changes persist, so if you set `color 3` or `solid` it will apply to all subsequent draws until you change it.

Not all things work or make sense for all commands; you can't change the dimensions of a line, or the color of a hardware sprite.

| Modifier | Description |
|---|---|
| `to 100,100` | Draws the object from the current point to the new point, or at the new point |
| `from 10,10` | Sets the current point but doesn't draw. The `from` is optional but must be used where a number precedes the coordinates |
| `here` | Same as `to` but done at the current point |
| `by 4,5` | Same as `to` but offset from the current point by 4 horizontal, 5 vertical |
| `solid` | Causes shapes to be filled in |
| `outline` | Causes shapes to be drawn in outline |
| `dim 3` | Sets the size of scalable objects (`char`, `image`) from 1 to 8 |
| `color 4` / `color 5` | Synonyms (due to American misspelling); sets the drawing color from LUT 0, which is set up as `RRRGGGBB` |

## Some Useful Examples

All these examples begin `bitmap on:cls:bitmap clear 3` — display and clear the bitmap, then fill it with color 3. This is `0000 0011` — and the color by default is `RRRG GGBB` in binary — so this is blue.

### Some Lines

```basic
100   bitmap on:cls:bitmap clear 3
110   line color $1E from 10,10 to 100,200 to 200,50 to 10,10 by 0,20
```

Note how you can chain commands and also the use of the relative position `by` which means "from here".

### Some Circles

```basic
100   bitmap on:cls:bitmap clear 3
110   circle solid color $1E outline 10,10 to 200,200 solid 10,10 to 30,30
```

Rectangles are the same. Currently we cannot draw ellipses.

### Some Text

```basic
100   bitmap on:cls:bitmap clear 3
110   text "Hello there" dim 1 color $FC to 10,10 dim 3 to 10,40
```

Drawing text from the font library in Vicky. These characters can be redefined.

### Some Pixels

```basic
100   bitmap on:cls:bitmap clear 3
110   repeat
120     plot color random(256) to random(320),random(230)
130   until false
```

Press Break to stop this one. Note you have to write `PLOT TO` here.

## Ranges

The range of values for draw commands is 0–319 and normally 0–239, though there is a VGA mode which is 320×200 (in which case it would be 0–199).

Colors are values from 0–255 — initially this can be viewed as a binary number `RRRGGGBB`.
