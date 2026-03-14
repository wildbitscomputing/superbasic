# Identifiers, Variables and Typing

## Procedure and Variable Naming

SuperBASIC lets you give long, descriptive names to both variables and procedures (also known as
subroutines). Using clear names makes your programs easier to read and understand.

A name must start with a letter or an underscore (`_`), and it can continue with any combination of
letters, numbers, or underscores. A name may also end with a type character (`$` or `#`), which shows
the kind of data stored in the variable (see the next section for more details).
Here are some examples of valid names:


```text
n
count17
number_of_lives
str2num
name$
average#
```

Here are some examples of _invalid_ names:

```text
2string      ' can not start with a number
$name        ' $ character must be at the end
total#sum    ' # character must be at the end
```


```{note}

When a program is stored in memory, each identifier name is stored only once, regardless
of how many times it appears in the program. Thus, aside from that single instance, using
shorter identifier names provides no additional space savings.
```

## Types

SuperBASIC supports three variable types: integers, floating-point numbers, and strings.
By default, a variable is an integer. Integers are whole numbers, such as −5, 0, or 4200. In SuperBASIC,
they can go up to about 2 billion or down to−2 billion.

A variable name ending with `#` represents a floating-point number (a decimal). Floating-point numbers
let you use very large, very small, or fractional values (like 178.2). They are more flexible than integers,
but sometimes less exact and a little slower to calculate.

A variable name ending with `$` represents a string. A string is simply arbitrary text, up to 253 characters
long. In program code, string values—called string literals—are written inside quotation marks. For
example, `"Arthur Dent"` is a string literal.

Here are some examples:

```basic
100   count = 19
110   height# = 178.2
120   name$ = "Arthur Dent"
```

## Arrays

An array is a collection of related variables that share the same name and are stored together. Arrays
are created using the `dim` statement, followed by the array name and the number of elements. Each
individual element is accessed by giving its index inside parentheses. Array indexes always begin at
zero:

```basic
100   dim fruits$(3)
110   fruits$(0) = "apple"
120   fruits$(1) = "orange"
130   fruits$(2) = "banana"
140   print fruits$(0)                   ' prints "apple"
150   print fruits$(2)                   ' prints "banana"
```

SuperBASIC supports both one-dimensional and two-dimensional arrays, with up to 254 elements in
each dimension.

When first created, string array elements are empty strings, and number array elements are set to zero.

Here is a two-dimensional array of numbers, which you can think of like a grid with rows and columns:

```basic
100   dim grid(8,8)                      ' 8 by 8 grid of numbers
110   grid(4,3) = 17
120   print grid(4,3)                    ' prints 17
130   print grid(7,7)                    ' prints 0
```

