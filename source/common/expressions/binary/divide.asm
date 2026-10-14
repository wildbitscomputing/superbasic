; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		divide.asm
;		Purpose:	32x32 bit integer division (2 variants)
;		Created:	22nd September 2022
;		Reviewed: 	27th November 2022
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section 	code

; ************************************************************************************************
;
;									Integer Division
;
; ************************************************************************************************

IntegerDivide: ;; [\]
		plx
		.dispatchintegeronly
		jsr 	CheckDivideZero 			; do div zero check
		jsr 	Int32Divide 				; do the division
		jsr 	CalculateSign 				; calculate result sign
		;
NSMCopyPlusTwoToZero:		
		lda 	NSMantissa0+2,x 			; copy result down from +2
		sta 	NSMantissa0,x
		lda 	NSMantissa1+2,x
		sta 	NSMantissa1,x
		lda 	NSMantissa2+2,x
		sta 	NSMantissa2,x
		lda 	NSMantissa3+2,x
		sta 	NSMantissa3,x
		rts

CheckDivideZero: 							; check Stack[X+1] not zero
		inx
		jsr 	NSMIsZero
		beq 	_CDVError
		dex
		rts
_CDVError:
		.error_divzero

; ************************************************************************************************
;
;									Integer Modulus
;
; ************************************************************************************************

IntegerModulus: ;; [%]
		plx
		.dispatchintegeronly
IntegerModulusNoCheck:		
		jsr 	CheckDivideZero 			; do div zero check
		jsr Slot3BankIn
		jsr ModulusPowerOfTwo
		php
		jsr Slot3BankOut
		plp
		bcs _IMDone
		jsr 	Int32Divide 				; do the division
_IMDone:
		asl 	NSStatus,x 					; clear the sign bit.
		lsr 	NSStatus,x
		rts

		.send code
		.section page2
		.logical * + $2000
; A 32-bit magnitude modulo a 16-bit power of two is just a mask.
; This also accelerates RANDOM(n) without changing its distribution or seed.
; The caller has already rejected a zero divisor. Carry signals a handled case.
ModulusPowerOfTwo:
		lda NSMantissa2+1,x
		ora NSMantissa3+1,x
		bne _MPFallback
		sec
		lda NSMantissa0+1,x
		sbc #1
		sta zTemp0
		lda NSMantissa1+1,x
		sbc #0
		sta zTemp0+1
		and NSMantissa1+1,x
		bne _MPFallback
		lda zTemp0
		and NSMantissa0+1,x
		bne _MPFallback
		lda NSMantissa0,x
		and zTemp0
		sta NSMantissa0,x
		lda NSMantissa1,x
		and zTemp0+1
		sta NSMantissa1,x
		stz NSMantissa2,x
		stz NSMantissa3,x
		sec
		rts
_MPFallback:
		clc
		rts
		.endlogical
		.send page2
		.section code

; ************************************************************************************************
;
;		32 bit unsigned division of FPA Mantissa A by FPA Mantissa B, 32 bit result.
;									(see divide.py)
;
; ************************************************************************************************

Int32Divide:
		.if mathIntegrated == 1
		pha
		jsr Slot3BankIn
		jsr DivideInteger16
		php
		jsr Slot3BankOut
		plp
		pla
		bcs _I32FastExit
		.endif
		pha 								; save AXY
		phy
		jsr 	NSMShiftUpTwo 				; copy S[X] to S[X+2]
		jsr 	NSMSetZeroMantissaOnly 		; set S[X] to zero

		ldy 	#32 						; loop 32 times
_I32DivideLoop:
		inx
		inx
		jsr 	NSMShiftLeft				; shift S[X+2] S[X] left as a 64 bit element
		dex
		dex
		jsr 	NSMRotateLeft
		;		
		jsr 	DivideCheckSubtract 		; check if subtract possible
		bcc 	_I32DivideNoCarryIn
		inc 	NSMantissa0+2,x 			; if possible, set Mantissa0[X+2].0
_I32DivideNoCarryIn:
		dey 								; loop round till division completed.
		bne 	_I32DivideLoop

		ply 								; restore AXY and exit
		pla
_I32FastExit:
		rts

; ************************************************************************************************
;
;		Shifted Division used in Floating Point Divide - does (a << 30) // b
;									(see divide.py)
;
; ************************************************************************************************

Int32ShiftDivide:
		pha 								; save AY
		phy

		inx 								; clear S[X+2]
		inx
		jsr 	NSMSetZero
		dex
		dex

		ldy 	#31 						; loop 31 times.
_I32SDLoop:
		jsr 	DivideCheckSubtract 		; check if subtract possible
		inx
		inx
		jsr 	NSMRotateLeft				; shift 64 bit FPA left, rotating carry in
		dex
		dex
		jsr 	NSMRotateLeft
		dey 	 							; do 31 times
		bne 	_I32SDLoop
		ply 								; restore AY and exit
		pla
		rts

; ************************************************************************************************
;
;							Do the division - check subtraction code
;
;			If can subtract FPB from FPA.Upper, do so, return carry set if was subtracted
;			Common code to both divisions.
;
; ************************************************************************************************

DivideCheckSubtract:
		jsr 	SubTopTwoStack 				; subtract Stack[X+1] from Stack[X+0]
		bcs 	_DCSExit 					; if carry set, then could do, exit
		jsr 	AddTopTwoStack 				; add it back in
		clc 								; and return False
_DCSExit:
		rts		

		.send 	code

		.if mathIntegrated == 1
		.section page2
		.logical * + $2000
; Same contract as Int32Divide: remainder at X, quotient at X+2.
; Carry clear leaves operands untouched for the 32-bit software fallback.
DivideInteger16:
		lda NSMantissa2,x
		ora NSMantissa3,x
		ora NSMantissa2+1,x
		ora NSMantissa3+1,x
		bne _DI16Fallback
		php
		sei
		lda $01
		pha
		stz $01
		lda $de04
		pha
		lda $de05
		pha
		lda $de06
		pha
		lda $de07
		pha
		; Unlike the multiplier, divisor precedes dividend in this unit.
		lda NSMantissa0+1,x
		sta $de04
		lda NSMantissa1+1,x
		sta $de05
		lda NSMantissa0,x
		sta $de06
		lda NSMantissa1,x
		sta $de07
		lda $de14
		sta NSMantissa0+2,x
		lda $de15
		sta NSMantissa1+2,x
		stz NSMantissa2+2,x
		stz NSMantissa3+2,x
		lda $de16
		sta NSMantissa0,x
		lda $de17
		sta NSMantissa1,x
		pla
		sta $de07
		pla
		sta $de06
		pla
		sta $de05
		pla
		sta $de04
		pla
		sta $01
		plp
		sec
		rts
_DI16Fallback:
		clc
		rts
		.endlogical
		.send page2
		.endif

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
