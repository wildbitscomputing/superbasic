# `+` (plus sign)

Integer or floating-point addition, or string concatenation. If either of the
numeric operands is floating-point, the result is floating-point. Adding a
number to a string produces a type error. See {kwd}`str$` for an easy way to
convert a number to a string.

```basic
100 sum = 4 + 2                 ' sum = 6
120 total# = 17.5 + 42.5        ' total# = 60.00000
130 prompt$ = "Hello " + "Bob"  ' prompt$ = "Hello Bob"
140 print sum, total#, prompt$
```
