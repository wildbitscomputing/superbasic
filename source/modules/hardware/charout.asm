; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		charout.asm
;		Purpose:	Output character
;		Created:	14th November 2022
;		Reviewed: 	No
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;			Print character as standard, but treat all control characters as font
;
; ************************************************************************************************

Export_EXTPrintNoControl:
		pha
		phx
		phy

		ldx 	1
		phx

		ldy 	EXTColumn 					; Y = Row, e.g. points to character.
		bra 	PrintCharacterOnly

; ************************************************************************************************
;
;									Output Character A
;
;		control+'a'  ($01)  begin
;		control+'b'  ($02)  left
;		control+'e'  ($05)  end
;		control+'f'  ($06)  right
;		control+'h'  ($08)  backspace
;		control+'i'  ($09)  tab
;		control+'l'  ($0C)  ff
;		control+'m'  ($0D)  cr
;		control+'n'  ($0E)  down
;		control+'p'  ($10)  up
;					  $8x 	set background
;					  $9x 	set foreground
;
; ************************************************************************************************

Export_EXTPrintCharacter:
PAGEDPrintCharacter:
		pha
		phx
		phy

		ldx 	1
		phx

		ldy 	EXTColumn 					; Y = current column

		ora 	#$00 						; check $80-$FF
		bpl 	_NotColour
		jmp 	EXPCColour
_NotColour:
		cmp 	#$20 						; check $00-$1F
		bcs 	_NotControl
		jmp 	EXPCControl
_NotControl:
		;
		;		Handle character.
		;
PrintCharacterOnly:
		pha
		lda		EXTPendingWrap				; check for a pending wrap state
		beq 	_print_char					; no pending wrap, jump to print
		jsr 	ApplyPendingWrap			; apply pending wrap, then print

	_print_char:
		pla
		ldx 	#2 							; select char memory
		stx 	1
		sta 	(EXTAddress),y
		inc 	1 							; select colour memory
		lda 	EXTTextColour
		sta 	(EXTAddress),y
		;
		iny 								; advance horizontal position
		cpy 	EXTScreenWidth 				; past the right-most character?
		beq		_line_wrap					; yes, handle line wrap
		sty 	EXTColumn					; store new column position and exit
		jmp 	EXPCExit					;
		;
	_line_wrap:
		lda 	EXTRow 						; check if we're on the last line
		inc		a							;
		cmp 	EXTScreenHeight 			;
		bcc 	_line_wrap_do 				; if no, then wrap to next line

		; we're in the bottom-right corner
		lda		EXTPendingWrapEnabled		; check if pending wrap is enabled
		beq 	_line_wrap_do 				; if not, then wrap immediately

		lda 	#1
		sta 	EXTPendingWrap 				; set pending wrap flag
		jmp 	EXPCExit 					; exit with hardware cursor set
											; to current position

_line_wrap_do:
		; This is a line wrap (not explicit CRLF) - mark the NEW row as wrapped
		inc 	EXTRow 						; bump row first
		jsr 	SetWrapFlag 				; mark this row as wrapped from previous
		bra 	EXPCCRLFContinue			; continue with CRLF processing

		;
		;		Carriage return (explicit, not from line wrap)
		;
EXPCCRLF:
		inc 	EXTRow  					; bump row

EXPCCRLFContinue:
		stz 	EXTColumn 					; back to column 0
		stz 	EXTPendingWrap 				; clear pending wrap, if any
		lda 	EXTRow 						; check if reached the bottom ?
		cmp 	EXTScreenHeight 			; if so, then scroll.
		beq 	EXPCScroll
		;
		clc 								; add width to address.
		lda 	EXTAddress
		adc 	EXTScreenWidth
		sta 	EXTAddress
		bcc 	_EXPCCRLFExit
		inc 	EXTAddress+1
_EXPCCRLFExit:
		jmp 	EXPCExit
		;
		;		Move left / beginning of line.
		;
