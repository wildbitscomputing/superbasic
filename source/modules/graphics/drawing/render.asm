; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		render.asm
;		Purpose:	Graphic Renderer
;		Created:	9th October 2022
;		Reviewed: 	No
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;							Render : A (size) YX (Data retrival)
;
; ************************************************************************************************

GXDrawGraphicElement:
		sta 	gxSize 						; save size
		dec 	a
		sta 	gxMask 						; and mask

		lda 	gxBitmapsOn 				; check BMP on
		beq 	_GXSLFail

		lda 	gxY0 						; push Y on stack
		pha

		sty 	gxAcquireVector+1 			; and acquisition vector
		stx 	gxAcquireVector
		jsr 	GXOpenBitmap 				; open the bitmap.

		lda 	gxUseMode 					; scale bits
		lsr 	a
		lsr 	a
		lsr 	a
		and		#7
		inc 	a
		sta 	gxScale

		stz 	gxzTemp1					; start first line
_GXGELoop:
		lda 	gxzTemp1 					; current line number to read.
		bit 	gxUseMode 					; check for flip.
		bpl		_GXNoVFlip
		lda 	gxMask
		sec
		sbc 	gxzTemp1
_GXNoVFlip:

		tax 								; get the Xth line.
		jsr 	_GXCallAcquire 				; get that data.
		lda 	gxScale 					; do scale identical copies of that line.
		sta 	gxzTemp1+1
_GXGELoop2:
		lda 	gxY0 						; off screen
		cmp 	gxHeight
		bcs 	_GXDGEExit

		jsr 	GXRenderOneLine 			; render line
		dec 	gxzTemp1+1 					; scale times.
		bne 	_GXGELoop2
		inc 	gxzTemp1 					; done all lines.
		lda 	gxzTemp1
		cmp 	gxSize
		bne 	_GXGELoop
_GXDGEExit:
		pla 								; restore Y for next time
		sta 	gxY0
		;
		ldx 	gxScale 					; get scale (1-8)
_GXShiftLeft:
		clc
		lda 	gxSize
		adc 	gxX0
		sta 	gxX0
		bcc 	_GXSLNoCarry
		inc 	gxX0+1
_GXSLNoCarry:
		dex
		bne 	_GXShiftLeft

		jsr 	GXCloseBitmap
		clc
		rts
_GXSLFail:
		sec
		rts

_GXCallAcquire:
		jmp 	(gxAcquireVector)

; ************************************************************************************************
;
;										Render one line.
;
; ************************************************************************************************

GXRenderOneLine:
		jsr 	gxPositionCalc 				; calculate position/offset.
		ldy 	gxOffset 					; Y contains position.
		stz 	gxzTemp2 					; do size pixels
_GXROLLoop1:
		lda 	gxScale 					; set to do 'scale' times
		sta 	gxzTemp2+1
_GXROLLoop2:
		lda 	gxzTemp2 					; get current pixel
		bit 	gxMode 						; check H Flip
		bvc 	_GXNoHFlip
		lda 	gxMask
		sec
		sbc 	gxzTemp2
_GXNoHFlip:
		tax 								; read from the pixel buffer
		lda 	gxPixelBuffer,x
		bne 	_GXDraw 					; draw if non zero
		lda 	gxUseMode 					; check to see if solid background
		and 	#4
		beq 	_GXZeroPixel
_GXDraw:
		lda 	(gxzScreen),y
		and 	gxANDValue
		eor 	gxPixelBuffer,x
		sta 	(gxzScreen),y
_GXZeroPixel:
		iny 								; advance pointer
		bne 	_GXNoShift
		inc 	gxzScreen+1 				; carry to next
		jsr 	GXDLTCheckWrap				; check for new page.
_GXNoShift:
		dec 	gxzTemp2+1 					; do the inner loop gxScale times.
		bne 	_GXROLLoop2
		inc 	gxzTemp2 					; next pixel.
		lda 	gxzTemp2
		cmp 	gxSize
		bne 	_GXROLLoop1
		inc 	gxY0
		rts

		.send code

		.section storage
gxSize:
		.fill 	1
gxMask:
		.fill 	1
gxAcquireVector:
		.fill 	2
gxScale:
		.fill 	1
gxUseMode:
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