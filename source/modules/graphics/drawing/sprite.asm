; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		sprite.asm
;		Purpose:	Sprite Functions
;		Created:	11th October 2022
;		Reviewed: 	No
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;									Select sprite
;
; ************************************************************************************************

GXSelect: ;; <7:SpriteUse>
		lda 	gxSpritesOn
		beq 	_GXSFail

		lda 	gxzTemp0 					; illegal sprite #
		cmp 	#64
		bcs 	_GXSFail
		sta 	GSCurrentSpriteID

		ldy 	gxzTemp0+1 					; control value.
		lda  	#0 							; multiply sprite # x 8 => A
		asl 	gxzTemp0
		asl 	gxzTemp0
		asl 	gxzTemp0
		rol 	a
		adc 	#$D9 						; sprite area
		sta 	GSCurrentSpriteAddr+1 		; address to GSCurrentSprite and gxzTemp
		sta 	gxzTemp0+1
		lda 	gxzTemp0
		sta 	GSCurrentSpriteAddr
		clc
		rts

_GXSFail:
		sec
		rts

; ************************************************************************************************
;
;							Select sprite image enable/disable control
;
; ************************************************************************************************

GXSelectImage: ;; <8:SpriteImage>
		lda 	gxSpritesOn
		beq 	_GXSIFail

		lda 	GSCurrentSpriteAddr+1 		; check sprite selected
		beq 	_GXSIFail 					; (checking the MSB)

		stz 	1

		lda 	gxzTemp0+1 					; push show/hide on the stack.
		bne 	_GXSIHide

		lda 	gxzTemp0 					; sprite image
		pha
		jsr 	GXOpenBitmap
		pla
		jsr 	GXFindSprite
		bcs 	_GXSICloseFail 				; no image

		ldy 	#1
		lda 	GSCurrentSpriteAddr
		sta 	gxzTemp0
		lda 	GSCurrentSpriteAddr+1
		sta 	gxzTemp0+1

		lda 	gxSpriteOffset
		sta	 	(gxzTemp0),y
		clc
		lda 	gxSpriteOffset+1
		adc 	gxSpriteOffsetBase
		iny
		sta	 	(gxzTemp0),y

		lda 	gxSpriteOffsetBase+1
		adc 	#0
		iny
		sta	 	(gxzTemp0),y

		lda 	gxSizeBits 					; get raw size
		eor 	#3 							; make it right (00=32 etc.)
		rol 	a 							; x 2
		asl 	a 							; x 4
		asl 	a 							; x 8
		asl 	a 							; x 16
		ora 	gxSpriteLUT 				; Or with LUT
		asl 	a 							; 1 shift
		ora 	#1 							; enable sprite.
		sta 	(gxzTemp0) 					; and write back
		jsr 	GXCloseBitmap
		;
		ldx 	GSCurrentSpriteID 			; point to sprite entries.
		lda 	gxSpriteHigh,x 				; clear upper two bits of size
		and 	#$3F
		sta 	gxSpriteHigh,x
		lda 	gxSizeBits 					; get bit size
		ror 	a 							; shift into bits 6/7
		ror 	a
		ror 	a
		and 	#$C0
		ora 	gxSpriteHigh,x 				; put in  upper 2 bits of sprite data
		sta 	gxSpriteHigh,x
		;
		lda 	gxSpriteLow,x 				; clear hidden flag.
		and 	#$7F
		sta 	gxSpriteLow,x
		clc
		rts

_GXSICloseFail:
		jsr 	GXCloseBitmap
_GXSIFail:
		sec
		rts

_GXSIHide:
		lda 	GSCurrentSpriteAddr  		; get Sprite h/w address and write there
		sta 	gxzTemp0
		lda 	GSCurrentSpriteAddr+1
		sta 	gxzTemp0+1
		lda 	#0
		sta 	(gxzTemp0)
		ldx 	GSCurrentSpriteID 			; get sprite ID
		lda 	gxSpriteLow,x 				; set the hidden bit.
		ora 	#$80
		sta 	gxSpriteLow,x
		clc
		rts


; ************************************************************************************************
;
;									Move Sprite
;
; ************************************************************************************************

GXMoveSprite: ;; <41:SpriteMove>
		lda 	gxSpritesOn
		beq 	_GXSIFail

		lda 	GSCurrentSpriteAddr+1 		; check sprite selected
		beq 	_GXSIFail

		sta 	gxzTemp0+1
		ldy 	#4
		lda 	GSCurrentSpriteAddr
		sta 	gxzTemp0
		;
		ldx 	GSCurrentSpriteID 			; get the size from the upper two bits
		lda 	gxSpriteHigh,x
		rol 	a	 						; into bits 0,1.
		rol 	a
		rol 	a
		and 	#3
		tax
		lda 	_GXMSOffset,x 				; get 32-SpriteSize/2
		pha
		;
		clc
		adc 	gxX0						; copy position.
		sta 	(gxzTemp0),y
		iny
		lda 	gxX0+1
		adc 	#0
		sta 	(gxzTemp0),y
		iny
		pla
		clc
		adc 	gxY0
		sta 	(gxzTemp0),y
		lda 	#0
		adc 	#0
		iny
		sta 	(gxzTemp0),y
		;
		lsr 	gxX0+1 						; divide X by 4
		ror 	gxX0
		lsr 	gxX0
		;
		lsr 	gxY0 						; divide Y by 4
		lsr 	gxY0

		ldx 	GSCurrentSpriteID 			; copy X/4 and Y/4 into the status bytes
		lda 	gxSpriteLow,x
		and 	#$80
		ora 	gxX0
		sta 	gxSpriteLow,x

		lda 	gxSpriteHigh,x
		and 	#$C0
		ora 	gxY0
		sta 	gxSpriteHigh,x
		clc
		rts

_GXSIFail:
		sec
		rts

_GXMSOffset:
		.byte 	32-8/2
		.byte 	32-16/2
		.byte 	32-24/2
		.byte 	32-32/2
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