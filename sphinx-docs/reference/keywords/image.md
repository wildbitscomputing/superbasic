# {kwd}`image`

Draws a sprite image onto the bitmap, with optional scaling or flipping.
Flipping is controlled by bits 7 and 6 of the mode byte (i.e., `$80` for
horizontal flip, `$40` for vertical flip) in the colour parameter. Both the
sprite and bitmap systems must be enabled. For more details, see
Chapter {ref}`chap:graphics`.

```basic
100 image 4 dim 3 colour 0,$80 to 100,100
```
