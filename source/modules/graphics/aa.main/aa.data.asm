; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		aa.data.asm
;		Purpose:	Data use for Graphics
;		Created:	6th October 2022
;		Reviewed: 	9th February 2023
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************
;
;		Page number to map in/out
;
GXMappingPage = 3
;
;		Address of that page in 6502 space.
;
GXMappingAddress = ($2000 * GXMappingPage)
;
;		LUT Edit slot
;
GXEditSlot = 8 + GXMappingPage

; ************************************************************************************************
;
;									Allocate or Re-Use memory
;
; ************************************************************************************************

.if graphicsIntegrated==1
;
;		Zero Page (reuse BASIC temps)
;
gxzTemp0 = zTemp0
gxzTemp1 = zTemp1
gxzTemp2 = zTemp2
gxzScreen = zsTemp
;
;		Buffer for pixel data. Needs to be 32 pixels minimum. (Reusing number conversion buffer)
;		When rendering character or sprite, this is used to do a line at a time.
;
gxPixelBuffer = numberBuffer
.else
.endif

; ************************************************************************************************
;
;										Drawing macro
;
; ************************************************************************************************

plotpixel .macro
		and 	gxANDValue
		eor 	gxEORValue
		.endm

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

		.section storage

; ************************************************************************************************
;
;										Graphics data area
;								(maintain order for first section)
;
; ************************************************************************************************
;
;		current X/Y coordinates
;
gxCurrentX:
		.fill 	2
gxCurrentY:
		.fill 	2
;
;		last pair of X/Y coordinates
;
gxLastX:
		.fill 	2
gxLastY:
		.fill 	2
;
;		Working coordinate sets
;
gxX0:
		.fill 	2
gxY0:
		.fill 	2
gxX1:
		.fill 	2
gxY1:
		.fill 	2
;
;		Sprites/Bitmaps/Tiles on flags
;
gxSpritesOn:
		.fill 	1
gxBitmapsOn:
		.fill 	1
gxTilesOn:
		.fill 	1		
;
;		Base page of bitmap
;
gxBasePage:
		.fill 	1
;
;		Base page of sprite Data
;
gxSpritePage:
		.fill 	1
;
;		Base page of tile image data
;		
gxTileImagePage:
		.fill 	1
;
;		Base page of tile map data
;		
gxTileMapPage:
		.fill 	1
;
;		Tile map size
;		
gxTileMapWidth:
		.fill 	1
gxTileMapHeight:
		.fill 	1		
;
;		Height of screen
;
gxHeight:
		.fill 	1
;
;		Mode byte for sprites/chars (vflip|hflip|size2|size1|size0|-|s1|s2)
;
gxMode:
		.fill 	1
;
;		Colours
;
gxColour:
		.fill 	1
gxEORValue:
		.fill 	1
gxANDValue:
		.fill 	1
;
;		Original LUT setting
;
gxOriginalLUTValue:
		.fill 	1
;
;		Offset in calculation.
;
gxOffset:
		.fill 	1
;
;		ID and Address of current selected sprite in I/O (MSB=0 => None)
;
GSCurrentSpriteID:
		.fill 	1
GSCurrentSpriteAddr:
		.fill 	2
;
;		Base address for sprite area
;
gxSpriteOffsetBase:
		.fill 	2
;
;		Sprite location store
;
;		Low <Hidden bit> <X Position >> 2>
; 		High <Size (00=8,01=16,10=24,11=32)> <Y Position >> 2>
;
gxSpriteLow:
		.fill 	64
gxSpriteHigh:
		.fill 	64
;
;		Tile read/write address. Not accessible if page = 0
;
gxTileAccessPage:
		.fill 	1
gxTileAccessAddress:
		.fill 	2		

		.send storage


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