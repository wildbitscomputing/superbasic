# {kwd}`pi`

Returns the floating-point constant π (approximately 3.14159265). No parentheses
are required.

```basic
100 r#=pi*2/235
110 print sin(pi/2)
```

{kwd}`sin()`, {kwd}`cos()`, and {kwd}`tan()` use radians. To convert degrees to
radians, multiply by `pi/180`.

`PI` is a reserved keyword, not a variable. Programs that previously assigned
their own `pi` variable must remove that assignment or rename the variable.
