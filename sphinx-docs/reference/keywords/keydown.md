# {kwd}`keydown()`

Checks whether a key is currently being pressed. The function takes a single
parameter, the raw key code. The example below also serves as a simple tool for
identifying these raw key codes.

```basic
100 repeat
110   for i = 0 to 255
120     if keydown(i) then print "Key pressed ";i
130   next
140 until false
```
