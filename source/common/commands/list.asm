; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		list.asm
;		Purpose:	LIST statement
;		Created:	4th October 2022
;		Reviewed:	1st December 2022
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;									LIST the program
;
; ************************************************************************************************

Command_List:	;; [list]
		stz 	listIndent 					; reset indent.
		;
		lda 	#$3F 						; silence at list.
		jsr 	SNDCommand
		;
		.cget 								; followed by an identifier ?
		and 	#$C0 				 		; if so, we are list procedure() which is a seperate block
		cmp 	#$40  						; of code.
		beq 	_CLListProcedure
		;
		stz		NSMantissa0+4				; set the lower (slot 4) to 0 and upper (slot 7) to $FFFF
		stz 	NSMantissa1+4 				; these are the default top and bottom.
		lda 	#$FF
		sta 	NSMantissa0+7
		sta 	NSMantissa1+7
		;
		;		Now decode the various combinations of list [something],[something]
		;
		;
		;		First value.
		;
		.cget 								; is first a comma, if so goto 2nd
		cmp 	#KWD_COMMA
		beq 	_CLSecond
		jsr 	CLIsDigit 					; if not digit, list all
		bcs 	_CLStart
		ldx 	#4 							; get 1st range into slot 4
		jsr 	Evaluate16BitInteger
		.cget 								; comma follows ?
		cmp 	#KWD_COMMA
		beq 	_CLSecond 					; if so go get it
		;
		lda 	NSMantissa0+4 				; copy 4->7
		sta 	NSMantissa0+7
		lda 	NSMantissa1+4
		sta 	NSMantissa1+7
		bra 	_CLStart
		;
		;		Second value.
		;
_CLSecond:
		iny 								; consume comma
		jsr 	CLIsDigit 					; digit found
		bcs 	_CLStart 					; if not, continue listing
		ldx 	#7 							; load 2nd range into slot 7
		jsr 	Evaluate16BitInteger
		;
		;		Loop through the whole program
		;
_CLStart
		; Decode range expressions with the caller's array RAM still mapped.
		; The cold listing walk itself only touches program/identifier memory.
		jsr Slot3BankIn
		jmp _CLStartPaged
_CLListProcedure:
		jsr Slot3BankIn
		jmp _CLListProcedurePaged
		.send code
		.section page2
		.logical * + $2000
_CLStartPaged:
		.cresetcodepointer
		;
_CLLoop:
		.breakcheck 		 				; break check here, as we want the option of breaking out of long lists.
		bne 	_CLBreak

		.cget0 								; any more ?
		beq 	_CLExit
		;
		ldx 	#4 							; check range every time, line numbers aren't in order.
		jsr 	CLCompareLineNo
		bcc 	_CLNext
		ldx 	#7
		jsr 	CLCompareLineNo
		beq 	_CLDoThisOne
		bcs 	_CLNext
_CLDoThisOne:
		jsr 	CLListOneLineShift 			; list current line (skip if shift held)
_CLNext:
		.cnextline
		bra 	_CLLoop
_CLExit:
		jmp 	WarmStart
_CLBreak:
		.error_break


; ************************************************************************************************
;
;									List from procedure.
;
; ************************************************************************************************

_CLListProcedurePaged:
		.cget 								; get the reference - look for this (4000-7FFF) in the code.
		sta 	zTemp1
		iny
		.cget
		sta 	zTemp1+1
		;
		;		Look for the PROC or FN definition.
		;
		.cresetcodepointer 					; search for it.
_CLLPSearch:
		.cget0 								; get offset
		cmp 	#0 							; if zero, end
		beq 	_CLExit

		ldy 	#3 							; check if PROC or FN something
		.cget
		cmp 	#KWD_PROC
		beq 	_CLLPCheckName
		cmp 	#KWD_FN
		bne 	_CLLPNext
_CLLPCheckName:
		pha 								; save keyword (PROC or FN)
		iny 								; check if it's this name.
		.cget
		cmp 	zTemp1 						; does it match ?
		bne 	_CLLPNextPop
		iny
		.cget
		cmp 	zTemp1+1
		beq 	_CLLPFoundPop
_CLLPNextPop:
		pla
_CLLPNext:
		.cnextline
		bra 	_CLLPSearch
		;
		;		Definition found. Stack has the keyword (PROC or FN).
		;		Determine the closing token.
		;
_CLLPFoundPop:
		pla
		cmp 	#KWD_FN
		bne 	_CLLPFoundProc
		;
		;		FN: check for single-line (= expr) — just list one line.
		;
		iny 								; skip past params to find '=' or EOL
		jsr 	SkipParamList
		.cget
		cmp 	#KWD_EQUAL
		beq 	_CLLPSingleLine 			; single-line FN: list one line only
		lda 	#KWD_ENDFN 					; multi-line FN: stop at ENDFN
		bra 	_CLLPListDef
_CLLPFoundProc:
		lda 	#KWD_ENDPROC 				; PROC: stop at ENDPROC
_CLLPListDef:
		sta 	listEndToken
		;
		;		List lines until closing token or end of program.
		;
_CLLPListLoop:
		.cget0 								; reached end
		beq 	_CLExit
		.breakcheck
		bne 	_CLBreak
		ldy 	#3
		.cget
		pha
		jsr 	CLListOneLineShift
		.cnextline
		pla
		cmp 	listEndToken 				; reached closing token?
		bne 	_CLLPListLoop
		jmp 	WarmStart
		;
		;		Single-line FN: list just this one line.
		;
_CLLPSingleLine:
		jsr 	CLListOneLineShift
		jmp 	WarmStart
		.endlogical
		.send page2
		.section code

; ************************************************************************************************
;
;								List the current line
;
; ************************************************************************************************

CLListOneLine:
		jsr 	ScanGetCurrentLineStep 		; get indent adjust.
		jsr 	TKListConvertLine 			; convert line into token Buffer
		ldx 	#(tokenBuffer >> 8) 		; print that line
		lda 	#(tokenBuffer & $FF)
		jsr 	PrintStringXA
		lda 	#13 						; new line
		jmp 	EXTPrintCharacter

; ************************************************************************************************
;
;		List one line, pause if Shift is held.
;
; ************************************************************************************************

CLListOneLineShift:
		jsr 	CLListOneLine				; always print the line
_CLLOSCheck:
		jsr 	IsShiftPressed				; shift held?
		beq 	_CLLOSDone
		jsr 	kernel.Yield				; wait for next interrupt
		jsr 	GetNextEvent				; process event to update KeyStatus
		bra 	_CLLOSCheck
_CLLOSDone:
		rts

; ************************************************************************************************
;
;		Compare Line# current line vs Line Number in S[X], returns CC/CS/Z/NZ as per 6502
;
; ************************************************************************************************

CLCompareLineNo:
		sec
		ldy 	#1
		.cget
		sbc 	NSMantissa0,x
		sta 	zTemp0
		iny
		.cget
		sbc 	NSMantissa1,x
		ora 	zTemp0
		rts

; ************************************************************************************************
;
;									Check if digit, CC if yes, CS no.
;
; ************************************************************************************************

CLIsDigit:
		.cget
		cmp 	#"0"
		bcc	 	_CLIDExitFalse
		cmp 	#"9"+1
		rts
_CLIDExitFalse:
		sec
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
;		05/12/22 		LIST break reports.
;		15/12/22 		LIST silences sound.
;		02/01/23 		Break check call now a macro.
;		01/03/23 		LIST procedure checks break.
;		19/02/26 		Added Shift-pause: hold Shift to pause listing.
;
; ************************************************************************************************
