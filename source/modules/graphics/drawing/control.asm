; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		control.asm
;		Purpose:	Graphics control.
;		Created:	11th October 2022
;		Reviewed: 	17th February 2022
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;										Initialise:
;
; ************************************************************************************************

GXInitialise: ;; <0:Initialise>
		stz 	1 							; access I/O
		lda 	#1 							; reset bitmap address
		sta 	$D000
		clc
		stz 	gxSpritesOn					; sprites/bitmaps/tiles off.
		stz 	gxBitmapsOn
		stz 	gxTilesOn
		ldx 	#15 						; erase work area
_GXIClear:
		stz 	gxCurrentX,x
		dex
		bpl 	_GXIClear
		jsr 	GXClearSpriteStore 			; clear sprite backup space.

		lda 	#$40                   		; Layer 0 = Bitmap 0, Layer 1 = Tile map 0
		sta 	$D002
		lda 	#$15                   		; Layer 2 = Tile Map 1
		sta 	$D003
		rts

; ************************************************************************************************
;
;										Bitmap Control
;
; ************************************************************************************************

GXControlBitmap: ;; <1:BitmapCtl>
		stz 	1

		lda 	gxzTemp0 					; get control bits
		and 	#1 							; get bitmap flag (is enabled)
		sta 	gxBitmapsOn
		lsr 	a 							; bit 0 into carry.
		lda 	$D000 						; read Vicky MCR
		ora 	#7 							; turn graphics, text, textoverlay on.
		and 	#$F7 						; clear bitmap bit
		bcc 	_CBNotOn  		
		ora 	#$08 						; bitmap on if 1 on 0 off
_CBNotOn:
		sta 	$D000 						; update Vicky MCR
		;
		lda 	gxzTemp0 					; get control settings (bits 0-2)
		and 	#7
		sta 	$D100 						; write in Vicky Bitmap Control Register #0

		lda 	gxzTemp0+1 					; get the base page requested
		bne 	_CBNotDefault
		lda 	#8  						; if zero, use default 8 e.g. bitmap at $10000
_CBNotDefault:
		sta 	gxBasePage 					; save as bitmap base page.

		jsr 	GXCalculateBaseAddress 	 	; convert page# to address
		lda 	gxzTemp0+1 					; copy address into Bitmap address registers
		sta 	$D103
		lda 	gxzTemp0
		sta 	$D102
		stz 	$D101

		ldx 	#240 						; height is 240 or 200 ?
		lda 	$D001 						; read MCR bit 0
		and 	#1
		beq 	_CBHaveHeight
		ldx 	#200 						; if bit 0 set 320x200
_CBHaveHeight
		stx 	gxHeight
		clc
		rts

; ************************************************************************************************
;
;										Sprite Control
;
; ************************************************************************************************

GXControlSprite: ;; <2:SpriteCtl>
		stz 	1
		lda 	gxzTemp0 					; get control bits
		and 	#1 							; set sprites flag
		sta 	gxSpritesOn
		lsr 	a 							; bit 0 into carry
		
		lda 	$D000 						; read Vicky MCR
		ora 	#7 							; turn graphics, text, textoverlay on.
		and 	#$DF 						; clear sprite bit
		bcc 	_CSNotOn
		ora 	#$20 						; sprite on if 1 on 0 off
_CSNotOn:
		sta 	$D000 						; update Vicky MCR


		lda 	gxzTemp0+1 					; get the base page
		bne 	_CSNotDefault
		lda 	#24  						; if zero, use 24 e.g. sprites at $30000
_CSNotDefault:
		sta 	gxSpritePage

		jsr 	GXCalculateBaseAddress 	 	; convert page# to address
		lda 	gxzTemp0 					; save this so we know where the sprites are.
		sta 	gxSpriteOffsetBase
		lda 	gxzTemp0+1
		sta 	gxSpriteOffsetBase+1
		;
		ldx 	#0 							; disable all sprites, clears all sprite memory.
_CSClear:
		stz 	$D900,x
		stz 	$DA00,x
		dex
		bne 	_CSClear
		;
		stz 	GSCurrentSpriteAddr+1 		; no sprite selected.
		jsr 	GXClearSpriteStore
		clc
		rts

