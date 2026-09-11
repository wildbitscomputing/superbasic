# {kwd}`fn` {kwd}`endfn`

Define a user function. Single-line functions use `= expr`; multi-line functions
use `endfn` to close the body. Use `return expr` inside a multi-line function to
return a value explicitly; a bare `endfn` returns zero.

```basic
100   print square(5)
110   print absval(-3)
120   end
200   fn square(x) = x * x
210   fn absval(x)
220     if x < 0
230       return -x
240     else
250       return x
260     endif
270   endfn
```
