; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		sprite.asm
;		Purpose:	Sprite Source Handler
;		Created:	9th October 2022
;		Reviewed: 	No
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;								Access from Sprite Memory
;
; ************************************************************************************************

GXSpriteHandler: ;; <6:DrawSprite>
		lda 	gxSpritesOn 				; sprites on ?
		beq 	_GXSHExit
		;
		lda 	gxzTemp0+1 					; eor with mode
		eor 	gxMode
		sta 	gxUseMode

		ldx 	gxzTemp0 					; sprite #
		phx
		jsr 	GXOpenBitmap 				; can access sprite information
		pla
		jsr 	GXFindSprite 				; get the sprite address
		php
		jsr 	GXCloseBitmap
		plp
		bcs		_GXSHExit 					; exit if find failed.

		lda 	gxSizePixels 				; return size
		ldx 	#GXSpriteAcquire & $FF
		ldy 	#GXSpriteAcquire >> 8
		jsr 	GXDrawGraphicElement
_GXSHExit:
		rts

GXSpriteAcquire:
		lda 	gxSpritePage				; point to base page
		sta 	GXEditSlot
		;
		;		Multiply Row Number by Sprite Size (0,1,2,3) + 1 * 8 e.g. 8,16,24 or 32
		;
		stx 	gxzTemp0 					; row number x 1,2,3,4
		lda 	#0
		ldx 	gxSizeBits
_GXTimesRowNumber:
		clc
		adc 	gxzTemp0
		dex
		bpl 	_GXTimesRowNumber
		stz 	gxzTemp0+1
		asl 	a 							; row x 2,4,6,8
		rol 	gxzTemp0+1
		asl 	a 							; row x 4,8,12,16
		rol 	gxzTemp0+1
		asl 	a 							; row x 8,16,24,32
		rol 	gxzTemp0+1
		sta 	gxzTemp0
		;
		;		Add base address of sprite
		;
		clc 								; add base address.
		lda 	gxzTemp0
		adc 	gxSpriteOffset
		sta 	gxzTemp0
		lda 	gxzTemp0+1
		adc 	gxSpriteOffset+1
		;
		; 		Get MSB in range $00-$1F, e.g. in the current page, bumping the selected page.
		;
_GXSAFindPage:
		cmp 	#$20 						; on this page
		bcc 	_GXSAFoundPage
		sbc 	#$20 						; forward one page
		inc 	GXEditSlot
		bra 	_GXSAFindPage
_GXSAFoundPage:
		;
		;		Make gxzTemp0 point to the sprite data, then copy it in.
		;
		ora 	#(GXMappingAddress >> 8) 	; physical address of page.
		sta 	gxzTemp0+1 					; gxzTemp0 now points to the page
		;
		ldy 	#0
_GXSACopyLoop:
		lda 	(gxzTemp0),y
		sta 	gxPixelBuffer,y
		iny
		cpy 	gxSizePixels
		bne 	_GXSACopyLoop
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
;		27/11/22 		Do nothing if sprites off.
;
; ************************************************************************************************