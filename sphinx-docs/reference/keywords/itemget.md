# itemget\$()

Takes three parameters: the string, the index of the substring required
(starting at 1), and the separator. A bad index will generate a range error.

```basic
100   print itemget$("paul,jane,lizzie,jack",3,",")
```
