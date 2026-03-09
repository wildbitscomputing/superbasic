# Structured Programming

SuperBASIC is built to help you write programs that are easy to read and easy to change later. If you’ve
used BASIC on another computer, you might be used to steering your program with commands like
`goto`, `gosub`, and `return`. These work fine in small programs, but once your code grows, they can
make things messy and hard to follow.

SuperBASIC still lets you use those commands if you want, but it also offers tools you’ll probably prefer
as your programs get bigger. With loops, procedures, and multi-step conditionals, your code can flow
more naturally—making it simpler to read, easier to fix, and more fun to work with.

## Named Procedures

A _named procedure_ is simply a block of code that has a name. Once you’ve defined a procedure, you can
run it—also called _calling it_—anywhere in your program just by using its name. This often makes your
code easier to follow (assuming you choose clear, descriptive names), and saves you from writing the
same steps over and over again.

A procedure is defined using the `proc` keyword, followed by the procedure’s name and a pair of
parentheses, followed by the code to be executed when the procedure is called. The definition is closed
with the `endproc` keyword:

```basic
200 proc greet()
210   print "Hello!"
220   print "How are you?"
230 endproc
```

The code inside a procedure—in this case, lines 210–220—is called the _body_ of the procedure. This is
the part that actually runs when the procedure is called. Note that the body does not execute until you
explicitly call the procedure.

In SuperBASIC, procedures must be defined at the end of your program, after the `end` keyword, but
you can call a procedure from anywhere in your code—including from within other procedures.

A procedure is called by writing its name followed by parentheses:

```basic
100 greet()                              ' prints "Hello!" and "How are you?"
110 print "Bye-bye!"                     ' prints "Bye−bye!"
120 end                                  ' end of program
200 proc greet()
210   print "Hello!"
220   print "How are you?"
230 endproc
```

Here, lines 200–230 define the procedure, and line 100 calls it. When the program encounters the
`greet()` call in line 100, it jumps to the first line of the procedure’s body (line 210, `print "Hello!"`),
executes the entire body, and then returns to line 110 to continue with the rest of the program.

## Procedures with parameters

Procedures become even more useful when they can accept _parameters_. A parameter is simply a
placeholder for a value that we’ll pass to the procedure when we call it.

Let’s tweak our `greet` procedure to greet someone by name:

```basic
100 greet("Alice")                       ' prints "Hello, Alice!"
110 greet("Bob")                         ' prints "Hello, Bob!"
120 print "Bye-bye!"                     ' prints "Bye−bye!"
130 end                                  ' end of program
200 proc greet(name$)
210   print "Hello, " + name$ + "!"
220 endproc
```

Here, we’ve added a parameter called `$name`, indicating that the procedure expects to receive a
string value that is a person’s name. 


When the procedure is called on line 100 with the argument `"Alice"` , `name$` is assigned that value,
and line 210 prints `Hello, Alice!` . When control returns to line 110 and the procedure is called with
`"Bob"` , `name$` becomes `"Bob"` , and line 210 prints `Hello, Bob!`.

## Multiple parameters

To define a procedure that takes more than one parameter, simply separate the parameter names with
commas, and do the same when providing arguments in the procedure call:

```basic
100    greet("Alice", "morning")            ' prints "Good morning, Alice! "
110    greet("Charlie", "evening")          ' prints "Good evening, Charlie! "
120    print "Bye-bye!"                     ' prints "Bye−bye!"
130    end                                  ' end of program
200    proc greet(name$, time_of_day$)
210        print"Good "; time_of_day$; ", "; name$; "!"
220    endproc
```

A procedure can accept up to 13 parameters.

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

You can also use `STEP` to control the increment:

```basic
100 for i = 0 to 100 step 10
110   print i
120 next
```

Some BASICs require the index variable in `NEXT` (e.g. `next i`) and have peculiar behaviours if you change the order; this is not supported.

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
