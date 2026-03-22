; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		errors.asm
;		Purpose:	Handle errors
;		Created:	29th September 2022
;		Reviewed: 	27th November 2022
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;								Report error A
;
; ************************************************************************************************

ErrorHandler:
		pha 								; save error #

		tay 								; find the error text
		beq 	_EHEnd
		ldx 	#0
		inc 	8+5 						; bank in module page 1 (ErrorText lives there)
		.set16 	zTemp0,ErrorText
_EHFind:
		dey 								; keep looking through text
		beq 	_EHFound
_EHFindZero:
		lda 	(zTemp0) 					; find the next error
		inc 	zTemp0
		bne 	_EHFNoCarry
		inc 	zTemp0+1
_EHFNoCarry:
		cmp 	#0
		bne 	_EHFindZero
		bra 	_EHFind

_EHFound:
		ldy 	#0 							; copy error string to ArgumentStorage buffer
_EHCopy:
		lda 	(zTemp0),y
		sta 	ArgumentStorage,y
		beq 	_EHCopyDone
		iny
		bra 	_EHCopy
_EHCopyDone:
		dec 	8+5 						; restore main ROM page
		lda 	#ArgumentStorage & $FF 		; print from buffer
		ldx 	#ArgumentStorage >> 8
		jsr 	PrintStringXA

		pla  								; check if error is 'open structure'
		cmp 	#ERRID_STRUCT
		beq 	_EHCREnd

		ldy 	#1 							; if line number zero don't print it
		.cget
		bne 	_EHAtMsg
		iny
		.cget
		beq 	_EHCREnd

_EHAtMsg:		
		ldx 	#_AtMsg >> 8 				; print " at "
		lda 	#_AtMsg & $FF
		jsr 	PrintStringXA

		ldy 	#1 							; line number into XA
		.cget
		pha
		iny
		.cget
		tax
		pla
		jsr 	ConvertInt16 				; convert XA to string
		jsr 	PrintStringXA 				; and print it.

_EHCREnd:
		lda 	#13 						; new line
		jsr 	EXTPrintCharacter
_EHEnd:			
		jmp 	WarmStart

_AtMsg:	.text 	" at line ",0

; ************************************************************************************************
;
;								  Print String at XA
;
; ************************************************************************************************

PrintStringXA:
		phy
		stx 	zTemp0+1
		sta 	zTemp0
		ldy 	#0
_PSXALoop:
		lda 	(zTemp0),y
		beq 	_PSXAExit
		jsr 	EXTPrintCharacter
		iny
		bra 	_PSXALoop
_PSXAExit:
		ply
		rts						
		.send code

; ************************************************************************************************
;
;									Changes and Updates
;
; ************************************************************************************************
;
;		Date			Notes
;		==== 			=====
;		29/01/23 		No line # for open structure.
;
; ************************************************************************************************
