# {kwd}`bsave`

Saves a chunk of memory into a file. The 2nd parameter is the address in full
memory space, *not* the 6502 CPU address. The 3rd parameter is the number of
bytes to save. In the default setup, for the RAM area (0000-7FFF) this will
however be the same.

```basic
100 bsave "memory.space",$0800,$7800
```
