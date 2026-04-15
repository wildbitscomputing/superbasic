;;
; [for]/[next] loop implementation
;;

;;
; `STK_FOR` frame layout in `basicStack`:
;
; The active [for] loop frame stores its payload in fixed byte offsets within
; the return-stack frame pointed to by `basicStack`. The offsets used by this
; module are:
;
; - `+16..+19` Step value in four-byte two's complement form.
; - `+12..+15` Terminal value in four-byte two's complement form.
; - `+8..+11` Current value of the loop index in four-byte two's complement
;             form.
; - `+6..+7`  Address of the loop index variable.
; - `+1..+5`  Saved loop-back code position.
;;

		.section code

;;
; Handle the [for] statement.
;
; Parses a [for] loop header, validates that the loop variable is an integer
; reference, evaluates the initial and terminal values, determines the step
; value (defaulting to `+1` for [to] and `-1` for [downto]), and builds the
; corresponding `STK_FOR` frame on the return stack. Once the frame is set up,
; it writes the initial loop index back to the referenced variable.
;
; \in Y         Relative offset to the statement arguments.
; \sideeffects  - Opens an `STK_FOR` frame on the return stack.
;               - Evaluates expressions into number-stack slots `0..2`.
;               - Stores loop metadata in `basicStack`.
;               - Saves the loop-back code position.
;               - Writes the initial loop index to the referenced variable.
;               - Modifies registers `A`, `X`, and `Y`.
;               - Raises `TypeError` or `SyntaxError` on invalid input.
; \see          FCIntegerToStack, CopyIndexToReference, NextCommand
;;

ForCommand: ;; [for]
		lda 	#STK_FOR+11 				; allocate 22 bytes on the return stack (see above).
		jsr 	StackOpen
		;
		;		Get an integer reference to Stack[0] - this is the loop variable.
		;
		ldx 	#0
		jsr 	EvaluateTerm
		lda 	NSStatus,x
		cmp 	#NSBIsReference+NSTInteger 	; do we have an integer 4 byte reference.
		bne		_FCError
		;
		;		= character
		;
		lda 	#KWD_EQUAL 					; =
		jsr 	CheckNextA
		;
		;		The Initial value to Stack[1]
		;
		inx
		jsr 	EvaluateInteger 			; <from> in +1
		;
		;		Save TO or DOWNTO in temporary memory
		;
		.cget 								; next should be DOWNTO or TO
		pha 								; save keyword for later
		iny 								; consume it
		cmp 	#KWD_DOWNTO
		beq 	_FCNoSyntax
		cmp 	#KWD_TO
		bne 	_FCSyntaxError
_FCNoSyntax:
		;
		;		The Terminal value to Stack[2]
		;
		inx
		jsr 	EvaluateInteger
		;
		;		Now set the +1 or -1 default step for the TO or DOWNTO
		;
		pla 								; restore DOWNTO or TO
		eor 	#KWD_DOWNTO 				; 0 if DOWNTO, #0 if TO
		beq 	_FCNotDownTo
		lda 	#2
_FCNotDownTo: 								; 0 if DOWNTO 2 if TO
		phy 								; save current position
		ldy 	#16
		dec 	a 							; 255 if DOWNTO, 1 if TO
		sta 	(basicStack),y 				; store low byte of step
		bmi 	_FCNegativeStep
		lda 	#0 							; next bytes are 0 for a step of 1
_FCNegativeStep:
		iny
		sta 	(basicStack),y 				; store rest of step in Basic Stack
		iny
		sta 	(basicStack),y
		iny
		sta 	(basicStack),y
		;
		;		Copy the reference where the index goes.
		;
		ldy 	#6 							; this is the address of the loop variable.
		lda 	NSMantissa0
		sta 	(basicStack),y
		lda 	NSMantissa1
		iny
		sta 	(basicStack),y
		;
		;		Copy the initial and terminal values in 2's complement
		;
		ldy 	#8 							; set initial index value
		ldx 	#1
		jsr 	FCIntegerToStack
		ldy 	#12 						; set the terminal value
		ldx 	#2
		jsr 	FCIntegerToStack
		;
		;		Handle optional STEP value
		;
		ply 								; restore position
		.cget 								; check for optional STEP keyword
		cmp 	#KWD_STEP
		bne 	_FCNoStep
		iny 								; consume STEP
		;
		ldx 	#0
		jsr 	EvaluateInteger 			; get the step value
		;
		phy 								; save the new position
		ldy 	#16 						; set the step value
		ldx 	#0
		jsr 	FCIntegerToStack
		ply 								; restore position
_FCNoStep:
		;
		;		Now set up the FOR Structure, starting with the code position
		;
		jsr 	STKSaveCodePosition 		; save loop back position
		;
		;		Now copy the current value to the index reference, in standard format.
		;
		bra 	CopyIndexToReference

_FCError:
		jmp 	TypeError
_FCSyntaxError:
		jmp 	SyntaxError

;;
; Copy an integer number-stack value into the [for] frame.
;
; Converts the integer value in number-stack slot `X` to four-byte two's
; complement form if necessary, then writes the four mantissa bytes to the
; `basicStack` frame starting at offset `Y`.
;
; \in X         Number-stack slot containing the integer value to copy.
; \in Y         Destination offset within `basicStack`.
; \sideeffects  - May negate `NSMantissa[0..3],x` in place for negative values
;                 before copying them.
;               - Advances `Y` while storing four bytes.
;               - Modifies register `A`.
; \see          ForCommand, NSMNegateMantissa
;;

FCIntegerToStack:
		bit 	NSStatus,x 					; is the value negative
		bpl	 	_FCNotNegative
		jsr 	NSMNegateMantissa 			; if so 2's complement the mantissa
