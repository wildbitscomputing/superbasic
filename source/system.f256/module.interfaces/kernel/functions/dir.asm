; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		dir.asm
;		Purpose:	DIR$() and DIR() functions — access buffered directory data
;		Created:	19th March 2026
;		Reviewed:	No.
;		Author:		M. Brukner
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;		DIR$(n) — return filename of directory entry n (0-based).
;		Evaluate argument in main code, call module for buffer access.
;
; ************************************************************************************************

DirStringUnary:	;; [dir$(]
		plx
		ldx 	#0
		jsr 	Evaluate8BitInteger
		jsr 	CheckRightBracket
		sta 	dirFuncArg
		jmp 	DirStringImpl 				; module does buffer access + return

; ************************************************************************************************
;
;		DIR(n) — return numeric directory info.
;		n >= 0: block count, n = -1: file count, n = -2: free blocks
;
; ************************************************************************************************

DirNumUnary:	;; [dir(]
		plx
		ldx 	#0
		jsr 	EvaluateNumber
		jsr 	CheckRightBracket
		lda 	NSStatus,x
		sta 	dirFuncSign 				; save sign
		lda 	NSMantissa0,x
		sta 	dirFuncArg 					; save value
		jmp 	DirNumImpl 					; module does buffer access + return

		.send code
