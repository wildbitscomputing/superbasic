(chap:crossdev)=

# Cross-development

Cross-development offers an alternative to the classic approach of developing
directly on the Wildbits machine. Instead, you write the code on a modern PC
using your standard development tools, then upload it through the USB debug
port. You can use this workflow for BASIC programs, machine-code programs,
graphics, and other data.

## Assistance

Each release in the SuperBASIC GitHub repository includes the file
{file}`howto-crossdev-basic.zip`, which contains everything you need to
cross-develop in BASIC, along with some example programs.

<https://github.com/wildbitscomputing/superbasic>

## Connection

To connect your Wildbits or Foenix machine to a PC (Windows, Linux, or Mac),
you'll need a standard USB data cable: Micro USB for the F256 Jr/K, or USB-C for
the Wildbits/Jr2 or Wildbits/K2. Some cables only provide power; make sure yours
supports data.

## Utility software

There are two ways to program the machine over USB. We recommend using
FnxMgr,[^1] a Python script that runs on all platforms and allows you to
automate code uploading. Alternatively, cross-developed code can be uploaded
using the Foenix IDE on Windows.

Besides Python version 3, the FnxMgr script requires `pyserial`.

## Cross-developing in SuperBASIC

You can cross-develop your program using any standard text editor. Line numbers
aren't required during development, but you can include them if you prefer or
need to—for example, when porting older code.

However, line numbers must be added before uploading, as the SuperBASIC
interpreter on the machine uses them to organize and edit the program. The file
must also end with a character whose ASCII code is greater than 127. Running
your program through the `number.py` script in the
{file}`howto-crossdev-basic.zip` archive ensures both requirements are met.

If your program already includes line numbers, you can add the end-of-file
marker manually by copying it from one of the examples in the archive.

I would start with something simple though:

```basic
10    print "Hello, world !"
20    zap
```

## Uploading and running

Note that this section assumes you're using a machine that starts up directly
into SuperBASIC. If you're booting from RAM, the process may differ slightly.

Uploading works by loading an ASCII text file into memory, which is then
effectively “typed in” via either the {kwd}`xload` or {kwd}`xgo` command.
{kwd}`xload` loads the program into the interpreter, allowing you to list, edit,
or run it as usual. {kwd}`xgo` does the same but immediately runs the program
afterward.

To load your program into memory for use with {kwd}`xload` or {kwd}`xgo`, use a
command like one of the following. On Windows, you can identify the correct COM
port using Device Manager; on Linux, use `lsusb` or `dmesg`.

### Example: Linux upload

```text
python fnxmgr.zip --port /dev/ttyUSB0 --binary load.bas --address 28000
```

### Example: Windows upload

```text
python fnxmgr.zip --port COM1 --binary load.bas --address 28000
```

## Memory use

Program text is uploaded to physical address `$28000` onwards. The {kwd}`xload`
and {kwd}`xgo` commands read from this address until they encounter the
end-of-file marker, so the upload area grows with the size of your source file.
Be aware that very large files may overlap with sprite memory at `$30000`. For
the full memory map including program pages, graphics regions, and the
{kwd}`lomem` command, see {doc}`memory`.

[^1]: https://github.com/pweingar/FoenixMgr
