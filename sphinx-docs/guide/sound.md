# Sound

## Introduction

Depending on the hardware model and generation, a Wildbits machine includes a
stereo SN76489 sound chip, and may also feature additional audio hardware such
as SID, OPL3, and MIDI chips.

In SuperBASIC, sound output uses only the SN76489 chip, with the same tones
played simultaneously on both the left and right channels.

## Channels

There are four sound channels, numbered 0 to 3. Channels 0–2 are simple square
wave channels; channel 3 is a noise channel.

```{figure} figures/sound-channels.*
:alt: Four sound channels mixed and sent to the left and right speakers
:width: 80%
:name: fig:sound-channels

Sound channels and output routing
```

Sounds have a queue of sounds to play. So you could queue up a series of notes
to play and they will carry on playing one after the other (if they are on the
same channel).

SuperBASIC does not stop to play the sounds; it is processed in the background.
Everything can be silenced with {kwd}`sound` {kwd}`off`.

It is possible to set a parameter to automatically change the pitch of the
channel as it plays to allow easy creation of simple warpy sound effects.

## Easy commands

Four commands {kwd}`zap`, {kwd}`shoot`, {kwd}`ping`, and {kwd}`explode` exist,
which play a simple sound effect.
