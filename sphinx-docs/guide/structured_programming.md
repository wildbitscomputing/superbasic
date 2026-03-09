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

```{mermaid}
flowchart LR
    CALL["myfunc(args)"] --> PROC["PROC myfunc(params)"]
    PROC --> BODY["Procedure body<br/>(params are local)"]
    BODY --> ENDP["ENDPROC"]
    ENDP --> RET["Return to caller"]

    style CALL fill:#2e7d32,color:#fff,stroke:#1b5e20
    style ENDP fill:#2e7d32,color:#fff,stroke:#1b5e20
```

A procedure is defined using the `proc` keyword, followed by the procedure’s name and a pair of
parentheses, followed by the code to be executed when the procedure is called. The definition is closed
with the `endproc` keyword:

```basic
200   proc greet()
210     print "Hello!"
220     print "How are you?"
230   endproc
```

The code inside a procedure—in this case, lines 210–220—is called the _body_ of the procedure. This is
the part that actually runs when the procedure is called. Note that the body does not execute until you
explicitly call the procedure.

In SuperBASIC, procedures must be defined at the end of your program, after the `end` keyword, but
you can call a procedure from anywhere in your code—including from within other procedures.

A procedure is called by writing its name followed by parentheses:

```basic
100   greet()                              ' prints "Hello!" and "How are you?"
110   print "Bye-bye!"                     ' prints "Bye−bye!"
120   end                                  ' end of program
200   proc greet()
210     print "Hello!"
220     print "How are you?"
230   endproc
```

Here, lines 200–230 define the procedure, and line 100 calls it. When the program encounters the
`greet()` call in line 100, it jumps to the first line of the procedure’s body (line 210, `print "Hello!"`),
executes the entire body, and then returns to line 110 to continue with the rest of the program.

### Procedures with parameters

Procedures become even more useful when they can accept _parameters_. A parameter is simply a
placeholder for a value that we’ll pass to the procedure when we call it.

Let’s tweak our `greet` procedure to greet someone by name:

```basic
100   greet("Alice")                       ' prints "Hello, Alice!"
110   greet("Bob")                         ' prints "Hello, Bob!"
120   print "Bye-bye!"                     ' prints "Bye−bye!"
130   end                                  ' end of program
200   proc greet(name$)
210     print "Hello, " + name$ + "!"
220   endproc
```

Here, we’ve added a parameter called `$name`, indicating that the procedure expects to receive a
string value that is a person’s name. 


When the procedure is called on line 100 with the argument `"Alice"` , `name$` is assigned that value,
and line 210 prints `Hello, Alice!` . When control returns to line 110 and the procedure is called with
`"Bob"` , `name$` becomes `"Bob"` , and line 210 prints `Hello, Bob!`.

### Multiple parameters

To define a procedure that takes more than one parameter, simply separate the parameter names with
commas, and do the same when providing arguments in the procedure call:

```basic
100   greet("Alice", "morning")            ' prints "Good morning, Alice! "
110   greet("Charlie", "evening")          ' prints "Good evening, Charlie! "
120   print "Bye-bye!"                     ' prints "Bye−bye!"
130   end                                  ' end of program
200   proc greet(name$, time_of_day$)
210     print"Good "; time_of_day$; ", "; name$; "!"
220   endproc
```

A procedure can accept up to 13 parameters.

```{admonition} Summary
:class: seealso
- A named procedure is a snippet of code that has a name.
- When you call a procedure, you give it values (called arguments), which get assigned to the parameters. A parameter is like a local variable that lives inside a procedure.
- A procedure can have no parameters, one parameter, or as many as you need.
- Procedures make your code more flexible—you can reuse the same procedure for lots of
different inputs.
```

## `for` loops

A `for` loop repeats a block of code a fixed number of times. When you know in advance how many
times you want something to run, a `for` loop is usually the clearest and most concise option.
The loop definition starts with the `for` keyword, followed by a loop variable, an equals sign, and a
range of values to count over:

```basic
100   for i = 1 to 10
110     print "Hello, World!"
120   next
```

The loop is closed with the `next` keyword. The code inside the loop—in this case, line 110—is called
the _body_ of the loop. The body executes once for each value in the loop variable’s range. In the example
above, the loop runs ten times, with `i` taking on the values 1 through 10, so the program prints `"Hello,
World!"` ten times.
Because the loop variable changes each time, you can use it inside the body to produce different results
on each pass. For example, this program prints the numbers 1 through 10:

```basic
100   for i = 1 to 10
110     print i
120   next
```

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


### Nested loops

A loop can contain another loop inside its body. This is called a _nested loop_. Nested loops are especially
useful when you need to repeat an action across two or more dimensions—for example, filling rows
and columns of a table.

For instance, to display a multiplication table, you could write:

```basic
10   cls                                 ' clear the screen
20   for i=1 to 9                        ' outer loop, cycle through rows 1 to 9
30     for j=1 to 9                      ' inner loop, cycle through columns 1 to 9
40       print i;"x";j;"=";i*j,          ' print one multiplication fact (i x j)
50     next                              ' go to the next column
60     print                             ' move the cursor to the next line
70     print                             ' insert a blank line for spacing
80   next                                ' go to the next row
```

As indicated by indentation, lines 30–70 form the body of the _outer loop_, while line 40 is the body of the
_inner loop_.
Let’s break down how this program executes, step by step:

