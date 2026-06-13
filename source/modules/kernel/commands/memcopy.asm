; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		memcopy.asm
;		Purpose:	MemCopy (DMA Access) command — slot 3 module implementation
;		Created:	11th January 2023
;		Reviewed: 	No
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************
;
;		$DF00 	Start - - - IntEn Fill Rect Enable
;		$DF01 	Fill byte (W) DMA Busy (R, bit 7)
;		$DF04-6 Source Address (18 bits)
;		$DF08-A Destination Address (18 bits)
; 		$DF0C-E	Count (18 bits)
; 		$DF0C-D	Rect Width (Rect mode)
;		$DF0E-F Rect Height (Rect mode)
;		$DF10-1 Stride (source)
;		$DF12-3 Stride (dest)
;
; ************************************************************************************************
;
;			MEMCOPY <addr>,<size> TO <addr>
;			MEMCOPY <addr>,<size> POKE <byte>
;
;			MEMCOPY <addr> RECT <x>,<y> BY <width> TO <addr>
;			MEMCOPY <addr> RECT <x>,<y> BY <width> POKE <byte>
;
;			<addr> can be AT x,y on the bitmap.
;
; ************************************************************************************************

		.section code

Export_MCCommandImpl:
		lda 	1 							; save current I/O ; switch to I/O 0
		pha
		stz 	1
		;
		stz 	$DF00 						; zero control byte.
		lda 	#$81 						; standard start byte (DMA Enabled, Start set)
		sta 	DMAControlByte
		;
		;		Put the first address in source and destination
		;
		jsr 	MCPosition 					; start position
		ldx 	#4 							; write to source AND $DF04 destination address $DF08
		jsr 	MCCopyAddress
		ldx 	#8
		jsr 	MCCopyAddress
		;
		;		See if we have the ,size or RECT width,height BY stride syntax
		;
		.cget 								; next character
		iny
		cmp 	#KWD_COMMA 					; , <size>
		beq 	_MCSize1D
		cmp 	#KWD_RECT 					; RECT <x>,<y>
		beq 	_MCRect2D
_MCSyntax:
		.error_syntax
		;
		; 		1D ,size syntax
		;
_MCSize1D:
		ldx 	#0 							; get size
		jsr 	EvaluateInteger
		ldx 	#$C 						; copy to size $DF0C-E
		jsr 	MCCopyAddress
		bra 	_MCDestination
		;
		;		2D RECT width,height syntax BY stride
		;
_MCRect2D:
		ldx 	#$C 						; width to $DF0C,D
		jsr 	MCEvalCopyData16
		jsr 	CheckComma
		ldx 	#$E 						; height to $DF0E,F
		jsr 	MCEvalCopyData16
		;
		lda 	#KWD_BY 					; BY keyword.
		jsr 	CheckNextA
		ldx 	#$10 						; store source and destination stride
		jsr 	MCEvalCopyData16
		ldx 	#$12
		jsr 	MCCopyData16
		;
		lda 	DMAControlByte 				; set bit 4 of DMA control indicating 2D.
		ora 	#$02
		sta 	DMAControlByte
		;
		;		Set up the destination which is POKE x or TO x
		;
_MCDestination:
		.cget 								; get next token
		iny
		cmp 	#KWD_POKE 					; is it POKE n
		beq 	_MCDestPoke
		cmp 	#KWD_TO 					; is it TO n
		bne 	_MCSyntax
		;
		;		TO <address>
		;
		jsr 	MCPosition 					; get target address
		ldx 	#8							; copy to target address at $DF08-A
		jsr 	MCCopyAddress
		bra 	_MCDoDMA 					; and we can go.
		;
		;		POKE <address>
		;
_MCDestPoke:
		jsr 	Evaluate8BitInteger 		; POKE what
		sta 	$DF01 						; set the FILL register
		;
		lda 	DMAControlByte 				; set bit 2 of control byte indicating FILL.
		ora 	#$04
		sta 	DMAControlByte
		;
_MCDoDMA:
		lda 	DMAControlByte 				; set the DMA Control byte to go !
		sta 	$DF00
		;
		;		Wait for DMA to complete
		;
_MCWaitBUSD:
		lda 	$DF01
		bmi 	_MCWaitBUSD
		;
		pla 								; restore I/O.
		sta 	1
		rts

; ************************************************************************************************
;
;		Copy number at slot 0 to DMA registers x,x+1,x+2
;
; ************************************************************************************************

MCCopyAddress:
		lda 	NSMantissa2 				; check valid vlaue
		and 	#$F8
		ora 	NSMantissa3
		bne 	_MCRange
		lda 	NSMantissa0
		sta 	$DF00,x
		lda 	NSMantissa1
		sta 	$DF01,x
		lda 	NSMantissa2
		sta 	$DF02,x
		rts
_MCRange:
		.error_range

; ************************************************************************************************
;
;		Evaluate 16 bit integer and put in DMA registers x,x+1
;
; ************************************************************************************************

MCEvalCopyData16:
		phx
		ldx 	#0
		jsr 	Evaluate16BitInteger
		plx
MCCopyData16:
		lda 	NSMantissa0
		sta 	$DF00,x
		lda 	NSMantissa1
		sta 	$DF01,x
		rts

; ************************************************************************************************
;
;		Get a position or at x,y on the bitmap
;
; ************************************************************************************************

MCPosition:
		ldx 	#0 							; get start address.
		.cget 								; is it AT x,y
		cmp 	#KWD_AT
		beq 	_MCPAt
		jmp 	EvaluateInteger
_MCPAt:
		iny
		jsr 	Evaluate8BitInteger 		; X position
		pha
		jsr 	CheckComma
		inx
		jsr 	Evaluate8BitInteger 		; Y position
		dex
		;
		sta 	NSMantissa1 				; put Y x 64 in Mantissa.0
		stz 	NSMantissa0
		stz 	NSMantissa2
		stz 	NSMantissa3
		lsr 	NSMantissa1
		ror 	NSMantissa0
		lsr 	NSMantissa1
		ror 	NSMantissa0
		;
		pla
		clc
		adc 	NSMantissa0 				; add X, Y * 256 and the
		sta 	NSMantissa0
		;
		lda 	NSMantissa1
		adc 	NSMantissa0+1
		sta 	NSMantissa1
		bcc 	_MCPNoCarry
		inc 	NSMantissa2
_MCPNoCarry:
		;
		lda 	gxBasePage
		sta 	NSMantissa2+1
		stz 	NSMantissa0+1
		stz 	NSMantissa1+1
		stz 	NSMantissa3+1
		ldx 	#1
		jsr 	NSMShiftRight
		jsr 	NSMShiftRight
		jsr 	NSMShiftRight
		ldx 	#0
		jmp 	AddTopTwoStack
		.send code

		.section storage
DMAControlByte:
		.fill 	1
		.send storage
