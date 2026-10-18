# {kwd}`delete`

Permanently deletes one closed file on the selected {kwd}`drive`, using the
kernel's current directory and path rules. No confirmation prompt is shown.

```basic
100 delete "old-picture.dat"
```

Use {kwd}`try` to handle storage errors without stopping the program:

```basic
100 try delete "old-picture.dat" to ec
110 if ec<>0 then print "Could not delete file; error ";ec
```

`ec` is zero on success and a nonzero kernel error code on failure. A missing
file is a failure, not a successful no-op. FAT32 kernels currently report a
generic error for a failed deletion, so do not assume that a nonzero code means
the file was missing. Without `TRY`, generic failures raise `Storage error`; an
explicit kernel `NOT_FOUND` result raises `File not found`.

Only exact filenames are supported. Empty strings, wildcards (`*`, `?`), commas,
colons, control characters, and paths ending in `/`, `.` or `..` components are
rejected with `Out of Range`. In particular, comma-separated IEC scratch lists
are not allowed. Directories are not removed recursively; use a
directory-management tool for that. Read-only files are subject to the kernel
filesystem's protections.

`TRY` captures storage-operation failures, not syntax, type, or invalid-name
errors. The command waits for the kernel's completion event and does not load
the file contents. Error details depend on the drive and kernel driver.

This command uses the existing kernel `File.Delete` API and does not require the
FAT32 missing-file-open fix used by {kwd}`exists`.
