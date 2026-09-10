# image

Draws a possibly scaled or flipped sprite image on the bitmap, using the
standard syntax. Flipping is done using bits 7 and 6 of the mode (e.g. `$80` and
`$40`) in the colour option. This requires both sprites and bitmap to be on.

```basic
100   image 4 dim 3 colour 0,$80 to 100,100
```
