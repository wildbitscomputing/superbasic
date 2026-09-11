# {kwd}`screen()` {kwd}`screen$()`

Returns the character located at the given screen coordinates. {kwd}`screen()`
returns the ASCII code of the character, while {kwd}`screen$()` returns the
character itself as a string. The coordinates are given as `row`, `column`, and
use the same coordinate system as {kwd}`print at`:

```basic
100 print at 15, 10; "#"
110 print screen$(15, 10) ' prints "#"
120 print screen(15, 10)  ' prints 35
```

See {kwd}`print` for a detailed visual explanation of the screen coordinates.

Together, {kwd}`screen` and {kwd}`print at` let you treat the screen as a big
grid of characters, making them great tools for simple character-based game
mechanics such as placing and moving objects on a map and detecting collisions:

```basic
100 cls
110 print at 15, 30; "@"
120 input at 0, 0; "Guess a row (0-59): "; row
130 input at 0, 0; "Guess a column (0-79): "; col
140 if screen$(row, col) = "@"
150   print at row, col; "x"
160   print at 0, 0; "*** You hit the target! ***"
170 else
180   print at 0, 0; "=== Oh no, you missed! ==="
190 endif
```
