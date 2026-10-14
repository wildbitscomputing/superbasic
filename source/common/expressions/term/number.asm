; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		number.asm
;		Purpose:	State machine inputting numbers
;		Created:	20th September 2022
;		Reviewed: 	27th November 2022
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

ESTA_Low = 1 								; state 1 is 1 byte, switches when A >= 24.
ESTA_High = 2 								; loading up to 32 bit integer in the mantissa
ESTA_Decimal = 3 							; fractional part.

; ************************************************************************************************
;
;		Encode Number. If CS, then start a new number. Returns CS if the number is okay,
;		CC if not.
;
;		A simple state machine.
;
;		State 1 is taking in integers up to 255 - this is very quick.
; 		State 2 is taking in integers up to 4 bytes
; 		State 3 is taking in numbers after the decimal place.
;
;		Do we need a state between 1 & 2 ?
;
; ************************************************************************************************

EncodeNumberStart: 							; come here to reset the FSM.
		sec
		bra 	EncodeNumberContinue+1

EncodeNumberContinue: 						; come here to continue it.
		clc
EncodeNumber:		
		php 								; save reset flag.
		cmp 	#"." 						; only accept 0-9 and .
		beq 	_ENIsOkay
		cmp 	#"0"
		bcc 	_ENBadNumber
		cmp 	#"9"+1
		bcc 	_ENIsOkay
_ENBadNumber:		
		plp 								; throw saved reset
		lda 	encodeState 				; if in decimal mode, construct final number
		cmp 	#ESTA_Decimal
		beq 	_ENConstructFinal		
_ENFail:
		clc 								; not allowed
		rts
;
_ENIsOkay:		
		plp 								; are we restarting
		bcc 	_ENNoRestart

		; --------------------------------------------------------------------
		;
		;		First initialise
		;
		; --------------------------------------------------------------------

_ENStartEncode:
		cmp 	#'.'						; first is decimal place, go straight to that.
		beq 	_ENFirstDP
_ENStartDigit:                          ; EvaluateTerm already checked '0'..'9'.
		and 	#15 						; put digit in mantissa, initially a single digit constant
		jsr 	NSMSetByte 					; in single byte mode.
		lda 	#ESTA_Low
		;
		;		Come here to successfully change state.
		;
_ENExitChange:
		sta 	encodeState 				; save new state		
		sec
		rts

_ENFirstDP:
		jsr 	NSMSetZero 					; clear integer part
		bra 	_ESTASwitchFloat			; go straight to float and exi

		; --------------------------------------------------------------------
		;
		;		Not restarting. Figure out what to do next
		;
		; --------------------------------------------------------------------
_ENNoRestart:		
		pha 								; save digit or DP on stack.
		lda 	encodeState 				; get current state
		cmp 	#ESTA_Low
		beq  	_ESTALowState	
		cmp 	#ESTA_High
		beq 	_ESTAHighState
		cmp 	#ESTA_Decimal
		beq 	_ESTADecimalState
		.debug 								; should not happen !
		
		; --------------------------------------------------------------------
		;
		;		Inputting to a single byte.
		;
		; --------------------------------------------------------------------

_ESTALowState:
		pla 								; get value back
		cmp 	#"."						; decimal point
		beq 	_ESTASwitchFloat 			; then we need to do the floating point bit
		and 	#15 						; make digit
		sta 	digitTemp 					; save it.
		;
		lda 	NSMantissa0,x 				; x mantissa0 x 10 and add it
		asl 	a
		asl 	a
		adc 	NSMantissa0,x
		asl 	a
		adc 	digitTemp
		sta 	NSMantissa0,x
		cmp 	#25 						; if >= 25 cannot guarantee next will be okay
		bcc 	_ESTANoSwitch 				; as could be 25 x 10 + 9
		lda 	#ESTA_High 					; so if so, switch to the high encoding state
		sta 	encodeState
_ESTANoSwitch:
		sec
		rts		

		; --------------------------------------------------------------------
		;
		;		Inputting to a the whole 4 byte mantissa
		;
		; --------------------------------------------------------------------

