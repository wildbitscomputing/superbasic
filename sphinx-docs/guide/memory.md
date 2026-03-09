# Memory

## CPU Address Space

The 65C02 can only address 64KB directly. The Wildbits/K2 hardware uses an MMU (Memory
Management Unit) to map 8KB pages from the full 512KB physical address space into the CPU's
64KB window.

On startup, SuperBASIC configures the CPU address space as follows:

| Slot | CPU Address       | Size | Contents                          |
|------|-------------------|------|-----------------------------------|
| 0    | `$0000`–`$1FFF`  |  8KB | System workspace and variables    |
| 1    | `$2000`–`$3FFF`  |  8KB | BASIC program page (banked)       |
| 2–3  | `$4000`–`$7FFF`  | 16KB | Array and `alloc()` storage       |
| 4–5  | `$8000`–`$BFFF`  | 16KB | SuperBASIC ROM                    |
| 6    | `$C000`–`$DFFF`  |  8KB | Kernel / I/O registers            |
| 7    | `$E000`–`$FFFF`  |  8KB | Kernel ROM                        |

```{note}
The `$C000`–`$DFFF` slot contains I/O registers and is used by the kernel. You can read and
write I/O registers here, and SuperBASIC itself uses this slot to access text screen and colour
RAM by temporarily mapping in different I/O pages. If you remap this slot, be sure to restore
it before returning control to the system.
```

### Slot 0 detail (`$0000`–`$1FFF`)

Slot 0 is identity-mapped to physical page 0 and holds all of the interpreter's runtime state:

| Address           | Size   | Contents                                               |
|-------------------|--------|--------------------------------------------------------|
| `$0000`–`$002F`  |  48 B  | Kernel zero page                                       |
| `$0030`–`$003F`  |  16 B  | SuperBASIC zero page (code pointer, temps, stack ptr)  |
| `$0050`–`$00AF`  |  96 B  | Number stack (status, mantissa, exponent — 16 entries) |
| `$0100`–`$01FF`  | 256 B  | 6502 hardware stack                                    |
| `$0200`–`$03FF`  | 512 B  | Argument storage (pexec command line)                  |
| `$0400`–`$041F`  |  32 B  | Control storage (`option` values)                      |
| `$0420`–`$0BFF`  |  ~2 KB | General storage (token buffer, line buffer, assembler state, listing state) |
| `$0C00`–`$0FFF`  | 512 B  | BASIC stack (FOR/NEXT, GOSUB, PROC frames — grows downward) |
| `$1000`–`$1FFF`  |   4 KB | Variable space (identifiers and values; strings grow downward from `$1FFF`) |

### Slot 1 — Program page (`$2000`–`$3FFF`)

Slot 1 holds the currently active page of the BASIC program. The interpreter banks different
physical pages into this slot via the MMU register at `$0009` as the program grows beyond a
single 8KB page.

### Slots 2–3 — Arrays (`$4000`–`$7FFF`)

The 16KB array area holds data created by `dim` and memory allocated by `alloc()`. Allocation
grows upward from `$4000`.

## Physical Memory Map (512KB)

The full 512KB of RAM is divided into 64 pages of 8KB each. SuperBASIC uses them as follows:

| Pages | Physical Address    | Usage                                  |
|-------|---------------------|----------------------------------------|
| 0     | `$00000`–`$01FFF`  | System workspace and variables (see above) |
| 1     | `$02000`–`$03FFF`  | Program page (banked into slot 1)      |
| 2–3   | `$04000`–`$07FFF`  | Array and `alloc()` storage            |
| 4–5   | `$08000`–`$0BFFF`  | SuperBASIC ROM                         |
| 6     | `$0C000`–`$0DFFF`  | I/O space (kernel reserved)            |
| 7     | `$0E000`–`$0FFFF`  | Kernel ROM                             |
| 8–15  | `$10000`–`$1FFFF`  | Bitmap graphics (64KB)                 |
| 16–17 | `$20000`–`$23FFF`  | Tile image data                        |
| 18–19 | `$24000`–`$27FFF`  | Tile map data                          |
| 20+   | `$28000`–           | Cross-development upload area (grows with source file size) |
| 24–29 | `$30000`–`$3BFFF`  | Sprite data                            |
| 30–47 | `$3C000`–`$5FFFF`  | Free                                   |
| 48–63 | `$60000`–`$7FFFF`  | BASIC program pages (default)          |

### Screen and colour RAM

The text screen and colour attribute memory are not in the main RAM region. They live on
I/O pages `$02` (text) and `$03` (colour) and are accessed by temporarily mapping them into the
`$C000`–`$DFFF` slot.

## Program Paging

BASIC programs are stored in banked memory pages. When the program needs more space than
a single 8KB page, SuperBASIC automatically allocates additional pages. The interpreter pages them
in and out of the CPU address space (slot 1, `$2000`–`$3FFF`) transparently as the program runs.

By default, program pages are allocated starting at page 48 (`$60000`). Up to 16 pages (128KB) are
available for BASIC programs in the default configuration.

## The `lomem` Command

The `lomem` command lets you change the first page used for BASIC program storage. This is useful
when you need to free up higher memory for graphics data, or when you want to make more pages
available for larger programs.

```basic
100   lomem $50000
```

The argument is a physical memory address. SuperBASIC converts it to a page number internally.
Valid values range from page 8 (`$10000`) up to page 63 (`$7E000`). The page number is calculated
by dividing the address by 8192 (the size of one page).

```{note}
Setting `lomem` to a low address may overlap with graphics or sprite memory. Make sure
the pages you allocate for BASIC programs do not conflict with other hardware resources you
are using.
```

The `lomem` setting persists across `new` and `load` — once set, it stays in effect until you
change it again or reset the machine.

## The `fre` Function

The `fre` function reports how much memory is available in each of the three storage areas:

| Call       | Returns                                              |
|------------|------------------------------------------------------|
| `fre(0)`   | Free program memory (bytes remaining across all unallocated pages) |
| `fre(-1)`  | Free variable and string space (bytes remaining in `$1000`–`$1FFF`) |
| `fre(-2)`  | Free array and `alloc()` space (bytes remaining in `$4000`–`$7FFF`) |

## Cross-Development Upload Area

When cross-developing, program text is uploaded to physical address `$28000` onwards (starting
at page 20). The `xload` and `xgo` commands read sequentially from this address until they
encounter an end-of-file marker (any byte with bit 7 set), so the upload area grows with the
size of the source file. A typical BASIC program fits in pages 20–21, but large files may extend
further. See {doc}`crossdev` for details.
