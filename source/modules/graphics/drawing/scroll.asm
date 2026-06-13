; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		scroll.asm
;		Purpose:	Scroll tilemap code.
;		Created:	21st February 2023
;		Reviewed: 	No
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;								Set the tilemap scroll.
;
; ************************************************************************************************

GXControlTileScrollX: ;; <12:TileScrollX>
		lda 	gxTileMapWidth 				; comparator value (max X tile)
		jsr 	GXScrollProcessor 			; scroll processing.
		bcs 	_GXCTSExit
		stz 	1 							; write it out.
		stx 	$D208
		sty 	$D209
_GXCTSExit:
		rts

GXControlTileScrollY: ;; <13:TileScrollY>
		lda 	gxTileMapHeight 			; comparator value (max X tile)
		jsr 	GXScrollProcessor 			; scroll processing.
		bcs 	_GXCTSExit
		stz 	1 							; write it out.
		stx 	$D20A
		sty 	$D20B
_GXCTSExit:
		rts

; ************************************************************************************************
;
;		gxzTemp0 contains a scroll offset, A the max tile size. Check tilemap is on
;		and scroll in range ; then calculate actual scrolling value and return in YX
;		CS = Fail.
;
; ************************************************************************************************

GXScrollProcessor:
		sta 	gxzTemp1 					; save max tile value.
		lda 	gxTilesOn 					; check tile map is on.
		sec
		beq 	_GXSPExit
		;
		stz 	gxzTemp1+1 					; convert tile size to a pixel scroll.
		ldx 	#3
_GXCalcMaxPixelScroll:		 	
		asl 	gxzTemp1
		rol 	gxzTemp1+1
		dex
		bne 	_GXCalcMaxPixelScroll
		;
		lda 	gxzTemp0 					; check scroll in range.
		cmp 	gxzTemp1
		lda 	gxzTemp0+1
		sbc 	gxzTemp1+1
		bcs		_GXSPExit

		lda 	gxzTemp0 	 				; save fine scroll.
		and		#7
		sta 	gxzTemp1

		asl 	gxzTemp0 					; shift left one, as whole tiles are 8 pixels. 
		rol 	gxzTemp0+1
		lda 	gxzTemp0+1 					; MSB is the upper byte.
		and 	#$0F
		tay
		;
		lda 	gxzTemp0 					; get coarse scroll
		and 	#$F0
		ora 	gxzTemp1 					; OR in fine scroll.
		tax 								; return in X

		clc
_GXSPExit:
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

