;;
; [print], [cprint], and [input] statements implementation
;;
		.section code

;;
; Handle the [input] statement.
;
; Interprets the [input] statement's arguments to read user input and assign
; values to variables. Operates identically to [print] for non-variable
; arguments; performs input when a variable is encountered.
;
; \in Y         Relative offset to statement arguments.
; \sideeffects  - Clears `isPrintFlag`.
;               - See `Command_IP_Main` side effects
; \see          [print], [cprint], Command_IP_Main
;;
Command_Input:  ;; [input]
		stz 	isPrintFlag
		bra 	Command_IP_Main

;;
; Handle the [cprint] statement.
;
; Interprets the [cprint] statement's arguments to print output in character
; mode. Operates identically to [print] except setting the print flag for
; character mode output.
;
; \in Y         Relative offset to statement arguments.
; \sideeffects  - Sets `isPrintFlag` to character mode (`0x7F`)
;               - See `Command_IP_Main` side effects
; \see          [input], [print], Command_IP_Main
;;
Command_CPrint:	;; [cprint]
		lda 	#$7F
		sta 	isPrintFlag 				; set input flag to character mode
		bra 	Command_IP_Main

;;
; Handle the [print] statement.
;
; Interprets the [print] statement's arguments to print output to the screen.
; Operates identically to [input] for non-variable arguments; when a variable
; is encountered, prints its value.
;
; \in Y         Relative offset to statement arguments.
; \sideeffects  - Sets `isPrintFlag` to control character mode (`0xFF`)
;               - See `Command_IP_Main` side effects
; \see          [input], [cprint], Command_IP_Main
;;
Command_Print:	;; [print]
		lda 	#$FF
		sta 	isPrintFlag 				; set input flag
		;

;;
; Shared implementation for [print], [cprint], and [input] statements.
;
; Interprets the statement's arguments to read user input or print output to
; the screen. When interpreting variable arguments, `isPrintFlag` controls
; whether to print or read and assign the input.
;
; \in Y             Relative offset to statement arguments.
; \in isPrintFlag   Controls operation mode (0=input, $7F=cprint, $FF=print).
; \sideeffects      - Advances the `Y` register to the end of the statement.
;                   - Modifies registers `A` and `X`.
;                   - May call various print/input routines based on argument
;                     types.
; \see              Command_Input, Command_Print, Command_CPrint,
;                   EvaluateExpressionAt0, CIInputValue, CPPrintStringXA,
;                   CPPrintVector, CPPVControl
;;
Command_IP_Main:
		; carry being clear means last print wasn't comma/semicolon
		clc
		;
		;		Print Loop
		;
_CPLoop:
		php 								; save last action flag
		.cget 								; get next character
		cmp  	#KWC_EOL 					; end of line or colon, exit now.
		beq 	_CPExit
		cmp 	#KWD_COLON
		beq 	_CPExit
		cmp 	#KWD_QUOTE 					; apostrophe (comment to end of line)
		beq 	_CPExit
		pla 								; throw last action flag
		;
		;		Decide what's next
		;
		.cget 								; next character and bump
		iny
		cmp 	#KWD_SEMICOLON				; is it a semicolon
		beq 	_CPContinueWithSameLine
		cmp 	#KWD_COMMA 					; comma
		beq 	_CPTab
		cmp 	#KWD_AT 					; `at` modifier
		beq 	_CPAtModifier
		cmp 	#KWD_TABLPAREN 				; `tab` modifier
		beq 	_CPTabModifier
		dey 								; undo the get
		jsr 	EvaluateExpressionAt0 		; evaluate expression at 0.
		lda 	NSStatus,x 					; read the status
		and 	#NSBIsReference 			; is it a reference
		beq 	_CPIsValue 					; no, display it
		;
		lda 	isPrintFlag 				; if print, dereference and print
		bne 	_CPIsPrint 					; otherwise display.
		jsr 	CIInputValue 				; input a value to the reference
		bra 	_CPNewLine

_CPIsPrint:
		jsr 	Dereference 				; dereference if required.
_CPIsValue:
		lda 	NSStatus,x 					; is it a number
		and 	#NSBIsString
		beq 	_CPNumber
		;
		ldx 	NSMantissa1 				; string, print the text.
		lda 	NSMantissa0
		jsr 	CPPrintStringXA
		bra 	Command_IP_Main 			; loop round clearing carry so NL if end
		;
		;		Print number
		;
_CPNumber:
		lda 	#5 							; maximum decimals
		jsr 	ConvertNumberToString 		; convert to string (in unary str$() function)
		ldx 	#decimalBuffer >> 8
		lda 	#decimalBuffer & $FF
		jsr 	CPPrintStringXA 			; print it.
		bra 	Command_IP_Main				; loop round clearing carry so NL if end
		;
		;		`at row, column` modifier
		;
