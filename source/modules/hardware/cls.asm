;;
; Clear screen/hardware cursor utilities.
;;
		.section code

;;
; Clear the screen and home the cursor.
;
; Clears the screen by filling the text page with spaces and color page with
; the current text color, then homes the cursor to the top-left corner (row 0,
; column 0).
;
; \in EXTTextColour     The color value to fill the color memory.
; \out EXTColumn        0
; \out EXTRow           0
; \out EXTAddress       `EXTMemory`
; \sideeffects          - Updates I/O page register 1.
;                       - Modifies registers `A` and `Y`.
;                       - Resets `EXTColumn`, `EXTRow`, and `EXTAddress`.
;                       - Updates text and color memory.
;						- Updates hardware cursor registers $D014-$D017.
; \see                  EXTHomeCursor, EXTSetHardwareCursor
;;
EXTClearScreenCode:
		;
		jsr 	ClearAllWrapFlags			; clear wrap tracking flags
		lda 	#2 							; select text page
		sta 	1
		lda		#32 						; fill with space
		jsr 	_EXTCSFill
		inc 	1 							; select color page
		lda 	EXTTextColour
		jsr 	_EXTCSFill
		bra 	EXTHomeCursor				; home cursor
		;
		;		Fill all text memory C000-D2FF with A - page set by caller
		;
_EXTCSFill:
		tax
		lda 	#EXTMemory & $FF
		sta 	EXTAddress
		lda 	#EXTMemory >> 8
		sta 	EXTAddress+1
_EXTCSFill1:
		ldy 	#0
		txa
_EXTCSFill2:
		sta 	(EXTAddress),y
		iny
		bne 	_EXTCSFill2
		inc 	EXTAddress+1
		lda 	EXTAddress+1
		cmp 	#$D2
		bne 	_EXTCSFill1
		txa
_EXTCSFill3:
		sta 	(EXTAddress),y
		iny
		cpy 	#$C0
		bne 	_EXTCSFill3
		rts

;;
; Home the cursor.
;
; Sets the current cursor position `EXTRow`, `EXTColumn` to the top-left
; corner of the display and the current screen line address pointer
; `EXTAddress` to the start of the text memory, updates the hardware cursor
; registers to reflect the new position.
;
; \out EXTColumn    0
; \out EXTRow       0
; \out EXTAddress   `EXTMemory`
; \sideeffects      - Modifies register `A`.
;                   - Resets `EXTColumn`, `EXTRow`, and `EXTAddress`.
;					- Updates hardware cursor registers $D014-$D017.
;;
EXTHomeCursor:
		stz 	EXTRow 						; reset row & column
		stz 	EXTColumn
		stz 	EXTPendingWrap				; clear pending wrap
		lda 	#<EXTMemory					; set address in I/O memory
		sta 	EXTAddress
		lda 	#>EXTMemory
		sta 	EXTAddress+1
		; fall through to set hardware cursor

;;
; Position the hardware cursor.
;
; Sets the hardware cursor position on the display based on `EXTColumn`
; and `EXTRow` values.
;
; \in EXTColumn     The column position for the cursor (0-based).
; \in EXTRow        The row position for the cursor (0-based).
; \sideeffects      - Zeroes I/O page register 1.
;                   - Modifies register `A`.
;                   - Updates hardware cursor registers $D014-$D017.
;;
EXTSetHardwareCursor:
        lda 	EXTSuppressCursor 			; check if cursor updates suppressed
        bne 	_EXTSHCExit 				; if non-zero, skip update
        stz 	1 							; I/O Page zero
        lda 	EXTColumn
        sta 	$D014 						; set cursor position
        stz 	$D015
        lda 	EXTRow
        sta 	$D016
        stz 	$D017
_EXTSHCExit:
        rts


;;
; Set current line address based on row position.
;
; Calculates and sets the `EXTAddress` pointer to the start of the line
; specified by `EXTRow`. Uses the precomputed row offset table for fast
; address calculation.
;
; \in 	EXTRow      The row number to set as current line (0-based).
; \out  EXTAddress	Pointer to the start of the specified row.
; \sideeffects      - Modifies registers `A` and `Y`.
;                   - Updates `EXTAddress` with calculated line address.
; \see     			EXTScreenRowOffsets, EXTMemory, EXTRow, EXTAddress, EXTColumn
;;
Export_EXTSetCurrentLine:
		lda     EXTRow						; `A` holds the current row

		; lookup the corresponding row offset
		asl 	a							; multiply row index by 2 to get byte index
		tay									; `Y` holds the byte index of the row offset

		; add row offset to address
		clc
		lda 	#<EXTMemory					; `A` = low byte of screen memory
		adc 	EXTScreenRowOffsets,y		; add the row offset
		sta 	EXTAddress					; store low byte of the line address

		lda 	#>EXTMemory					; `A` = high byte of screen memory
		adc 	EXTScreenRowOffsets+1,y		; add the row offset
		sta 	EXTAddress+1				; store high byte of the line address
        rts

		.send code
