# Cross Development of BASIC Programs

Cross development is an alternative to the classic way of programming a Home Computer, where the programmer types code directly into the machine. Cross development allows you to write the code on a Personal Computer, and upload it through the USB debug port. It is also possible to do this with machine code and graphic and other data.

## Assistance

In the SuperBASIC git, <https://github.com/wildbitscomputing/superbasic>, each release contains a file `howto-crossdev-basic.zip` which gives everything you need to cross develop in BASIC and some example programs.

## Connection

To connect your Wildbits/K2 to a PC (Windows, Linux, Mac) you need a USB data cable — Micro USB for the Wildbits/Jr or Wildbits/K, or USB-C for the Wildbits/Jr2 or Wildbits/K2. Some cables only provide power; make sure yours supports data. The USB plug connects to the board, and the other end to the PC.

## Software

There are two ways of programming the board. I prefer FnxMgr (<https://github.com/pweingar/FoenixMgr>) which is a Python script which runs on all platforms, and can easily automate uploading. It can also be uploaded through the Foenix IDE on Windows.

Besides Python version 3, the FnxMgr script requires `pyserial`.

## BASIC

The input to the program is standard ASCII files, with line numbers. Line numbers are required for editing only. (The `number.py` script on the SuperBASIC GitHub adds line numbers and the end-of-file marker automatically.) However, you do not need to use line numbers in programming, though `GOTO` and `GOSUB` are implemented if you wish, or want to port old software.

I would start with something simple though:

```basic
10    print "Hello, world !"
20    zap
```

Each file should end in a character with an ASCII code greater than 127, which marks the end of the file. You can copy one from the software in GitHub.

## Uploading and Running

This is written for boards which automatically start up into BASIC.

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

Program text is uploaded to physical address `$28000` onwards. The `xload` and `xgo` commands
read from this address until they encounter the end-of-file marker, so the upload area grows
with the size of your source file. Be aware that very large files may overlap with sprite memory
at `$30000`. For the full memory map including program pages, graphics regions, and the `LOMEM`
command, see {doc}`memory`.