EXPCLeft:
		stz 	EXTPendingWrap
		lda 	EXTColumn
		bne 	_EXPCLeftNormal 			; not at column 0, just decrement
		;
		; At column 0 - check if current row is a continuation
		lda 	EXTRow
		beq 	_EXPCLeftExit 				; at row 0, can't go up
		jsr 	CheckWrapFlag
		bcc 	_EXPCLeftExit 				; not a continuation, stay at col 0
		;
		; This row is a continuation - move to end of previous row
		dec 	EXTRow
		lda 	EXTScreenWidth
		dec 	a
		sta 	EXTColumn
		; Update EXTAddress to previous row
		sec
		lda 	EXTAddress
		sbc 	EXTScreenWidth
		sta 	EXTAddress
		bcs 	+
		dec 	EXTAddress+1
+		bra 	EXPCExit
		;
_EXPCLeftExit:
		jmp 	EXPCExit
_EXPCLeftNormal:
		dec 	EXTColumn
		bra 	EXPCExit
EXPCBegin:
		stz 	EXTColumn
		stz 	EXTPendingWrap
		; Follow wrap flags upward to find first row of logical line
_EBFollowWrap:
		lda 	EXTRow
		beq 	_EBDone 					; at row 0, can't go higher
		jsr 	TestWrapFlag
		beq 	_EBDone 					; not a continuation, this is the start
		dec 	EXTRow 						; move up one row
		sec
		lda 	EXTAddress
		sbc 	EXTScreenWidth
		sta 	EXTAddress
		bcs 	_EBFollowWrap
		dec 	EXTAddress+1
		bra 	_EBFollowWrap
_EBDone:
		jmp 	EXPCExit
		;
		;		Scroll screen up, blank line.
		;
EXPCScroll:
		dec 	EXTRow 						; the height-1 th line.
		jsr 	EXTScreenScroll 			; scroll the screen
		bra 	EXPCExit
		;
		;		Set FGR/BGR colour
		;
EXPCColour:
		cmp 	#$A0						; 80-9F set foreground/background
		bcs 	EXPCExit
		jsr 	EXPCHandleColour
		bra 	EXPCExit
		;
		;		Handle control characters 00-1F 80-FF
		;
EXPCControl:
		cmp 	#$11 						; only handle 00-10.
		bcs 	EXPCExit
		asl 	a 							; double into X
		tax
		jmp 	(EXPCActionTable,x) 		; and execute code.
		;
		;		Up
		;
EXPCUp:
		lda 	EXTRow 						; already at top ?
		beq 	EXPCExit
		dec 	EXTRow 						; up one in position/address
		sec
		lda 	EXTAddress
		sbc 	EXTScreenWidth
		sta 	EXTAddress
		bcs 	EXPCExit
		dec 	EXTAddress+1
		bra 	EXPCExit

		;
		;		Exit
		;
EXPCExit:
		jsr 	EXTSetHardwareCursor 		; place the physical cursor.
		pla
		sta 	1
		ply
		plx
		pla
		rts

		;
		;		Right/End of line
		;
EXPCRight:
		iny
		cpy 	EXTScreenWidth
		bne 	_EXPCRightNormal 			; not at end, just set column
		;
		; At last column - check if next row is a continuation
		lda 	EXTRow
		inc 	a
		cmp 	EXTScreenHeight
		bcs 	_EXPCRightStay 				; at bottom of screen, stay
		; Check wrap flag for next row
		pha 								; save next row number
		jsr 	TestWrapFlag
		pla 								; restore next row number
		beq 	_EXPCRightStay 				; next row not wrapped, stay
		;
		; Next row is a continuation - move to column 0 of next row
		inc 	EXTRow
		stz 	EXTColumn
		; Update EXTAddress to next row
		clc
		lda 	EXTAddress
		adc 	EXTScreenWidth
		sta 	EXTAddress
		bcc 	+
		inc 	EXTAddress+1
+		bra 	EXPCExit
		;
_EXPCRightStay:
		ldy 	EXTScreenWidth
		dey
_EXPCRightNormal:
		sty 	EXTColumn
		bra 	EXPCExit
EXPCSetColumnY: 							; set column to Y
		sty 	EXTColumn
		bra 	EXPCExit
		;
		;		Clear
		;
EXPCClearScreen:
		jsr		EXTClearScreenCode
		jsr 	ClearAllWrapFlags 			; clear all wrap tracking on screen clear
		bra 	EXPCExit
		;
		;		Down
		;
