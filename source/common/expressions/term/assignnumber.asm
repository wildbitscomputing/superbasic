; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		assignnumber.asm
;		Purpose:	Assign a numeric value
;		Created:	30th September 2022
;		Reviewed: 	28th September 2022
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;				Assign a numeric reference, can be 1,2 or 4 byte integers, or a float
;
; ************************************************************************************************

AssignNumber:
		phy
		lda 	NSMantissa0,x 				; copy mantissa0/1 to zTemp0
		sta 	zTemp0
		lda 	NSMantissa1,x
		sta 	zTemp0+1
		;
		lda 	NSStatus,x 					; clear reference bits
		and 	#(NSBIsReference ^ $FF)
		sta 	NSStatus,x
		;
		and 	#NSBTypeMask				; assigning to a float ?
		cmp 	#NSTFloat
		beq 	_ANFloat
		;
		;		Assign an integer
		;
		lda		NSExponent+1,x 				; is it a float
		beq		_ANNotFloat

		; check if the float argument is in fact an integer
		inx
		jsr 	FloatIntegerPart 			; convert it to an integer
		dex
		bcc		_ANNotFloat					; no digits were lost, okay to proceed
		jmp 	TypeError					; it was, in fact, a float, report an error

_ANNotFloat:
		lda 	NSStatus,x 					; check if byte/word reference.
		and 	#3
		bne 	_ANByteWord
		;
		;		4 byte integer assign
		;
		jsr 	_ANCopy4PackSign 			; copy all 4 bytes and sign
		bra 	_ANExit
		;
		;		1 or 2 byte/word assign
		;
_ANByteWord:
		pha 								; save count
		lda 	NSMantissa0+1,x 			; do byte
		sta 	(zTemp0)
		pla
		cmp	 	#1
		beq 	_ANExit
		lda 	NSMantissa1+1,x 			; do word
		ldy 	#1
		sta 	(zTemp0),y
		bra 	_ANExit

		;
		;		Assign a float
		;
_ANFloat:
		jsr 	_ANCopy4PackSign 			; write all 4 bytes and packed sign
		lda 	NSExponent+1,x 				; copy exponent to slot 4
		ldy 	#4
		sta 	(zTemp0),y
_ANExit:
		ply
		rts
;
;		Copy all 4 bytes, with sign bit, from (zTemp),y+3
;
_ANCopy4PackSign:
		ldy 	#3
		lda 	NSStatus+1,x 				; sign bit into status
		and 	#$80 						; put into high bit of mantissa 3
		ora 	NSMantissa3+1,x
		sta 	(zTemp0),y
		dey
		lda 	NSMantissa2+1,x
		sta 	(zTemp0),y
		dey
		lda 	NSMantissa1+1,x
		sta 	(zTemp0),y
		dey
		lda 	NSMantissa0+1,x
		sta 	(zTemp0),y
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
;		26/11/22 		Changed so you cannot assign a float directly to an integer, causes a
;						Range Error. Previously it auto truncated.
;
; ************************************************************************************************
