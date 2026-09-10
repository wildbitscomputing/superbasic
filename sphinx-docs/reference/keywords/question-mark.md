# ?

`?` is an indirection operator that does a similar job to `PEEK` and `POKE`,
i.e. accesses memory. It is the same as `!` except it operates on a byte level.

```basic
100   ?a = 42
110   print ?a
120   print a?b
130   a?b=12
```
