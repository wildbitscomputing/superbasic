# `@` (at sign)

The address operator. Returns the memory address of an expression that has a
fixed location in memory—typically a variable or an array element. This address
can be assigned to another variable and used later to access or modify the
original value.

For example, `@fred` gives the address where the variable `fred` is stored. You
can store that address in another variable—often called a pointer—and later use
it with one of the indirection operators (`?`, `!`) or with {kwd}`poke` to read
or change the contents of `fred`.

```basic
100 print @fred, @a(4)
110 fred = 17
120 ptr = @fred
130 ?ptr = 42
140 print fred
```
