# Memory

## CPU Address Space

The 65C02 can only address 64KB directly. The Wildbits/K2 hardware uses an MMU (Memory
Management Unit) to map 8KB pages from the full 512KB physical address space into the CPU's
64KB window.

On startup, SuperBASIC configures the CPU address space as follows:

| CPU Address       | Size | Contents                          |
|-------------------|------|-----------------------------------|
| `$0000`–`$7FFF`  | 32KB | RAM (pages 0–3, identity-mapped)  |
| `$8000`–`$BFFF`  | 16KB | SuperBASIC ROM                    |
| `$C000`–`$DFFF`  |  8KB | Kernel / I/O registers            |
| `$E000`–`$FFFF`  |  8KB | Kernel ROM                        |

The lower 32KB of RAM has logical addresses equal to physical addresses by default. This is where
BASIC variables, the stack, and system workspace live.

```{warning}
The `$C000`–`$DFFF` region is reserved by the kernel. You can read and write I/O registers
here, but do not map RAM into this region unless you are absolutely sure of what you are doing.
```

## Physical Memory Map (512KB)

The full 512KB of RAM is divided into 64 pages of 8KB each. SuperBASIC uses them as follows:

| Pages   | Physical Address          | Usage                              |
|---------|---------------------------|------------------------------------|
| 0–3     | `$00000`–`$07FFF`        | CPU RAM (variables, stack, system) |
| 4       | `$08000`–`$09FFF`        | Text screen / colour RAM           |
| 5–7     | `$0A000`–`$0FFFF`        | Reserved / I/O                     |
| 8–15    | `$10000`–`$1FFFF`        | Bitmap graphics (64KB)             |
| 16–23   | `$20000`–`$2FFFF`        | Tile graphics / tile maps          |
| 24–29   | `$30000`–`$3BFFF`        | Sprite data                        |
| 30–31   | `$3C000`–`$3FFFF`        | Sprite data (continued)            |
| 32–39   | `$40000`–`$4FFFF`        | Sound / reserved                   |
| 40–47   | `$50000`–`$5FFFF`        | Available for BASIC programs       |
| 48–63   | `$60000`–`$7FFFF`        | BASIC program pages (default)      |

## Program Paging

BASIC programs are stored in banked memory pages. When the program needs more space than
a single 8KB page, SuperBASIC automatically allocates additional pages. The interpreter pages them
in and out of the CPU address space transparently as the program runs.

By default, program pages are allocated starting at page 48 (`$60000`). Up to 16 pages (128KB) are
available for BASIC programs in the default configuration.

## The LOMEM Command

The `LOMEM` command lets you change the first page used for BASIC program storage. This is useful
when you need to free up higher memory for graphics data, or when you want to make more pages
available for larger programs.

```basic
100 lomem $50000
```

The argument is a physical memory address. SuperBASIC converts it to a page number internally.
Valid values range from page 8 (`$10000`) up to page 63 (`$7E000`). The page number is calculated
by dividing the address by 8192 (the size of one page).

```{note}
Setting `LOMEM` to a low address may overlap with graphics or sprite memory. Make sure
the pages you allocate for BASIC programs do not conflict with other hardware resources you
are using.
```

The `LOMEM` setting persists across `NEW` and `LOAD` — once set, it stays in effect until you
change it again or reset the machine.

## The FRE Function

`FRE(0)` returns the number of free bytes available for BASIC program storage, based on the
current `LOMEM` setting and how many pages the program is currently using.

## Cross-Development Upload Area

When cross-developing, program text is uploaded to physical address `$28000`–`$2BFFF` (pages
20–21). The `XLOAD` and `XGO` commands read from this area. See {doc}`crossdev` for details.