; ************************************************************************************************
;
;								Control the tile map
;
; ************************************************************************************************

GXControlTilemap: ;; <10:TileCtl>
		stz 	1 							; access I/O
		lda 	gxzTemp0 					; get the Map Page/Enable
		bmi 	_GXCTOn
		;
		lda 	$D000 						; turn off bitmap enable bit in MCR
		and 	#$EF 						; clear bit 4
		sta 	$D000
		stz 	gxTilesOn 					; clear tiles on flag. 	
		clc
		rts
		;
_GXCTOn:
		sta 	gxTilesOn 					; set tiles on flag.
		;
		lda 	$D000	 					; turn tilemap on
		ora 	#$17
		sta 	$D000
		stz 	$D20C 						; turn off tilemap#1 and tilemap#2
		stz 	$D218
		;
		lda 	#64 						; default size of 64x32
		sta 	gxTileMapWidth
		lda		#32
		sta 	gxTileMapHeight
		;
		lda 	gxTilesOn 					; set the tile map page
		and 	#$7F
		bne	 	_GXCTNotMapDefault 			; check for default
		lda 	#TILEMAP_ADDRESS >> 13
_GXCTNotMapDefault:		
		sta 	gxTileMapPage
		;
		lda 	gxzTemp0+1 					; set the tile image page
		bne 	_GXCTNotImgDefault 			; check for default
		lda 	#TILEIMAGES_ADDRESS >> 13
_GXCTNotImgDefault:		
		sta 	gxTileImagePage
		;
		lda 	#$11 						; set tilemap#0 on and 8x8
		sta 	$D200
		;
		lda 	gxTileMapPage 				; put tile map address in.
		jsr		GXCalculateBaseAddress
		stz 	$D201
		lda 	gxzTemp0
		sta 	$D202
		lda 	gxzTemp0+1
		sta 	$D203
		;
		lda 	gxTileMapWidth	 			; set tilemap size.
		sta 	$D204
		lda 	gxTileMapHeight
		sta 	$D206
		;
		stz 	$D208 						; clear scrolling register
		stz 	$D209
		stz 	$D20A
		stz 	$D20B
		;
		lda 	gxTileImagePage 			; set the tile image address
		jsr 	GXCalculateBaseAddress		
		stz 	$D280
		lda 	gxzTemp0
		sta 	$D281
		lda 	gxzTemp0+1
		sta 	$D282
		clc
		rts

; ************************************************************************************************
;
;								Control the tile map size
;
; ************************************************************************************************

GXControlTileSize: ;; <11:TileSize>
		lda 	gxTilesOn 					; check on
		sec
		beq 	_GXCTSExit

		stz 	1 							; access I/O 0
		
		lda 	gxzTemp0 					; save parameter to registes
		sta 	gxTileMapWidth
		sta 	$D204

		lda 	gxzTemp0+1
		sta 	gxTileMapHeight
		sta 	$D206

		clc
_GXCTSExit:
		rts

; ************************************************************************************************
;
;								Convert page number to an address
;
; ************************************************************************************************

GXCalculateBaseAddress:
		sta 	gxzTemp0
		stz 	gxzTemp0+1
		lda 	#5
_GXShift:
		asl 	gxzTemp0
		rol 	gxzTemp0+1
		dec		a
		bne 	_GXShift
		rts

; ************************************************************************************************
;
;							Reset the sprite location store
;
; ************************************************************************************************

GXClearSpriteStore:
		ldx 	#63 						; erase 64 sprite store elements
_GXCSSLoop:
		stz 	gxSpriteHigh,x
		lda 	#$80 						; set the 'hidden' bit.
		sta 	gxSpriteLow,x
		dex
		bpl 	_GXCSSLoop
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
;		20/02/23 		Added control functionality for tile on/off/location and size of map.
; 		22/02/23 		Fixed bug no defaults on setting tilemap page defaults.
;		23/03/23 		Tilemap disable was $D2C0 not $D20C
;
; ************************************************************************************************

