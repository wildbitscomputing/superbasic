# `<` (less than), `<=` (less equal), `=` (equal), `<>` (not equal), `>` (greater than), `>=` (greater equal)

Numeric and string comparison. Each operator returns 0 if the condition is
{kwd}`false` and -1 if {kwd}`true`. Comparing a number to a string produces a
type error. Use {kwd}`str$` and {kwd}`val` for type conversion.

```basic
100 input "Enter your answer:", a
110 if a <> 42: print "Incorrect": else: print "Correct!": endif
120 if name$ = "" then input "Enter your name:", name$
130 print "Hello, "; name$
```
