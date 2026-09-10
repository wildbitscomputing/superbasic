# print

Prints to the current output device, either strings or numbers (which are
preceded by a space). `print` with `,` goes to the next tab stop. A return is
printed unless the command ends in `;` or `,`.

The `at row, column` modifier positions the cursor before printing (zero-based,
top-left is 0,0).

```basic
100   print 42,"hello"
110   print at 10,5;"positioned text"
```
