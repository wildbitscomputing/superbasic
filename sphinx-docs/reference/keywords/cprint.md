# cprint

Operates the same as the `print` command, but control characters (e.g.
`00`–`1F`, `80`–`FF`) are printed using the characters from the FONT memory, not
as control characters. The example below prints a horizontal upper bar
character, not a new line.

```basic
100   cprint chr$(13);
```
