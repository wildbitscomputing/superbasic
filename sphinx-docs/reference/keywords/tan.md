# {kwd}`tan()`

Returns the tangent of a numeric angle in **radians**, as a floating-point
value.

```basic
100 print tan(pi/4)
```

The result above is approximately 1. Tangent is calculated as sine divided by
cosine, sharing the angle reduction and anchor tables. It is undefined at odd
multiples of π/2: a computed zero cosine raises `Division by zero`, while
rounding near a pole can instead produce a very large, inaccurate result. Avoid
evaluating at or very close to these poles.

Results and angle reduction have the same precision limitations as {kwd}`sin()`.
This function does not modify BASIC variables. Remove or rename existing
user-defined `FN TAN` functions when migrating to the built-in.

See also {kwd}`sin()`, {kwd}`cos()`, and {kwd}`pi`.
