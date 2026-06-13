; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		mode.asm
;		Purpose:	Graphics set drawing mode
;		Created:	11th October 2022
;		Reviewed: 	17th February 2023
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;								Set colour, mode (bits 0 & 1)
;
;				  Sets AND value and EOR value to access mode (see below)
;
; ************************************************************************************************

GXSetColourMode: ;; <4:Colour>
		ldx 	gxzTemp0
		stx 	gxColour 								; set colour
		lda 	gxzTemp0+1 								;
		sta 	gxMode 									; set mode
		;
		;		Now process bits 0/1 to set the drawing type. Normal (0) EOR (1) AND (2) OR (3)
		;
		and 	#3 										; only interested in bits 0-3
		stz 	gxANDValue 								; initially AND with 0, and EOR with Colour
		ldx 	gxColour
		stx 	gxEORValue
		cmp 	#2 										; if mode 2/3 And with colour
		bcc 	_GXSDCNotAndColour
		stx 	gxANDValue
_GXSDCNotAndColour:
		bne 	_GXSDCNotAnd 							; mode 2, Don't EOR with colour
		stz 	gxEORValue
_GXSDCNotAnd:
		lsr 	a 										; if bit 0 set, 1's complement AND value
		bcc 	_GXSDCNoFlip
		lda	 	gxANDValue
		eor 	#$FF
		sta 	gxANDValue
_GXSDCNoFlip:
		clc
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
;
; ************************************************************************************************