EXPCDown:
		lda 	EXTScreenHeight 			; at the bottom
		dec 	a
		cmp 	EXTRow
		beq 	EXPCExit
		inc 	EXTRow 						; down one in position/address
		clc
		lda 	EXTAddress
		adc 	EXTScreenWidth
		sta 	EXTAddress
		bcc 	EXPCExit
		inc 	EXTAddress+1
		bra 	EXPCExit
		;
		;		Tab
		;
EXPCTab:
		lda 	EXTColumn 					; next tab stop
		and 	#$F8
		clc
		adc 	#8
		sta 	EXTColumn
		cmp 	EXTScreenWidth 				; too far, new line.
		bcc 	EXPCExit
		jmp 	EXPCCRLF
		;
		;		Backspace
		;
EXPCBackSpace:
		dey 								; decrement column
		bmi 	_BSWrapCheck 				; if negative, check for wrap
		dec 	EXTColumn
		stz 	EXTPendingWrap
		lda 	#2
		sta 	1
		lda 	#32
		sta 	(EXTAddress),y
		jmp 	EXPCExit

_BSWrapCheck:
		; At column 0 - check if current row is a continuation
		lda 	EXTRow
		bne 	_BSNotRow0
		jmp 	EXPCExit 					; at row 0, can't go up
_BSNotRow0:
		jsr 	CheckWrapFlag 				; check if current row wrapped
		bcs 	_BSDoWrap
		jmp 	EXPCExit 					; not a continuation, stop at col 0

_BSDoWrap:
		; This row is a continuation - move to previous row
		jsr 	ClearWrapFlag 				; clear the wrap flag since we're unwrapping
		dec 	EXTRow
		; Set column to last position
		lda 	EXTScreenWidth
		dec 	a
		sta 	EXTColumn
		tay
		; Update EXTAddress to previous row
		sec
		lda 	EXTAddress
		sbc 	EXTScreenWidth
		sta 	EXTAddress
		bcs 	_BSNoCarry
		dec 	EXTAddress+1
_BSNoCarry:
		; Delete character at new position
		stz 	EXTPendingWrap
		lda 	#2
		sta 	1
		lda 	#32
		sta 	(EXTAddress),y
		jmp 	EXPCExit
		;
		;		End of line
		;
EXPCEnd:
		lda 	#2 							; access text screen
		sta 	1
		; Follow continuation rows downward to find last wrapped row
_EEFollowWrap:
		lda 	EXTRow
		inc 	a 							; check next row
		cmp 	EXTScreenHeight
		bcs 	_EEDoSearch 				; past bottom of screen
		; Check wrap flag for next row
		pha 								; save next row number
		jsr 	TestWrapFlag
		beq 	_EENotWrapped 				; not wrapped, current row is last
		pla 								; restore next row number
		sta 	EXTRow 						; move to next row (A = next row)
		clc
		lda 	EXTAddress
		adc 	EXTScreenWidth
		sta 	EXTAddress
		bcc 	_EEFollowWrap
		inc 	EXTAddress+1
		bra 	_EEFollowWrap
_EENotWrapped:
		pla 								; clean up stack
_EEDoSearch:
		ldy 	EXTScreenWidth 				; point to last character
		dey
EXPCEndSearch:
		dey 								; if past start, move to col 0.
		bmi 	EXPCFound
		lda 	(EXTAddress),y 				; keep going back till non space found
		cmp 	#' '
		beq 	EXPCEndSearch
EXPCFound:
		iny 								; move to following cell.
		jmp 	EXPCSetColumnY
		;
		;		Clear to end of line
		;
EXPCClearEOL:
		lda 	#2 							; access character RAM
		sta 	1
		lda 	#' ' 						; fill current row from cursor to end
_ECEOLFill1:
		sta 	(EXTAddress),y
		iny
		cpy 	EXTScreenWidth
		bcc 	_ECEOLFill1
		; Set up working address for continuation rows
		lda 	EXTAddress
		sta 	zTemp0
		lda 	EXTAddress+1
		sta 	zTemp0+1
		lda 	EXTRow
		sta 	zTemp1 						; working row number
		; Clear continuation rows
