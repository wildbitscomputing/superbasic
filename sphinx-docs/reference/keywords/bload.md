# bload

Loads a file into memory. The 2nd parameter is the address in full memory space,
*not* the 6502 CPU address. In the default setup, for the RAM area
(`0000`–`7FFF`) this will however be the same.

```basic
100   bitmap on:bitmap clear 1
110   bload "mypic.bin",$10000
```
