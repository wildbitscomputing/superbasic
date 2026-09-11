# {kwd}`cprint`

Behaves like {kwd}`print`, except that control-character values `$00`–`$1F` and
`$80`–`$FF` are displayed as their corresponding font symbols rather than being
interpreted as control characters. The example below prints a horizontal upper
bar character, not a newline.

```basic
100 cprint chr$(13)
```
