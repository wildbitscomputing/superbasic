# {kwd}`gfx`

Sends a three-parameter command directly to the graphics subsystem. The last two
parameters are often coordinates, although not always.

This is a low-level call to the graphics library and is generally discouraged
for regular use. The command parameters are documented in the
{file}`graphics.txt` document in the SuperBASIC repository.[^1] Use of this
function is uncommon.

```basic
100 gfx 22,130,100
```

[^1]: <https://github.com/wildbitscomputing/superbasic/blob/main/documents/graphics.txt>
