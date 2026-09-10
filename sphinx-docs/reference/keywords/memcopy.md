# memcopy

This command is an interface to the Wildbits/K2's DMA hardware. `MEMCOPY` has
several formats:

```basic
100   memcopy $10000,$4000 to $18000
110   memcopy $10000,$4000 poke $F7
120   memcopy $10000 rect 64,48 by 320 to $18000
130   memcopy $10000 rect 64,48 by 320 poke $18
140   memcopy at 32,32 rect 64,48 by 320 to at 128,128
```

Line 100 is a straight linear copy. Line 110 is a linear fill. Line 120 is a
rectangular area copy. Line 130 is a rectangular area fill. Line 140 shows an
alternate way using pixel coordinates.
