# {kwd}`cursor`

Turns the text cursor on or off. Turning the cursor off reduces flicker when
printing a large amount of text.

```basic
100 cursor off
110 for i=0 to 1000: print "hello": next
120 cursor on
```
