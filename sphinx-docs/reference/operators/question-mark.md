# `?` (question mark)

An 8-bit indirection operator. Reads or writes a single byte at a specific
address or offset, similar to {kwd}`peek` and {kwd}`poke`. It works like `!`,
but operates at the byte level instead of 16-bit words.

```basic
100 a = 17        ' a is a 32-bit integer
110 ptr = @a      ' ptr holds the address of a
120 print ?ptr    ' prints 17 (least significant byte of a)
130 ptr?0 = 255   ' modify a's least significant byte
140 print a       ' prints 255
```
