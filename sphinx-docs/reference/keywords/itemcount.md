# itemcount()

Together, `itemcount` and `itemget` provide a way of encoding multiple data
items in strings. A multiple-element string has a separating character, which
can be any ASCII character, often a comma. `itemcount()` takes a string and a
separator and returns the number of items.

```basic
100   print itemcount("hello,world",",")
```
