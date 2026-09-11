# {kwd}`event()`

The {kwd}`event()` function tracks elapsed time and is commonly used to trigger
movement or actions in games. It returns {kwd}`true` at predictable intervals,
based on a 70Hz timer (i.e. 70 ticks per second). It takes two parameters: a
variable and a duration in ticks.

If the variable is zero, the function waits the specified number of ticks before
returning {kwd}`true` once. If the variable is non-zero, it tracks repeated
events. For example, `event(evt1,70)` returns {kwd}`true` once per second (since
70 ticks = 1 second).

Note: Event timing continues even if the game is paused. So if an event is set
to occur every 20 seconds, it may appear to fire during the pause. To avoid
this, reset the event variable to zero when unpausing—this restarts the timer.

If the event variable is set to -1, it disables the event. This can be used to
implement one-shot timers by setting the variable to -1 once the event has
fired.

The example below prints `"Hello"` once a second.

```basic
100 repeat
110   if event(myevent1,70) then print "Hello"
120 until false
```
