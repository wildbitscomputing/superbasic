# `.` (period)

Assembly label operator. Assigns the label following the period to the current
assembly address. The label acts as an integer variable that holds this address:

```basic
100 ' Fills the top screen row with the character in A
110 assemble $6000, 0: .fill_top_row ' start an assembly block and label it
120 ldy $0001                    ' save I/O page in Y
130 pha: lda #2: sta $0001: pla  ' switch to I/O page 2
140 ldx #80                      ' number of columns to fill
150 .fill_loop                   ' define the loop label
160 dex                          ' move (backwards) to the next column
170 sta $c000,x                  ' write the char to column X
180 cpx #0                       ' are we done?
190 bne fill_loop                ' if not zero, keep going
200 tya: sta $0001               ' restore original I/O page
210 rts                          ' return from the routine
220 cls                          ' clear the screen
230 call fill_top_row, asc("#")  ' fill the top row with #
```

Labels can be referenced before they are defined, but doing so requires a
multi-pass assembly block—see Chapter {ref}`chap:assembly` for details.

Since labels are variables, they must be globally unique.
