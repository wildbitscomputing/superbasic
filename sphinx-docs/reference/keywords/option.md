# {kwd}`option`

Option is used for general control functions which are not common enough to
justify their own keyword.

Option 0-7 set highlighting colours for comment foreground, comment background,
line number, token, constant, identifier, punctuation, data respectively, the
lower 4 bits setting the colour. Setting the upper bit 7 will disable the
background change.

The example below sets the listing to all white.

```basic
100 for i = 0 to 7:option i,128+15:next
```
