
		.section 	code

;;
; Convert floating-point entry at position X in the number stack to an
; integer.
;
; Sets carry if the value was not already an exact integer.
;;
FloatIntegerPart:
		pha
		phy
		ldy		#$0							; store the carry status in Y

		lda 	NSExponent,x 				; is it integer already ?
		beq 	_exit 						; if so do nothing
		jsr 	NSMIsZero 					; is it zero ?
		beq 	_zero 						; if so return zero.

		jsr 	NSNormalise 				; normalise
		beq 	_zero 						; normalised to zero, exit zero

	_shift:
		lda 	NSExponent,x 				; if Exponent >= 0 exit.
		bpl 	_check_zero

		jsr 	NSMShiftRight 				; shift mantissa right
		bcc 	+
		ldy 	#$1							; record that we lost a non-zero bit
+   	inc 	NSExponent,x 				; bump exponent
		bra 	_shift

	_check_zero:
		jsr 	NSMIsZero 					; avoid -0 problem
		bne 	_exit	 					; set to zero if mantissa zero.

	_zero:
		jsr 	NSMSetZero

	_exit:
		cpy		#$1							; sets the carry flag if Y is 1
		ply
		pla
		rts

		.send 	code
