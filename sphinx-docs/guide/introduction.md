# Introduction

This document is not a tutorial and assumes the reader has some knowledge of programming in general and BASIC in particular.

If you want to learn programming, I would advise you try learning using one of the numerous courses available. The course in the Vic20 manual is highly regarded and can be used with an emulator such as "Vice", and much of the knowledge will transfer directly.

F256's SuperBASIC is a modernised BASIC interpreter for the 65C02 processor. It currently occupies 5 blocks of Flash mapped into 2 slots (16KB) of the 65C02 memory space, from `$8000`–`$BFFF`.

Currently editing is still done using line numbers, however it is possible to cross-develop without line numbers. There are some examples at the primary GitHub repository at <https://github.com/paulscottrobson/SuperBASIC> under the `games` directory.

There is no requirement to actually use line numbers in programs. `GOTO`, `GOSUB` and `RETURN` are supported but this is more for backwards compatibility with older programs. It is advised to use Procedures, For/Next, While, Repeat and If/Else/Endif commands for better programming and clarity.

## Storage

Programs are stored in ASCII format, so in cross development any editor can be used. `LOAD`, `VERIFY` and `SAVE` read and write files in this format. Internally the format is quite different.

## Memory Usage

Memory usage is split into several regions:

| Address | Region | Notes |
|---|---|---|
| `$0000`–`$0FFF` | System / Zero Page | |
| `$1000`–`$1FFF` | Identifier Table | Variable names and values |
| `$2000`–`$3FFF` | Program Memory | Banked via MMU slot 1 (up to 32 × 8KB pages) |
| `$4000`–`$7FFF` | Arrays / ALLOC Storage | 16KB dedicated region |
| `$8000`–`$BFFF` | SuperBASIC ROM | 5 blocks of Flash mapped into 2 slots |
| `$C000`–`$DFFF` | I/O Pages | Hardware registers |
| `$E000`–`$FFFF` | Kernel | |

Keywords such as `REPEAT` are replaced by a single byte, or for less common options, by two bytes. Identifiers are replaced by a reference into the identifier table from `$1000`–`$1FFF`. The first part of this table is a list of identifiers along with the current value. Arrays and allocated memory (using `alloc()`) follow that. String memory occupies the top of the memory area and works down.

This should be entirely transparent to the developer.

## Memory Usage Elsewhere

SuperBASIC uses memory locations outside the normal 6502 address space as well:

- If you use a **bitmap**, it will be placed at `$10000` in physical space and occupy 320×240 bytes.
- If you use **sprites**, they are loaded to `$30000` in physical space, and the size depends on how many you have.
- If you use **tiles**, the tile map is stored at `$24000` and the tile image data at `$26000`.
- If you **cross develop**, the memory location from `$28000` onwards is used to store the BASIC code you have uploaded.

If you do not use any of these features directly (you can set up your own bitmaps and sprites yourself, and enter programs through the keyboard, saving to the SD Card or IEC drive) then the memory is all yours.
