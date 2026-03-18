; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		load.asm
;		Purpose:	LOAD command
;		Created:	30th December 2022
;		Reviewed: 	No
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

; ************************************************************************************************
;
;									LOAD a Basic file
;
; ************************************************************************************************

		.section code

Command_Load: ;; [LOAD]
		phy 								; save Y (token buffer position)
		jsr		IsDestructiveActionOK
		ply 								; restore Y (clobbered by key input)
		bcs		_not_ok

		jsr 	LoadFile
_not_ok
		jmp		WarmStart

; ************************************************************************************************
;
;				Load named file.
;
; ************************************************************************************************

LoadFile:
		ldx 	#0
		jsr 	EvaluateString 				; file name to load

		ldx 	zTemp0+1					; zTemp0 -> XA
		lda 	zTemp0
		jsr 	KNLOpenFileRead 			; open file for reading
		bcs 	CLErrorHandler 				; error, so fail.
		sta 	BasicFileStream 			; save the reading stream.

		inc 	EXTSuppressCursor 			; freeze cursor position during loading
		lda 	BasicFileStream 			; restore stream for LoadReadByteInit
		jsr     LoadReadByteInit            ; Init reader with the stream
		jsr 	NewProgram 					; does the actual NEW.
		stz 	LoadEOFFlag 				; clear EOF Flag.
_CLLoop:
		jsr 	LoadReadLine 				; get next line.
		beq 	_CLExit 					; end, exit.

		jsr 	TKTokeniseLine 				; tokenise the line.

		lda 	tokenLineNumber 			; line number = 0
		ora 	tokenLineNumber+1
		beq 	_CLLoop 					; not legal code, blank line or maybe a comment.

		jsr 	EditProgramCode 			; do the editing etc.
		bra 	_CLLoop
		;
		;		File loaded
		;
_CLExit:
		lda 	BasicFileStream
		jsr 	KNLCloseFile
		;
		;		Complete message - it's a bit slow.
		;
CLComplete:
		stz 	EXTSuppressCursor 			; resume cursor tracking
		rts
		;
		;		Close file and handle error
		;
CLCloseError:
		pha
		lda 	BasicFileStream
		jsr 	KNLCloseFile
		pla

; ************************************************************************************************
;
;					Handle error A, file never opened, file handling stuff.
;
; ************************************************************************************************


CLErrorHandler:
		cmp 	#KERR_NOTFOUND
		beq 	_CLEHNotFound
		.error_driveio
_CLEHNotFound:
		.error_notfound

; ************************************************************************************************
;
;				Read line into lineBuffer ; return Z set if no more lines
;
; ************************************************************************************************

LoadReadLine:
		ldx 	#0 							; look for first character non space/ctl
		jsr 	LoadReadCharacter
		beq 	_LRLExit 					; eof ?
		cmp 	#' '+1 						; space control tab skip
		bcc 	LoadReadLine
_LRLLoop:
		sta 	lineBuffer,x 				; write into line buffer
		stz 	lineBuffer+1,x 				; make ASCIIZ
		inx
		jsr 	LoadReadCharacter 			; next line

		cmp 	#32 						; until < space ctrl/eof.
		bcs 	_LRLLoop
		lda 	#1 							; return code 1, okay.
_LRLExit:
		rts


; ************************************************************************************************
;
;			Return a single character, handle TABS, return $0D for $0A, 0 if EOF.
;
; ************************************************************************************************

LoadReadCharacter:
		phx
		phy
		lda 	LoadEOFFlag 				; already done EOF.
		bne 	_LRCIsEOF

		jsr 	LoadReadByte 				; read a byte
		bcc		_LRCExit 					; read okay.

		cmp 	#KERR_EOF 					; if error not EOF it's an actual error.
		bne 	CLCloseError
		dec 	LoadEOFFlag
_LRCIsEOF:
		lda 	#0
_LRCExit:
		cmp 	#9 							; convert tab to space
		bne 	_LRCNotTab
		lda 	#' '
_LRCNotTab:
		cmp 	#$0A
		bne 	_LRCNotLF
		lda 	#$0D
_LRCNotLF:
		ply
		plx
		cmp 	#0 							; set Z flag if EOF.
		rts

; ************************************************************************************************
;
;				Init the reader.  A = file stream; can't fail.
;
; ************************************************************************************************

LoadReadByteInit:
		sta     LoadFileStream 				; save stream
		stz     LoadNextCharacter 			; reset buffer
		stz     LoadEndCharacter
		rts

; ************************************************************************************************
;
;				Read one character into A. CC = succeeded, CS = failed, A = Event error
;              	CS when finished (A = EOF)
;
; ************************************************************************************************

LoadReadByte:
		phx

		ldx     LoadNextCharacter 					; all data consumed ?
		cpx     LoadEndCharacter
		bne     _KNLRBGetNextByte
		;
	  	; 		Buffer empty; try to fetch more.
	  	;
		lda     LoadFileStream
		ldx     #KNLReadBufferLen 			; set bytes to read.
		jsr     KNLReadBlock 				; read next chunk from the stream
		bcs     _KNLRBError 				; error has occurred on read.
		;
		sta     LoadEndCharacter 						; # read is the number available
		ldx     #0 							; reset the read pointer.
		stx     LoadNextCharacter
		;
		;		Get next byte from the buffer
		;
_KNLRBGetNextByte:
		lda     KNLReadBuffer,x 			; get the next data item
		inc     LoadNextCharacter 					; and advance the index
		clc 								; succeeded
_KNLRBError:
		plx
		rts


		.send code

		.section storage

LoadEOFFlag:
		.fill 	1
BasicFileStream:
		.fill 	1
LoadFileStream:   								; stream to read from
		.byte   ?
LoadNextCharacter:     								; next byte to return
		.byte   ?
LoadEndCharacter:      								; end of bytes available.
		.byte   ?

		.send storage

; ************************************************************************************************
;
;									Changes and Updates
;
; ************************************************************************************************
;
;		Date			Notes
;		==== 			=====
; 		18/01/23 		Made LOAD a seperate file.
;		19/02/26 		Hide cursor during load, show Loading/Complete messages.
;
; ************************************************************************************************
