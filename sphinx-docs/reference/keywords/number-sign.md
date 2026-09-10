# # and \$

`#` and `$` are used to type variables. `#` is a floating point value, `$` is a
string. The default type is integer. Variables are not stored internally by name
but by reference. This means they are quick to access but means they are always
in existence from the start of a program if used in it. Integers are 32-bit
signed; floats have a 32-bit signed mantissa and 8-bit exponent, giving
approximately 9 decimal digits of precision.

```basic
100   an_integer  = 42
110   a_float#  = 3.14159
120   a_string$ = "hello world"
```
