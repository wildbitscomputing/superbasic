# {kwd}`rnd()` {kwd}`random()`

Generates random numbers. this has two forms, which is still many fewer than
odo. {kwd}`rnd()` behaves like Microsoft BASIC, negative numbers set the seed, 0
repeats the last value, and positive numbers return a float 0 \<= n < 1.
{kwd}`random`{code}`(n)` returns a number from `0` to `n-1`.

```basic
100 print rnd(1),random(6)
```
