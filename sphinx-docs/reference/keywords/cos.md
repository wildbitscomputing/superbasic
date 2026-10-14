# {kwd}`cos()`

Returns the cosine of a numeric angle in **radians**, as a floating-point value.

```basic
100 print cos(0)
110 print cos(pi)
```

The results above are approximately 1 and -1. Results and angle reduction have
the same precision limitations as {kwd}`sin()`.

Remove or rename existing user-defined `FN COS` functions when migrating to the
built-in. This function does not modify BASIC variables.

See also {kwd}`sin()`, {kwd}`tan()`, and {kwd}`pi`.
