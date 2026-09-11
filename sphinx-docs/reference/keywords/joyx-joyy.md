# {kwd}`joyx()` {kwd}`joyy()`

Return the directional value of a joystick or gamepad along the X or Y axis. A
value of `1` indicates movement to the right (X) or down (Y), `-1` indicates
movement to the left or up, and `0` means no movement. Each function takes a
single argument, the gamepad number.

Keyboard keys Z / X / K / M / L (left / right / up / down / fire) are also
mapped to this input, so a physical gamepad is not required.

```basic
100   cls: cursor off
110   while true
120     print at 0,0;"x:";joyx(0);" y:";joyy(0);"  ";
130   wend
```
