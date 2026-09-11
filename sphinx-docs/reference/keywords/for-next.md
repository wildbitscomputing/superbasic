# {kwd}`for` {kwd}`next`

A loop that repeats code a fixed number of times. The loop body will be executed
at least once. The default step is 1 for {kwd}`to` and -1 for {kwd}`downto`.

```basic
100 for i = 1 to 10: print i: next
110 for i = 10 downto 1: print i: next
120 for i = 1 to 100 step 10: print i: next
```

The variable name on `NEXT` is not supported.
