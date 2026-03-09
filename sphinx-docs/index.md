# F256 SuperBASIC Reference Manual

*By Paul Robson & Matthias Brukner*

A modernised BASIC interpreter for the 65C02-based Wildbits/K2 retro computers.

::::{grid} 2
:gutter: 3

:::{grid-item-card} Introduction
:link: guide/introduction
:link-type: doc
Overview, memory layout, and storage format.
:::

:::{grid-item-card} Getting started
:link: guide/getting_started
:link-type: doc
Line-number editing, screen editor keys, and cross-development.
:::

:::{grid-item-card} Variables & Types
:link: guide/variables
:link-type: doc
Integers, floats, strings, and arrays.
:::

:::{grid-item-card} Structured Programming
:link: guide/structured_programming
:link-type: doc
Procedures, WHILE, REPEAT, FOR, and IF/ELSE/ENDIF.
:::

:::{grid-item-card} Graphics
:link: guide/graphics
:link-type: doc
Bitmap drawing, modifiers, colours, and the graphics pipeline.
:::

:::{grid-item-card} Tiles & Tile Maps
:link: guide/tiles
:link-type: doc
8×8 tile maps, scrolling, and data formats.
:::

:::{grid-item-card} Sprites
:link: guide/sprites
:link-type: doc
Hardware sprites, building sprite sets, and collision detection.
:::

:::{grid-item-card} Sound
:link: guide/sound
:link-type: doc
SN76489 channels, sound queuing, and easy sound effects.
:::

:::{grid-item-card} Inline Assembly
:link: guide/assembler
:link-type: doc
65C02 inline assembler modelled on the BBC Micro.
:::

:::{grid-item-card} Memory
:link: guide/memory
:link-type: doc
Physical memory map, program paging, and the LOMEM command.
:::

:::{grid-item-card} Cross Development
:link: guide/crossdev
:link-type: doc
USB uploading and FnxMgr.
:::

:::{grid-item-card} Keyword Reference
:link: reference/keywords
:link-type: doc
Complete A–Z reference for every SuperBASIC keyword.
:::

::::

```{toctree}
:hidden:
:caption: User Guide

guide/introduction
guide/getting_started
guide/variables
guide/structured_programming
guide/graphics
guide/tiles
guide/sprites
guide/sound
guide/assembler
guide/memory
guide/crossdev
```

```{toctree}
:hidden:
:caption: Reference

reference/keywords
```
