# assemble

Initialises an assembler pass. Apart from the simplest bits of code, the
assembler is two-pass. It has two parameters. The first is the location in
memory the assembled code should be stored, the second is the mode. At present
there are two mode bits; bit 0 indicates the pass (0 = first pass, 1 = second
pass) and bit 1 specifies whether the code is listed as it goes. Normally these
values will be 0 and 1, as the listing is a bit slow. 6502 mnemonics are typed
as-is.

```basic
100   assemble $6000,1:lda #42:sta count:rts
```

Normally these are wrapped in a loop for the two passes for forward references:

```basic
100   for pass = 0 to 1
110     assemble $6000,pass
120     bra forward
130     <some code>
140     .forward:rts
150   next
```

This is almost identical to the BBC Microcomputer's inline assembler.
