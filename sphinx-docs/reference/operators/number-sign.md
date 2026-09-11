# `#` (number sign)

Identifier suffix designating a floating-point variable. Floating-point values
are stored as a 32-bit signed mantissa and an 8-bit exponent, and can represent
numbers approximately between -3.4E+38 and +3.4E+38, with around 9 decimal
digits of precision. The type suffix is considered part of the variable's name;
for example, `age` and `age#` are treated as two distinct variables (integer and
floating-point, respectively). See Chapter {ref}`chap:variables` for an in-depth
exploration of variable types.

```basic
100 an_integer = 42
110 a_float# = 3.14159
120 print an_integer, a_float
```

Variables are not stored internally by name but by reference. This means they
are quick to access but means they are always in existence from the start of a
program if used in it. Integers are 32-bit signed; floats have a 32-bit signed
mantissa and 8-bit exponent, giving approximately 9 decimal digits of precision.
