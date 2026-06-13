; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		circle.asm
;		Purpose:	Circle drawing code
;		Created:	9th October 2022
;		Reviewed: 	17th February 2022
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;									Draw/Fill Circle
;
; ************************************************************************************************

GXFillCircle: ;; <37:FillCircle>
		lda 	#255 						; A determines fill or not
		bra 	GXCircle
GXFrameCircle: ;; <36:FrameCircle>
		lda 	#0
GXCircle:
		sta 	gxIsFillMode				; save Fill flag
		lda 	gxBitmapsOn
		beq 	_GXCFail
		jsr 	GXSortXY 					; topleft/bottomright
		jsr 	GXOpenBitmap 				; start drawing
		jsr 	GXCircleSetup 				; set up for drawing
		stz 	gxYChanged
_GXCircleDraw:
		lda 	gxxCentre					; while x <= y
		cmp 	gxYCentre
		bcc 	_GXCircleContinue
		bne 	_GXNoLast  					; fix up if x < y
		jsr 	GXPlot1  
_GXNoLast:
		jsr 	GXCloseBitmap 				; close the bitmap
		clc
		rts

_GXCircleContinue:
		jsr 	GXPlot2 					; draw it
		jsr 	GXCircleMove 				; adjust the coordinates
		bra 	_GXCircleDraw

_GXCFail:
		sec
		rts

; ************************************************************************************************
;
;									Plot line/points
;
; ************************************************************************************************

GXPlot2:
		jsr 	GXPlot1 						; plot and swap, fall through does twice
GXPlot1:
		lda 	gxYCentre 						; if y = 0, don't do it twice (xor)
		beq 	_GXPlot1Only
		jsr 	GXPlot0 						; plot and negate
_GXPlot1Only:
		jsr 	GXPlot0 						; twice, undoing negation
		lda 	gxxCentre 						; swap X and Y
		ldx	 	gxYCentre
		sta 	gxYCentre
		stx 	gxxCentre
		lda 	gxYChanged 						; toggle Y Changed flag
		lda 	#$FF
		sta 	gxYChanged
		rts
		jsr 	GXPlot0 						; do once

		rts

		;
		;		Draw offset gX (always +ve) gY (can be -ve)
		;
GXPlot0:lda 	gxIsFillMode 					; outline mode, always draw as X or Y will change
		beq 	_GXPlot0Always
		lda 	gxYChanged						; fill mode, only draw if changed.
		beq 	GXPlot0Exit
_GXPlot0Always:
		ldx 	#2 								; copy Y1-A => Y0
		lda 	gxYCentre
		jsr 	GXSubCopy
		ldx 	#0 								; copy X1-A => X0,
		lda 	gxxCentre
		jsr 	GXSubCopy
		pha 									; save last offset X
		jsr 	gxPositionCalc 					; calculate position/offset.
		pla
		;
		asl 	a 								; store 2 x last offset in gxzTemp0
		sta 	gxzTemp0
		stz 	gxzTemp0+1
		rol 	gxzTemp0+1
		;
		lda 	gxIsFillMode
		adc 	#128
		jsr 	GXDrawLineTemp0 				; routine from Rectangle.
		sec 									; GY = -GY
		lda 	#0
		sbc 	gxYCentre
		sta 	gxYCentre
GXPlot0Exit:
		rts
;
;		16 bit calc of XY1 - A => XY0 ; A is in gxzTemp0
;
GXSubCopy:
		sta 	gxzTemp0
		stz 	gxzTemp0+1
		and 	#$80
		beq 	_GXNoSx
		dec 	gxzTemp0+1
_GXNoSx:
		;
		sec
		lda 	gxX1,x
		sbc 	gxzTemp0
		sta 	gxX0,x
		lda 	gxX1+1,x
		sbc 	gxzTemp0+1
		sta 	gxX0+1,x
		lda 	gxzTemp0 						; return A
		rts

