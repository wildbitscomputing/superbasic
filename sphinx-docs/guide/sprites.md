# Sprites

## Introduction

Sprites are graphic images of differing sizes (8×8, 16×16, 24×24 or 32×32) which can appear on top of a bitmap but which don't affect that bitmap. It is a bit like a cartoon where you have a background and animated characters are placed on it.

The sprite command adopts the same syntax as the graphics commands in the previous section. An example is:

```basic
sprite 3 image 5 to 20,20
```

This manipulates sprite number 3 (there are 64, numbered 0–63), using image number 5, centred on screen position 20,20. The image number comes from the data set — in the example set below it would be `enemy.png` rotated by 90° — the sixth entry as we count from 0. You can change the location and image independently.

Most of the theoretical graphics options do not work; you cannot colour, scale, flip etc. a sprite — the graphic is what it is. However, they are very fast compared with drawing an image on the screen using the `image` command.

## Creating Sprites

SuperBASIC by default loads sprite data to memory location `$30000`. This chapter explains how to create that data file. This can be done by the developer, or via a Python script.

## Getting Images

Sprite data is built from PNG images up to 32×32. There are some examples in the Solarfox directory in the GitHub: <https://github.com/wildbitscomputing/superbasic>.

They can be created individually, or ripped from sprite sheets — this is what `ripgfx.py` is doing in the Makefile in `solarfox/graphics`; starting with the PNG file `source.png` it is informed where graphics are, and it tries to work out a bounding box for that graphic, and exports it to the various files.

## Building a Sprite Data Set

Sprite data sets are built using the `spritebuild.py` Python script (in the utilities subdirectory). Again there is an example of this in the Solarfox directory.

Sprite set building takes a file of sprite definitions — a simple text list of files, which can be either PNG files as-is, or postfixed by a rotate angle (only 0, 90, 180 and 270) or `v` or `h` for vertical and horizontal mirroring:

```text
graphics/ship.png
graphics/ship.png 90
graphics/ship.png 180
graphics/ship.png 270
graphics/enemy.png
graphics/enemy.png 90
graphics/enemy.png 180
graphics/enemy.png 270
graphics/collect1.png
graphics/collect2.png
graphics/life.png h
```

Sprite images are numbered in the order they appear in the file, from zero, and should be loaded at `$30000`.

When building the sprite it strips it as much as possible and centres it in the smallest sprite size it fits in. When using BASIC commands to position a sprite, that position is relative to the centre of the sprite.

## Build Pipeline

```{mermaid}
flowchart LR
    PNG["PNG images<br/>(up to 32×32)"] --> BUILD["spritebuild.py"]
    BUILD --> BIN["Binary sprite set"]
    BIN --> MEM["$30000+<br/>Sprite Memory"]
    MEM --> HW["64 Hardware<br/>Sprites"]

    style PNG fill:#1565c0,color:#fff,stroke:#0d47a1
    style BUILD fill:#e65100,color:#fff,stroke:#bf360c
    style BIN fill:#2e7d32,color:#fff,stroke:#1b5e20
    style HW fill:#c62828,color:#fff,stroke:#b71c1c
```

## Collision Detection

Collision detection between sprites is done using `hit(sprite1, sprite2)`. This uses a box test based on the size of the sprite. The value returned is zero for no collision, or the lower of the two coordinate differences from the centre, approximately.

This only works if sprites are positioned via the graphics system; there is no way of reading sprite memory to ascertain where the physical sprites are.

## Data Format

At present there is a very simple data format:

```text
+00 is the format code ($11)
+01 is the sprite size  (0-3, representing 8,16,24 and 32 pixel size)
+02 the LUT to use (normally zero)
+03 the first byte of sprite data
```

The size, LUT and data are then repeated for every sprite in the sprite set. The file should end with a sprite size of `$80` (128) to indicate the end of the set.
