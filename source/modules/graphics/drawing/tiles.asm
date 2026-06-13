; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		tiles.asm
;		Purpose:	Tile update Functions
;		Created:	22nd February 2022
;		Reviewed: 	No
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;											Select tile
;
; ************************************************************************************************

GXSelectTile: ;; <14:TilePos>
		lda 	gxTilesOn 					; check tilemap in use
		beq 	_GXSFail


		lda 	gxzTemp0 					; check X and Y in range
		cmp 	gxTileMapWidth
		bcs 	_GXSFail
		lda 	gxzTemp0+1
		cmp 	gxTileMapHeight
		bcs 	_GXSFail

		lda 	gxTileMapPage 				; page to access = tile access page.
		sta 	gxTileAccessPage
		;
		;		Calculate tilemapwidth . y + x
		;
		ldx 	gxTileMapWidth 				; YX is the additive, e.g. shifted left. gxzTemp0+1 is shifted right.
		ldy 	#0

		lda 	gxzTemp0 					; initial result is X
		sta 	gxTileAccessAddress 		
		stz  	gxTileAccessAddress+1
_GXSTMultiply:
		lsr 	gxzTemp0+1 					; shift Y right
		bcc 	_GXSTNoAdd 					; add if CS

		clc 								; add YX to result
		txa
		adc 	gxTileAccessAddress
		sta 	gxTileAccessAddress
		tya
		adc 	gxTileAccessAddress+1
		sta 	gxTileAccessAddress+1
_GXSTNoAdd:
		txa 								; shift YX left
		asl 	a
		tax
		tya
		rol 	a
		tay
		lda 	gxzTemp0+1 					; multiply complete
		bne 	_GXSTMultiply

		asl 	gxTileAccessAddress 		; double it, as it is a word array.
		rol 	gxTileAccessAddress+1

_GXSTFixAddressLoop: 						; force address into page range and adjust page
		jsr 	GXSTFixAddress
		bcs 	_GXSTFixAddressLoop		
		clc
		rts
_GXSFail:
		sec
		rts

; ************************************************************************************************
;
;						Adjust page:address so it is a valid page:address offset
;
; ************************************************************************************************

GXSTFixAddress:
		pha
		lda 	gxTileAccessAddress+1 		; in legal page range e.g. $0000-$1FFF
		cmp 	#$20
		bcc 	_GXSTFAExit
		sbc 	#$20 						; adjust address
		inc 	gxTileAccessPage 			; adjust page up.
		sec
_GXSTFAExit:
		pla
		rts

; ************************************************************************************************
;
;								Write a tile and advance
;
; ************************************************************************************************

GXSTWriteTile: ;; <15:TileWrite>
		sec 								; CS = update flag
		bra 	GXSTTileAccess
GXSTReadTile: ;; <16:TileRead>
		clc
GXSTTileAccess:				
		lda 	GXEditSlot 					; save oroginal page
		pha
		php 								; save update flag
		;
		lda 	gxTileAccessPage 			; access the tile page.
		sta 	GXEditSlot
		;
		ldx 	gxzTemp0 					; X = New value
		;
		lda 	gxTileAccessAddress 		; set gxzTemp0 to point there
		sta 	gxzTemp0
		lda 	gxTileAccessAddress+1
		ora 	#(GXMappingAddress >> 8)
		sta 	gxzTemp0+1		
		;
		plp 								; get flag
		bcc 	_GXSNoUpdate 				; updating the tile map ?
		;
		txa 								; new value
		sta 	(gxzTemp0) 					; write it out, as a word.
		ldy 	#1
		lda 	#0
		sta 	(gxzTemp0),y
_GXSNoUpdate:		
		lda 	(gxzTemp0) 					; read the value

		plx 								; restore old page
		stx 	GXEditSlot

		inc 	gxTileAccessAddress 		; advance tile ptr by 2 - will always be even.
		inc 	gxTileAccessAddress
		bne 	_GXSNoCarry
		inc 	gxTileAccessAddress+1
_GXSNoCarry:
		jsr 	GXSTFixAddress 				; fix address if required.

		clc 								; return with ok flag.
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