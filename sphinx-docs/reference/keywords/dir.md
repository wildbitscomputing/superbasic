# {kwd}`dir`

Lists directory entries on the current drive, optionally at a specified path.

```basic
dir
dir "/games"
```

Entries are displayed as they are read, in filesystem order. The listing does
not need to fit in the directory snapshot buffer. Hidden entries are omitted.

Hold Shift to pause the listing and release it to resume. Press Ctrl+C to stop,
including while paused. The directory stream is closed before returning to
BASIC.

The optional comma-separated sort argument is no longer supported.

Use `dir load` to save a directory snapshot for access from a BASIC program
without displaying it:

```basic
10 dir load "/games"
20 print dir(-1)
30 print dir$(0)
```

After a successful load, `dir(-1)` gives the entry count, `dir$(n)` gives the
name of entry `n` (starting at zero), and `dir(n)` gives its size in blocks.
`dir(-2)` gives the free block count. A normal `dir` listing does not replace
this snapshot.

The snapshot holds at most 127 entries and shares a fixed buffer for their
names. If either limit is exceeded, `dir load` reports `Directory buffer full`
and clears the snapshot count; `dir(-1)` then returns zero. Use a normal `dir`
to display larger directories.
