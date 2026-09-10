# sound

Generates a sound on one of the channels. There are four channels. Channel 3 is
a noise channel; channels 0–2 are simple square wave channels. Sound has two
forms:

```basic
100   sound 1,500,10
```

This generates a sound of pitch 500 which runs for about 10 timer ticks. The
actual frequency is 111,563 / \<pitch value>. The pitch value can be from 1 to
1023\.

Sounds can be queued up:

```basic
100   sound 1,1000,20:sound 1,500,10:sound 1,250,20
```

An adjuster value can be added which adds a constant to the pitch every tick:

```basic
100   sound 1,500,10,10
```

`sound off` turns off all sound and empties the queues.
