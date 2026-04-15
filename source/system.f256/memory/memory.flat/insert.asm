; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		insert.asm
;		Purpose:	Insert line into code
;		Created:	5th October 2022
;		Reviewed: 	16th December 2022
;		Author : 	Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;				Insert line in tokenbuffer space at current codePtr point (CC) end (CS)
;		
; ************************************************************************************************

MemoryInsertLine:
		php
_MDLIRetry:
		jsr 	IMemoryFindEnd 				; find end to zTemp2.

		lda 	zTemp2+1 					; is there space for the new line ?
		cmp 	#(BasicEnd >> 8)-2
		bcc 	_MDLIHasRoom 				; yes, continue normally.
		;
		;		Page full — try to allocate a new page (CS=append only)
		;
		plp
		bcs 	_MDLICanAlloc 				; CS = append, can always allocate new page
		lda 	(codePtr) 					; CC: check if at end of program
		bne 	_MDLIPageSplit 				; non-zero = mid-page, split the page
_MDLICanAlloc:
		jsr 	MemoryAllocPage 			; allocate & initialize new page
		bcs 	_MDLIError 					; out of memory
		sec 								; re-push CS for append path
		php
		bra 	_MDLIRetry 					; retry on the new (empty) page
		;
_MDLIHasRoom:
		plp 								; do at a specific point or the end ?
		bcc 	_MDLIFound 					; CC = insert at codePtr position.
		;
		lda 	zTemp2 						; CS = append, so put on the end.
		sta 	codePtr
		lda 	zTemp2+1
		sta 	codePtr+1
		;
		;		zTemp2 is top, codePointer is insert point. Make space for the token buffer
		;	 	data (offset, line#, buffer)
		;
_MDLIFound:
		lda 	tokenOffset 				; insert gap in Y, the offset, e.g. length of the new line
		tay
_MDLIInsert:		
		lda 	(zTemp2) 					; shift one byte up , at least one covers end case (copying link 0)
		sta 	(zTemp2),y 					; work from top down.

		lda 	codePtr 					; reached insert point ?
		cmp 	zTemp2
		bne 	_MDLINext
		lda 	codePtr+1
		cmp 	zTemp2+1
		beq 	_MDLIHaveSpace
_MDLINext:
		lda 	zTemp2 						; if no, keep zTemp2 going backwards opening up space.
		bne 	_MDLINoBorrow
		dec 	zTemp2+1
_MDLINoBorrow:
		dec 	zTemp2
		bra 	_MDLIInsert
		;
		;		Now we have the space, copy the buffer in.
		;
_MDLIHaveSpace:		
		ldy 	tokenOffset 				; bytes to copy
		dey 								; from offset-1 (last written) to the end of the buffer.
_MDLICopy:
		lda 	tokenOffset,y
		sta 	(codePtr),y
		dey
		bpl 	_MDLICopy
		rts

_MDLIPageSplit:
		jsr 	PageSplitImpl 				; split page via slot 3 module
		bcs 	_MDLIError 					; out of memory
		clc
		php
		jmp 	_MDLIRetry

_MDLIError:
		.error_memory

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
	