# {kwd}`if` ... {kwd}`else` ... {kwd}`endif`

The {kwd}`if` statement. Comes in two forms:

The first is the classic BASIC style: {kwd}`if` *\<condition>* {kwd}`then`
*\<statement>*. All code must be on a single line, and {kwd}`then` is mandatory:

```basic
100 if name$ = "Alice" then age = 7
110 if name$ = "Dinah" then goto 200
```

The second form, {kwd}`if` ... \[{kwd}`else` ...\] {kwd}`endif`, supports
multi-line conditional logic and includes an optional {kwd}`else` clause. The
{kwd}`endif` keyword is mandatory, even if no {kwd}`else` is used. This form can
also be written on a single line by separating each statement with colons:

```basic
100 if age < 18: print "child": else: print "adult": endif
110 if name$ = "Bob"
120   print "Hello, Bob!"
130 else
140   print "Hello, stranger!"
150 endif
```
