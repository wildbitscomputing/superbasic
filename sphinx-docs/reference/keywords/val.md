# {kwd}`val()`

Converts a string to a number. There must be some number there, e.g. `"-42xxx"`
works and returns −42 but `"xxx"` returns an error. To make it usable, use
{kwd}`isval()` which checks validity first.

```basic
100   print val("42")
110   print val("413.22")
```
