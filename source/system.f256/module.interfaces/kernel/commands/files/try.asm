; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		try.asm
;		Purpose:	Try to execute various commands, returns error code.
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
;									TRY command
;
; ************************************************************************************************

Command_Try:	;; [try]
		.cget 								; get first 
		cmp 	#KWC_SHIFT1					; can only try in SHIFT_1
		bne 	_TrySyntax
		iny 								; get second
		.cget
		iny 								; and consume it.
		cmp 	#KWD1_BLOAD
		beq 	_TryBLoad
		cmp	 	#KWD1_BSAVE
		beq 	_TryBSave
		cmp #KWD1_DELETE
		beq _TryDelete

_TrySyntax:
		.error_syntax
		;
		;		Routines must return error code in A.
		;
_TryBLoad:
		jsr 	BLOADHandler
		bra 	_TryExit
_TryBSave:
		jsr 	BSaveHandler
		bra _TryExit
_TryDelete:
		jsr DeleteHandler

_TryExit:
		pha 								; save result 
		.cget 								; check for TO
		iny
		cmp 	#KWD_TO
		bne 	_TrySyntax				

		ldx 	#0 							; get an integer reference.
		jsr 	EvaluateTerm
		lda 	NSStatus,x
		cmp 	#NSBIsReference+NSTInteger 	; do we have an integer 4 byte reference.
		bne		_TrySyntax

		pla 								; error code.
		ldx	 	#1 							; address in 0, data in 1
		jsr 	NSMSetByte
		dex
		jmp 	AssignVariable 				; do the assign and exit

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
