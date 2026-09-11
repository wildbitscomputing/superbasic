# {kwd}`joyb()`

Returns a integer value indicating the status of the fire buttons on a joystick
or gamepad. Bit 0 corresponds to the main fire button. Takes a single parameter,
the gamepad number.

Keyboard keys Z / X / K / M / L (left / right / up / down / fire) are also
mapped to this input, so a physical gamepad is not required.

```basic
100 if joyb(0) & 1 then fire()
```
