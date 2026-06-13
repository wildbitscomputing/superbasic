; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		clear.asm
;		Purpose:	Clear Screen
;		Created:	6th October 2022
;		Reviewed: 	9th February 2023
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

ScreenSize200 = 320 * 200
ScreenSize240 = 320 * 240

		.section code

; ************************************************************************************************
;
;								Clear bitmap to colour gxzTemp0
;
; ************************************************************************************************

GXClearBitmap: ;; <3:Clear>
		lda 	gxBitmapsOn 				; check BMP turned on.
		beq 	_GXCBFail
		jsr 	GXOpenBitmap 				; start access
		ldy 	#ScreenSize200 / 8192 		; X is pages to clear as 2 graphic heights.
		lda 	gxHeight
		cmp 	#200 						; 200 ?
		beq 	_GXCalcLastPage
		ldy 	#ScreenSize240 / 8192		
_GXCalcLastPage:

		tya 								; add to base page
		clc
		adc 	gxBasePage
		sta 	GXEditSlot  				; clear from this page back

_GXClearAll:
		jsr 	_GXClearBlock 				; clear 8k block
		dec 	GXEditSlot  				; back to previous
		lda 	GXEditSlot
		cmp 	gxBasePage 					; until before base page
		bcs 	_GXClearAll
		jsr 	GXCloseBitmap	 			; stop access
		clc
		rts
_GXCBFail:
		sec
		rts

_GXClearBlock:
;
;		Clear 1 8k block
;
		.set16 	gxzTemp1,GXMappingAddress
_GXCB0:
		lda 	gxzTemp0 					; clear colour
		ldy 	#0
_GXCB1: 									; do 4 chunks at a time, really should DMA this.
		sta 	(gxzTemp1),y
		iny
		sta 	(gxzTemp1),y
		iny
		sta 	(gxzTemp1),y
		iny
		sta 	(gxzTemp1),y
		iny
		bne 	_GXCB1
		inc 	gxzTemp1+1
		lda 	gxzTemp1+1
		cmp	 	#(GXMappingAddress >> 8)+$20
		bne 	_GXCB0
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
;		9/2/23 			beq _GXCalcLastPage added as was clearing 240 rows irrespective of height
;
; ************************************************************************************************