_ECEOLNextRow:
		lda 	zTemp1
		inc 	a
		cmp 	EXTScreenHeight
		bcs 	_ECEOLDone 					; past bottom of screen
		; Check wrap flag for next row
		pha 								; save next row number
		jsr 	TestWrapFlag
		beq 	_ECEOLNotWrapped 			; not a continuation, done
		; Clear the wrap flag for next row
		lda 	WrapBitTable,y
		eor 	#$FF
		and 	lwWrapFlags,x
		sta 	lwWrapFlags,x
		; Advance working address to next row
		pla
		sta 	zTemp1 						; update working row
		clc
		lda 	zTemp0
		adc 	EXTScreenWidth
		sta 	zTemp0
		bcc 	+
		inc 	zTemp0+1
+		ldy 	#0 							; clear entire row
		lda 	#' '
_ECEOLFill2:
		sta 	(zTemp0),y
		iny
		cpy 	EXTScreenWidth
		bcc 	_ECEOLFill2
		bra 	_ECEOLNextRow 				; check for more continuations
_ECEOLNotWrapped:
		pla 								; clean up stack
_ECEOLDone:
		jmp 	EXPCExit
		;
		;		Vector table for CTRL+A to CTRL+P
		;
EXPCActionTable:
		.word 	EXPCExit 					; 00
		.word 	EXPCBegin 					; 01 A Start of Line
		.word 	EXPCLeft 					; 02 B Left
		.word 	EXPCExit 					; 03 C <Break>
		.word 	EXPCExit 					; 04
		.word 	EXPCEnd 					; 05 E End of Line
		.word 	EXPCRight 					; 06 F Right
		.word 	EXPCExit 					; 07
		.word 	EXPCBackSpace 				; 08 H Backspace
		.word 	EXPCTab 					; 09 I Tab
		.word 	EXPCExit 					; 0A
		.word 	EXPCClearEOL 				; 0B K Clear to EOL
		.word 	EXPCClearScreen				; 0C L CLS
		.word 	EXPCCRLF 					; 0D M CR/LF
		.word 	EXPCDown 					; 0E N Down
		.word 	EXPCExit 					; 0F
		.word 	EXPCUp 						; 10 P Up
;
;		Handle colour change (80-9F)
;
EXPCHandleColour:
		cmp 	#$90 						; 8x foreground 9x background
		bcs 	EXPCBackground
		;
		asl 	a 							; shift it 4 bits to the right.
		asl 	a
		asl 	a
		asl 	a
		ldx 	#$0F 						; Mask in X
EXPCUpdate:
		pha 								; save new colour
		txa 								; get mask
		and 	EXTTextColour 				; mask out old.
		sta 	EXTTextColour
		pla 								; or in new colour
		ora 	EXTTextColour
		sta 	EXTTextColour
		rts
EXPCBackground:
		and 	#$0F 						; get the colour
		ldx 	#$F0 						; mask
		bra 	EXPCUpdate

; ************************************************************************************************
;
;		Shift+Left: Move cursor left to start of previous word
;		Shift+Right: Move cursor right to start of next word
;		Word = sequence of alphanumeric characters (A-Z, a-z, 0-9)
;
; ************************************************************************************************

Export_EXTWordJump:
		pha
		phx
		phy
		ldx 	1
		phx
		lda 	#2 							; access text screen
		sta 	1
		bcs 	_EWRSkipWord 				; C=1: word right
		;
		; Word Left: skip non-word chars left, then word chars left
		;
_EWLSkipNonWord:
		jsr 	EWMoveCursorLeft
		bcc 	_EWDone 					; can't move further left
		ldy 	EXTColumn
		lda 	(EXTAddress),y
		jsr 	EWIsWordChar
		bcc 	_EWLSkipNonWord 			; not a word char, keep skipping
_EWLSkipWord:
		jsr 	EWMoveCursorLeft
		bcc 	_EWLDoneRight 				; at start, stop
		ldy 	EXTColumn
		lda 	(EXTAddress),y
		jsr 	EWIsWordChar
		bcs 	_EWLSkipWord 				; still a word char, keep going
_EWLDoneRight:
		jsr 	EWMoveCursorRight 			; back up one (went past word start)
		bra 	_EWDone
		;
		; Word Right: skip word chars right, then non-word chars right
		;
_EWRSkipWord:
		ldy 	EXTColumn
		lda 	(EXTAddress),y
		jsr 	EWIsWordChar
		bcc 	_EWRSkipNonWord 			; not a word char, switch
		jsr 	EWMoveCursorRight
		bcc 	_EWDone 					; can't move further right
		bra 	_EWRSkipWord
