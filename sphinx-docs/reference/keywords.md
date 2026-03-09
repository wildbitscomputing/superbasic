# Keyword Reference

This describes the keywords in SuperBASIC. Some that are naturally grouped together, such as graphics, have their own section.

## !

`!` is an indirection operator that does a similar job to `DEEK` and `DOKE`, i.e. accesses memory. It can be used either in unary fashion (`!47` reads the word at location 47) or binary (`a!4` reads the word at the value in address `a+4`). It can also appear on the left-hand side of an assignment statement when it functions as a `DOKE`, writing a 16-bit value in low/high order. It reads or writes a 16-bit address in the 6502 memory map.

```basic
10    !a = 42
20    print !a
30    print a!b
40    a!b=12
```

## ' and REM

Comment. `'` and `REM` are synonyms. The rest of the line is ignored. The only difference between the two is when listing, `'` comments show up in reverse to highlight them. Remarks should be in quotes for syntactic consistency.

```basic
10    ' "This is a title comment"
20    REM
30    REM "Another comment"
```

## abs()

Returns the absolute value of the parameter.

```basic
10    print abs(-4)
```

## alloc()

Allocate the given number of bytes of memory and return the address. Can be used for data structures or program memory for the assembler.

Note: `alloc()` uses a bump allocator. There is no corresponding deallocation function — allocated memory is only freed when the program is cleared (`NEW` or `RUN`).

```basic
10    myAssemblerCode = alloc(128)
```

## asc()

Returns the ASCII value of the first character in the string, or zero if the string is empty.

```basic
10    print asc("*")
```

## # and $

`#` and `$` are used to type variables. `#` is a floating point value, `$` is a string. The default type is integer. Variables are not stored internally by name but by reference. This means they are quick to access but means they are always in existence from the start of a program if used in it. Integers are 32-bit signed; floats have a 32-bit signed mantissa and 8-bit exponent, giving approximately 9 decimal digits of precision.

```basic
100   an_integer  = 42
110   a_float#  = 3.14159
120   a_string$ = "hello world"
```

## ?

`?` is an indirection operator that does a similar job to `PEEK` and `POKE`, i.e. accesses memory. It is the same as `!` except it operates on a byte level.

```basic
100   ?a = 42
110   print ?a
120   print a?b
130   a?b=12
```

## $

Hexadecimal constant prefix. `$2A` is the same as the decimal constant 42.

```basic
100   print $2a
110   !$7ffe = 31702
```

## *

Multiply.

```basic
100   print 4*2
```

## +

Add or string concatenation.

```basic
100   sum = 4+2
110   prompt$ = "hello "+"world !"
```

## -

Subtract.

```basic
100   print 44 - 2
```

## %

Binary modulus operator. Returns the non-negative remainder. The second value must be non-zero.

```basic
100   print 42 % 5 : rem prints 2
110   print -17 % 5 : rem prints 2
```

## .

Sets the following label to the current assembler address. So the example below sets the label `mylabel` at the current address and you can write things like `bra mylabel`. Note also that this is an integer variable.

```basic
100   .mylabel
```

## / and \\

Signed division. An error occurs if the divisor is zero. Backslash is integer division, forward slash returns a floating point value.

```basic
100   print 22/7
110   print 22\7
```

## < <= <> = > >=

Comparison binary operators, which return 0 for false and −1 for true. They can be used to compare two numbers or two strings.

```basic
100   if a<42 then "a is not the answer to life the universe and everything"
110   if name$="" then input name$
```

## @

Returns the address of an l-expr, normally this is a variable of some sort, but it can be an array element or even an indirection.

```basic
100   print @fred, @a(4)
```

## &

Binary AND operator. This is a binary operator not a logical one, so it can return values other than true and false.

```basic
100   print count & 7
```

## ^

Binary exclusive OR operator. This is a binary operator not a logical one, so it can return values other than true and false.

