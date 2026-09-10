# alloc()

Allocate the given number of bytes of memory and return the address. Can be used
for data structures or program memory for the assembler.

Note: `alloc()` uses a bump allocator. There is no corresponding deallocation
function — allocated memory is only freed when the program is cleared (`NEW` or
`RUN`).

```basic
10    myAssemblerCode = alloc(128)
```
