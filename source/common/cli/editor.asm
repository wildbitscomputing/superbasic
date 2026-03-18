; ***************************************************************************************
; ***************************************************************************************
;
;		Name : 		editor.asm
;		Author :	Paul Robson (paul@robsons.org.uk)
;		Created : 	5th October 2022
;		Reviewed :	1st December 2022
;		Purpose :	Process token buffer for editor
;
; ***************************************************************************************
; ***************************************************************************************

		.section code

; ***************************************************************************************
;
;			Using the tokenised data in the token buffer, insert/delete code
;
; ***************************************************************************************

EditProgramCode:
		;
		;		Delete the line first
		;
		lda 	tokenLineNumber 			; try to find the line.
		ldx 	tokenLineNumber+1
		jsr 	MemorySearch
		bcc 	_EPCNoDelete 				; reached the end : don't delete
		bne 	_EPCNoDelete 				; found slot but didn't match : no delete
		jsr 	MemoryDeleteLine 			; delete the line
_EPCNoDelete:		
		;
		;		Insert the line.
		;
		lda 	tokenBuffer 				; buffer empty - we just want to delete a line.
		cmp 	#KWC_EOL
		beq 	_EPCNoInsert

		lda 	tokenLineNumber 			; find the line - it cannot exist as we've just deleted it.
		ldx 	tokenLineNumber+1 			; so this can't fail, it returns some point in the code.
		jsr 	MemorySearch
		clc 								; insert at this point.
		jsr 	MemoryInsertLine 			; insert the line
_EPCNoInsert:
		lda		#1
		sta		programChanged				; mark program changed
		rts

; ***************************************************************************************
;
;			Reset the token buffer so it appears empty
;
; ***************************************************************************************

ResetTokenBuffer:
		lda		#3					; reset the token buffer to empty
		sta		tokenOffset			; (3 bytes for line number & offset)
		stz		tokenLineNumber
		stz		tokenLineNumber+1
		.csetcodepointer tokenOffset
		rts

; ***************************************************************************************
;
;			Determine if it is safe to continue with a destructive action
;
; ***************************************************************************************

IsDestructiveActionOK:
		lda		programChanged
		beq		_ok_exit

		ldx 	#_continue >> 8 	; print confirmation prompt
		lda 	#_continue & $FF
		jsr 	PrintStringXA

_next_char
		jsr		KNLGetSingleCharacter
		cmp		#'y'
		beq		_ok
		cmp		#'Y'
		beq		_ok
		cmp		#27
		beq		_not_ok
		cmp		#'n'
		beq		_not_ok
		cmp		#'N'
		beq		_not_ok
		cmp		#13
		beq		_not_ok
		bra		_next_char

_ok:
		lda		#'Y'
		jsr		EXTPrintCharacter
		lda		#13
		jsr		EXTPrintCharacter

		stz		programChanged
_ok_exit:
		clc
		rts

_not_ok:
		lda		#'N'
		jsr		EXTPrintCharacter
		lda		#13
		jsr		EXTPrintCharacter

		sec
		rts

_continue:
		.text	"Unsaved changes, continue (y/N)? ",0

		.send code


; ***************************************************************************************
;
;									Changes and Updates
;
; ***************************************************************************************
;
;		Date			Notes
;		==== 			=====
;
; ***************************************************************************************