```basic
100   print a^$0E
```

## |

Binary OR operator. This is a binary operator not a logical one, so it can return values other than true and false.

```basic
100   print read.value | 4
```

## << >>

Binary operators which shift an integer left or right a certain number of times logically. Much quicker than multiplication.

```basic
100   print a << 2,32 >> 2
```

## assemble

Initialises an assembler pass. Apart from the simplest bits of code, the assembler is two-pass. It has two parameters. The first is the location in memory the assembled code should be stored, the second is the mode. At present there are two mode bits; bit 0 indicates the pass (0 = first pass, 1 = second pass) and bit 1 specifies whether the code is listed as it goes. Normally these values will be 0 and 1, as the listing is a bit slow. 6502 mnemonics are typed as-is.

```basic
100   assemble $6000,1:lda #42:sta count:rts
```

Normally these are wrapped in a loop for the two passes for forward references:

```basic
100   for pass = 0 to 1
110     assemble $6000,pass
120     bra forward
130     <some code>
140     .forward:rts
150   next
```

This is almost identical to the BBC Microcomputer's inline assembler.

## assert

Every good programming language should have `assert`. It verifies contracts and detects error conditions. If the expression following is zero, an error is produced.

```basic
100   assert myage = 42
```

## bitmap

Turns the bitmap on or off, or clears it, or sets its address (the default address is `$10000`). Only one bitmap is used in BASIC, but you can use others by accessing I/O. Keywords are `ON`, `OFF`, `CLEAR <colour>`, `AT <address>` and can be chained. On or Off without an `AT` will reset the address.

```basic
100   bitmap at $18000 on clear $03
110   bitmap at $18000 on:bitmap clear $03
```

## bload

Loads a file into memory. The 2nd parameter is the address in full memory space, *not* the 6502 CPU address. In the default setup, for the RAM area (`0000`–`7FFF`) this will however be the same.

```basic
100   bitmap on:bitmap clear 1
110   bload "mypic.bin",$10000
```

## bsave

Saves a chunk of memory into a file. The 2nd parameter is the address in full memory space, *not* the 6502 CPU address. The 3rd parameter is the number of bytes to save.

```basic
100   bsave "memory.space",$0800,$7800
```

## call

Calls an assembly subroutine at the specified address. You may provide up to three arguments, which will be loaded into the A, X, and Y registers respectively. The address can be specified in decimal or hex.

```basic
100   call $4000
110   call $4000,65,0,0
```

## chr$()

Convert an ASCII integer to a single character string.

```basic
100   print chr$(42)
```

## circle

Draws a circle, using the standard syntax. The vertical height defines the radius of the circle. See the section on graphics for drawing options.

```basic
100   circle here solid to 200,200
```

## cls

Clears the text screen.

```basic
100   cls
```

## cprint

Operates the same as the `print` command, but control characters (e.g. `00`–`1F`, `80`–`FF`) are printed using the characters from the FONT memory, not as control characters. The example below prints a horizontal upper bar character, not a new line.

```basic
100   cprint chr$(13);
```

## cursor

Turns the flashing cursor on or off.

```basic
100   cursor on
```

## dir

Shows all the files in the current drive.

```basic
100   dir
```

## dim

Dimension number or string arrays with up to two dimensions, with a maximum of 254 elements in each dimension.

```basic
100   dim a$(10),a_sine#(10)
110   dim name$(10,2)
```

## drive

Sets the current drive for load/save. The default drive is zero.

```basic
100   drive 1
```

## end

Ends the current program and returns to the command line.

```basic
100   end
```

## event()

`event()` tracks time. It is normally used to activate object movement or events in a game, and generates true at predictable rates. It takes two parameters: a variable and an elapsed time.

If that variable is zero, then this function doesn't return true until after that many tenths of seconds has elapsed. If it is non-zero, it tracks repeated events, so `event(evt1,70)` will return true every second — the clock operates at the timer rate, 70Hz.

