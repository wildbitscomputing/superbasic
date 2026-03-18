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

DIR_SORT_NAME	= 0
DIR_SORT_SIZE	= 1

; ************************************************************************************************
;
;		DIR [path] [BY NAME|SIZE]
;
; ************************************************************************************************

Command_Dir:	;; [dir]
		lda 	#DIR_SORT_NAME
		sta 	dirSortMode
		stz 	kernel.args.directory.open.path_len
		;
		.cget
		cmp 	#KWC_EOL
		beq 	_CDGo
		cmp 	#KWD_BY
		beq 	_CDParseSort
		;
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
		cmp 	#KWD_BY
		bne 	_CDGo
_CDParseSort:
		iny
		.cget
		cmp 	#KWD_SIZE
		bne 	_CDGo
		iny
		lda 	#DIR_SORT_SIZE
		sta 	dirSortMode
_CDGo:
		jmp 	DirImpl

	.send code
