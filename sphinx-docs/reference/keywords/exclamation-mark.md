# !

`!` is an indirection operator that does a similar job to `DEEK` and `DOKE`,
i.e. accesses memory. It can be used either in unary fashion (`!47` reads the
word at location 47) or binary (`a!4` reads the word at the value in address
`a+4`). It can also appear on the left-hand side of an assignment statement when
it functions as a `DOKE`, writing a 16-bit value in low/high order. It reads or
writes a 16-bit address in the 6502 memory map.

```basic
10    !a = 42
20    print !a
30    print a!b
40    a!b=12
```
