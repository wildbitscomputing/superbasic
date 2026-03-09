# Tiles and Tile Maps

## Introduction

SuperBASIC supports a single tile map, made up of 8×8 pixel images. A tile map can be up to 255×255 tiles in size. The default size is 64×32.

## Setting Up a Tile Map

The `TILES` command sets up a tile map. For example, the following command sets up a 48×48 tile map at the default locations (see below), and turns it on:

```basic
100 tiles dim 48,48 on
```

## Manipulating a Tile Map

The `TILE` command is used to manipulate a tile map, by either scrolling its position, or by writing to it. These commands can be chained in a similar manner to the graphics drawing ones.

This example sets the draw pointer at tile 4 across, 5 down and draws the following tiles, writing horizontally: tile 10, 3 tile 11s, and another tile 10. So it is not difficult to create maps programmatically.

`TILE TO` scrolls the tile map on the screen — this is in pixels, not whole tiles.

The `TILE()` function reads the tile at the current map position (which following the code at line 100, should be 11).

```basic
100 tile at 4,5 draw 10,11 line 3,10
110 tile to 14,12
120 t = tile(5,5)
```

## Data Formats

There are two data files required for a tile map:

```{mermaid}
flowchart LR
    MAP["$24000<br/>Map Data<br/>(w × h × 2 bytes)"] -- index into --> IMG["$26000<br/>Image Data<br/>(64 bytes/tile)"] -- 8×8 pixels --> SCR["Screen<br/>320×240"]

    style MAP fill:#1565c0,color:#fff,stroke:#0d47a1
    style IMG fill:#e65100,color:#fff,stroke:#bf360c
    style SCR fill:#2e7d32,color:#fff,stroke:#1b5e20
```

The **images file** is a sequence of 64 bytes, representing an 8×8 tile. These are indexed from zero. This images file is held at `$26000` by default (though it can be placed anywhere).

The **map file** is a word sequence, which is (map width × map height × 2) bytes in size, as specified in the Hardware Reference Manual. This map is held at `$24000` by default (it too can be placed anywhere).
