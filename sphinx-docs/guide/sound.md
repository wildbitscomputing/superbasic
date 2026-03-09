# Sound

## Introduction

Depending on the hardware model and generation, a Wildbits/K2 machine includes a stereo SN76489 sound chip, and may also feature additional audio hardware such as SID, OPL3, and MIDI chips.

In SuperBASIC these are simplified, so the same tones are played on left or right channels simultaneously.

## Channels

There are four sound channels, numbered 0 to 3. Channels 0–2 are simple square wave channels; channel 3 is a noise channel.

```{mermaid}
flowchart TD
    CH0["Channel 0 — Square"] --> MIX["Mixer"]
    CH1["Channel 1 — Square"] --> MIX
    CH2["Channel 2 — Square"] --> MIX
    CH3["Channel 3 — Noise"] --> MIX
    MIX --> SPK["Speaker"]

    style CH0 fill:#1565c0,color:#fff,stroke:#0d47a1
    style CH1 fill:#1565c0,color:#fff,stroke:#0d47a1
    style CH2 fill:#1565c0,color:#fff,stroke:#0d47a1
    style CH3 fill:#e65100,color:#fff,stroke:#bf360c
    style MIX fill:#2e7d32,color:#fff,stroke:#1b5e20
```

Sounds have a queue of sounds to play. So you could queue up a series of notes to play and they will carry on playing one after the other (if they are on the same channel).

SuperBASIC does not stop to play the sounds; it is processed in the background. Everything can be silenced with `sound off`.

It is possible to set a parameter to automatically change the pitch of the channel as it plays to allow easy creation of simple warpy sound effects.

## Easy Commands

Four commands `ZAP`, `SHOOT`, `PING` and `EXPLODE` exist which play a simple sound effect.
