# {kwd}`exists`

Checks whether a file can be opened for reading, without reading its contents or
writing to it. Returns `true` (-1) when the file opens successfully and `false`
(0) when the kernel explicitly reports that it was not found.

```basic
100 name$="picture.dat"
110 if exists(name$)
120   print "File already exists. Choose another name or confirm overwrite."
130 else
140   print "File not found."
150 endif
```

Uses the selected {kwd}`drive` and the kernel's current directory and path
rules. Supply a nonempty, exact filename; `*` and `?` wildcards are rejected
with `Out of Range`. This is a file probe, not a directory-existence test. The
file is closed before the function returns. No load address or scratch space for
file data is required.

An ambiguous failure raises `Storage error`, **not** `false`. In particular,
Detecting missing files on SD cards requires a kernel whose FAT32 driver
distinguishes `NOT_FOUND` from `ERROR`. Older kernels may raise `Storage error`
for missing files. Read errors, unavailable drives, and resource failures must
not be treated as permission to overwrite a file. `TRY` does not catch errors
from this function; it currently only supports `BLOAD` and `BSAVE`.

Checking and saving are separate operations: this is not an atomic
create-if-absent guarantee. It does not change `SAVE` or `BSAVE` behavior.

`EXISTS(` is now reserved syntax; rename any existing function of that name.
