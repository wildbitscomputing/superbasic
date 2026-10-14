# {kwd}`sin()`

Returns the sine of a numeric angle in **radians**, as a floating-point value.

```basic
100 print sin(pi/2)
110 angle#=30*pi/180
120 print sin(angle#)
```

The results above are approximately 1 and 0.5. Angles may be negative or span
multiple revolutions. Results are approximate; use a tolerance when comparing
them. For very large angles, limited input and π precision reduce accuracy.

Sine and cosine share 65 quarter-wave anchor points with a cubic correction
between anchors. The main calculation uses fixed-point arithmetic internally;
small angles use a floating-point path to preserve very small nonzero results.
The BASIC interface still accepts numeric angles in radians and returns
floating-point results.

This built-in does not modify BASIC variables. Remove or rename existing
user-defined `FN SIN` functions when migrating programs to the built-in. Unlike
degree-based helpers, no degree conversion is needed for radian formulas.

See also {kwd}`cos()`, {kwd}`tan()`, and {kwd}`pi`.
