# {kwd}`sound`

Generates a sound on one of the channels. There are four channels, corresponding
to the. Channel 3 is a noise channel, channels 0-2 are simple square wave
channels generating one note each. Sound has two forms:

```basic
100 sound 1,500,10
```

generates a sound of pitch 1000 which runs for about 10 timer ticks. The actual
frequency is 111,563 / \<pitch value>. The pitch value can be from 1 to 1023.
Sounds can be queued up, so you can play 3 notes in a row, e.g.

```basic
100 sound 1,1000,20:sound 1,500,10:sound 1,250,20
```

An adjuster value can be added which adds a constant to the pitch every tick,
which allows the creation of some simple warpy effects, as in the {kwd}`zap`
command:

```basic
100 sound 1,500,10,10
```

This creates a tone which drops as it plays (higher pitch values are lower
frequency values).

Channel 3 operates slightly differently. It generates noises which can be
modulated by channel 2. However, there are currently 8 sounds, which are
accessed by the pitch being 16 times the sound number:

```basic
100 sound 3,6*16,10
```

This generates an explosiony sort of sound. You can just use the constant 96 of
course instead.

Finally this turns off all sound and empties the queues:

```basic
100 sound off
```