- When the program first enters the outer loop (`i=1`), the inner loop in lines 30-50 runs through all
values of `j` from 1 to 9, printing the results of `1 × j`.
- After the inner loop finishes, execution returns to the outer loop’s body. Lines 60 and 70 add row
spacing, and then the `next` statement in line 80 increases `i` by one, and the process repeats
with `i=2`.
- This continues until the outer loop has cycled through all its values, producing the full table.

Notice that the inner loop restarts for each new row, allowing the program to cover every combination
of two ranges of values, creating 81 multiplication facts in total:

```text
1x1=1   1x2=2   1x3=3   1x4=4   1x5=5   1x6=6   1x7=7   1x8=8   1x9=9
2x1=2   2x2=4   2x3=6   2x4=8   2x5=10  2x6=12  2x7=14  2x8=16  2x9=18
3x1=3   3x2=6   3x3=9   3x4=12  3x5=15  3x6=18  3x7=21  3x8=24  3x9=27
...
9x1=9   9x2=18  9x3=27  9x4=36  9x5=45  9x6=54  9x7=63  9x8=72  9x9=81
```

Nested loops aren’t limited to two levels—you can nest three or more if the problem naturally has more
dimensions. Be aware, though, that readability drops quickly as nesting grows. In such cases, it is often
clearer to move the inner logic into a _named procedure_. This allows the outer loop to function as a
high-level outline, while the steps of the inner loops are contained in a separate, well-labeled block of
code.

For example, our multiplication-table program can be rewritten to move the inner loop into its own
procedure:

```basic
10     cls                               ' clear the screen
20     for i=1 to 9                      ' loop through rows 1 to 9
30       print_row(i)                    ' print multiplication facts for the row
40       print                           ' insert a blank line for spacing
50     next                              ' go to the next row
60     end
100    proc print_row(i)                 ' print one row of the table
110      for j=1 to 9                    ' loop through columns 1 to 9
120        print i;"x";j;"=";i*j,        ' print the multiplication fact
130      next                            ' go to the next column
140      print                           ' move the cursor to the next line
150    endproc
```

This version produces the same results as before, but the outer loop now reads like a high-level outline:
“for each row, print the row, then add spacing.” Meanwhile, the detailed logic for printing a row is
encapsulated in a self-contained named procedure.

### Counting backwards
You can also make a loop count backwards by using the `downto` keyword instead of `to`. This version
prints the numbers from 10 down to 1:

```basic
100   for i = 10 downto 1
110     print i
120   next
```

```{admonition} Compatibility with other BASICs
:class: seealso
In some BASIC dialects, the loop variable must be written again after the `next` keyword
(for example, `next i`), and intricate behaviors are triggered if a loop is closed out of order.
SuperBASIC simplifies this by requiring only a plain `next`, with no variable name, and it
does not support or allow those peculiar behaviors.
```

## `while` and `repeat` loops

`while` and `repeat` are a structured way of doing something repeatedly, until a condition becomes either true or false.

A `while` loop checks its condition before entering the loop. For example:

```basic
100   lives = 3
110   while lives > 0
120     playgame()
130   wend
```

Here, the program keeps calling `playgame()` while the variable `lives` is greater than zero. If the test
on line 110 fails immediately, the loop body will never run. Notice how indentation, shown when the
program is listed, helps to make the repeated block visually clear.

```{mermaid}
flowchart LR
    WHILE["WHILE condition"] --> TEST{"true?"}
    TEST -->|yes| BODY["Loop body"] --> WHILE
    TEST -->|no| WEND["WEND"]

    style WHILE fill:#e65100,color:#fff,stroke:#bf360c
    style TEST fill:#f57f17,color:#fff,stroke:#e65100
```


A `repeat` loop, on the other hand, always runs its body at least once, because the test is checked only
at the end:

```basic
100   lives = 3
110   repeat
120     playgame()
130   until lives = 0
```

This example produces the same behaviour as the `while` loop above, but with a different control flow:
The loop executes `playgame()` once before checking whether `lives  = 0`.

```{mermaid}
flowchart LR
    REPEAT["REPEAT"] --> BODY["Loop body"] --> TEST{"UNTIL condition"}
    TEST -->|false| REPEAT
    TEST -->|true| DONE["Done"]

    style REPEAT fill:#e65100,color:#fff,stroke:#bf360c
    style TEST fill:#f57f17,color:#fff,stroke:#e65100
```

## `if` ... `else` ... `endif`

`if` is a conditional test, allowing code to be run if some test is satisfied, e.g.:

```basic
100   if count = 0 then explode
110   if name$ = "Paul Robson" then print "You are very clever and modest."
```

(the built-in instruction `explode` plays a simple explosion effect).

This is standard BASIC — `if` the test 'passes' the code following the `then` is executed.

However, there is an alternate form, more in tune with modern programming: `if ... else ... endif`:

```basic
100   for n = 1 to 10
110     if n % 2 = 0
120       print n;" is even"
130     else
140       print n;" is odd"
150     endif
160   next
```

This prints whether a number is even or odd, based on the value of `n`. You can include multiple lines
of code in either the `if` or `else` clause.

The `else` part is optional.

This can all be written on one line (or pretty much any way you like), e.g.

```basic
100   for n = 1 to 10
110     if n % 2 = 0:print n;" is even":else:print n;" is odd":endif
120   next
```

You cannot write, as you can in some BASIC interpreters, the following:

```basic
100   if a = 2 then print "A is two" else print "A is not two"
```

Once you have a `then` you are locked into the simple form; no `else` or `endif`.

Generally when programming you use the `then` short version for simple tests, and the `if..else..endif` for more complicated ones.

Here endeth the lesson.

