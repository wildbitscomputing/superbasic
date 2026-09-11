# `$` (dollar sign)

Depending on where it's encountered, the dollar sign can play one of two roles:

When placed before a numeric constant, it designates a hexadecimal value. For
example, `$10` is interpreted as a hexadecimal constant with the decimal value
16\. Similarly, `$2A` represents the decimal value 42:

```basic
100 n = $2A
110 if n = 42 then print "Found it!"
120 !$7ffe = 31702
```

When used as a suffix in an identifier, `$` designates a string variable. The
suffix is considered part of the variable name, so `id` and `id$` are treated as
two distinct variables—an integer and a string, respectively. See
Chapter {ref}`chap:variables` for an in-depth discussion of variable types.

```basic
100 an_integer_id = $FFFF
110 a_string_id$ = "Hello world"
120 print an_integer_id, a_string_id$
```
