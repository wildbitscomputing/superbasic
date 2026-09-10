# bitmap

Turns the bitmap on or off, or clears it, or sets its address (the default
address is `$10000`). Only one bitmap is used in BASIC, but you can use others
by accessing I/O. Keywords are `ON`, `OFF`, `CLEAR <colour>`, `AT <address>` and
can be chained. On or Off without an `AT` will reset the address.

```basic
100   bitmap at $18000 on clear $03
110   bitmap at $18000 on:bitmap clear $03
```
