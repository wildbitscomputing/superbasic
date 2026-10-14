; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		if.asm
;		Purpose:	IF command
;		Created:	1st October 2022
;		Reviewed: 	1st December 2022
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************

; ************************************************************************************************
;
;										IF (two forms)
;
; ************************************************************************************************

		.section code

IfCommand: ;; [if]
		ldx 	#0 							; Get the if test.
		jsr 	EvaluateNumber
		;
		.cget 								; what follows ?
		cmp 	#KWD_THEN  					; could be THEN <stuff> 
		bne 	_IfStructured 				; we still support it.

		; ------------------------------------------------------------------------
		;
		;						 IF ... THEN <statement> 
		;
		; ------------------------------------------------------------------------

		iny 								; consume THEN
		jsr 	NSMIsZero 					; is it zero
		beq 	_IfFail 					; if fail, go to next line
		rts 								; if THEN just continue
_IfFail:
		jmp 	EOLCommand

		; ------------------------------------------------------------------------
		;
		;		   The modern, structured, nicer IF ... ELSE ... ENDIF
		;
		; ------------------------------------------------------------------------

_IfStructured:
		jsr 	NSMIsZero 					; is it zero
		bne 	_IfExit 					; if not, then continue normally.
		lda 	#KWD_ELSE 					; look for else/endif 
		ldx 	#KWD_ENDIF
		jsr 	BranchScanForward 			; and run from there
_IfExit: 
		rts

; ************************************************************************************************
;
;					ELSE code - should be found when running a successful IF clause
;
; ************************************************************************************************

ElseCode: ;; [else] 					
		lda 	#KWD_ENDIF 					; else is only run after the if clause succeeds
		tax 								; so just go to the structure exit
		jmp 	BranchScanForward

; ************************************************************************************************
;
;										ENDIF code
;
; ************************************************************************************************

EndIf:	;; [endif]							; endif code does nothing
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