_ESTAHighState:
		pla 								; get value back
		cmp 	#"." 						; if DP switch to dloat
		beq 	_ESTASwitchFloat
		jsr 	ESTAShiftDigitIntoMantissa 	; a routine does this.
		sec
		rts

		; --------------------------------------------------------------------
		;
		;		Entering decimal mode - still have then input digit on the stack
		;
		; --------------------------------------------------------------------

_ESTASwitchFloat:
		stz 	decimalCount 				; reset the count of digits - we divide by 10^n at the end.
		inx 								; zero the decimal additive.
		jsr 	NSMSetZero
		dex
		lda 	#ESTA_Decimal 				; switch to decimal mode
		bra 	_ENExitChange

		; --------------------------------------------------------------------
		;
		;		Decimal Mode
		;
		; --------------------------------------------------------------------

_ESTADecimalState:
		pla 								; digit.
		cmp 	#"." 						; fail on 2nd decimal point.
		beq 	_ENFail
		;
		inx 								; put digit into fractional part of X+1
		jsr 	ESTAShiftDigitIntoMantissa
		dex
		;
		inc 	decimalCount 				; bump the count of decimals
		;
		lda 	decimalCount 				; too many decimal digits.
		cmp 	#11
		beq 	_ESTADSFail
		sec
		rts
_ESTADSFail:
		jmp 	RangeError
		
		; --------------------------------------------------------------------
		;
		;		Build final number from components
		;
		; --------------------------------------------------------------------

_ENConstructFinal:
		lda 	decimalCount 				; get decimal count
		beq 	_ENCFExit 					; no decimals
		phy
		asl 	a 							; x 4 and CLC
		asl 	a
		adc 	decimalCount
		tay 
		;
		lda 	DecimalScalarTable-5,y 		; copy decimal scalar to X+2
		sta 	NSMantissa0+2,x  			; this is 10^-n
		lda 	DecimalScalarTable-5+1,y
		sta 	NSMantissa1+2,x
		lda 	DecimalScalarTable-5+2,y
		sta 	NSMantissa2+2,x
		lda 	DecimalScalarTable-5+3,y
		sta 	NSMantissa3+2,x
		lda 	DecimalScalarTable-5+4,y
		sta 	NSExponent+2,x
		lda 	#NSTFloat
		sta 	NSStatus+2,x
		;
		ply
		;
		inx 								; multiply decimal const by decimal scalar
		jsr 	FloatMultiply
		dex
		jsr 	FloatAdd 					; add to integer part.
_ENCFExit:
		clc 								; reject the digit.
		rts

; ************************************************************************************************
;
;			Put digit A into the mantissa at X, e.g. mantissa = mantissa x 10 + digit
;
; ************************************************************************************************

ESTAShiftDigitIntoMantissa:
		and 	#15 						; save digit
		pha

		lda 	NSMantissa3,x 				; push mantissa on stack
		pha
		lda 	NSMantissa2,x 
		pha
		lda 	NSMantissa1,x 
		pha
		lda 	NSMantissa0,x 
		pha
		jsr 	NSMShiftLeft 				; x 2
		jsr 	NSMShiftLeft 				; x 4

		clc 								; pop mantissa and add
		pla 
		adc 	NSMantissa0,x
		sta 	NSMantissa0,x
		pla
		adc 	NSMantissa1,x
		sta 	NSMantissa1,x
		pla
		adc 	NSMantissa2,x
		sta 	NSMantissa2,x
		pla
		adc 	NSMantissa3,x
		sta 	NSMantissa3,x 				; x 5
		jsr 	NSMShiftLeft 				; x 10
		;
		pla 								; add digit
		clc
		adc 	NSMantissa0,x
		sta 	NSMantissa0,x
		bcc 	_ESTASDExit
		inc 	NSMantissa1,x
		bne 	_ESTASDExit
		inc 	NSMantissa2,x
		bne 	_ESTASDExit
		inc 	NSMantissa3,x
_ESTASDExit:
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
