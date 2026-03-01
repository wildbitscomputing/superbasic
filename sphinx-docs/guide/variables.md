# Identifiers, Variables and Typing

## Procedure and Variable Naming

SuperBASIC allows full naming of both variables and procedures (a type of "subroutine"). A name begins with an alphabetic character or underscore, and continues with either alphanumeric characters or underscores. They may also have a type character (`$`, `(`, or `#`), e.g.:

```basic
hello_world
count09
my_name_is_earl
name$
inventory(
mean_value#
```

This allows you to write readable code — no more trying to remember what `C7` is.

An implementation note: when the program is stored in memory, it only keeps one copy of the actual identifier "text" name, irrespective of how many times you use it. So apart from that once, there is no space saving from using long identifier names.

## Types

Variables in SuperBASIC are one of three types: integers, floating point, and strings.

By default a variable holds an **integer**, which is a number between about −2 billion and +2 billion (technically it's a 32-bit integer).

A variable name that ends with a `#` holds a **floating point** number (decimal), which has a much larger range but is less accurate and slower.

A variable name that ends with a `$` holds a **string**, which is a sequence of characters up to 253 characters in length.

These are some examples of variables being assigned values:

```basic
100 count = 42
110 height# = 162.7
120 name$ = "Jack Hobbs"
```

## Arrays

Arrays are a collection of variables, stored under one name. SuperBASIC supports up to two dimensions of arrays, with a maximum of 254 elements in each dimension. Arrays are indexed from zero.

```basic
100 dim a$(3)
110 a$(1) = "Entry 1"
120 a$(3) = "Entry 3"
130 dim grid(8,8)
140 grid(4,3) = 42
```