_EWRSkipNonWord:
		jsr 	EWMoveCursorRight
		bcc 	_EWDone 					; can't move further right
		ldy 	EXTColumn
		lda 	(EXTAddress),y
		jsr 	EWIsWordChar
		bcc 	_EWRSkipNonWord 			; not a word char, keep skipping
		;
_EWDone:
		jsr 	EXTSetHardwareCursor
		pla
		sta 	1
		ply
		plx
		pla
		rts

;
;		Move cursor one position left. Returns CS if moved, CC if at start.
;
EWMoveCursorLeft:
		lda 	EXTColumn
		bne 	_EWMLNormal
		; At column 0 - check if current row is a continuation
		lda 	EXTRow
		beq 	_EWMLFail 					; at row 0
		jsr 	TestWrapFlag
		beq 	_EWMLFail 					; not wrapped
		; Move to end of previous row
		dec 	EXTRow
		sec
		lda 	EXTAddress
		sbc 	EXTScreenWidth
		sta 	EXTAddress
		bcs 	+
		dec 	EXTAddress+1
+		lda 	EXTScreenWidth
		dec 	a
		sta 	EXTColumn
		sec
		rts
_EWMLNormal:
		dec 	EXTColumn
		sec
		rts
_EWMLFail:
		clc
		rts
;
;		Move cursor one position right. Returns CS if moved, CC if at end.
;
EWMoveCursorRight:
		ldy 	EXTColumn
		iny
		cpy 	EXTScreenWidth
		bne 	_EWMRNormal
		; At end of row - check if next row is continuation
		lda 	EXTRow
		inc 	a
		cmp 	EXTScreenHeight
		bcs 	_EWMRFail 					; at bottom
		jsr 	TestWrapFlag
		beq 	_EWMRFail 					; not wrapped
		; Move to start of next row
		inc 	EXTRow
		stz 	EXTColumn
		clc
		lda 	EXTAddress
		adc 	EXTScreenWidth
		sta 	EXTAddress
		bcc 	+
		inc 	EXTAddress+1
+		sec
		rts
_EWMRNormal:
		sty 	EXTColumn
		sec
		rts
_EWMRFail:
		clc
		rts
;
;		Check if character in A is a word character (A-Z, a-z, 0-9)
;		Returns CS if word char, CC if not
;
EWIsWordChar:
		cmp 	#'0'
		bcc 	EWNotWord
		cmp 	#'9'+1
		bcc 	EWIsWord 					; 0-9
		cmp 	#'A'
		bcc 	EWNotWord
		cmp 	#'Z'+1
		bcc 	EWIsWord 					; A-Z
		cmp 	#'a'
		bcc 	EWNotWord
		cmp 	#'z'+1
		bcc 	EWIsWord 					; a-z
EWNotWord:
		clc
		rts
EWIsWord:
		sec
		rts

EXTScreenScroll:
		lda 	#2 							; select text page
		sta 	1
		lda		#32 						; fill with space
		jsr 	Export_EXTScrollFill
		inc 	1 							; select colour page
		lda 	EXTTextColour
		jsr 	Export_EXTScrollFill
		jmp 	ShiftWrapFlagsUp 			; shift wrap flags to match scroll

