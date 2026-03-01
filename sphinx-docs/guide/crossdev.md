# Cross Development of BASIC Programs

Cross development is an alternative to the classic way of programming a Home Computer, where the programmer types code directly into the machine. Cross development allows you to write the code on a Personal Computer, and upload it through the USB debug port in the F256. It is also possible to do this with machine code and graphic and other data.

## Assistance

In the SuperBASIC git, <https://github.com/paulscottrobson/superbasic>, each release contains a file `howto-crossdev-basic.zip` which gives everything you need to cross develop in BASIC and some example programs.

## Connection

To connect your F256Junior to a PC (Windows, Linux, Mac) you need a standard USB cable with a Micro USB plug. This needs to be a data cable — some cables only provide power. The Micro USB plug plugs into the board, and the USB plug into the PC.

## Software

There are two ways of programming the board. I prefer FnxMgr (<https://github.com/pweingar/FoenixMgr>) which is a Python script which runs on all platforms, and can easily automate uploading. It can also be uploaded through the Foenix IDE on Windows.

Besides Python version 3, the FnxMgr script requires `pyserial`.

## BASIC

The input to the program is standard ASCII files, with line numbers. Line numbers are required for editing only. (There is a Python script on the SuperBASIC GitHub which adds these automatically.) However, you do not need to use line numbers in programming, though `GOTO` and `GOSUB` are implemented if you wish, or want to port old software.

I would start with something simple though:

```basic
10 print "Hello, world !"
20 zap
```

Each file should end in a character with an ASCII code greater than 127, which marks the end of the file. You can copy one from the software in GitHub.

## Uploading and Running

This is written for people with "B" boards which automatically start up into BASIC. If you are booting from RAM, or have an A board, it will be slightly different.

Uploading works by loading the ASCII text into memory. It is then effectively "typed in" by either the `xload` command or the `xgo` command. The first loads the program in (and it can then be listed or edited or run in the normal way). The second loads and runs it.

To load the program into memory to be "loaded" you need something like the below.

### Linux Upload

```bash
python ../bin/fnxmgr.zip --port /dev/ttyUSB0 --binary load.bas --address 28000
```

### Windows Upload

```text
python ..\bin\fnxmgr.zip --port COM1 --binary load.bas --address 28000
```

## Memory Use

Program memory occupies `$2000`–`$3FFF` and is **banked via MMU slot 1**, supporting up to 32 × 8KB pages (~256KB of program space). Array and `alloc()` storage lives at `$4000`–`$7FFF` (16KB). The BASIC ROM is mapped into `$8000`–`$BFFF`.

The memory block `$C000`–`$DFFF` contains I/O pages — you can change I/O registers, but do not map RAM here and change it unless you are absolutely sure of what you are doing.

The memory block `$E000`–`$FFFF` contains the Kernel.

## Sprites

Sprites are loaded (in BASIC) to `$30000` and there is a simple index format. This is covered in the sprites section.
