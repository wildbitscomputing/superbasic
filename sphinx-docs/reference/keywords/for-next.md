# for next

A loop which repeats code a fixed number of times, which must be executed at
least once. The default step is 1 for `to` and −1 for `downto`; use `STEP` to
set a different increment. The variable name on `NEXT` is not supported.

```basic
100   for i = 1 to 10:print i:next
110   for i = 10 downto 1:print i:next
120   for i = 0 to 100 step 10:print i:next
```
