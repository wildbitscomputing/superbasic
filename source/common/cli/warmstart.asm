; ***************************************************************************************
; ***************************************************************************************
;
;		Name : 		warmstart.asm
;		Author :	Paul Robson (paul@robsons.org.uk)
;		Created : 	5th October 2022
;		Reviewed :	1st December 2022
;		Purpose :	Main console I/O loop
;
; ***************************************************************************************
; ***************************************************************************************

; ***************************************************************************************
;
;									Warm Start
;
; ***************************************************************************************

		.section code

WarmStart:
		ldx 	#$FF
		txs
		;
		;		Reset slot 3 module state in case an error left it mapped.
		;		(Error paths in slot 3 modules jump to ErrorHandler/WarmStart,
		;		 skipping Slot3BankOut and leaving slot 3 on the module page.)
		;
		lda 	Slot3Depth
		beq 	_slot3ok
		stz 	Slot3Depth
		lda 	#3
		sta 	8+3
_slot3ok:

		lda		EXTPendingWrap				; check for a pending wrap state
		beq 	_set_color					; no pending wrap, jump to set color
		jsr		EXTApplyPendingWrap			; apply pending wrap

	_set_color:
		lda 	#CLICommandLine+$80 		; set console colour whatever the current colour is.
		jsr 	EXTPrintCharacter

		jsr 	InputLine 					; get line to lineBuffer
		;
		;		Check for /x
		;
		lda 	lineBuffer 					; first character is slash
		cmp 	#"/"
		bne 	_WSNotSlash
		jsr 	IsDestructiveActionOK 		; confirm if unsaved program (before module page-in)
		bcs 	WarmStart 					; user cancelled
		ldx 	#(lineBuffer+1) >> 8 		; boot rest of line.
		lda 	#(lineBuffer+1) & $FF
		jsr 	EXTBootXA 					; JSR so wrapper restores slot 5 on return
		jsr 	ResetTokenBuffer 			; RunNamed returned, program was not found
		.error_noprogram

_WSNotSlash:
		jsr 	TKTokeniseLine 				; tokenise the line
		;
		;		Decide whether editing or running
		;
		lda 	tokenLineNumber 			; line number <> 0
		ora 	tokenLineNumber+1
		bne 	_WSEditCode 				; if so,edit code.
		;
		;		Run code in token buffer
		;
		stz 	tokenOffset 				; zero the "offset", meaning it only runs one line.
		lda 	pageCount 					; set page index to last page so DoCheckEnd
		dec 	a 							; sees end-of-program (CPX pageCount sets Z=1
		sta 	codePtr+2 					; when codePtr+2 = pageCount-1, after INX).
		.csetcodepointer tokenOffset		; set up the code pointer.
		lda 	tokenBuffer 				; nothing to run
		cmp 	#KWC_EOL
		beq 	WarmStart
		jsr 	RUNCodePointerLine 			; execute that line.
		bra 	WarmStart
		;
		;		Editing code in token buffer.
		;
_WSEditCode:
		jsr 	EditProgramCode 			; edit the program code
		jsr 	ClearSystem 				; clear all variables etc.
		bra 	WarmStart

		.send code

; ***************************************************************************************
;
;									Changes and Updates
;
; ***************************************************************************************
;
;		Date			Notes
;		==== 			=====
;		26/11/22 		Added code to set console colour when typing in commands.
;		25/02/23		Support for /<command>
;
; ***************************************************************************************
