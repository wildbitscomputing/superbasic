# isval()

This is a support for `val()` and takes the same parameter (a string). This
deals with the problem that `val()` errors if you give it a non-numeric value.
This checks to see if the string is a valid number and returns −1 if so, 0 if it
is not.

```basic
100   print isval("42")
110   print isval("i like chips in gravy")
```