_CPAtModifier:
		jsr 	CPPrintAt			        ; subroutine to keep `_CPLoop` within branch range
		bra 	Command_IP_Main
_CPTabModifier:
		jsr 	CPPrintTab			        ; subroutine to keep `_CPLoop` within branch range
		bra 	Command_IP_Main
		;
		;		New line
		;
_CPNewLine:
		lda 	#13
		bra 	_CPPrintCharDirect
		;
		;		Comma, Semicolon.
		;
_CPTab:
		lda 	#9 							; print TAB
_CPPrintCharDirect:
		jsr 	CPPVControl 				; print TAB/CR using the non PETSCII

_CPContinueWithSameLine:
		sec 								; loop round with carry set, which
		bra 	_CPLoop 					; will inhibit final CR
		;
		;		Exit
		;
_CPExit:
		plp 								; get last action flag
		bcs 	_CPExit2  					; carry set, last was semicolon or comma
		lda 	#13 						; print new line
		jsr 	CPPVControl
_CPExit2:
		rts

;;
; Input to a variable reference
;
; Reads a line of user input from the keyboard and assigns it to the current variable reference.
; Handles both string and numeric assignments, echoing input and supporting backspace editing.
; If the target is a string variable, assigns the input as a string; if numeric, parses and
; assigns the value.
;
; \in NSStatus  Determines if assignment is string or number.
; \sideeffects  - Modifies registers `A`, `X`, `Y`
;               - Modifies `lineBuffer`, `NSMantissa[0..3]`, `NSStatus`, and `zTemp0`.
;               - Calls `AssignVariable`, `ValEvaluateZTemp0`, and print routines for echo and error.
; \see          CPInputVector, EXTPrintCharacter, AssignVariable, ValEvaluateZTemp0
;;
CIInputValue:
		lda		EXTPendingWrap				; check for pending wrap before input
		beq 	_input
		phy
		jsr 	EXTApplyPendingWrap			; apply pending wrap if needed
		ply

	_input:
		stz		EXTPendingWrapEnabled		; disable pending wrap for user input
		ldx 	#0 							; input a line
_CIInputLine:
		jsr 	CPInputVector 				; get key
		cmp 	#13 						; 13 = End
		beq 	_CIHaveValue
		cmp 	#8 							; 8 = BS
		beq 	_CIBackspace
		cmp 	#32 						; ignore other control characters
		bcc 	_CIInputLine
		cpx 	#80 						; max length
		bcs 	_CIInputLine
		sta 	lineBuffer,x
		inx
		jsr 	EXTPrintCharacter 			; echo it.
		bra 	_CIInputLine
		;
_CIBackspace:
		cpx 	#0 							; nothing to delete
		beq 	_CIInputLine
		jsr 	EXTPrintCharacter 			; echo it.
		dex
		bra 	_CIInputLine
		;
_CIHaveValue:
		stz 	lineBuffer,x 				; ASCIIZ string now in line buffer.
		lda 	NSStatus 					; was it a string assignment
		and 	#NSBIsString
		beq 	_CIAssignNumber 			; assign a number
		;
		;		Assign string
		;
		ldx 	#1
		lda 	#lineBuffer & $FF 			; set up to point to new string
		sta 	NSMantissa0,x
		lda 	#lineBuffer >> 8
		sta 	NSMantissa1,x
		stz 	NSMantissa2,x
		stz 	NSMantissa3,x
		lda 	#NSBIsString 				; so it becomes a string value
		sta  	NSStatus,x
		bra 	_assign_and_exit
		;
		;		Assign number
		;
_CIAssignNumber:
		lda 	#lineBuffer & $FF 			; set up to point to new string
		sta 	zTemp0
		lda 	#lineBuffer >> 8
		sta 	zTemp0+1
		ldx 	#1 							; put in slot 1
		jsr 	ValEvaluateZTemp0 			; use the VAL() code
		bcc 	_assign_and_exit
		lda 	#"?" 						; error ?
		jsr 	CPPrintVector
		bra 	CIInputValue

	_assign_and_exit:
		dex 								; X = 0
		jsr 	AssignVariable

		lda		#1
		sta 	EXTPendingWrapEnabled		; re-enable pending wrap
		rts

;;
; Print a null-terminated string.
;
; Prints each character of a null-terminated string using the vectored print routine.
; The string is accessed via a 16-bit address passed in registers X and A.
;
; \in X         High byte of string address.
; \in A         Low byte of string address.
; \return       None.
; \sideeffects  - Modifies 'A` register and `zTemp0`.
;               - Calls `CPPrintVector` for each character.
; \see          CPPrintVector
;;
CPPrintStringXA:
		phy
		stx 	zTemp0+1
		sta 	zTemp0
		ldy 	#0
