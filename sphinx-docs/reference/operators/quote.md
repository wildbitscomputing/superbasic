# `"` (quote)

Delimits a string literal. A string must begin and end with a quote on the same
line. To construct a string that spans multiple lines, use string concatenation
with the newline character ({kwd}`chr$`{code}`(13)`). To include an actual quote
character inside the string, use two consecutive quotes (`""`).

```basic
100 print "Hello, world!"                     ' Hello, world!
110 print "She said ""hi"" and walked away."  ' She said "hi" and walked away.
120 greeting$ = "Hi, Bob!" + chr$(13) + "How are you today?"
130 print greeting$
```
