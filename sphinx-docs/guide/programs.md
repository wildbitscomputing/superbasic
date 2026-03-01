# Writing Programs in SuperBASIC

## Writing Programs

Programs in SuperBASIC are written in the "classic" style, using line numbers. A line number on its own deletes a line.

`LIST` operates as in most other systems, except there is the option to `LIST <procedure>()` which lists the given procedure by name. (`LIST` also uses commas, not `-` as some BASICs do, e.g. `LIST 100,300`.)

It is easy to cross develop in SuperBASIC (see later), writing a program on your favourite text editor, and sending it down the USB cable using the Python script `fnxmgr`, or the Foenix IDE. It is also possible to develop without line numbers and have them added as the last stage before uploading.

Upper and lower case is considered to be the same, so variables `myName`, `MYNAME` and `MyName` are all the same variable. The only place where case is specifically differentiated is in string constants.

Programs can be loaded or saved to SD Card or to an IEC type drive (the 6-pin DIN serial port) using the `SAVE` and `LOAD` commands.

There is also currently a `VERIFY` command whose purpose is to check files have been saved correctly. While the SD Card and IEC code has been seen to be reliable in practice, the code is still relatively new; so when saving BASIC programs in development, I recommend saving them under incremental names (e.g. `prog1.bas`, `prog2.bas`), verifying them, and periodically backing up your SD card.

This may seem slightly long-winded, but is a good defensive measure as there may be bugs in the kernel routines, or the BASIC routines which handle program editing.

The documents directory in the SuperBASIC GitHub, which is publicly accessible, has a simple syntax highlighter for the Sublime Text editor.

## Screen Editor

The built-in screen editor supports navigation, line editing, and scroll-based program browsing.

**Cursor Movement**

| Key | Action |
|---|---|
| ← / → | Move cursor left / right |
| ↑ / ↓ | Move cursor up / down |
| Home, Ctrl+A, Ctrl+↑ | Go to start of line |
| Ctrl+E, Ctrl+↓ | Go to end of line |
| Ctrl+← | Jump one word left |
| Ctrl+→ | Jump one word right |

**Scrolling**

| Key | Action |
|---|---|
| F/WLD+↑ | Scroll up through program listing |
| F/WLD+↓ | Scroll down through program listing |

**Editing**

| Key | Action |
|---|---|
| Del | Delete character before cursor |
| Ctrl+D | Delete character at cursor |
| Shift+Del | Insert blank line (like Atari 800) |
| Ctrl+K | Clear to end of line (including continuation rows) |
| Shift+Home, Ctrl+L | Clear screen |
| Return | Enter / confirm the current line |
| Shift+Return | Jump to start of next line without evaluating |

The editor tracks line wrapping so that scrolling, Home/End, and Backspace all behave correctly across lines that span multiple display rows.