_PSXALoop:
		lda 	(zTemp0),y
		beq 	_PSXAExit
		jsr 	CPPrintVector
		iny
		bra 	_PSXALoop
_PSXAExit:
		ply
		rts

;;
; Print a character
;
; Routes character output to the appropriate print handler based on the current
; print mode. Uses `isPrintFlag` to determine whether to print with or without
; control character processing.
;
; \in A             Character to print.
; \in isPrintFlag   Determines control character processing ($FF=print control
;                   chars).
; \sideeffects      - Calls either `EXTPrintCharacter` or `EXTPrintNoControl`.
; \see              CPPVControl, EXTPrintNoControl, EXTPrintCharacter
;;
CPPrintVector:
		bit 	isPrintFlag 				; check if char only mode and call appropriate handler
		bmi 	CPPVControl
		jmp 	EXTPrintNoControl

;;
; Print a control character
;
; Prints a character with control character processing enabled.
;
; \in A         Character to print.
; \sideeffects  - Calls `EXTPrintCharacter`.
; \see          CPPrintVector, EXTPrintCharacter
;;
CPPVControl:
		jmp 	EXTPrintCharacter

;;
; Input a character.
;
; Gets a single character from the keyboard input system.
;
; \in           None.
; \out A        Character read from input.
; \sideeffects  - Calls `KNLGetSingleCharacter`.
; \see          KNLGetSingleCharacter, CPPrintVector
;;
CPInputVector:
		jmp 	KNLGetSingleCharacter

;;
; Handle the `at row,column` modifier for print/input statements.
;
; Parses row and column coordinates from the statement and positions the
; cursor at the specified screen location. Both coordinates are range-checked
; against screen dimensions.
;
; \in Y             Current parsing position in the statement.
; \out Y            Updated parsing position after consuming row,column arguments.
; \out EXTRow       Set to the specified row coordinate.
; \out EXTColumn    Set to the specified column coordinate.
; \out EXTAddress   Updated to point to the start of the specified row.
; \sideeffects      - Modifies registers `A` and `X`.
; \see              Evaluate8BitInteger, CheckComma, EXTSetCurrentLine,
;                   EXTScreenHeight, EXTScreenWidth, RangeError
;;
CPPrintAt:
		ldx		#0 							; bottom stack level
		jsr		Evaluate8BitInteger			; parse row into `A`
		cmp		EXTScreenHeight				; check if row is within valid range
		bcs		_range_error
		pha									; save it on the stack
		jsr		CheckComma					; ensure the next character is a comma
		jsr		Evaluate8BitInteger			; parse column into `A`
		cmp		EXTScreenWidth				; check if column is within valid range
		bcs		_range_error

		; successfully parsed row and column, can set the cursor position now
		sta		EXTColumn					; save column into `EXTColumn`
		pla 								; restore row into `A`
		sta 	EXTRow						; save row into `EXTRow`
		stz 	EXTPendingWrap				; clear pending wrap, if any

		phy
		jsr 	EXTSetCurrentLine			; set current line address to `EXTRow`
		ply
		rts

_range_error:
		jmp 	RangeError 					; branch to range error handler

;;
; Handle the `tab(column)` modifier for print/input statements.
;
; Parses the column coordinate from the statement and positions the cursor
; accordingly. If the requested column is to the left of the current cursor
; position, moves the cursor to the next line and then to the specified column.
;
; \in Y             Current parsing position in the statement.
; \out Y            Updated parsing position after consuming column argument
;                   and the closing parenthesis.
; \out EXTRow       If newline occurred, set to the updated row coordinate.
; \out EXTColumn    Set to the specified column coordinate.
; \out EXTAddress   If newline occurred, updated to point to the start of the
;                   current row.
; \sideeffects      - Modifies registers `A` and `X`.
; \see              Evaluate8BitInteger, CheckComma, EXTSetCurrentLine,
;                   EXTScreenHeight, EXTScreenWidth, RangeError
;;
CPPrintTab:
		; 		Parse
		ldx		#0 							; bottom stack level
		jsr		Evaluate8BitInteger			; parse column into `A`
		sta		zTemp0                      ; save it in `zTemp0` for now
		jsr		CheckRightBracket

		; 		Set the cursor position
		lda 	zTemp0
		cmp 	EXTColumn 					; compare with current column
		bcs 	_CPTabSetColumnOnly 		; if requested column is to the right, just move there

		inc 	EXTRow						; move to next row
		stz 	EXTPendingWrap				; clear pending wrap, if any

		pha
		phy
		jsr 	EXTSetCurrentLine			; set current line address to `EXTRow`
		ply
		pla

_CPTabSetColumnOnly:
		sta		EXTColumn					; save column into `EXTColumn`
		rts

		.send code
