# return

Outside a function, returns from a `GOSUB` call. Inside a multi-line function
body (`fn` ... `endfn`), `return expr` evaluates the expression and returns its
value; a bare `return` returns zero.

```basic
100   return
110   return x * 2
```