Note that if a game pauses the event times will continue. One way out is to zero the event variables when leaving pause — this will cause it to fire after another delay period. If the event variable is set to −1 it will never fire, so this can be used to create one-shots.

```basic
100   repeat
110     if event(myevent1,70) then print "Hello"
120   until false
```

## false

Returns the constant zero.

```basic
100   print false
```

## for next

A loop which repeats code a fixed number of times, which must be executed at least once. The default step is 1 for `to` and −1 for `downto`; use `STEP` to set a different increment. The variable name on `NEXT` is not supported.

```basic
100   for i = 1 to 10:print i:next
110   for i = 10 downto 1:print i:next
120   for i = 0 to 100 step 10:print i:next
```

## frac()

Return the fractional part of a number.

```basic
100   print frac(3.14159)
```

## fre()

Returns information about free memory. The parameter selects which region:

- `fre(0)` — free program memory (banked pages)
- `fre(-1)` — free variable/string space
- `fre(-2)` — free array space

```basic
100   print fre(0)
110   print fre(-1)
120   print fre(-2)
```

## get() and get$()

Wait for the next key press then return either the character as a string, or as the ASCII character code.

```basic
100   print "Letter ";get$()
```

## getdate$(n)

Reads the current date from the clock returning a string in the format `dd:mm:yy`. The parameter is ignored.

```basic
100   print "Today is ";getdate$(0)
```

## gettime$(n)

Reads the current time from the clock returning a string in the format `hh:mm:ss`. The parameter is ignored.

```basic
100   print "It is now ";gettime$(0)
```

## gfx

Sends a three-parameter command directly to the graphics subsystem. Often the last two parameters are coordinates (not always). It is not advised to use this for general use as programs would be somewhat unreadable.

```basic
100   gfx 22,130,100
```

## gosub

Call a routine at a given line number. Provided for compatibility with older programs; use named procedures instead for new code.

```basic
100   gosub 1000
```

## goto

Transfer execution to given line number. Provided for compatibility with older programs; use structured control flow instead for new code.

```basic
100   goto 200
```

## hit()

Tests if two sprites overlap. This is done using a box test based on the size of the sprite (e.g. 8×8, 16×16, 24×24, 32×32). The value returned is zero for no collision, or the lower of the two coordinate differences from the centre, approximately. This only works if sprites are positioned via the graphics system.

```basic
100   print hit(1,2)
```

## if then and if else endif

`IF` has two forms. The first is classic BASIC: `if <condition> then <do something>`. All the code is on one line. The `THEN` is mandatory.

```basic
100   if name="benny" then my_iq = 70
```

The second form allows multi-line conditional execution, with an optional `else` clause. Note the `endif` is mandatory; you cannot use a single line `if then else`:

```basic
100   if age < 18:print "child":else:print "adult":endif
```

## image

Draws a possibly scaled or flipped sprite image on the bitmap, using the standard syntax. Flipping is done using bits 7 and 6 of the mode (e.g. `$80` and `$40`) in the colour option. This requires both sprites and bitmap to be on.

```basic
100   image 4 dim 3 colour 0,$80 to 100,100
```

## inkey() and inkey$()

If a character key has been pressed, return either the character as a string, or as the ASCII character code. If no key is available return `""` or `0`. This uses key presses — if you want to check whether a key is up or down, use `keydown()`.

```basic
100   print inkey(),inkey$()
```

## input

Inputs numbers or strings from the keyboard. This version uses the same syntax as `print`, except that where there is a variable a value is entered into that variable.

```basic
100   input "Your name is ?";a$
```

## int()

Returns the integer part of a number.

```basic
100   print int(3.14159)
```

## isval()

This is a support for `val()` and takes the same parameter (a string). This deals with the problem that `val()` errors if you give it a non-numeric value. This checks to see if the string is a valid number and returns −1 if so, 0 if it is not.

