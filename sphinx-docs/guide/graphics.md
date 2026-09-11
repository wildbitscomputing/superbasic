(chap:graphics)=

# Graphics

## Introduction

The graphics subsystem consists of three components, which is a subset of the
full capabilities of the Wildbits machines.

Firstly there is an 8x8 pixel tile grid of up to 256x256 tiles, which can be
scrolled about.

Secondly, on top of that is a 320x240 bitmap screen, which can have anything
drawn on it.

Thirdly, on top of that, are the sprites.

The graphics are much more complex than this; the system allows up to three tile
maps for example. Those can be done in BASIC if you wish, by directly accessing
the system registers, as covered in the hardware reference guide.

| Layer    | Description                                          |
| -------- | ---------------------------------------------------- |
| Tile Map | 8×8 pixel tile grid, up to 256×256 tiles, scrollable |
| Bitmap   | 320×240 pixel screen drawn on top of the tile layer  |
| Sprites  | Hardware sprites drawn on top of the bitmap          |

## Bitmap graphics

Bitmap Graphics can be done in one of three ways.

- Firstly, they can be done using BASIC commands like {kwd}`line`, {kwd}`plot`
  and {kwd}`text`. These are the easiest.

- Secondly, they can be done by directly accessing the graphics library via the
  {kwd}`gfx` command.

- Thirdly, you can "hit the hardware" directly using {kwd}`poke` and {kwd}`pokw`
  or the indirection operators.

The latter is the most flexible. BASIC simplifies the graphics system to some
extent to make it easier to use; for example, the underlying hardware can have
up to three bitmaps, but only one is supported using BASIC commands.

## Graphics modifiers and actions

Following drawing commands {kwd}`plot`, {kwd}`line`, {kwd}`rect`, {kwd}`circle`,
{kwd}`sprite`, {kwd}`char` and {kwd}`image` there are actions and modifiers
which either change or cause the command to be done (e.g. draw the line, draw
the string etc.). Changes persist, so if you set {kwd}`colour` 3 or {kwd}`solid`
it will apply to all subsequent draws until you change it. Not all things work
or make sense for all commands; you can't change the dimensions of a line, or
the colour of a hardware sprite.

| Modifier                                         | Description                                                                                                                                                                                                                                                                                                                   |
| ------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| {kwd}`to`{code}` 100,100`                        | Draws the object from the current point to the new point, or at the new point.                                                                                                                                                                                                                                                |
| {kwd}`from`{code}` 10,10`                        | Sets the current point, but doesn't draw. So you have {kwd}`rect` 10,10 {kwd}`to` 100,100. Note that {kwd}`plot` requires {kwd}`to` to do something, which is a little odd but consistent. The {kwd}`from` is optional, but must be used where a number precedes the coordinates (e.g. you can't do {kwd}`colour` 5 100,200). |
| {kwd}`here`                                      | Same as {kwd}`to` but done at the current point.                                                                                                                                                                                                                                                                              |
| {kwd}`by`{code}` 4,5`                            | Same as {kwd}`to` but offset from the current point by 4 horizontal, 5 vertical.                                                                                                                                                                                                                                              |
| {kwd}`solid`                                     | Causes shapes to be filled in.                                                                                                                                                                                                                                                                                                |
| {kwd}`outline`                                   | Causes shapes to be drawn in outline.                                                                                                                                                                                                                                                                                         |
| {kwd}`dim`{code}` 3`                             | Sets the size of scalable objects ({kwd}`char`, {kwd}`image`) from 1 to 8.                                                                                                                                                                                                                                                    |
| {kwd}`colour`{code}` 4` / {kwd}`color`{code}` 4` | Synonyms, sets the current drawing colour from LUT 0, which is set up as `RRRGGGBB`.                                                                                                                                                                                                                                          |

## Some useful examples

All these examples start with {kwd}`bitmap`
{kwd}`on`{code}`:`{kwd}`cls`{code}`:`{kwd}`bitmap` {kwd}`clear`{code}` 3`, which
enables the bitmap display, clears the screen, and fills the bitmap with color
value 3. In binary, this is `00000011`, and since colors are encoded as
`RRRGGGBB` by default, this corresponds to blue.

### Example: some lines

```basic
100 bitmap on:cls:bitmap clear 3
110 line colour $1E from 10,10 to 100,200 to 200,50 to 10,10 by 0,20
```

Note how you can chain commands, and also the use of the relevant position
{kwd}`by` which means from here.

### Example: some circles

```basic
100 bitmap on:cls:bitmap clear 3
110 circle solid colour $1E outline 10,10 to 200,200 solid 10,10 to 30,30
```

Rectangles are the same. Currently we cannot draw ellipses.

### Example: some text

```basic
100 bitmap on:cls:bitmap clear 3
110 text "Hello there" dim 1 colour $FC to 10,10 dim 3 to 10,40
```

Drawing text from the font library in Vicky. These characters can be redefined.

### Example: some pixels

```basic
100 bitmap on:cls:bitmap clear 3
110 repeat
120 plot color random(256) to random(320),random(230)
130 until false
```

Press break to stop this one. Note you have to write {kwd}`plot` {kwd}`to` here.

## Ranges

The range of values for draw commands is 0–319 and normally 0–239, though there
is a VGA mode which is 320x200 (in which case it would be 0-199).

Colors are values from 0 to 255, interpreted in binary as `RRRGGGBB` by default.
