; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		cd.asm
;		Purpose:	CD$() function — return current working directory
;		Created:	18th March 2026
;		Reviewed:	No.
;		Author:		M. Brukner
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;		CD$() — returns the current working directory as a string.
;
; ************************************************************************************************

OP_JMP = $4C

CdStringUnary:	;; [cd$(]
		plx 								; balance stack (return from unary dispatch)
		jsr 	CheckRightBracket 			; consume the )
		;
		lda 	kernel.Chdir 				; check if kernel supports chdir
		cmp 	#OP_JMP
		bne 	_CDSFallback
		stz 	kernel.args.buflen 			; buflen=0 = getcwd
		lda 	#lineBuffer & $FF
		sta 	kernel.args.buf
		lda 	#lineBuffer >> 8
		sta 	kernel.args.buf+1
		lda 	KNLDefaultDrive
		sta 	kernel.args.directory.open.drive
		jsr 	kernel.Chdir
		bcc 	_CDSReturn 					; success
		;
_CDSFallback:
		lda 	#"/" 						; fallback: return "/"
		sta 	lineBuffer
		stz 	lineBuffer+1
		;
_CDSReturn:
		ldx 	#0 							; return lineBuffer as string
		lda 	#lineBuffer & $FF
		sta 	NSMantissa0,x
		lda 	#lineBuffer >> 8
		sta 	NSMantissa1,x
		lda 	#NSBIsString
		sta 	NSStatus,x
		rts

		.send code
