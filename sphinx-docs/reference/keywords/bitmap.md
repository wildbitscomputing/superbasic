# {kwd}`bitmap`

Turns the bitmap layer on or off, clears it, or sets its memory address
(`$10000` by default). Only one bitmap layer is supported. Modifier keywords
include {kwd}`on`, {kwd}`off`, {kwd}`clear` *\<color>*, and {kwd}`at`
*\<address>*, and may be chained as shown in the example below. Using {kwd}`on`
or {kwd}`off` without {kwd}`at` will reset the bitmap address to its default.
See Chapter {ref}`chap:graphics` for more details.

```basic
100 bitmap at $18000 on clear $03
110 bitmap at $18000 on: bitmap clear $03
```
