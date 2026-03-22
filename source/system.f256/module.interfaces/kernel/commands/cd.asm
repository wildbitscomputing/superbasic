; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		cd.asm
;		Purpose:	Change current directory
;		Created:	18th March 2026
;		Reviewed:	No.
;		Author:		Matthias Brukner
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;		CD command: change current working directory.
;		CD "path" changes to the given path.
;		CD alone prints the current directory.
;
; ************************************************************************************************

Command_Cd:		;; [cd]
		lda 	kernel.Chdir 				; check if kernel supports chdir
		cmp 	#OP_JMP
		beq 	_CDSupported
		.error_notdone
_CDSupported:
		.cget
		cmp 	#KWC_EOL 					; end of line?
		beq 	_CDPrintCwd
		cmp 	#KWD_COLON
		beq 	_CDPrintCwd
		;
		;		CD "path" — change directory
		;
		ldx 	#0
		jsr 	EvaluateString 				; path string -> zTemp0
		lda 	zTemp0
		sta 	kernel.args.buf
		lda 	zTemp0+1
		sta 	kernel.args.buf+1
		;
		ldy 	#$FF 						; find string length
_CDPathLen:
		iny
		lda 	(zTemp0),y
		bne 	_CDPathLen
		sty 	kernel.args.buflen
		;
		lda 	KNLDefaultDrive
		sta 	kernel.args.directory.open.drive
		jsr 	kernel.Chdir
		bcc 	_CDDone
		.error_range 						; chdir failed
_CDDone:
		jmp 	WarmStart
		;
		;		CD alone — print current directory
		;
_CDPrintCwd:
		stz 	kernel.args.buflen 			; buflen=0 means getcwd
		lda 	#lineBuffer & $FF
		sta 	kernel.args.buf
		lda 	#lineBuffer >> 8
		sta 	kernel.args.buf+1
		lda 	KNLDefaultDrive
		sta 	kernel.args.directory.open.drive
		jsr 	kernel.Chdir
		bcs 	_CDDone 					; error, just return
		lda 	#lineBuffer & $FF
		ldx 	#lineBuffer >> 8
		jsr 	PrintStringXA
		lda 	#13
		jsr 	EXTPrintCharacter
		jmp 	WarmStart

		.send code
