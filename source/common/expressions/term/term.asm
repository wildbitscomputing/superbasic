;;
; Term evaluation
;;

		.section code

;;
; Evaluate a term at stack level `X`.
;
; Evaluates a single term (operand) in an expression and stores the result at the specified
; stack level. A term can be a number, quoted string, hex constant, variable reference,
; unary function, or punctuation unary operator:
;
;   number (in ASCII)		$30-$39 (0-9)
;	quoted string 			$FF <data>
;	hex constant 			$FE <data>
;	variable 				$40-$7F
; 	text unary function 	defined by constants
;	punctuation unary 		@ ? ! ( -
;
; \in Y         Relative offset to the beginning of the term.
; \in X         Stack level to use for evaluation.
; \sideeffects  - Modifies registers `A`, `Y` and `zTemp0`.
;               - Advances code pointer past the term.
;               - Updates `NSStatus`, `NSMantissa*` at stack level X.
;               - May call various handlers based on term type.
; \see          EvaluateExpression, VariableHandler, EncodeNumberStart, Dereference
;;
EvaluateTerm:
		.cget 								; look at first character
		bmi 	_ETCheckUnary 				; unary function ? (text ones)
		cmp 	#$40 						; 40-7F => identifier reference
		bcs 	_ETVariable
		cmp 	#'0' 						; is it a number
		bcc 	_ETPuncUnary 				; if not it might be a punctuation unary.
		cmp 	#'9'+1
		bcs 	_ETPuncUnary

		; ----------------------------------------------------------------------------------------
		;
		;		A number 0-9 found - use the number FSM to convert it to an actual number.
		;
		; ----------------------------------------------------------------------------------------

		jsr 	EncodeNumber._ENStartDigit 	; already validated as 0-9
		jmp _ETNumber

		; ----------------------------------------------------------------------------------------
		;
		;		Token found - check it's a unary function (non punctuation) like LEFT$
		; 		or could be the marker for a string or a hex constant.
		;
		; ----------------------------------------------------------------------------------------

_ETCheckUnary:
		cmp 	#KWC_STRING 				; string token
		beq 	_ETString
		cmp 	#KWC_HEXCONST 				; hex constant.
		beq 	_ETHexConstant
		;
		cmp 	#KWC_FIRST_UNARY 			; check it actually is a unary function
		bcc 	_ETSyntaxError
		cmp 	#KWC_LAST_UNARY+1
		bcs 	_ETSyntaxError
		;
		phx 								; push X on the stack
		asl 	a 							; put vector x 2 into X
		tax
		iny 								; consume unary function token
		jmp 	(VectorSet0,x) 				; and do it.

_ETSyntaxError:
		jmp 	SyntaxError

		; ----------------------------------------------------------------------------------------
		;
		;		String $FE <total length> <ASCII digits> $0
		;
		; ----------------------------------------------------------------------------------------

_ETHexConstant:
		iny 								; skip #
		iny 								; skip count
		jsr 	NSMSetZero 					; clear result
_ETHLoop:
		.cget 								; get next character
		iny 								; and consume
		cmp 	#0 							; exit if zero
		beq 	_ETHExit
		pha 								; save on stack.
		jsr 	NSMShiftLeft 				; x 2
		jsr 	NSMShiftLeft 				; x 4
		jsr 	NSMShiftLeft 				; x 8
		jsr 	NSMShiftLeft 				; x 16
		pla 								; ASCII
		cmp 	#'A'
		bcc 	_ETHNotChar
		sbc 	#7
_ETHNotChar:
		and 	#15 						; digit now
		ora 	NSMantissa0,x 				; put in LS Nibble
		sta 	NSMantissa0,x
		bra 	_ETHLoop 					; go round.
_ETHExit:
		rts

		; ----------------------------------------------------------------------------------------
		;
		;		String $FF <total length> <text> $00
		;
		; ----------------------------------------------------------------------------------------

_ETString:
		iny 								; look at length
		.cget 								; push length on stack.
		pha
		iny 								; first character
		jsr 	MemoryInline 				; put address of string at (code-Ptr),y on stack
											; (may have to duplicate into soft memory)
		pla 								; restore count and save
		sta 	zTemp0

		tya 								; add length to Y to skip it.
		clc
		adc 	zTemp0
		tay

		lda 	#NSTString 					; mark as string
		sta 	NSStatus,x
		rts

		; ----------------------------------------------------------------------------------------
		;
		;		Variable reference 40-7F
		;
		; ----------------------------------------------------------------------------------------

_ETVariable:
		bra 	VariableHandler

		; ----------------------------------------------------------------------------------------
		;
		;		Punctuation Unary these are @ (deref) ?! (indirection) ( (parenthesis)
		;		and - (negation)
		;
		; ----------------------------------------------------------------------------------------

_ETPuncUnary:
		iny 								; consume the unary character
		cmp 	#KWD_MINUS 					; unary minus
		beq 	_ETUnaryNegate
		cmp 	#KWD_ATCH 					; @ reference -> constant
		beq 	_ETDereference
		cmp 	#KWD_LPAREN 				; parenthesis
		beq 	_ETParenthesis
		stz 	zTemp0 						; zTemp0 is the indirection level.
		cmp 	#KWD_QMARK 					; byte indirection (0) ?
		beq 	_ETIndirection
		inc 	zTemp0
		cmp 	#KWD_PLING					; word indirection (1) \
		bne 	_ETSyntaxError

		; ----------------------------------------------------------------------------------------
		;
		;		Indirection, ind count-1 is in zTemp0 - does unary ? (byte) ! (word)
		;
		; ----------------------------------------------------------------------------------------

_ETIndirection:
		lda 	zTemp0 						; push indirection amount (0-1) => (1-2) on the stack
		inc 	a
		pha
		jsr 	EvaluateTerm				; evaluate the term
		jsr 	Dereference 				; dereference it.
		lda 	NSStatus,x 					; must be a +ve integer.
		bne 	_ETTypeMismatch
		pla 								; indirection 1-2
		ora 	#NSBIsReference 			; make it a reference.
		sta 	NSStatus,x
		rts
_ETTypeMismatch:
		jmp 	TypeError

		; ----------------------------------------------------------------------------------------
		;
		;		Unary negation (-)
		;
		; ----------------------------------------------------------------------------------------

_ETUnaryNegate:
		jsr 	EvaluateTerm				; evaluate the term
		jsr 	Dereference 				; dereference it.
		lda 	NSStatus,x 					; must be a number
		and 	#NSTString
		bne 	_ETTypeMismatch
		jmp 	NSMNegate  					; just toggles the sign bit.

		; ----------------------------------------------------------------------------------------
		;
		;		Dereference a reference to a constant address (@)
		;
		; ----------------------------------------------------------------------------------------

_ETDereference:
		jsr 	EvaluateTerm				; evaluate the term
		lda 	NSStatus,x 					; must be a reference
		and 	#NSBIsReference
		beq 	_ETTypeMismatch
		stz 	NSStatus,x 					; make it an integer address
		rts

		; ----------------------------------------------------------------------------------------
		;
		;		Expression in parenthesis.
		;
		; ----------------------------------------------------------------------------------------

_ETParenthesis:
		jsr 	EvaluateExpression 			; evaluate here, from lowest precedence
		jmp 	CheckRightBracket 			; check for )

_ETNumber:
		iny
		.cget
		; Integer delimiters need not enter the generic number state machine.
		; Decimal numbers retain its original finalisation and rounding path.
		cmp #'0'
		bcc _ETNumberDot
		cmp #'9'+1
		bcs _ETNumberDone
		jsr EncodeNumber._ENNoRestart ; digit already validated above
		bra _ETNumber
_ETNumberDot:
		cmp #'.'
		bne _ETNumberDone
		jsr EncodeNumberContinue
_ETDecimal:
		iny
		.cget
		jsr EncodeNumberContinue
		bcs _ETDecimal
_ETNumberDone:
		rts

		.send code
