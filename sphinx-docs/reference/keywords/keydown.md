# keydown()

Checks to see if a key is currently pressed or not — the parameter passed is the
kernel raw key code. The demo below is also a simple program for identifying
those raw key codes.

```basic
100   repeat
110     for i = 0 to 255
120       if keydown(i) then print "Key pressed ";i
130     next
140   until false
```
