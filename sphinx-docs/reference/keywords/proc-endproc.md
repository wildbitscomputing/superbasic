# proc endproc

Named procedures. These should be used rather than `GOSUB`. Or else. The empty
brackets are mandatory even if there aren't any parameters. Definitions are
skipped during normal execution, so they can appear anywhere in your program.

```basic
100   proc printmessage(msg$,n)
110     print msg$+"world  x "+str$(n)
120   endproc
130   printmessage("hello",42)
```
