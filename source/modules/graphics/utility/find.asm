; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		find.asm
;		Purpose:	Get address, size and LUT of sprite (address is offset from base)
;		Created:	10th October 2022
;		Reviewed: 	17th February 2022
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;					Get address, size and LUT of sprite A (assume already opened)
;					in sprite data structure. Returns CS if bad sprite, CC if okay.
;
; ************************************************************************************************

GXFindSprite:
		tax  								; sprite index in X

		stz 	gxSpriteOffset 				; sprite offset is the offset in the sprite list.
		stz 	gxSpriteOffset+1

		stz 	gxzTemp1 					; zTemp1 is the address in memory, given the current selected page.
		lda 	#GXMappingAddress >> 8
		sta 	gxzTemp1+1

		lda 	gxSpritePage 				; and point to the sprite page.
		sta 	GXEditSlot 

		lda 	(gxzTemp1) 					; get the first sprite record header, identifying the format.
		cmp 	#$11						; should be $11
		bne 	_GXFSFail 					; if not, fail

		jsr 	_GXFSIncrement 				; increment pointers.
		;
		;		Main search loop
		;
_GXFindLoop:
		lda 	(gxzTemp1) 					; reached the end, if so then failed.
		cmp 	#$80
		beq 	_GXFSFail
		cpx 	#0 							; if zero, then found.
		beq 	_GXFSFound		
		dex 								; decrement count.

		asl 	a 							; index into table
		tay 								; so we can look it up.

		clc 								; add LSB
		lda 	gxSpriteOffset 				
		adc 	_GXFSSizeTable,y
		sta 	gxSpriteOffset 				; these two should move in lock step.
		sta 	gxzTemp1
		bcc 	_GXNextNoCarry 				; adjust for carry as we add the MSB seperately.
		inc 	gxSpriteOffset+1
		inc 	gxzTemp1+1
_GXNextNoCarry:		
		clc
		lda 	gxzTemp1+1 					; add MSB
		adc 	_GXFSSizeTable+1,y
		sta 	gxzTemp1+1
		lda 	gxSpriteOffset+1
		adc 	_GXFSSizeTable+1,y
		sta 	gxSpriteOffset+1
		jsr 	_GXFSNormalise 				; and normalise the page address.		
		bra 	_GXFindLoop 				; and go round again. 
		;
		;		Found the sprite, copy the data out.
		;
_GXFSFound:
		lda 	(gxzTemp1)					; get the bit size (e.g. 0-3)
		sta 	gxSizeBits
		inc 	a 							; 1,2,3,4 - calculating pixel size
		asl 	a 							; 2,4,6,8
		asl 	a 							; 4,8,12,16
		asl 	a 							; 8,16,24,32
		sta 	gxSizePixels 				

		jsr 	_GXFSIncrement 				; and to the LUT
		lda 	(gxzTemp1) 					; copy that out.
		sta 	gxSpriteLUT

		jsr 	_GXFSIncrement 				; and it now points to the first graphic data byte
		clc
		rts
;
;		Advance offset/address by 1.
;
_GXFSIncrement:
		inc 	gxSpriteOffset 				; these two should move in sync
		inc 	gxzTemp1
		bne 	_GXFSNormalise
		inc 	gxSpriteOffset+1
		inc 	gxzTemp1+1
;
;		If overflow, adjust back.
;		
_GXFSNormalise:
		lda 	gxzTemp1+1 					; are we out of range.
		cmp 	#(GXMappingAddress >> 8)+$20
		bcc 	_GXFSOkay
		inc 	GXEditSlot 					; next 8k page
		sec 								; adjust page address back
		sbc 	#$20
		sta 	gxzTemp1+1
_GXFSOkay:
		rts		

_GXFSFail:
		sec
		rts		
;
;		Total size of each sprite entry (pixel size^2 + lut + size)
;
_GXFSSizeTable:
		.word 	8*8+2,16*16+2,24*24+2,32*32+2

		.send code

		.section storage

gxSizePixels: 									; sprite size (in pixels)
		.fill 	1
gxSizeBits: 								; size (0-3)
		.fill 	1
gxSpriteLUT: 									; LUT to use
		.fill 	1
gxSpriteOffset: 								; offset from base page.
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