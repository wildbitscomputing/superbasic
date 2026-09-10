# event()

`event()` tracks time. It is normally used to activate object movement or events
in a game, and generates true at predictable rates. It takes two parameters: a
variable and an elapsed time.

If that variable is zero, then this function doesn't return true until after
that many tenths of seconds has elapsed. If it is non-zero, it tracks repeated
events, so `event(evt1,70)` will return true every second — the clock operates
at the timer rate, 70Hz.

Note that if a game pauses the event times will continue. One way out is to zero
the event variables when leaving pause — this will cause it to fire after
another delay period. If the event variable is set to −1 it will never fire, so
this can be used to create one-shots.

```basic
100   repeat
110     if event(myevent1,70) then print "Hello"
120   until false
```
