; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		save.asm
;		Purpose:	SAVE command interface (implementation in kernel module)
;		Created:	31st December 2022
;		Reviewed: 	No
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

; ************************************************************************************************
;
;		SAVE a Basic file — open the file, then hand off to slot 3 module.
;
; ************************************************************************************************

		.section code

Command_Save: ;; [SAVE]
		jsr 	EvaluateString 				; file name
		ldx 	zTemp0+1					; zTemp0 -> XA
		lda 	zTemp0
		jsr 	KNLOpenFileWrite 			; open file for writing
		bcs 	_CSErrorHandler 			; error, so fail.
		sta 	BasicFileStream 			; save the writing stream.
		jmp 	SaveImpl 					; continue in slot 3 module

_CSErrorHandler:
		jmp 	CLErrorHandler

; ************************************************************************************************
;
;					Write X bytes out to BasicFileStream from zTemp0
;					(kept in main code — shared with BSAVE)
;
; ************************************************************************************************

CLWriteByteBlock:
		cpx 	#0 							; written the lot?
		beq 	_CLWBBExit					; if so, exit
		lda 	BasicFileStream 			; stream to write, count in X
		jsr 	KNLWriteBlock 				; call one write attempt
		bcs 	_CLWBBError 				; error occurred
		sta 	zTemp1 						; save bytes written.
		txa 								; subtract bytes written from X
		sec
		sbc 	zTemp1
		tax
		clc 								; advance zTemp0 pointer
		lda 	zTemp0
		adc 	zTemp1
		sta 	zTemp0
		bcc 	CLWriteByteBlock
		inc 	zTemp0+1
		bra 	CLWriteByteBlock
_CLWBBExit:
		rts
_CLWBBError:
		jmp 	CLErrorHandler

		.send 	code

; ************************************************************************************************
;
;									Changes and Updates
;
; ************************************************************************************************
;
;		Date			Notes
;		==== 			=====
; 		16/02/23 		Changed end to Jsr CLComplete / Jmp Warmstart as was returning to runner
; 						after save.
;		15/04/26		Moved save loop, write block, and clean line to slot 3 module.
;
; ************************************************************************************************
