; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		line.asm
;		Purpose:	Line drawing code
;		Created:	6th October 2022
;		Reviewed: 	9th February 2023
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;		For gxX0,gxY0 calculate position in gxzScreen, offset in gxOffset and select current
;		segment.
;
; ************************************************************************************************
;
;		The main calculation is gxY0*320 = gxY0 * 5 * 64
;
gxPositionCalc:
		lda 	gxzTemp0 						; save temp memory slot
		pha
		;
		;		Calculate gxY0 * 5 => gxzScreen
		;
		lda 	gxY0 							; gxzScreen = Y0
		sta 	gxzScreen
		stz 	gxzScreen+1
		;
		asl 	gxzScreen 						; gxzScreen = Y0 * 4
		rol 	gxzScreen+1
		asl 	gxzScreen
		rol 	gxzScreen+1
		;
		clc 									; gxzScreen = Y0 * 5, as it's still in A
		adc 	gxzScreen
		sta 	gxzScreen
		bcc 	_GXPCNoCarry
		inc 	gxzScreen+1
_GXPCNoCarry:
		;
		;		Calculate gxY0 * 10
		;
		asl 	gxzScreen 						; now Y0 * 10
		rol 	gxzScreen+1 					
		;
		; 		Save MSB and zero it. Think of s+1.s+0 as a decimal fraction of 32nds. The LSB multiplied
		;		by 32 gives range 0..8191 (255*32 so 8160 technically). The MSB would be multiplied by 32*256
		;		to give an address, but then redivided by 32*256 to give the page offset. 
		;
		lda	 	gxzScreen+1 					
		sta 	gxzTemp0 						; the page offset.
		stz 	gxzScreen+1
		;
		;		Multiply by 32 (e.g. 2^5)
		;
		lda 	#5 								; now multiply by 32, this puts this in the range 0..8191
_GXPCMultiply32:
		asl 	gxzScreen
		rol 	gxzScreen+1
		dec 	a
		bne 	_GXPCMultiply32
		;
		;		Add gxX0 to this, then split it into the offset (LSB) and address (MSB) because when we are writing to (xx),y
		;		xx.0 is always zero, to improve tracking of page changes.
		;
		clc
		lda 	gxX0 						; add X to this value, put the result in gxOffset, gxzScreen has to be on a page boundary
		adc 	gxzScreen
		sta 	gxOffset
		lda 	gxX0+1
		adc 	gxzScreen+1
		;
		;		Adding could shift into the next page, so if >$20 shift into range and adjust the page number.
		;
		cmp 	#$20 						; has it overflowed into the next one ?
		bcc 	_GXPCNoOverflow
		and 	#$1F 						; fix it up
		inc 	gxzTemp0 					; add 1 to the page number
_GXPCNoOverflow:
		;
		;		Make it a real address in zero page with the LSB,0, provideing page gxzTemp0 is selected.
		;
		ora 	#(GXMappingAddress >> 8) 	; make it the address mapped in.
		sta 	gxzScreen+1
		stz 	gxzScreen
		;
		;		Add the page offset to the base page and map it in.
		;
		clc
		lda 	gxzTemp0 					; get the page number
		adc 	gxBasePage 					; by adding the base page
		sta 	GXEditSlot 					; and map it into memory.
		;
		pla
		sta 	gxzTemp0
		rts

; ************************************************************************************************
;
;						Move the (gxzScreen),gxOffset down one line
;
; ************************************************************************************************

GXMovePositionDown:
		clc 								; add 320 to offset/temp+1
		lda 	gxOffset
		adc 	#64
		sta 	gxOffset
		lda 	gxzScreen+1
		adc 	#1
		sta 	gxzScreen+1
		cmp 	#((GXMappingAddress+$2000) >> 8) ; on to the next page ?
		bcc 	_GXMPDExit
		sec  								; next page, adjust address
		sbc 	#$20
		sta 	gxzScreen+1
		inc 	GXEditSlot 					; bump page
_GXMPDExit:
		rts
		.send 	code

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