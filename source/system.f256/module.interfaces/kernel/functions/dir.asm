; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		dir.asm
;		Purpose:	DIR$() and DIR() functions — access buffered directory data
;		Created:	19th March 2026
;		Reviewed:	No.
;		Author:		Matthias Brukner
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
		pha 								; save value (CheckRightBracket clobbers A)
		jsr 	CheckRightBracket
		pla
		cmp 	dirFileCount 				; bounds check
		bcs 	_DSSRange
		sta 	dirFuncArg
		jmp 	DirStringImpl 				; module does buffer access + return
_DSSRange:
		jmp 	RangeError

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
		;
		lda 	dirFuncSign
		bmi 	_DNCheckNeg
		lda 	dirFuncArg 					; positive: check index < fileCount
		cmp 	dirFileCount
		bcs 	_DNRange
		bra 	_DNGo
_DNCheckNeg:
		lda 	dirFuncArg 					; negative: only -1 and -2 are valid
		cmp 	#3
		bcs 	_DNRange
_DNGo:
		jmp 	DirNumImpl 					; module does buffer access + return
_DNRange:
		jmp 	RangeError

		.send code
