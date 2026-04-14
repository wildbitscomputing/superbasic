;;
; Variable term parsing and array access logic
;;

		.section code

;;
; Parse a variable term into a number-stack reference.
;
; Reads the encoded variable reference at the current token position, resolves
; the variable record address in `VariableSpace`, and constructs a reference
; value in the current number-stack slot. Scalar variables return immediately as
; references to their stored data; array references dispatch to the array
; access logic, which also handles function-call syntax for procedure arrays.
;
; \in X         Number-stack slot to receive the variable reference.
; \in Y         Parsing position at the encoded variable token.
; \out Y        Advanced past the encoded variable reference.
; \out NSMantissa[0..3],x  Reference payload pointing at the variable data.
; \out NSExponent,x        Cleared for the constructed reference.
; \out NSStatus,x          Variable base type with `NSBIsReference` set; array
;                          variables also retain the array flag.
; \sideeffects  - Uses `zTemp0` as a pointer to the variable record.
;               - Reads the variable type byte from the record metadata.
;               - May dispatch to array indexing or `FunctionCall` handling
;                 for array/procedure references.
;               - Modifies registers `A` and `Y`.
; \see          FunctionCall, Evaluate8BitInteger, CheckRightBracket
;;

VariableHandler:
		.cget 								; copy variable address to zTemp0
		clc
		adc 	#((VariableSpace >> 8) - $40) & $FF
		sta 	zTemp0+1
		iny
		.cget
		sta 	zTemp0
		iny
		;
		clc									; copy variable address+3 to mantissa
		adc 	#3 							; this is the address of the data.
		sta 	NSMantissa0,x
		lda 	zTemp0+1
		adc 	#0
		sta 	NSMantissa1,x
		;
		stz 	NSMantissa2,x
		stz 	NSMantissa3,x
		stz 	NSExponent,x
		;
		phy
		ldy 	#2 							; read type
		lda 	(zTemp0),y
		ply
		;
		and 	#NSBTypeMask+NSBIsArray 	; get type information
		ora 	#NSBIsReference 			; make a reference.
		sta 	NSStatus,x

		and 	#NSBIsArray
		bne 	_VHArray
		rts

; ************************************************************************************************
;
;									Accessing an array.
;
; ************************************************************************************************

_VHArray:
		lda 	NSStatus,x 					; check if this is a function call
		and 	#NSBTypeMask+NSBIsArray
		cmp 	#NSTProcedure+NSBIsArray 	; function = procedure type + array bit
		bne 	_VHNotFunction
		jmp 	FunctionCall 				; dispatch to function call handler
_VHNotFunction:
		;
		inx
		jsr 	Evaluate8BitInteger 		; get the 1st index.
		;
		lda 	#$FF 						; set Status of X+2 to a duff value so we know if we picked it up.
		sta 	NSStatus+1,x
		;
		.cget 								; followed by comma
		cmp 	#KWD_COMMA
		bne 	_VHNoSecondIndex
		iny 								; skip the comma
		inx
		jsr 	Evaluate8BitInteger 		; get the 2nd index.
		dex
_VHNoSecondIndex:
		dex 								; set X back.
		jsr 	CheckRightBracket 			; and check the right bracket.

		; -----------------------------------------------------------------------------------------------------
		;
		;		So at this point S[X] refers to the array record S[X+1] the 1st index, and S[X+2] the second
		;		Status[X+2] is $FF if there was only one array index, $00 if there were two.
		;
		; -----------------------------------------------------------------------------------------------------
		;
		;		So first check if the number of indices match
		;
		phy 								; save position
		;
		lda 	NSMantissa0,x 				; copy record address to zaTemp (moved 6/12/22)
		sta 	zaTemp
		lda 	NSMantissa1,x
		sta 	zaTemp+1
		;
		ldy 	#2 							; check first index is not-zero, e.g. array defined
		lda 	(zaTemp),y
		beq 	_VHBadArray
		;
		ldy 	#3 							; get the second index - which is 0 if there is one index.
		lda 	(zaTemp),y
		beq 	_VHHas2Mask
		lda 	#$FF
_VHHas2Mask: 								; so we are now 0 if there is 1 index, and $FF if there is 2 - the inverse of Status, Stack[X+2]
		cmp 	NSStatus+2,x 				; so if they are the same there are the wrong number of indices
		beq 	_VHBadIndex
		;
		;		Now check the indices are in range.
		;
		asl 	a 							; carry will be set if a second index
		bcc 	_VHCheckFirstIndex
		;
		;		Second index
		;
		ldy 	#3 			 				; check the 2nd size >= 2nd index
		lda 	(zaTemp),y
		cmp 	NSMantissa0+2,x
		bcc 	_VHBadIndex
		;
		;		First index
		;
_VHCheckFirstIndex:
		ldy 	#2 			 				; check the 2nd size >= 2nd index
		lda 	(zaTemp),y
		cmp 	NSMantissa0+1,x
		bcc 	_VHBadIndex
		;
		;		Now calculate second index * first size if required.
		;
		stz 	zTemp0 						; clear zTemp0 (if 1 index)
		stz 	zTemp0+1
		lda 	NSStatus+2,x 				; if only one index provided, don't need to multiply
		bmi 	_VHNoMultiply
		;
		;		Make zTemp0 = 2nd index * (first max index+1)
		;
		phx
		lda 	NSMantissa0+2,x 			; get 2nd index on stack
		pha
		ldy 	#2 							; get 1st size in A
		lda 	(zaTemp),y
		inc 	a 							; add 1 for zero base
		plx
		jsr 	Multiply8x8 				; calculate -> Z0
		plx
_VHNoMultiply:
		;
		; 		Add the 1st index, gives us an offset (by number) in the array memory
		;
		clc
		lda 	zTemp0
		adc 	NSMantissa0+1,x
		sta 	zTemp0
		lda 	zTemp0+1
		adc 	#0
		sta 	zTemp0+1
		;
		;		Get the type (from Status,0) and use it to scale up
		;
		lda 	NSStatus,x
		jsr 	ScaleByBaseType
		;
		;		Add the base memory address to get the final address.
		;
		clc
		lda 	(zaTemp)
		adc 	zTemp0
		sta 	NSMantissa0,x
		;
		ldy 	#1
		lda 	(zaTemp),y
		adc 	zTemp0+1
		sta 	NSMantissa1,x
		;
		ply 								; restore position
		rts

_VHBadIndex:
		.error_arrayidx
_VHBadArray:
		.error_arraydec

		.send code
