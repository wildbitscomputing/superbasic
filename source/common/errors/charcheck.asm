; ***************************************************************************************
; ***************************************************************************************
;
;		Name : 		charcheck.asm
;		Author :	Paul Robson (paul@robsons.org.uk)
;		Created : 	21st September 2022
;		Reviewed :	23rd November 2022
;		Purpose :	Check next character type functions.
;
; ***************************************************************************************
; ***************************************************************************************

		.section code

; ***************************************************************************************
;
; 		Common Macro, can create for any token. Use for common ones like ) and ,
;
; ***************************************************************************************

checknext .macro
		.cget 								; get next character and skip it
		iny
		cmp 	#\1 						; exit if matches
		bne 	CNAFail
		rts
		.endm

CheckRightBracket:
		.checknext KWD_RPAREN

CheckComma:
		.checknext KWD_COMMA

; ***************************************************************************************
;
; 							Check A, gives Syntax Error
;
; ***************************************************************************************

CheckNextA:
		.ccmp								; match ?
		bne 	CNAFail
		iny 								; skip character
		rts 								; and exit
CNAFail:
		jmp 	SyntaxError

		.send 	code

; ***************************************************************************************
;
;									Changes and Updates
;
; ***************************************************************************************
;
;		Date			Notes
;		==== 			=====
;
; ***************************************************************************************
