# {kwd}`inkey()` {kwd}`inkey$()`

Returns the most recent key press, if any. {kwd}`inkey()` returns the ASCII code
of the key, while {kwd}`inkey$()` returns the character as a string. If no key
has been pressed, they return `0` and `""` respectively.

These functions check for past key presses—they do not detect whether a key is
currently being held down. To check the current state of a key (up or down), use
{kwd}`keydown()` instead.

```basic
100 print inkey(), inkey$()
```
