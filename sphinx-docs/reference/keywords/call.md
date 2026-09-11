# {kwd}`call`

Calls an assembly subroutine at the specified address. Optionally, you may
provide up to three arguments, which will be loaded into the A, X, and Y
registers, respectively.

```basic
100 call $4000
110 call $5000, $ff, $f0
```
