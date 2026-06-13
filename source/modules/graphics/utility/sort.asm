; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		sort.asm
;		Purpose:	Coordinate sorting code
;		Created:	6th October 2022
;		Reviewed: 	9th February 2023
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;			Sort X and Y coordinates - topleft/bottom right - rectangles, circles etc.
;
; ************************************************************************************************

GXSortXY:
		jsr 	GXSortY 					; will be sorted on Y now
		lda 	gxX0 						; compare X0 v X1
		cmp 	gxX1
		lda 	gxX0+1
		sbc 	gxX1+1
		bcc 	_GXSXYExit 					; X0 < X1 exit
		ldx 	#0 							; swap them over
		ldy 	#4
		jsr 	GXSwapXY
		inx
		iny
		jsr 	GXSwapXY
_GXSXYExit:
		rts

; ************************************************************************************************
;
;			Sort coordinate pairs so Y1 >= Y0, swaps X as well keeping pairs together
;
; ************************************************************************************************

GXSortY:
		lda 	gxY0 						; if Y0 >= Y1
		cmp 	gxY1
		bcc 	_GXSYSorted
		;
		ldx 	#3 							; swap 3-0 - for lines we want to sort but keep lines together
		ldy 	#7 							; with 4-7
_GXSwap1:
		jsr 	GXSwapXY
		dey
		dex
		bpl 	_GXSwap1
_GXSYSorted:
		rts

; ************************************************************************************************
;
;								Swap offset X,Y from gxX0
;
; ************************************************************************************************

GXSwapXY:
		lda 	gxX0,x
		pha
		lda 	gxX0,y
		sta 	gxX0,x
		pla
		sta 	gxX0,y
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