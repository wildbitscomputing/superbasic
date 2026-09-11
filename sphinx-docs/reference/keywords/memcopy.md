# {kwd}`memcopy`

This command is an interface to the machine's DMA hardware. A {kwd}`memcopy`
command has several formats.

The first in line 100 is a straight linear copy of memory from `$10000` to
`$18000` of length `$4000`.

The second in line 110 is a linear fill from `$10000` , to `$4000` bytes on,
with the byte value `$F7`

The third in line 120 is a rectangular area of memory, 64 x 48 pixels or bytes,
from `$10000`. The 320 is the characters per line, which is a typical value.
This copies a 2D area of screen memory rather than a linear one.

The fourth, line 130 is a window, as defined, being filled with the byte pattern
`$18`.

The final shows an alternate way of showing addresses. This makes use of the
knowledge that this normally video memory - it doesn't have to be of course - at
32,32 and at 128,128 later, convert to the addresses of those pixels in bitmap
memory.

```basic
100 memcopy $10000,$4000 to $18000
110 memcopy $10000,$4000 poke $F7
120 memcopy $10000 rect 64,48 by 320 to $18000
130 memcopy $10000 rect 64,48 by 320 poke $18
140 memcopy at 32,32 rect 64,48 by 320 to at 128,128
```
