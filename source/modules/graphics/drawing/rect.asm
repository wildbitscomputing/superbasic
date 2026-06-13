; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		rect.asm
;		Purpose:	Rectangle/Solid Rectangle drawing code
;		Created:	8th October 2022
;		Reviewed: 	17th February 2022
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;									Draw/Fill Rectangle
;
; ************************************************************************************************

GXFillRectangle: ;; <35:FillRect>
		sec 								; pass carry in for fill/frame
		bra 	GXRectangle
GXFrameRectangle: ;; <34:FrameRect>
		clc
GXRectangle:
		lda 	gxBitmapsOn 				; exit if off.
		beq 	_GXRFail
		php 								; save Fill flag (CS)
		jsr 	GXOpenBitmap 				; start drawing
		jsr 	GXSortXY 					; sort both X and Y so top left/bottom right
		;
		;		Do the top line first.
		;
		jsr 	gxPositionCalc 				; setup gxzScreen, gxOffset and the position.
		sec 								; sec = Draw line
		jsr 	GXDrawLineX1X0 				; draw a line length X1-X0

		lda 	gxY0 						; reached end of rectangle ?
		cmp 	gxY1 						; e.g. 1 pixel high.
		beq 	_GXRectangleExit
_GXRectLoop:
		jsr 	GXMovePositionDown 			; down one.
		inc 	gxY0 						; change Y pos
		lda 	gxY0 						; reached last line
		cmp 	gxY1
		beq 	_GXLastLine
		plp 								; get flag back for solid/edged
		php
		jsr 	GXDrawLineX1X0 				; draw horizontal line
		bra 	_GXRectLoop

_GXLastLine: 								; draw the last solid line.
		sec
		jsr 	GXDrawLineX1X0
_GXRectangleExit:
		pla 								; throw fill flag.
		jsr 	GXCloseBitmap 				; stop drawing and exit
		clc
		rts

_GXRFail:
		sec
		rts

; ************************************************************************************************
;
;					Draw solid line/ends from current position length x1-x0
;
; ************************************************************************************************

GXDrawLineX1X0:
		php 								; save solid/either-end
		sec 								; calculate x1-x0
		lda		gxX1
		sbc 	gxX0
		sta 	gxzTemp0
		lda 	gxX1+1
		sbc 	gxX0+1
		sta 	gxzTemp0+1
		plp
		;
; ************************************************************************************************
;
;					Draw solid line/ends from current position length gxzTemp0
;
; ************************************************************************************************

GXDrawLineTemp0:

		lda 	gxzScreen 					; push gxzScreen, gxOffset and GXEditSlot on stack
		pha
		lda 	gxzScreen+1
		pha
		lda 	gxOffset
		pha
		lda 	GXEditSlot
		pha
		ldy 	gxOffset 					; Y offset
		bcc 	_GXDLTEndPoints 			; if CC draw end points only.
		;
		;		Draw solid line.
		;
_GXDLTLine:
		lda 	(gxzScreen),y 				; set pixel
		.plotpixel
		sta 	(gxzScreen),y
		;
		lda 	gxzTemp0 					; decrement counter
		bne 	_GXDLTNoBorrow
		dec 	gxzTemp0+1 					; borrow, if goes -ve then exit
		bmi 	_GXDLTExit
_GXDLTNoBorrow:
		dec 	gxzTemp0
		iny 								; next slot.
		bne 	_GXDLTLine
		inc 	gxzScreen+1 				; carry to next
		jsr 	GXDLTCheckWrap				; check for new page.
		bra 	_GXDLTLine
		;
		;		Draw end points only.
		;
_GXDLTEndPoints:
		lda 	(gxzScreen),y 				; set pixel
		.plotpixel
		sta 	(gxzScreen),y
		;
		tya 								; advance to right side
		clc
		adc 	gxzTemp0
		tay
		lda 	gxzScreen+1
		adc 	gxzTemp0+1
		sta 	gxzScreen+1
		jsr 	GXDLTCheckWrap 				; fix up.

		lda 	(gxzScreen),y 				; set pixel on the right
		.plotpixel
		sta 	(gxzScreen),y

_GXDLTExit: 								; restore screen position.
		pla
		sta 	GXEditSlot
		pla
		sta 	gxOffset
		pla
		sta 	gxzScreen+1
		pla
		sta 	gxzScreen
		rts
;
;		Check if gxzScreen needs wrapping round.
;
GXDLTCheckWrap:
		lda 	gxzScreen+1 				; check end of page
		cmp 	#((GXMappingAddress+$2000) >> 8)
		bcc 	_GXDLTCWExit
		sbc 	#$20 						; fix up
		sta 	gxzScreen+1
		inc 	GXEditSlot 					; next bitmap vram page.
_GXDLTCWExit:
		rts

		.send code

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