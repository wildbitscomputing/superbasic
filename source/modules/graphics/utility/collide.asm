; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		collide.asm
;		Purpose:	Check if two sprites collide.
;		Created:	1st November 2022
;		Reviewed: 	No
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;					 				Collision of Sprites
;
; ************************************************************************************************

GXCollide: 	;; <9:SpriteCollide>
		lda 	gxzTemp0 					; check if sprite numbers are legal.
		tax
		ora 	gxzTemp0+1
		and 	#$C0
		sec
		bne 	_GXCollideFail 				; if either >= 64, fail.
		ldy 	gxzTemp0+1 					; at this point X is 1st sprite and Y is 2nd sprite.
		;
		lda 	gxSpriteLow,y 				; check if either hidden bit is set
		ora 	gxSpriteLow,x
		bmi 	_GXOkayFail 				; if either hidden, then they cannot collide.
		;
		lda 	gxSpriteHigh,y 				; need to calculate sum of sizes.
		and 	#$C0 						; isolate size bits of sprite Y
		sta 	gxzTemp1 					; save temporarily
		lda 	gxSpriteHigh,x
		and 	#$C0 						; isolate size bits of sprite X
		clc
		adc 	gxzTemp1 					; add only size bits (no y-position overflow)
		;
		;		So for 24 (10) and 32 (11) after AND CS:A is 1:0100 0000
		;		After the shifts it is 1:0100 (20)
		;		Adding the 8 (allowing for 00) => 28 which is (24+32)/2
		;
		;		Then adjust for coordinates being stored / 2
		;
		and 	#$C0 					 	; mask off
		ror 	a 							; 5/6/7
		lsr 	a 							; 4/5/6
		lsr 	a 							; 3/4/5
		lsr 	a 							; 2/3/4
		clc
		adc 	#$08
		lsr 	a 							; adjust because all coordinates are divided by 4 to store.
		lsr 	a
		sta 	gxzTemp1 					; so the difference between the centres has to be less than this.
		;
		lda 	gxSpriteHigh,y 				; calculate y1-y0
		and 	#$3F
		sta 	gxzTemp1+1
		sec
		lda 	gxSpriteHigh,x
		and 	#$3F
		sbc 	gxzTemp1+1
		bcs 	_GXCAbs1 					; calculate |y1-y0|
		eor 	#$FF
		inc 	a
_GXCAbs1:
		cmp 	gxzTemp1 					; if >= difference then no overlap
		bcs 	_GXOkayFail
		sta 	gxzTemp1+1 					; save |y1-y0|
		;
		sec 								; calculate |x1-x0|
		lda 	gxSpriteLow,y
		sbc 	gxSpriteLow,x
		bcs 	_GXCAbs2
		eor 	#$FF
		inc 	a
_GXCAbs2:
		cmp 	gxzTemp1 					; if >= difference then no overlap
		bcs 	_GXOkayFail
		;
		cmp 	gxzTemp1+1 					; is it less than the previous one.
		bcc 	_GXCHaveLowest
		lda 	gxzTemp1+1 					; if not, that's the smallest difference.
_GXCHaveLowest:
		asl 	a 							; scale to allow for >> 2
		asl 	a
		clc
		rts

_GXOkayFail:
		clc
_GXCollideFail:
		lda 	#$FF
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