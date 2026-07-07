; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		save.asm
;		Purpose:	SAVE command implementation (slot 3 module)
;		Created:	15th April 2026
;		Author:		Matthias Brukner (mbrukner@gmail.com)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;	Save the current program to disk. Called after the file has been opened
;	for writing by the Command_Save stub (BasicFileStream is set).
;
; ************************************************************************************************

Export_SaveImpl:
		lda		#_CSSavingMsg & $FF
		ldx		#_CSSavingMsg >> 8
		jsr		PrintStringXA

		.cresetcodepointer						; prepare to loop through code.
_CSLoop:
		.cget0									; any more?
		beq		_CSExit
		jsr		_CSGetCleanLine
		sty		zTemp0+1						; save write address of data
		sta		zTemp0
		jsr		CLWriteByteBlock				; write the block out (main code).
		.cnextline								; go to next line.
		bra		_CSLoop

_CSExit:
		lda		BasicFileStream					; close file
		jsr		KNLCloseFile
		jsr		CLComplete						; display complete message.
		stz		programChanged					; mark program not changed since save
		jmp		WarmStart						; and warm start

_CSSavingMsg:
		.text	"Saving",0

; ************************************************************************************************
;
;			Strip control codes from tokenised line, append CR, len in X
;
; ************************************************************************************************

_CSGetCleanLine:
		lda		#0								; no indent.
		jsr		TKListConvertLine				; convert line into token Buffer

		ldx		#0								; copy stripping controls.
		ldy		#0
_CSClean:
		lda		tokenBuffer,y
		beq		_CSDoneClean
		bmi		_CSIgnoreCharacter
		sta		lineBuffer,x
		inx
_CSIgnoreCharacter:
		iny
		bra		_CSClean
_CSDoneClean:
		lda		#13								; add CR, length now in X and ASCIIZ.
		sta		lineBuffer,x
		inx
		stz		lineBuffer,x

		ldy		#(lineBuffer >> 8)				; line address in YA
		lda		#(lineBuffer & $FF)
		rts

		.send code