```basic
100   print isval("42")
110   print isval("i like chips in gravy")
```

## itemcount()

Together, `itemcount` and `itemget` provide a way of encoding multiple data items in strings. A multiple-element string has a separating character, which can be any ASCII character, often a comma. `itemcount()` takes a string and a separator and returns the number of items.

```basic
100   print itemcount("hello,world",",")
```

## itemget$()

Takes three parameters: the string, the index of the substring required (starting at 1), and the separator. A bad index will generate a range error.

```basic
100   print itemget$("paul,jane,lizzie,jack",3,",")
```

## joyb()

Returns a value indicating the status of the fire buttons on a gamepad, with the main fire button being bit 0. Takes a single parameter, the number of the gamepad. The keyboard keys Z X K M L (left/right/up/down/fire) are also mapped onto this controller.

```basic
100   if joyb(0) & 1 then fire()
```

## joyx() joyy()

Returns the directional value of a gamepad in the x and y axes respectively as −1, 0 or 1, with 1 being right and down. Each takes a single parameter which is the number of the pad. Keyboard keys are also mapped.

```basic
100   x = x + joyx(0)
```

## keydown()

Checks to see if a key is currently pressed or not — the parameter passed is the kernel raw key code. The demo below is also a simple program for identifying those raw key codes.

```basic
100   repeat
110     for i = 0 to 255
120       if keydown(i) then print "Key pressed ";i
130     next
140   until false
```

## load

Loads a BASIC program from the current drive.

```basic
load "game.bas"
```

## left$()

Returns several characters from a string counting from the left.

```basic
100   print left$("mystring",4)
```

## len()

Returns the length of the string as an integer.

```basic
100   print len("hello, world")
```

## let

Assignment statement. The `LET` is optional. You can also use `@a` where `a` is a reference.

```basic
100   let a = 42
110   a$="hello"
120   a#=22.7
```

## line

Draws a line, using the standard syntax which is explained in the graphics section.

```basic
100   line 100,100 colour $e0 to 200,200
```

## list

Lists the program. It is possible to list any part of the program using the line numbers, or list a procedure by name.

```basic
100   list
110   list 1000
120   list 100,200
130   list ,400
140   list myfunction()
```

## local

Defines the list of variables (no arrays allowed) as local to the current procedure. The locals are initialised to an empty string or zero depending on their type.

```basic
100   local test$,count
```

## max() min()

Returns the largest or smallest of the parameters. There can be any number of these (at least one). You can't mix strings and integers.

```basic
100   print max(3,42,5)
```

## mdelta

Gets the current delta status of the PS/2 mouse. 6 reference parameters (normally integer variables) are provided: cumulative mouse changes in the x, y, z axes, and the number of times the left, middle and right buttons have been pressed.

```basic
100   mdelta dx,dy,dz,lmb,mmb,rmb
```

## memcopy

This command is an interface to the Wildbits/K2's DMA hardware. `MEMCOPY` has several formats:

```basic
100   memcopy $10000,$4000 to $18000
110   memcopy $10000,$4000 poke $F7
120   memcopy $10000 rect 64,48 by 320 to $18000
130   memcopy $10000 rect 64,48 by 320 poke $18
140   memcopy at 32,32 rect 64,48 by 320 to at 128,128
```

Line 100 is a straight linear copy. Line 110 is a linear fill. Line 120 is a rectangular area copy. Line 130 is a rectangular area fill. Line 140 shows an alternate way using pixel coordinates.

## mid$()

Returns a subsegment of a string, given the start position (first character is 1) and the length, so `mid$("abcdef",3,2)` returns `"cd"`.

```basic
100   print mid$("hello",2,3)
110   print mid$("another word",2,99)
```

## mouse

Gets the current status of the PS/2 mouse. 6 reference parameters (normally integer variables) are provided: current mouse position in the x, y, z axes, and the status of the left, middle and right buttons.

