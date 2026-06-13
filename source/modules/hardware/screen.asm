.section code

;;
; Read character from screen at specified coordinates.
;
; Retrieves the character stored at the given row and column position on the
; screen. Uses precomputed row offsets for efficient address calculation and
; indirect addressing for memory access. No bounds checking is performed on
; the coordinates; the caller must ensure that the row and column coordinates
; are within valid ranges.
;
; \in A         Row coordinate (0-based).
; \in Y         Column coordinate (0-based).
; \out A        Character at the specified screen position.
; \sideeffects  - Modifies `A` register and `zTemp0`.
; \see          EXTScreenRowOffsets, EXTMemory, zTemp0
;;
Export_EXTScreenAt:
		phy									; save column coordinate on stack

		; lookup the corresponding row offset
		asl 	a							; multiply row index by 2 to get byte index
		tay									; `Y` holds the byte index of the row offset

		lda 	#2 							; select text page
		sta 	$0001

		; add row offset to the beginning of the text memory address,
		; store the result in `zTemp0`
		clc
		lda 	#<EXTMemory					; `A` = low byte of screen memory
		adc 	EXTScreenRowOffsets,y		; add the row offset
		sta 	zTemp0						; store low byte of the line address

		lda 	#>EXTMemory					; `A` = high byte of screen memory
		adc 	EXTScreenRowOffsets+1,y		; add the row offset
		sta 	zTemp0+1					; store high byte of the line address

		; read character from screen memory at (row, column)
		ply									; restore column index into `Y`
		lda 	(zTemp0),y					; zTemp0 + Y = character address

		rts

		.send code
