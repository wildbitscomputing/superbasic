# `<<` (left shift)

Bit-shift operators. Shift an integer left (`<<`) or right (`>>`) by a given
number of bits. Both operands must be integers, and the result is always an
integer. Often used as a fast alternative to multiplying or dividing by powers
of two.

```basic
100 n = 42
110 print n << 2  ' prints 168 (42 * 4)
120 print n >> 1  ' prints 21 (42 \ 2)
```
