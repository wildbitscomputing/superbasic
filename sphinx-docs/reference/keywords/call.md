# call

Calls an assembly subroutine at the specified address. You may provide up to
three arguments, which will be loaded into the A, X, and Y registers
respectively. The address can be specified in decimal or hex.

```basic
100   call $4000
110   call $4000,65,0,0
```
