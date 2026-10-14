; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		multiply.asm
;		Purpose:	Multiply Stack[x] by Stack[x+1] floating point
;		Created:	23rd September 2022
;		Reviewed: 	27th November 2022
;		Author : 	Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section 	code

; ************************************************************************************************
;
;									Floating point multiplication
;
; ************************************************************************************************

FloatingPointMultiply:
		jsr 	FloatPrepare 				; prepare for floats

FloatMultiply:	
		pha
		jsr 	NSNormalise		 			; normalise S[X] and exit if zero
		beq 	_FDExit 					; return zero if zero (e.g. zero*something)
		inx 
		jsr 	NSNormalise		 			; normalise S[x+1] and error if zero.
		dex
		cmp 	#0
		beq 	_FDSetZero 					

		.if mathIntegrated == 1
		jsr 	MathMultiplyMantissa 		; hardware path for normalised mantissas
		.else
		jsr 	MultiplyShort 				; portable software fallback
		.endif
		adc 	NSExponent,x 				; calculate exponent including the shift.
		clc
		adc 	NSExponent+1,x
		sta 	NSExponent,x
		bra 	_FDExit

_FDSetZero:
		jsr 	NSMSetZero 					; return 0
_FDExit:
		jsr 	NSNormalise 				; normalise the result
		pla
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
