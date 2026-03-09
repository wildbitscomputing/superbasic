# Sound

## Introduction

Depending on the hardware model and generation, a Wildbits machine includes a stereo SN76489 sound chip, and may also feature additional audio hardware such as SID, OPL3, and MIDI chips.

In SuperBASIC these are simplified, so the same tones are played on left or right channels simultaneously.

## Channels

There are four sound channels, numbered 0 to 3. Channels 0–2 are simple square wave channels; channel 3 is a noise channel.

```{mermaid}
flowchart TD
    classDef primary fill:#272662,color:#fff,stroke:#1a1a4a
    classDef secondary fill:#F1632B,color:#fff,stroke:#d14a1a
    classDef accent fill:#44A348,color:#fff,stroke:#358a38

    CH0["Channel 0 — Square"]:::primary --> MIX["Mixer"]:::accent
    CH1["Channel 1 — Square"]:::primary --> MIX
    CH2["Channel 2 — Square"]:::primary --> MIX
    CH3["Channel 3 — Noise"]:::secondary --> MIX
    MIX --> SPK["Speaker"]:::primary
```

Sounds have a queue of sounds to play. So you could queue up a series of notes to play and they will carry on playing one after the other (if they are on the same channel).

SuperBASIC does not stop to play the sounds; it is processed in the background. Everything can be silenced with `sound off`.

It is possible to set a parameter to automatically change the pitch of the channel as it plays to allow easy creation of simple warpy sound effects.

## Easy Commands

Four commands `zap`, `shoot`, `ping` and `explode` exist which play a simple sound effect.
