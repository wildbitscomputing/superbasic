# `!` (exclamation mark)

A 16-bit indirection operator. Reads or writes a 16-bit word at a specific
address or offset, similar to {kwd}`peekw` and {kwd}`pokew`. It has two forms:

- Unary: `!47` reads the 16-bit word stored at address 47 (i.e., it reads the
  byte at 47 and the next byte at 48 as a single word).

- Binary: `a!4` reads the word at address `a + 4`, making it easy to index into
  structured data like tables or arrays.

When used on the left-hand side of an assignment, it behaves like {kwd}`pokew`,
writing a 16-bit value to memory in little-endian order (low byte first, then
high).

```basic
100 !a = 42
110 print !a
120 print a!b
130 a!b=12
```
