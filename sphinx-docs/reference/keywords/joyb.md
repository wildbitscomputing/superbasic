# joyb()

Returns a value indicating the status of the fire buttons on a gamepad, with the
main fire button being bit 0. Takes a single parameter, the number of the
gamepad. The keyboard keys Z X K M L (left/right/up/down/fire) are also mapped
onto this controller.

```basic
100   if joyb(0) & 1 then fire()
```