_FCNotNegative:
		lda 	NSMantissa0,x 				; copy out to the basic stack
		sta 	(basicStack),y
		iny
		lda 	NSMantissa1,x
		sta 	(basicStack),y
		iny
		lda 	NSMantissa2,x
		sta 	(basicStack),y
		iny
		lda 	NSMantissa3,x
		sta 	(basicStack),y
		rts

;;
; Write the current [for] loop index back to the referenced variable.
;
; Reads the loop-variable address and current loop index from the active
; `STK_FOR` frame in `basicStack`, converts the stored two's complement loop
; value back into the variable's packed integer format, and writes it to the
; referenced variable record.
;
; \sideeffects  - Uses `zTemp0` as the destination pointer.
;               - Reads the loop variable address and loop index from the
;                 active `basicStack` frame.
;               - Writes four bytes to the referenced variable storage.
;               - Modifies registers `A`, `X`, and `Y`.
; \see          ForCommand, NextCommand
;;

CopyIndexToReference:
		phy
		;
		ldy 	#6 							; copy address-8 to write to zTemp0
		sec 								; (because we copy from offset 8)
		lda 	(basicStack),y
		sbc 	#8
		sta 	zTemp0
		iny
		lda 	(basicStack),y
		sbc 	#0
		sta 	zTemp0+1
		;
		ldx 	#4 							; this is the copy counter/
		;
		ldy 	#8+3 		 				; the MSB of the mantissa
		lda 	(basicStack),y
		asl 	a 							; into carry

		ldy 	#8 							; where to copy from.
		bcc 	_CITRNormal
		;
		;		Copy out -ve
		;
		sec
_CITRNegative:								; copy and negate simultaneously.
		lda 	#0
		sbc 	(basicStack),y
		sta 	(zTemp0),y
		iny
		dex
		bne 	_CITRNegative
		dey 								; look at MSB of mantissa

		lda 	(zTemp0),y 					; set the MSB as negative packed.
		ora 	#$80
		sta 	(zTemp0),y
		ply
		rts
		;
		;		Copy out +ve
		;
_CITRNormal:
		lda 	(basicStack),y 				; copy without negation.
		sta 	(zTemp0),y
		iny
		dex
		bne 	_CITRNormal
		ply 								; and exit.
		rts

;;
; Handle the [next] statement.
;
; Validates that the top return-stack frame is a [for] frame, increments the
; loop index by the stored step value, writes the updated index back to the
; loop variable, and compares the new value against the terminal bound using a
; signed comparison direction derived from the sign of the step. Control then
; either loops back to the saved code position or closes the [for] frame.
;
; \in Y         Relative offset to the statement arguments.
; \sideeffects  - Verifies the top return-stack frame type.
;               - Uses `zTemp1` as a temporary pointer and comparison offsets.
;               - Updates the loop index stored in `basicStack`.
;               - Writes the updated index to the referenced variable.
;               - Either reloads the saved loop-back position or closes the
;                 current [for] frame.
;               - Modifies registers `A`, `X`, and `Y`.
; \see          CopyIndexToReference, STKLoadCodePosition, StackClose
;;

NextCommand: ;; [next]
		lda 	#STK_FOR+11 				; check FOR is TOS
		ldx 	#ERRID_FOR 					; this error
		jsr 	StackCheckFrame

		phy
		;
		;		Set up a pointer to step value (basicStack+16) via zTemp1
		;		We use (zTemp1),y with the same y offsets as (basicStack),y
		;		so that index[y] + step[y] works (both at y=8..11, offset by 8)
		;
		lda 	basicStack 					; zTemp1 = basicStack + 8
		clc
		adc 	#8
		sta 	zTemp1
		lda 	basicStack+1
		adc 	#0
		sta 	zTemp1+1
		;
		;		Bump the index, and update the index variable
		;
		ldy 	#8 							; offset to bump
		ldx 	#4 							; four bytes to add
		clc
_NCBump:
		lda 	(basicStack),y 				; get index
		adc 	(zTemp1),y 					; add step
		sta 	(basicStack),y
		iny 								; next byte
		dex 								; are we done yet?
		bne 	_NCBump
		jsr		CopyIndexToReference		; copy it to the reference variable.
		;
		;		Compare the index and terminal value
		;
		;		if TO , exit if terminal < index (e.g. 10 < 11)
		;		if DOWNTO, exit if index < terminal (e.g. -3 < -2)
		;
		ldy 	#19 						; get MSB of step value
		lda 	(basicStack),y
		asl 	a 							; sign bit to carry
		;
		lda 	#12 						; offset of LHS = terminal offset
		sta 	zTemp1
		bcc 	_NCCompRev 					; use if step is +ve
		lda 	#8 							; now the LHS = index value
_NCCompRev:
		sta 	zTemp1 						; so zTemp1 is the index for LHS
		eor 	#(8^12) 					; and zTemp1+1 is the index for RHS
		sta 	zTemp1+1
		ldx 	#4 							; bytes to compare
		sec

_NCCompare:
		ldy 	zTemp1 						; do compare using the two indices
		lda 	(basicStack),y
		ldy 	zTemp1+1
		sbc 	(basicStack),y

		inc 	zTemp1 						; bump the indices (inc,dex do not change C or V)
		inc 	zTemp1+1
		dex 								; do it 4 times.
		bne 	_NCCompare
		;
		bvc 	_NCNoOverflow 				; convert to signed comparison
		eor 	#$80
_NCNoOverflow:
		ply 								; restore Y position
		asl 	a 							; is bit 7 set.
		bcc 	_NCLoopBack 				; if no , >= so loop back
		;
		jmp 	StackClose 					; exit the loop

_NCLoopBack:
		jmp 	STKLoadCodePosition 		; loop back

		.send code
