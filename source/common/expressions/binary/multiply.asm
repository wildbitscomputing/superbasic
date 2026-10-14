; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		multiply.asm
;		Purpose:	32x32 bit integer multiplication, 32 bit result with rounding and shift
;		Created:	21st September 2022
;		Reviewed: 	27th November 2022
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

MulInteger: 	;; [*]
		plx
		.dispatcher FloatingPointMultiply,NotDoneError
		.if mathIntegrated == 1
		; Two 15-bit magnitudes fit the F256 unsigned 16x16 unit, with no
		; intermediate overflow in the legacy multiplier. Larger values retain
		; that path's existing overflow/rounding behaviour.
		lda NSMantissa2,x
		ora NSMantissa3,x
		ora NSMantissa2+1,x
		ora NSMantissa3+1,x
		bne _MISoftware
		lda NSMantissa1,x
		ora NSMantissa1+1,x
		bmi _MISoftware
		jsr MultiplyInteger16
		lda NSMantissa3,x
		bpl _MIExit
		.error_range
_MISoftware:
		.endif
		jsr 	MultiplyShort
		cmp 	#0
		beq 	_MIExit
		.error_range
_MIExit:
		rts		

		.if mathIntegrated == 1
MultiplyInteger16:
		; Preserve the shared unit and I/O selection; no IRQ can see partial
		; operands. X and Y are unchanged, including for nonzero stack levels.
		php
		sei
		lda $01
		pha
		stz $01
		lda $de00
		pha
		lda $de01
		pha
		lda $de02
		pha
		lda $de03
		pha
		lda NSMantissa0,x
		sta $de00
		lda NSMantissa1,x
		sta $de01
		lda NSMantissa0+1,x
		sta $de02
		lda NSMantissa1+1,x
		sta $de03
		lda $de10
		sta NSMantissa0,x
		lda $de11
		sta NSMantissa1,x
		lda $de12
		sta NSMantissa2,x
		lda $de13
		sta NSMantissa3,x
		pla
		sta $de03
		pla
		sta $de02
		pla
		sta $de01
		pla
		sta $de00
		pla
		sta $01
		plp
		jmp CalculateSign
		.endif

; ************************************************************************************************
;
;		Multiply stack entry X by stack entry X+1. If necessary right shifts. Returns on 
;		exit the number of left shifts required to fix it up. Calculates sign of result.
;
;		Does not change exponent.
;
; ************************************************************************************************

MultiplyShort:
		phy 								; save Y
		jsr 	NSMShiftUpTwo 				; copy S[X] to S[X+2]
		jsr 	NSMSetZeroMantissaOnly 		; set mantissa S[X] to zero
		ldy 	#0 							; Y is the shift count.
		;
		;		Main multiply loop.
		;				
_I32MLoop:
		lda 	NSMantissa0+2,x 			; check S[X+2] is zero
		ora 	NSMantissa1+2,x
		ora 	NSMantissa2+2,x
		ora 	NSMantissa3+2,x
		beq 	_I32MExit 					; exit if zero

		lda 	NSMantissa0+2,x 			; check LSB of n1 
		and 	#1
		beq 	_I32MNoAdd
		;
		jsr 	AddTopTwoStack 				; if so add S[X+1] to S[X+0]
		;
		lda 	NSMantissa3,x 				; has MantissaA overflowed ?
		bpl 	_I32MNoAdd
		;
		;		Overflow. Shift result right, increment the shift count, keeping the
		; 		result in 31 bits - now we lose some precision though.
		;
_I32ShiftRight:		
		jsr 	NSMShiftRight 				; shift S[X] right
		iny 								; increment shift count
		bra 	_I32MShiftUpper 			; n2 is doubled by default.
		;
_I32MNoAdd:
		bit 	NSMantissa3+1,x				; if we can't shift S[X+1] left, shift everything right
		bvs 	_I32ShiftRight 				; instead.

		inx
		jsr 	NSMShiftLeft 				; shift additive S[X+1] left
		dex

_I32MShiftUpper:
		inx 								; shift S[X+2] right
		inx
		jsr 	NSMShiftRight
		dex
		dex

		bra 	_I32MLoop 					; try again.

_I32MExit:
		jsr 	CalculateSign
		tya 								; shift in A
		ply 								; restore Y and exit
		rts

; ************************************************************************************************
;
;								Calculate sign from the two signs
;
; ************************************************************************************************

CalculateSign:
		lda 	NSStatus,x 					; sign of result is 0 if same, 1 if different.
		asl 	NSStatus,x 					; shift result left
		eor 	NSStatus+1,x
		asl 	a 							; shift bit 7 into carry
		ror 	NSStatus,x 					; shift right into status byte.
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
