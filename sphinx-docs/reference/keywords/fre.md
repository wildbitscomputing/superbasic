# fre()

Returns information about free memory. The parameter selects which region:

- `fre(0)` — free program memory (banked pages)
- `fre(-1)` — free variable/string space
- `fre(-2)` — free array space

```basic
100   print fre(0)
110   print fre(-1)
120   print fre(-2)
```
