# Structured Programming

SuperBASIC is designed for better and more readable programs. If you learnt BASIC on another machine, you will mostly have used `GOTO`, `GOSUB` and `RETURN`.

These are terrible.

SuperBASIC does support these, but it is strongly advised you do not use them. However, they can be useful for running old code. SuperBASIC is not Microsoft BASIC compatible, but is close enough so that code will normally work with minor alterations.

## Named Procedures

The language supports named procedures, which are full identifiers. This means that instead of writing `GOSUB 300`, you can have a procedure called `addscore` or `moveinvaders` or whatever you like; they can be meaningful and this enhances program readability.

```basic
100 printmessage("hello",42)
110 end
120 proc printmessage(msg$,n)
130   print msg$+"world  x "+str$(n)
140 endproc
```

This is a simple piece of code showing a procedure call `printmessage` which prints a silly message. It has two parameters: the message (in `msg$`) and a number (in `n`).

These are considered "local" to the procedure, so if you have either of them "outside" the procedure the values are not affected:

```basic
90  n = 12
100 printmessage("hello",42)
105 print n
110 end
120 proc printmessage(msg$,n)
130   print msg$+"world  x "+str$(n)
140 endproc
```

This will print the message ("Hello world x 42") and after it, will print the value of `n`, which will still be 12. `n` will only be 42 inside `printmessage`.

If you have no parameters then the brackets must still be used:

```basic
100 endgame()
110 end
120 proc endgame()
130   print "You lose !"
140 endproc
```

## While and Repeat

While and Repeat are a structured way of doing something repeatedly, until a 'test' becomes either true or false:

```basic
100 lives = 3
110 while lives > 0
120   playgame()
130 wend
```

You could do this with a repeat loop:

```basic
100 lives = 3
110 repeat
120   playgame()
130 until lives = 0
```

The difference between while and repeat loops is that the repeat loop is always done once — if the initial test on while fails, the repeated part will never be done at all.

## For Loops

For loops are another way of repeating code, and are found in most BASICs. This time, you know how many times the code is to be repeated:

```basic
100 for i = 1 to 10
110   print "Hello world"
120 next
```

Each time you go round the loop, `i` has a different value:

```basic
100 for i = 1 to 10
110   print i
120 next
```

It is also possible to count backwards using `downto`:

```basic
100 for i = 10 downto 1
110   print i
120 next
```

There are two variations from common BASIC. Firstly there is currently no `STEP`; you can only count either up by 1, or down by 1. Secondly, some BASICs require the index in `next` (e.g. `next i`) and have peculiar behaviours if you change the order, which are not supported, nor should they be.

## If ... Else ... Endif

If is a conditional test, allowing code to be run if some test is satisfied:

```basic
100 if count = 0 then explode
110 if name$ = "Paul Robson" then print "You are very clever and modest."
```

(There is an instruction `explode`.)

This is standard BASIC — if the test 'passes' the code following the `then` is executed.

However, there is an alternate form, more in tune with modern programming: `if ... else ... endif`:

```basic
100 for n = 1 to 10
110   if n % 2 = 0
120     print n;" is even"
130   else
140     print n;" is odd"
150   endif
160 next
```

The `else` part is not mandatory. Note the `endif` is mandatory in the block form. You cannot mix the `then` form with `else`/`endif`:

```basic
' This does NOT work:
100 if a = 2 then print "A is two" else print "A is not two"
```

Once you have a `then` you are locked into the simple form; no `else` or `endif`.

Generally when programming you use the `then` short version for simple tests, and the `if..else..endif` for more complicated ones.

### WHILE loop (test at top)

```{mermaid}
flowchart LR
    WHILE["WHILE condition"] --> TEST{"true?"}
    TEST -->|yes| BODY["Loop body"] --> WHILE
    TEST -->|no| WEND["WEND"]

    style WHILE fill:#e65100,color:#fff,stroke:#bf360c
    style TEST fill:#f57f17,color:#fff,stroke:#e65100
```

### REPEAT loop (test at bottom)

```{mermaid}
flowchart LR
    REPEAT["REPEAT"] --> BODY["Loop body"] --> TEST{"UNTIL condition"}
    TEST -->|false| REPEAT
    TEST -->|true| DONE["Done"]

    style REPEAT fill:#e65100,color:#fff,stroke:#bf360c
    style TEST fill:#f57f17,color:#fff,stroke:#e65100
```

### FOR loop

```{mermaid}
flowchart LR
    FOR["FOR i = start TO end"] --> BODY["Loop body"]
    BODY --> NEXT["NEXT"]
    NEXT --> CHECK{"i past end?"}
    CHECK -->|no| BODY
    CHECK -->|yes| DONE["Done"]

    style FOR fill:#e65100,color:#fff,stroke:#bf360c
    style CHECK fill:#f57f17,color:#fff,stroke:#e65100
```

### Procedure call

```{mermaid}
flowchart LR
    CALL["myfunc(args)"] --> PROC["PROC myfunc(params)"]
    PROC --> BODY["Procedure body<br/>(params are local)"]
    BODY --> ENDP["ENDPROC"]
    ENDP --> RET["Return to caller"]

    style CALL fill:#2e7d32,color:#fff,stroke:#1b5e20
    style ENDP fill:#2e7d32,color:#fff,stroke:#1b5e20
```