```basic
100   mouse x,y,z,isx,isy,isz
```

## new

Erases the current program.

```basic
100   new
```

## not()

Unary operator returning the logical NOT of its parameter, i.e. 0 if non-zero, −1 otherwise.

```basic
100   print not(42)
```

## option

`option` is used for general control functions which are not common enough to justify their own keyword. Option 0–7 set highlighting colours for Comment Foreground, Comment Background, Line Number, Token, Constant, Identifier, Punctuation, Data respectively. The lower 4 bits set the colour; setting bit 7 will disable the background change.

```basic
100   for i = 0 to 7:option i,128+15:next
```

## palette

Sets the graphics palette. The parameters are the colour id and the red, green and blue components. On start up, the palette is `RRRGGGBB`.

```basic
100   palette 1,255,128,0
```

## peek() peekw() peekl() peekd()

The `peek`, `peekw`, `peekl` and `peekd` functions retrieve 1–4 bytes from the 6502 memory space.

```basic
100   print peekd(42),peek(1)
```

## playing()

Returns true if a channel is currently playing a sound.

```basic
100   print playing(0)
```

## plot

Plot a point in the current colour using the standard syntax described in the graphics section.

```basic
100   plot to 100,200
```

## poke pokew pokel poked

The `poke`, `pokew`, `pokel` and `poked` functions write one to four bytes to the 6502 memory space.

```basic
100   poke 4096,1: pokew $c004,$a705
```

## print

Prints to the current output device, either strings or numbers (which are preceded by a space). `print` with `,` goes to the next tab stop. A return is printed unless the command ends in `;` or `,`.

The `at row, column` modifier positions the cursor before printing (zero-based, top-left is 0,0).

```basic
100   print 42,"hello"
110   print at 10,5;"positioned text"
```

## proc endproc

Simple procedures. These should be used rather than `GOSUB`. Or else. The empty brackets are mandatory even if there aren't any parameters.

```basic
100   printmessage("hello",42)
110   end
120   proc printmessage(msg$,n)
130     print msg$+"world  x "+str$(n)
140   endproc
```

## rnd() random()

Generates random numbers. `rnd()` behaves like Microsoft BASIC: negative numbers set the seed, 0 repeats the last value, and positive numbers return a float 0 <= n < 1. `random(n)` returns a number from 0 to n−1.

```basic
100   print rnd(1),random(6)
```

## read / data

Reads from `DATA` statements. The types must match. For syntactic consistency, string data must be in quote marks.

```basic
100   read a$,b
110   data "hello world"
120   data 59
```

## rect

Draws a rectangle, using the standard syntax described in the graphics section.

```basic
100   rect 100,100 colour $ff to 200,200
```

## restore

Resets the data pointer to the start of the program.

```basic
100   restore
```

## repeat until

Conditional loop, which is tested at the bottom.

```basic
100   count = 0
110   repeat
120     count = count + 1:print count
130   until count = 10
```

## return

Return from `GOSUB` call. You can make up your own death threats.

```basic
100   return
```

## right$()

Returns several characters from a string counting from the right.

```basic
100   print right$("last four characters",4)
```

## run

Runs the current program after clearing variables as for `CLEAR`. Can also have a parameter which does a `LOAD` and then `RUN`.

```basic
100   run
110   run "demo.bas"
```

## save

Saves a BASIC program to the current drive.

```basic
save "game.bas"
```

## screen()

Returns the character code at the given screen position (row, column).

```basic
100   print screen(0,0)
```

## screen$()

Returns the character at the given screen position (row, column) as a single-character string.

```basic
100   print screen$(0,0)
```

## setdate

Sets the RTC to the given date; the parameters are the day, month and year (00–99).

```basic
100   setdate 23,1,3
```

## settime

Sets the RTC to the given time; the parameters are hours, minutes, seconds.

```basic
100   settime 9,44,25
```

## sgn()

