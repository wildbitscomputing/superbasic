# {kwd}`alloc()`

Allocates the specified number of bytes in memory and returns the starting
address of the allocated block. Useful for efficient byte-level storage, custom
data structures, or program memory for assembly instructions.

The following example uses {kwd}`alloc()` to build a table of printable ASCII
characters from 32 to 127:

```basic
100 char_start = 32: char_end = 127     ' define ASCII range
110 buffer_size = char_end - char_start
120 buffer = alloc(buffer_size)         ' allocate memory buffer
130 ' fill buffer with ASCII codes from start to end
140 for n = 0 to buffer_size - 1
150   poke buffer + n, char_start + n
160 next
170 ' print characters stored in buffer
180 for n = 0 to buffer_size - 1
190   print chr$(peek(buffer + n));
200 next
```

Note: {kwd}`alloc()` uses a bump allocator. There is no corresponding
deallocation function — allocated memory is only freed when the program is
cleared ({kwd}`new` or {kwd}`run`).

```basic
10    myAssemblerCode = alloc(128)
```
