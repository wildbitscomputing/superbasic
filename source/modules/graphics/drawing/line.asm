; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		line.asm
;		Purpose:	Line drawing code
;		Created:	6th October 2022
;		Reviewed: 	17th February 2023
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;									Draw line (see lines2.py)
;
; ************************************************************************************************

GXLine: ;; <33:Line>
		lda 	gxBitmapsOn					; check bitmap on.
		beq 	_GXLFail
		jsr 	GXOpenBitmap 				; access it.
		jsr 	GXSortY						; sort pairs so Y1 >= Y0 e.g. top to bottom.
		jsr 	GXLineSetup 				; the calculations in the linescanner constructor
		jsr 	gxPositionCalc 				; calculate position/offset.
_GXDrawLoop:
		ldy 	gxOffset 					; draw the pixel
		lda 	(gxzScreen),y
		.plotpixel
		sta 	(gxzScreen),y

		jsr 	GXLineIsComplete 			; is the line complete ?
		beq 	_GXLExit
		jsr 	GXLineAdvance 				; code as per advance method
		bra 	_GXDrawLoop
_GXLExit:
		jsr 	GXCloseBitmap 				; restore and return success.
		clc
		rts
_GXLFail:
		sec
		rts

; ************************************************************************************************
;
;								Is line complete , return Z if so
;
; ************************************************************************************************

GXLineIsComplete:
		lda 	gxIsDiffYLarger 			; is dy larger
		bne 	_GXLICCompareY 				; if so compare Y1 versus Y0

		lda 	gxX0 						; compare X, LSB and MSB
		eor 	gxX1
		bne 	_GXLICExit
		lda 	gxX0+1
		eor 	gxX1+1
_GXLICExit:
		rts

_GXLICCompareY: 							; compare Y
		lda 	gxY1
		eor 	gxY0
		rts

; ************************************************************************************************
;
;								  Advance the line position
;
; ************************************************************************************************

GXLineAdvance:
		clc 								; add adjust to position
		lda 	gxPosition
		adc 	gxAdjust
		sta 	gxPosition
		stz 	gxAddSelect 				; clear add select flag
		bcs 	_GXLAOverflow 				; if carry out, overflowed.
		cmp 	gxTotal 					; if exceeded total
		bcc 	_GXLANoExtra
_GXLAOverflow:
		dec 	gxAddSelect 				; set addselect to $FF
		sec 								; subtract total and write back
		sbc 	gxTotal
		sta 	gxPosition
		;
_GXLANoExtra:
		lda 	gxIsDiffYLarger
		beq 	_GXDXLarger
		;
		;		dy larger, so always do y and sometimes x
		;
		jsr 	GXIncrementY
		lda 	gxAddSelect
		beq 	_GXLAExit
		jsr 	gxAdjustX
		bra 	_GXLAExit
		;
		;		dx larger, so always do x and sometimes Y
		;
_GXDXLarger:
		jsr 	gxAdjustX
		lda 	gxAddSelect
		beq 	_GXLAExit
		jsr 	GXIncrementY
_GXLAExit:
		rts

; ************************************************************************************************
;
;										 Advance X/Y
;
; ************************************************************************************************

gxAdjustX:
		lda 	gxDXNegative
		bpl 	_GXAXRight
		;
		;		Go left.
		;
		lda 	gxX0
		bne 	_GXAXNoBorrow
		dec 	gxX0+1
_GXAXNoBorrow:
		dec 	gxX0
		;
		dec 	gxOffset 					; pixel left
		lda 	gxOffset
		cmp 	#$FF
		bne 	_GXAYExit 					; underflow
		dec 	gxzScreen+1 					; borrow
		lda 	gxzScreen+1 					; gone off page
		cmp 	#GXMappingAddress >> 8
		bcs 	_GXAYExit
		clc
		adc 	#$20 						; fix up
		sta 	gxzScreen+1
		dec 	GXEditSlot 				; back one page
_GXAYExit:
		rts
		;
		;		Go right.
		;
_GXAXRight:
		inc 	gxX0
		bne 	_GXAXNoCarry
		inc 	gxX0+1
_GXAXNoCarry:
		inc 	gxOffset 					; pixel right
		bne 	_GXAXExit 					; if not overflowed, exit.
		inc 	gxzScreen+1 					; next line
		lda 	gxzScreen+1
		cmp 	#((GXMappingAddress+$2000) >> 8) ; on to the next page ?
		bcc 	_GXAXExit
		sbc 	#$20 						; fix up
		sta 	gxzScreen+1
		inc 	GXEditSlot 				; next page
_GXAXExit:
		rts

GXIncrementY:
		inc 	gxY0
		jmp 	GXMovePositionDown


; ************************************************************************************************
;
;										Set up the draw
;
; ************************************************************************************************

GXLineSetup:
		;
		; 		diffY = (y1 - y0) / 2
		;
		lda 	gxY1
		sec
		sbc 	gxY0
		lsr 	a
		sta 	gxDiffY
		;
		; 		diffX = |(x1-x0)|/2 , and set the flag for dX being negative.
		;
		stz 	gxDXNegative 				; clear -ve flag
		sec
		lda 	gxX1
		sbc 	gxX0
		sta 	gxDiffX
		;
		lda 	gxX1+1 						; calculate MSB
		sbc 	gxX0+1
		ror 	a 							; rotate bit into DiffX halving it
		ror 	gxDiffX
		asl 	a
		bpl 	_GDXNotNegative
		lda 	#0 							; make absolute value of |dx|
		sec
		sbc 	gxDiffX
		sta 	gxDiffX
		dec 	gxDXNegative 				; -ve flag = $FF.
_GDXNotNegative:
		;
		; 		See if dy > dx, and set adjust and total accordingly.
		;
		stz 	gxIsDiffYLarger 			; clear larger flag

		lda 	gxDiffY 					; set adjust and total.
		sta 	gxAdjust
		lda 	gxDiffX
		sta 	gxTotal

		lda 	gxDiffY 					; if dy > dx
		cmp 	gxDiffX
		bcc 	_GDXNotLarger
		dec 	gxIsDiffYLarger 			; set the dy larger flag
		lda 	gxDiffX 					; set adjust and total other way round
		sta 	gxAdjust
		lda 	gxDiffY
		sta 	gxTotal
_GDXNotLarger:
		;
		;		Pos = total / 2
		;
		lda 	gxTotal
		lsr 	a
		sta 	gxPosition
		rts

		.send code

; ************************************************************************************************
;
;										Data for Line drawing
;
; ************************************************************************************************

		.section storage
gxDiffX:
		.fill 	1
gxDiffY:
		.fill 	1
gxIsDiffYLarger:
		.fill 	1
gxDXNegative:
		.fill 	1
gxPosition:
		.fill 	1
gxAdjust:
		.fill 	1
gxTotal:
		.fill 	1
gxAddSelect:
		.fill 	1

		.send storage

; ************************************************************************************************
;
;									Changes and Updates
;
; ************************************************************************************************
;
;		Date			Notes
;		==== 			=====
;
; ************************************************************************************************