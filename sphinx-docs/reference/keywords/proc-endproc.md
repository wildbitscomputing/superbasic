# {kwd}`proc` {kwd}`endproc`

Simple procedures. These should be used rather than {kwd}`gosub`. The empty
parentheses are mandatory even if there aren't any parameters. Definitions are
skipped during normal execution, so they can appear anywhere in your program.

```basic
100 printmessage("hello", 42)
110 end
120 proc printmessage(msg$,n)
130   print msg$ + "world  x " + str$(n)
140 endproc
```