Export_EXTApplyPendingWrap:
ApplyPendingWrap:
		stz		EXTPendingWrap				; clear pending wrap flag
		stz 	EXTColumn 					; reset column to 0
		jsr 	EXTScreenScroll 			; scroll the screen
		jsr 	SetWrapFlag 				; mark current row as wrapped (we're at bottom row)
		jsr 	EXTSetHardwareCursor 		; place the physical cursor
		ldy 	EXTColumn 					; re-point Y to column 0
		rts

; ************************************************************************************************
;
;		Insert a blank line at the current cursor row
;		Scrolls content from current row down, blanks current row
;		Used by Shift+DEL (like C64 BASIC insert line)
;
; ************************************************************************************************

Export_EXTInsertLine:
		pha
		phx
		phy

		; Save original cursor position
		lda 	EXTRow
		pha
		lda 	EXTAddress
		pha
		lda 	EXTAddress+1
		pha

		; Follow wrap flags down to last continuation row
_EILFollowWrap:
		lda 	EXTRow
		inc 	a
		cmp 	EXTScreenHeight
		bcs 	_EILAtLastRow 				; past bottom of screen
		; Check wrap flag for next row
		pha 								; save next row number
		jsr 	TestWrapFlag
		beq 	_EILNotWrapped 				; not a continuation, stop
		pla 								; next row number
		sta 	EXTRow
		clc
		lda 	EXTAddress
		adc 	EXTScreenWidth
		sta 	EXTAddress
		bcc 	_EILFollowWrap
		inc 	EXTAddress+1
		bra 	_EILFollowWrap
_EILNotWrapped:
		pla
_EILAtLastRow:
		; EXTRow/EXTAddress now point to last row of logical line
		; Advance one more row to insert BELOW it
		lda 	EXTRow
		inc 	a
		cmp 	EXTScreenHeight
		bcs 	+ 							; at bottom of screen, can't advance
		sta 	EXTRow
		clc
		lda 	EXTAddress
		adc 	EXTScreenWidth
		sta 	EXTAddress
		bcc 	+
		inc 	EXTAddress+1
+

		lda 	1 							; save I/O page
		pha

		; Scroll content down from current row to bottom
		; Copy backwards: last row <- second-to-last, etc.

		; Calculate address of last row
		lda 	EXTScreenHeight
		dec 	a 							; last row index
		asl 	a 							; multiply by 2 for table index
		tay
		clc
		lda 	#<EXTMemory
		adc 	EXTScreenRowOffsets,y
		sta 	zTemp1 						; dest = last row
		lda 	#>EXTMemory
		adc 	EXTScreenRowOffsets+1,y
		sta 	zTemp1+1

		; Source = last row - 1 (second to last row)
		sec
		lda 	zTemp1
		sbc 	EXTScreenWidth
		sta 	zTemp0
		lda 	zTemp1+1
		sbc 	#0
		sta 	zTemp0+1

		; Copy text page
		lda 	#2
		sta 	1
		jsr 	_EILScrollDown

		; Reset pointers for colour page
		lda 	EXTScreenHeight
		dec 	a
		asl 	a
		tay
		clc
		lda 	#<EXTMemory
		adc 	EXTScreenRowOffsets,y
		sta 	zTemp1
		lda 	#>EXTMemory
		adc 	EXTScreenRowOffsets+1,y
		sta 	zTemp1+1
		sec
		lda 	zTemp1
		sbc 	EXTScreenWidth
		sta 	zTemp0
		lda 	zTemp1+1
		sbc 	#0
		sta 	zTemp0+1

		; Copy colour page
		lda 	#3
		sta 	1
		jsr 	_EILScrollDown

		; Blank the current row with spaces
		lda 	#2 							; text page
		sta 	1
		ldy 	#0
		lda 	#' '
_EILBlankText:
		sta 	(EXTAddress),y
		iny
		cpy 	EXTScreenWidth
		bne 	_EILBlankText

		; Blank with current color
		lda 	#3 							; colour page
		sta 	1
		ldy 	#0
		lda 	EXTTextColour
_EILBlankColour:
		sta 	(EXTAddress),y
		iny
		cpy 	EXTScreenWidth
		bne 	_EILBlankColour

		; Shift wrap flags down for rows from current to bottom
		; and clear wrap flag for current row
		jsr 	_EILShiftWrapFlags

		pla
		sta 	1 							; restore I/O page

		; Restore original cursor position
		pla
		sta 	EXTAddress+1
		pla
		sta 	EXTAddress
		pla
		sta 	EXTRow
		stz 	EXTColumn

		ply
		plx
		pla
		rts

;
;		Shift wrap flags down starting from current row
;		Row N's flag moves to row N+1, current row flag is cleared
;
_EILShiftWrapFlags:
		pha
		phx
		phy

		; Start from the last row and work backwards to current row
		; Each row gets the wrap flag from the row above it
		lda 	EXTScreenHeight
		dec 	a 							; last row index
		sta 	zTemp0 						; current row being processed

_EILShiftWrapLoop:
		; Check if we've reached the cursor row
		lda 	zTemp0
		cmp 	EXTRow
		beq 	_EILClearCurrentWrap 		; at cursor row, clear its flag
		bcc 	_EILShiftWrapDone 			; past cursor row, done

		; Get wrap flag from row above (zTemp0 - 1)
		dec 	a 							; row above
		lsr 	a
		lsr 	a
		lsr 	a 							; byte index
		tax
		lda 	zTemp0
		dec 	a 							; row above
		and 	#7 							; bit index
		tay
		lda 	lwWrapFlags,x
		and 	WrapBitTable,y 				; isolate the bit
		beq 	_EILWrapNotSet

		; Row above has wrap flag set - set it for current row
		lda 	zTemp0
		lsr 	a
		lsr 	a
		lsr 	a
		tax
		lda 	zTemp0
		and 	#7
		tay
		lda 	WrapBitTable,y
		ora 	lwWrapFlags,x
		sta 	lwWrapFlags,x
		bra 	_EILWrapNext

_EILWrapNotSet:
		; Row above has wrap flag clear - clear it for current row
		lda 	zTemp0
		lsr 	a
		lsr 	a
		lsr 	a
		tax
		lda 	zTemp0
		and 	#7
		tay
		lda 	WrapBitTable,y
		eor 	#$FF
		and 	lwWrapFlags,x
		sta 	lwWrapFlags,x

_EILWrapNext:
		dec 	zTemp0
		bra 	_EILShiftWrapLoop

_EILClearCurrentWrap:
		; Clear wrap flag for current row (it's now a fresh blank line)
		lda 	EXTRow
		lsr 	a
		lsr 	a
		lsr 	a
		tax
		lda 	EXTRow
		and 	#7
		tay
		lda 	WrapBitTable,y
		eor 	#$FF
		and 	lwWrapFlags,x
		sta 	lwWrapFlags,x

		; Also clear wrap flag for row EXTRow+1 (if exists)
		; because it no longer continues from the now-blank current row
		lda 	EXTRow
		inc 	a
		cmp 	EXTScreenHeight 			; past end of screen?
		bcs 	_EILShiftWrapDone 			; yes, skip
		; Clear flag for EXTRow+1
		lsr 	a
		lsr 	a
		lsr 	a
		tax
		lda 	EXTRow
		inc 	a
		and 	#7
		tay
		lda 	WrapBitTable,y
		eor 	#$FF
		and 	lwWrapFlags,x
		sta 	lwWrapFlags,x

_EILShiftWrapDone:
		ply
		plx
		pla
		rts

;
;		Scroll rows down from zTemp0 (src) to zTemp1 (dest)
;		Stop when dest reaches EXTAddress (current row)
;
_EILScrollDown:
		; Check if dest is at or above current row - if so, we're done
		lda 	zTemp1+1
		cmp 	EXTAddress+1
		bcc 	_EILScrollDone 				; dest < current, done
		bne 	_EILScrollCopy 				; dest > current high byte, continue
		lda 	zTemp1
		cmp 	EXTAddress
		bcc 	_EILScrollDone 				; dest < current, done
		beq 	_EILScrollDone 				; dest = current, done

_EILScrollCopy:
		; Copy one row from zTemp0 to zTemp1
		ldy 	#0
_EILScrollByte:
		lda 	(zTemp0),y
		sta 	(zTemp1),y
		iny
		cpy 	EXTScreenWidth
		bne 	_EILScrollByte

		; Move both pointers up one row
		sec
		lda 	zTemp0
		sbc 	EXTScreenWidth
		sta 	zTemp0
		lda 	zTemp0+1
		sbc 	#0
		sta 	zTemp0+1

		sec
		lda 	zTemp1
		sbc 	EXTScreenWidth
		sta 	zTemp1
		lda 	zTemp1+1
		sbc 	#0
		sta 	zTemp1+1

		bra 	_EILScrollDown

_EILScrollDone:
		rts

; ************************************************************************************************
;
;		Line-wrap flag helper functions
;		Track which rows wrapped from the previous row (for backspace across wraps)
;
; ************************************************************************************************

;
;		Set wrap flag for current row (indicates it wrapped from previous row)
;
SetWrapFlag:
		pha
		phx
		phy
		lda 	EXTRow
		jsr 	TestWrapFlag 				; X = byte index, Y = bit index
		lda 	WrapBitTable,y
		ora 	lwWrapFlags,x
		sta 	lwWrapFlags,x
		ply
		plx
		pla
		rts

;
;		Clear wrap flag for current row
;
ClearWrapFlag:
		pha
		phx
		phy
		lda 	EXTRow
		jsr 	TestWrapFlag 				; X = byte index, Y = bit index
		lda 	WrapBitTable,y
		eor 	#$FF 						; invert to get mask
		and 	lwWrapFlags,x
		sta 	lwWrapFlags,x
		ply
		plx
		pla
		rts

;
;		Check if current row is a continuation (wrapped from previous)
;		Returns: CC if not wrapped, CS if wrapped
;
CheckWrapFlag:
		phx
		phy
		lda 	EXTRow
		jsr 	TestWrapFlag 				; Z set = not wrapped
		beq 	_CWFNotWrapped
		ply
		plx
		sec
		rts
_CWFNotWrapped:
		ply
		plx
		clc
		rts

;
;		Clear all wrap flags (for screen clear)
;
ClearAllWrapFlags:
		ldx 	#7
		lda 	#0
_CAWFLoop:
		sta 	lwWrapFlags,x
		dex
		bpl 	_CAWFLoop
		rts

;
;		Shift wrap flags up by 1 row (for scroll up operation)
;		Row N becomes row N-1, row 0 is lost, new row at bottom is cleared
;
ShiftWrapFlagsUp:
		phx
		phy

		; Shift all 8 bytes RIGHT, carrying bits between them
		; Row 1 -> Row 0, Row 2 -> Row 1, etc. (bit N -> bit N-1)
		; Start from high byte, shift right through carry
		; DEX/BPL don't affect carry, so this loop preserves carry between bytes
		clc
		ldx 	#7
_SWFULoop:
		lda 	lwWrapFlags,x
		ror 	a 							; shift right, carry out to next byte
		sta 	lwWrapFlags,x
		dex
		bpl 	_SWFULoop

		ply
		plx
		rts

;
;		Shift wrap flags down by 1 row (for scroll down operation)
;		Row N becomes row N+1, last row is lost, row 0 is cleared
;
ShiftWrapFlagsDown:
		phx
		phy

		; Shift all 8 bytes LEFT, carrying bits between them
		; Row 0 -> Row 1, Row 1 -> Row 2, etc. (bit N -> bit N+1)
		; Start from low byte, shift left through carry
		; Use Y as down-counter since DEY doesn't affect carry flag
		ldy 	#8
		clc
		ldx 	#0
_SWFDLoop:
		lda 	lwWrapFlags,x
		rol 	a 							; shift left, carry out to next byte
		sta 	lwWrapFlags,x
		inx
		dey 								; DEY doesn't affect carry!
		bne 	_SWFDLoop

		ply
		plx
		rts

;
;		Test wrap flag for row A.
;		Input: A = row number
;		Output: Z clear = wrapped, Z set = not wrapped
;		Sets X = byte index, Y = bit index (for callers that need them)
;		Clobbers A.
;
TestWrapFlag:
		pha
		lsr 	a
		lsr 	a
		lsr 	a 							; byte index
		tax
		pla
		and 	#7 							; bit index
		tay
		lda 	lwWrapFlags,x
		and 	WrapBitTable,y
		rts
;
;		Bit lookup table for wrap flags
;
WrapBitTable:
		.byte 	1, 2, 4, 8, 16, 32, 64, 128

		.send code

; ************************************************************************************************
;
;									Changes and Updates
;
; ************************************************************************************************
;
;		Date			Notes
;		==== 			=====
;		27/11/22 		Changed End so to end of text line, e.g. after last non space
;						Added Ctrl+K delete to EOL suggested by Jessie O.
;		01/01/23 		Added routine to print using only font characters.
;		04/04/23 		TAB was doing END if past screen width rather than CRLF.
;		19/02/26 		Added line-wrap flag tracking, backspace across wrapped
;						lines, insert overflow to next wrapped row.
;		20/02/26 		Added TestWrapFlag shared subroutine, refactored
;						inline wrap flag checks. Added Ctrl+Left/Right
;						Shift+Left/Right word jump cursor movement.
;
; ************************************************************************************************
