# Getting Started

## Writing Programs

Programs in SuperBASIC are written in the classic style, using line numbers. A line number on its
own deletes that line.

```basic
100   print "Hello, world!"
110   zap
```

`list` operates as in most other systems, except you can also list a single procedure by name
with `list <procedure>()`. Use commas, not dashes, to specify a range, e.g. `list 100,300`.

It is easy to cross-develop in SuperBASIC (see Chapter 9), writing a program on your favourite text
editor, and transfering it to the Wildbits over USB using the FnxMgr or the Foenix IDE. It is also possible to
develop without line numbers and have them added as the last stage before uploading.

Upper and lower case are treated as the same, so `myName`, `MYNAME`, and `MyName` all refer to the
same variable. The only place where case matters is inside string constants.

Programs can be loaded from or saved to an SD Card or an IEC-type drive (the 6-pin DIN serial port)
using the `save` and `load` commands.

The documentsdirectory in the SuperBASIC GitHub repository has a simple syntax highlighter for the
Sublime Text editor.

## Screen Editor

The built-in screen editor lets you type, edit, and navigate program lines directly on the machine.

### Editing

| Key                 | Action                                      |
|---------------------|---------------------------------------------|
| Enter               | Submit the current line                     |
| Shift+Enter         | Move to next line without submitting        |
| DEL/Backspace       | Delete character before cursor              |
| Ctrl+D              | Delete character at cursor                  |
| Shift+DEL/Backspace | Insert a blank line                         |

### Navigation

| Key               | Action                                      |
|-------------------|---------------------------------------------|
| Arrow keys        | Move cursor up / down / left / right        |
| Ctrl+Left         | Jump to previous word                       |
| Ctrl+Right        | Jump to next word                           |
| Ctrl+Up           | Jump to beginning of line                   |
| Ctrl+Down         | Jump to end of line                         |

### Scrolling

| Key               | Action                                      |
|-------------------|---------------------------------------------|
| Fnx+Up            | Scroll screen up (show previous lines)      |
| Fnx+Down          | Scroll screen down (show later lines)       |

### Other

| Key               | Action                                      |
|-------------------|---------------------------------------------|
| Shift+Home        | Clear screen                                |
| Ctrl+C            | Break execution                             |

Lines that are longer than the screen width automatically wrap to the next row. The editor
handles wrapped lines seamlessly — cursor movement, deletion, and insertion all work correctly
across wrapped rows.

