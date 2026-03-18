; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		dir.asm
;		Purpose:	DIR command interface (implementation in kernel module)
;		Created:	1st January 2023
;		Reviewed:	No.
;		Author:		Paul Robson (paul@robsons.org.uk)
;					Jessie Oberreuter (gadget@hackwrenchlabs.com)
;
; ************************************************************************************************
; ************************************************************************************************

	.section code

Command_Dir:	;; [dir]
		;
		;		Parse optional path parameter (must happen in main code,
		;		not module space, because .cget accesses program memory
		;		in slot 3 which is swapped when the module is banked in).
		;
		.cget
		cmp 	#KWC_EOL 					; end of line?
		beq 	_CDNoPath
		cmp 	#KWD_COLON 					; colon separator?
		beq 	_CDNoPath
		;
		ldx 	#0
		jsr 	EvaluateString 				; evaluate path string -> zTemp0
		lda 	zTemp0 						; set path pointer
		sta 	kernel.args.directory.open.path
		lda 	zTemp0+1
		sta 	kernel.args.directory.open.path+1
		;
		ldy 	#$FF 						; find string length
_CDPathLen:
		iny
		lda 	(zTemp0),y
		bne 	_CDPathLen
		sty 	kernel.args.directory.open.path_len
		jmp 	DirImpl
_CDNoPath:
		stz 	kernel.args.directory.open.path_len
		jmp 	DirImpl

	.send code
