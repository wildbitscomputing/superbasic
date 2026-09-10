# inkey() and inkey\$()

If a character key has been pressed, return either the character as a string, or
as the ASCII character code. If no key is available return `""` or `0`. This
uses key presses — if you want to check whether a key is up or down, use
`keydown()`.

```basic
100   print inkey(),inkey$()
```
