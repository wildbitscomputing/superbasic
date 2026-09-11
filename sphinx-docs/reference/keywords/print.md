# {kwd}`print`

Displays text or numbers on the screen at the current cursor position. You can
print strings, numbers, variables, or results of calculations, and you can mix
them together in the same statement.

```basic
100 print "2 + 2 = " 4
110 print "Hmm,"; (17 - 10) * 6; " sounds familiar..."
120 input "What's your name?", $name
130 print "Hello, "; $name; "!"
```

Items separated by a space or a semicolon (`;`) are printed directly after one
another, while a comma (`,`) places the next item at the next tab position.

Normally, {kwd}`print` finishes by moving the cursor to a new line, but if it
ends with a semicolon (`;`) or comma (`,`), the next {kwd}`print` will continue
on the same line.

```basic
100 print "Goodbye, ";
110 print "feet!"
```

## {kwd}`at` modifier

You can use the {kwd}`at` modifier to position the cursor and the following
{kwd}`print` output at specific screen coordinates. SuperBASIC's default text
mode fits 80 characters across and 60 lines down. The {kwd}`at` coordinates are
zero-based and given as `row`, `column`:

```basic
100 cls
110 ' print at row 4, column 9
120 print at 4, 9; "HELLO"
```

```{image} /_static/print-at.*
---
alt: 80 columns, 60 rows; HELLO at row 4, column 9.
---
```

The following program places an asterisk in each corner of the screen, then
moves the cursor back to the top-left corner:

```basic
100 cls
110 print at 0, 0; "*";
120 print at 0, 79; "*";
130 print at 59, 0; "*";
140 print at 59, 79; "*";
150 print at 0, 0;
```

Note that when control returns to SuperBASIC, the system will place its input
prompt where the cursor was last positioned. If you delete line 150 and run the
program again, because line 140 positions the cursor on the very last character
of the screen, the system will have to scroll the output to make room for the
prompt, erasing the asterisks at the top.

The {kwd}`at` modifier doesn't have to appear immediately after {kwd}`print`,
may be used multiple times in the same statement, and can be freely mixed with
other arguments:

```basic
100 cls
110 print "Hello"; at 2,4 "from"; at 4,8 "Canada"
```

For the reverse of {kwd}`print at`, that is, *reading* the character at a
specific screen position, see {kwd}`screen$()`.