; ************************************************************************************************
;
;						Adjust coordinates (e.g. the coord change part)
;
; ************************************************************************************************

GXCircleMove:
		stz 	gxYChanged 					; clear Y changed flag
		lda 	gxzTemp1+1 					; check sign of D
		bpl 	_GXEMPositive
		;
		;		D < 0 : inc X, add 4x+6
		;
		inc 	gxxCentre 					; X++
		lda 	gxxCentre
		jsr 	_GXAdd4TimesToD 			; add 4 x A to D
		lda 	#6  						; and add 6
		bra 	_GXEMAddD
		;
		;		D >= 0 : inc X, dec Y, add 4(x-y)+10
		;
_GXEMPositive:
		inc 	gxxCentre					; X++
		dec 	gxYCentre 					; Y--
		;
		sec 								; calculate X-Y
		lda 	gxxCentre
		sbc 	gxYCentre
		jsr 	_GXAdd4TimesToD 			; add 4 x A to D
		lda 	#10  						; and add 10
		dec 	gxYChanged
_GXEMAddD:
		clc
		adc 	gxzTemp1
		sta 	gxzTemp1
		bcc 	_GXEMNoCarry
		inc 	gxzTemp1+1
_GXEMNoCarry:
		rts
;
;		Add 4 x A (signed) to D
;
_GXAdd4TimesToD:
		sta 	gxzTemp0 					; make 16 bit signed.
		and 	#$80
		beq 	_GXA4Unsigned
		lda 	#$FF
_GXA4Unsigned:
		sta 	gxzTemp0+1
		;
		asl 	gxzTemp0  					; x 4
		rol 	gxzTemp0+1
		asl 	gxzTemp0
		rol 	gxzTemp0+1
		;
		clc 								; add
		lda		gxzTemp0
		adc 	gxzTemp1
		sta 	gxzTemp1
		lda		gxzTemp0+1
		adc 	gxzTemp1+1
		sta 	gxzTemp1+1
		rts

; ************************************************************************************************
;
;										Circle setup
;
; ************************************************************************************************

GXCircleSetup:
		;
		;		Calculate R (y1-y0)/2, height in slot 1
		;
		sec
		lda 	gxY1
		sbc 	gxY0
		lsr 	a
		sta 	gxRadius
		;
		;		Calculate centres (x0+x1)/2
		;
		ldx 	#0
		jsr 	_GXCalculateCentre
		ldx 	#2
		jsr 	_GXCalculateCentre
		;
		;		X = 0, Y = R
		;
		stz 	gxxCentre
		lda 	gxRadius
		sta 	gxYCentre
		;
		;		d = 3 - 2 x R
		;
		asl 	a 							; R x 2
		sta 	gxzTemp0
		sec
		lda 	#3
		sbc 	gxzTemp0
		sta 	gxzTemp1
		lda 	#0
		sbc 	#0
		sta 	gxzTemp1+1
		rts
;
;		Calculates midpoint for X/Y
;
_GXCalculateCentre:
		sec
		lda 	gxX1,x
		adc 	gxX0,x
		sta 	gxX1,x
		lda 	gxX1+1,x
		adc 	gxX0+1,x
		lsr 	a
		sta 	gxX1+1,x
		ror 	gxX1,x
		rts

		.send code

		.section storage
gxRadius:
		.fill 	1
gxxCentre:
		.fill 	1
gxYCentre:
		.fill 	1
gxIsFillMode:
		.fill 	1
gxYChanged:
		.fill  	1
		.send storage

; ************************************************************************************************
;
;		Usage
;			gxzScreen and gxOffset are used as usual
;			gxzTemp0 holds the line length and is general workspace.
;			x1,y1 hold the circle centre
;			gX,gY are the coordinates x,y (note x, y both < 128)
;			d is stored in gxzTemp1 (2 bytes)
;			r is stored in gxRadius
;
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