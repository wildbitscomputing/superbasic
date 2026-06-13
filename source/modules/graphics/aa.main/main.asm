; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		main.asm
;		Purpose:	Graphics main entry point.
;		Created:	6th October 2022
;		Reviewed: 	9th February 2022
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;									Graphics Plot Routine
;
; ************************************************************************************************

Export_GXGraphicDraw:
		cmp 	#GCMD_Move					; low value instructions don't use coordinates
		bcs 	_GDCoordinate 				; (see graphics.txt)
		;
		;		Non coordinate functions
		;
		stx 	gxzTemp0 					; save X/Y
		sty 	gxzTemp0+1
		bra 	_GDExecuteA 				; and execute
		;
		;		Coordinate functions
		;
_GDCoordinate:
		pha 								; save AXY
		phx
		phy
		ldx 	#3 							; copy currentX to lastX
_GDCopy1:
		lda 	gxCurrentX,x
		sta 	gxLastX,x
		dex
		bpl 	_GDCopy1
		;
		;		Update Y
		;
		pla 								
		sta 	gxCurrentY
		stz 	gxCurrentY+1
		;
		;		Update X, which uses a bit from A.
		;
		pla
		sta 	gxCurrentX
		pla 								; get A (command+X.1) back
		pha
		and 	#1 							; put LSB as MSB of Current.X
		sta 	gxCurrentX+1
		;
		;		Check if we are clipping X,Y (everything except sprite move)
		;
		pla 								; get command back
		and 	#$FE 						; lose LSB, chuck the stray X bit
		pha 								; push back.
		cmp 	#GCMD_SpriteMove 			; move sprite does not clip.
		beq 	_GDCopyToWorkArea
		;
		;		See if coordinate is in range, if so, reject it as error.
		;
		lda 	gxCurrentX+1 				; X < 256 X okay
		beq 	_GDCheckY
		lda 	gxCurrentX 					; otherwise X < 320 = 256 + 64
		cmp 	#64
		bcs 	_GDError1
_GDCheckY:
		lda 	gxCurrentY 					; check Y < Height.
		cmp 	gxHeight
		bcc 	_GDCopyToWorkArea
_GDError1:
		pla
_GDError2:
		sec
		rts
		;
		;		Copy the sprite current/last to the work area where we can manipulate it.
		;
_GDCopyToWorkArea:
		;
		ldx 	#7 							; copy current and last to gxXY/12 work area
_GDCopy2:
		lda 	gxCurrentX,x
		sta 	gxX0,x
		dex
		bpl 	_GDCopy2
		;
		;		Execute command X
		;
		pla 								; get command
_GDExecuteA:
		cmp 	#GRFirstFreeCode*2 			; bad command ?
		bcs 	_GDError2
		tax 								; go execute the command.
		jmp 	(GRVectorTable,x)

GXMove: ;; <32:Move>
		clc
		rts

GRUndefined:
		sec
		rts

; ************************************************************************************************
;											DRAWING MODES
; ************************************************************************************************
;
;		Mode 0: AND 0 EOR Colour 				Sets Colour
;		Mode 1: AND $FF EOR Colour 				Exclusive Or Colour
; 		Mode 2: And Colour:EOR 0 				AND with Colour.
;		Mode 3: AND ~Colour EOR Colour 			Or Colour
;
; ************************************************************************************************

		.send code

; ************************************************************************************************
;
;									Changes and Updates
;
; ************************************************************************************************
;
;		Date			Notes
;		==== 			=====
; 		21/02/23 		Added exit code for bad GFX commands.
;
; ************************************************************************************************	