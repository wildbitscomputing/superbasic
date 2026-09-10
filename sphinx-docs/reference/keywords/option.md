# option

`option` is used for general control functions which are not common enough to
justify their own keyword. Option 0–7 set highlighting colours for Comment
Foreground, Comment Background, Line Number, Token, Constant, Identifier,
Punctuation, Data respectively. The lower 4 bits set the colour; setting bit 7
will disable the background change.

```basic
100   for i = 0 to 7:option i,128+15:next
```
