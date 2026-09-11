(chap:getting-started)=

# Getting started

The blinking cursor on the screen indicates that SuperBASIC is ready for your
input. The built-in editor lets you move around freely using the cursor keys and
edit anything you see on the screen --- including the SuperBASIC startup banner
with the Wildbits flower (try it!).

You can enter any characters you like, in any combination. As far as the BASIC
interpreter is concerned, a line of text on the screen doesn't have to make
sense, or even contain alphabetic characters, as long as you don't press
{kbd}`return` while the cursor is on that line.

Pressing {kbd}`return` tells SuperBASIC to interpret the current line, which it
will dutifully do. At that point, if the line isn't a valid BASIC command,
you'll likely see this error:

```output
Syntax error
```

Don't worry, though: apart from overwriting whatever was on the screen in that
space, this error is harmless. All it means is that SuperBASIC did not
understand your input.

Once you're done playing around and ready to enter something SuperBASIC will
understand, go to a blank line, type the text below, and press {kbd}`return`:

```basic
print "Hello!"
```

You'll see the computer respond with `"Hello!"`. That is a much nicer greeting
than "Syntax error", but in reality we're just greeting ourselves. The computer
told us "Hello!" because that's what we instructed it to do. If instead we type

```basic
print "Goodbye!"
```

we'll get `"Goodbye!"`. This type of interaction with SuperBASIC --- where we
type a command, press {kbd}`return`, and the interpreter immediately responds
with a result of that command --- is called immediate mode. All BASIC commands
can be tried out in the immediate mode, but some, such as print, are better
suited to it than others. Here are some fun sound commands to try out in the
immediate mode:

```basic
zap : shoot
```

This won't print anything on the screen, but if you have speakers connected to
your computer, you'll hear a short burst of playful sound effects. The colon (:)
character acts as a command separator, allowing us to put two different commands
on the same line. Here’s another command to try in the immediate mode:

```basic
print 2 + 5
```

Try guessing what it’s going to print before you press {kbd}`return`!

The immediate mode is fun, but at some point you will notice that the SuperBASIC
commands that you write are short-lived. Sure, you can go up with a cursor to a
command you just typed, change it, press {kbd}`return`, and have the machine
respond with the new output. But if you enter enough new commands, each on its
own line, some of the olds ones will eventually scroll off the screen and be
lost.

To save a command in SuperBASIC memory, we have to give it an “official” line
number, for example:

```basic
100 print 2 + 5
```

When you press {kbd}`return` on this line, you’ll notice that the computer
didn’t print anything back. What it did, though, is store the line in its
memory. You can ask SuperBASIC to show you the program lines that it remembers
by typing

```basic
list
```

and pressing {kbd}`return`. Try it! You should see your line printed back, now
in color:

```basic
100 print 2+5
```

To run it, type

```basic
run
```

and press {kbd}`return`. The computer will print back “7”, just like it did
before, but because now this line is stored in the SuperBASIC memory, we can
invoke it with run over and over again. We can even clear the screen and it will
still be there:

```basic
cls run
```

To add another line, type

```basic
110 zap : shoot
```

and press {kbd}`return`. Once again, the computer won’t print anything back, but
it will store this new line in memory, appending it to the already existing one.
You can verify it by typing

```basic
list
```

again and pressing {kbd}`return`. To run your now two-line program, type

```basic
run
```

and press {kbd}`return`.

Note that although the program is stored in memory, it will disappear if you
reset or turn off the machine. To be able to access it again after a power off,
you need to explicitly save, like this:

```basic
save "my_first_program.bas"
```

(Don’t forget to press {kbd}`return`!)

The text in quotes (`my_first_program.bas`) is the program’s name. It doesn’t
have to be this exact phrase, any name you like will do, but as a matter of
convention, we recommend that you end all program names with .bas to indicate
that they contain SuperBASIC code.

You can test loading of the program you just saved by pressing the Reset button
and then typing

```basic
load "my_first_program.bas"
```

and pressing {kbd}`return`. Once it’s loaded, you can list it and run it just as
before!
