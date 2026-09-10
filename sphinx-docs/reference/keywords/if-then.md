# if then and if else endif

`IF` has two forms. The first is classic BASIC:
`if <condition> then <do something>`. All the code is on one line. The `THEN` is
mandatory.

```basic
100   if name="benny" then my_iq = 70
```

The second form allows multi-line conditional execution, with an optional `else`
clause. Note the `endif` is mandatory; you cannot use a single line
`if then else`:

```basic
100   if age < 18:print "child":else:print "adult":endif
```
