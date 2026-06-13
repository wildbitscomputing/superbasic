;;
; External hardware functions
;;

.section code

;;
; Initialize hardware display system.
;
; Performs initialization of the display hardware and text console system.
; Sets up screen dimensions, cursor, colors, and clears the display.
; This function must be called before using any other display functions.
;
; \out EXTTextColour	0x52
; \out EXTScreenWidth	80
; \out EXTScreenHeight	60
;
; \sideeffects	- Sets `EXTTextColour` to $52 (default color)
;				- Sets screen dimensions to 80×60 characters
;				- Enables hardware cursor with character 214
;				- Clears screen and homes cursor
;				- Uses registers `A`, `X`, `Y` and `zTemp0`, `zTemp1` for calculations
;				- Modifies hardware registers $D004, $D008, $D009, $D010, $D012, and $D658
;				- Calls `EXTClearScreenCode`
;
; \see;			EXTClearScreenCode, EXTLoadStartupPalette, EXTScreenWidth, EXTScreenHeight
;;
Export_EXTInitialize:
		stz 	$0001 						; Access I/O page 0
		stz 	$D004 						; Disable border
		stz 	$D008
		stz 	$D009
		lda 	#1+8						; Timer On at 70Hz counting up.
		sta 	$D658

		;
		; Set text color
		;
		lda 	#$52
		sta 	EXTTextColour

		;
		; Set screen dimensions
		;
		lda 	#80 						; number of columns
		sta 	EXTScreenWidth
		lda 	#60							; number of rows
		sta 	EXTScreenHeight

		; initial pending wrap state
		stz 	EXTPendingWrap				;
		lda 	#1							;
		sta 	EXTPendingWrapEnabled		;
		stz 	EXTSuppressCursor			; enable hardware cursor updates

		;
		; Precompute the screen row offsets
		;
		._precompute_screen_row_offsets

		;
		; Set up the hardware cursor
		;
		lda 	#1+4 						; enable cursor
		sta 	$D010
		lda 	#214 						; cursor character
		sta 	$D012

		jsr 	EXTLoadStartupPalette		; load the boot palette
		jsr 	EXTClearScreenCode 			; clear the screen and home cursor

		rts

;;
; Precompute screen row offset table.
;
; Calculates and stores 16-bit memory offsets for each screen row in the
; `EXTScreenRowOffsets` table. Each offset represents the distance from the
; screen base address (`EXTMemory`) to the start of that row.
;
; \in EXTScreenHeight
; \in EXTScreenWidth
; \in EXTScreenRowOffsets
; \sideeffects				- Uses registers `A` and `Y`
;							- Uses variables `zTemp0` and `zTemp1`
;;
_precompute_screen_row_offsets .macro
		lda		EXTScreenHeight				; get screen height
		sta		zTemp0 						; `zTemp0` = row counter
		;
		; Check if screen height is too large
		;
		bpl		loop_start					; screen height is less then 128, continue
		.error_initerror					; bail out with error

	loop_start:
		stz		zTemp1						; zTemp1 holds the current offset
		stz		zTemp1+1					;
		ldy		#0			  				; `Y` = offset byte index

	next_row:
		;
		; Store the current offset in the row offsets table
		;
		lda		zTemp1						; get low byte of offset
		sta		EXTScreenRowOffsets,y		; store low byte
		iny
		lda		zTemp1+1					; get high byte of offset
		sta		EXTScreenRowOffsets,y		; store high byte
		iny
		;
		; Add screen width to offset
		;
		clc
		lda		zTemp1						; `A` holds the low byte of offset
		adc		EXTScreenWidth				; add screen width
		sta		zTemp1						; store low byte of new offset
		bcc		no_carry					; if no carry, we are done
		inc		zTemp1+1					; increment high byte of offset if carry occurred

	no_carry:
		dec		zTemp0						; decrement row counter
		bne		next_row					; if not zero, precompute the next row's offset
		.endmacro

.send code
