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

; ************************************************************************************************
;
;		DIR [LOAD] [path]
;
;		DIR streams entries directly to the display. DIR LOAD stores entries
;		for later access through DIR$() and DIR().
;
; ************************************************************************************************

Command_Dir:	;; [dir]
		stz 	dirLoadOnly
		stz 	kernel.args.directory.open.path_len
		;
		.cget
		cmp 	#KWC_EOL
		beq 	_CDGo
		cmp 	#KWD_COMMA
		beq 	_CDSyntax
		cmp 	#KWC_SHIFT1 				; extended keyword prefix?
		bne 	_CDEvalPath
		;
		;		Check for LOAD keyword
		;
		iny
		.cget
		cmp 	#KWD1_LOAD
		bne 	_CDSyntax
		iny
		inc 	dirLoadOnly
		.cget
		cmp 	#KWC_EOL
		beq 	_CDGo
		cmp 	#KWD_COMMA
		beq 	_CDSyntax
		;
		;		Evaluate path string
		;
_CDEvalPath:
		ldx 	#0
		jsr 	EvaluateString
		lda 	zTemp0
		sta 	kernel.args.directory.open.path
		lda 	zTemp0+1
		sta 	kernel.args.directory.open.path+1
		phy
		ldy 	#$FF
_CDLen:	iny
		lda 	(zTemp0),y
		bne 	_CDLen
		sty 	kernel.args.directory.open.path_len
		ply
		.cget
		cmp 	#KWD_COMMA
		beq 	_CDSyntax
_CDGo:
		jmp 	DirImpl

_CDSyntax:
		jmp 	SyntaxError

	.send code
