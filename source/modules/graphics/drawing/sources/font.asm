; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		font.asm
;		Purpose:	Font source handler
;		Created:	9th October 2022
;		Reviewed: 	No
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;									Access from font memory
;
; ************************************************************************************************

GXFontHandler: ;; <5:DrawFont>
		lda 	gxzTemp0+1 					; eor with mode
		eor 	gxMode
		sta 	gxUseMode

		stz 	gxzTemp0+1 					; gxzTemp0 is font #
		asl	 	gxzTemp0 					; x 2
		rol	 	gxzTemp0+1
		asl	 	gxzTemp0 					; x 4
		rol	 	gxzTemp0+1
		asl	 	gxzTemp0 					; x 8
		rol	 	gxzTemp0+1

		lda 	gxzTemp0+1 					; put in page C0
		ora 	#$C0
		sta 	gxzTemp0+1

		lda 	#8 							; size 8x8
		ldx 	#GXGetGraphicDataFont & $FF ; XY = Graphic Data retrieval routine
		ldy 	#GXGetGraphicDataFont >> 8
		jmp 	GXDrawGraphicElement
;
;		Get line X of the graphics into the Pixel Buffer
;
GXGetGraphicDataFont:
		txa 								; X->Y
		tay
		ldx 	1 							; preserve old value
		lda 	#1 							; access page 1 (font memory)
		sta 	1
		lda 	(gxzTemp0),y 				; read the font element.
		stx 	1 							; put old value back.
		ldx 	#0 							; do 8 times
_GXExpand:
		stz 	gxPixelBuffer,x 			; zero in pixel buffer
		asl 	a 							; shift bit 7 into C
		bcc 	_GXNoPixel
		pha 								; if set, set pixel buffer to current colour.
		lda 	gxColour
		sta 	gxPixelBuffer,x
		pla
_GXNoPixel:
		inx 								; do the whole byte.
		cpx 	#8
		bne 	_GXExpand
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