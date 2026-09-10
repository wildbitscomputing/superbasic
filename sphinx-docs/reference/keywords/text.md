# text

Draws a possibly scaled or flipped string from the standard font on the bitmap,
using the standard syntax. Flipping is done using bits 7 and 6 of the mode in
the colour option.

```basic
100   text "hello" dim 2 colour 3 to 100,100
```