Returns the sign of a number, which is −1, 0 or 1 depending on the value.

```basic
100   print sgn(42)
```

## sound

Generates a sound on one of the channels. There are four channels. Channel 3 is a noise channel; channels 0–2 are simple square wave channels. Sound has two forms:

```basic
100   sound 1,500,10
```

This generates a sound of pitch 500 which runs for about 10 timer ticks. The actual frequency is 111,563 / \<pitch value\>. The pitch value can be from 1 to 1023.

Sounds can be queued up:

```basic
100   sound 1,1000,20:sound 1,500,10:sound 1,250,20
```

An adjuster value can be added which adds a constant to the pitch every tick:

```basic
100   sound 1,500,10,10
```

`sound off` turns off all sound and empties the queues.

## spc()

Return a string consisting of a given number of spaces.

```basic
100   a$ = spc(32)
```

## sprite

Manipulate one of the 64 hardware sprites using the standard modifiers. Also supported are `sprite image <n>` which turns a sprite on and selects image \<n\>, and `sprite off` which turns a sprite off. For `sprite .. to` the sprite is centred on those coordinates.

```basic
100   sprite 4 image 2 to 50,200
```

## sprites

Enables and disables all sprites, optionally setting the location of the sprite data in memory (default `$30000`). When turned on, all the sprites are erased and their control values set to zero.

```basic
100   sprites at $18000 on
```

## stop

Stops program with an error.

```basic
100   stop
```

## str$()

Converts a number to a string, in signed decimal form.

```basic
100   print str$(42),str$(412.16)
```

## text

Draws a possibly scaled or flipped string from the standard font on the bitmap, using the standard syntax. Flipping is done using bits 7 and 6 of the mode in the colour option.

```basic
100   text "hello" dim 2 colour 3 to 100,100
```

## tile

Manipulates the tile map. This allows you to set the scroll offset (with `TO xscroll,yscroll`) and draw on the tile map using `AT x,y` to set the position and `DRAW` followed by a list of tiles, with a repeat option using `LINE`.

```basic
100   tile to 12,0
110   tile at 4,5 draw 10,11,11,11,10
120   tile at 4,5 draw 10,11 line 3,10
```

## tile()

Returns the tile at the given tile map position (not screen position).

```basic
100   print tile(2,3)
```

## tiles

Sets up the tile map. Allows the setting of the size with `DIM <width>,<height>` and the location of the data with `AT <map address>,<image address>`. All addresses must be at the start of an 8KB page. Currently only 8×8 tiles are supported.

```basic
100   tiles on
110   tiles off
120   tiles dim 42,32 at $24000,$26000 on
```

## timer()

Returns the current value of the 70Hz frame timer, which will wrap round in a couple of days.

```basic
100   print timer()
```

## true

Returns the constant −1.

```basic
100   print true
```

## try

Tries to execute a command, usually involving the Kernel, returning an error code if it fails or 0 if successful. Currently supports `BLOAD` and `BSAVE`.

```basic
100   try bload "myfile",$10000 to ec
110   print ec
```

## val()

Converts a string to a number. There must be some number there, e.g. `"-42xxx"` works and returns −42 but `"xxx"` returns an error. To make it usable, use `isval()` which checks validity first.

```basic
100   print val("42")
110   print val("413.22")
```

## verify

Compares the current BASIC program to a program stored on the current drive. This command is a defensive measure against potential bugs in either the kernel, the kernel drivers, or BASIC itself.

```basic
verify "game.bas"
```

## while wend

Conditional loop with test at the top.

```basic
100   islow = 0
110   while islow < 10
120     print islow
130     islow = islow + 1
140   wend
```

## xload xgo

These commands are for cross development in BASIC. If you store an ASCII BASIC program, terminated with a character code >= 128, then these commands will Load or Load-and-Run that program.

## zap ping shoot and explode

Simple commands that generate a simple sound effect.

```basic
100   ping:zap:explode
```
