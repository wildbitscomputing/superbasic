; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		bload.asm
;		Purpose:	BLOAD command (load binary)
;		Created:	2nd January 2023
;		Reviewed: 	No
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

; ************************************************************************************************
;
;									LOAD a Binary File
;
; ************************************************************************************************

		.section code

Command_BLoad: ;; [BLOAD]
		jsr 	BLOADHandler
		cmp 	#0
		bne 	_BLError
		rts
_BLError:		
		jmp 	CLErrorHandler

; ************************************************************************************************
;
;							BLOAD code ; returns A = 0 or error
;
; ************************************************************************************************

BLOADHandler:
		ldx 	#0
		jsr 	EvaluateString 				; file name to load
		jsr 	CheckComma 					; consume comma
		inx 							
		jsr 	EvaluateInteger 			; load address (full physical address)

		phy
		;
		;		Try to open the file.
		;
		lda 	NSMantissa0					; file name -> XA
		ldx 	NSMantissa1
		jsr 	KNLOpenFileRead 			; open file for reading
		bcs 	_BLErrorExit 				; error, so fail.
		sta 	BasicFileStream 			; save the reading stream.
		;
		;		Open memory for access
		;
		ldx 	#1 							; address is in slot # 1
		jsr 	BLOpenPhysicalMemory 		; open for access.
		;
		;		Keep reading file till empty.
		;
_BLReadFile:
		lda 	BasicFileStream
		ldx     #KNLReadBufferLen 			; set bytes to read.
		jsr 	KNLReadBlock 				; read next block
		bcs 	_BLFileError 				; file error, which might be EOF.

		cmp 	#0 							; read nothing.
		beq 	_BLReadFile
		sta 	BLCopyCounter 				; counter.
		;
		;		Have a data chunk, copy to target
		;
		ldy 	BLYOffset 					; copy the buffer out here
		ldx 	#0 							; offset in buffer.
_BLCopyLoop:
		lda 	KNLReadBuffer,x 			; copy byte and advance
		sta 	(zTemp2),y
		iny
		bne 	_BLNoAdjust 				; check changed 256 byte or 8k page.
		jsr 	BLAdvancePhysicalMemory
_BLNoAdjust:
		inx
		dec 	BLCopyCounter
		bne 	_BLCopyLoop
		sty 	BLYOffset 					; update Y offset
		bra 	_BLReadFile 				; go ask for more.
		;
		;		Error occurs. Check if EOF which means the file is loaded.
		;
_BLFileError:
		cmp 	#KERR_EOF 					; End of file
		bne 	_BLErrorHandler				; no, it's an actual error
		jsr 	BLClosePhysicalMemory 		; close the access.
		lda 	BasicFileStream 			; close the file
		jsr 	KNLCloseFile
		lda 	#0 							; and return zero.
		ply
		rts
		;
		;		Close file and handle error
		;
_BLErrorHandler:
		pha 								; save code
		jsr 	BLClosePhysicalMemory 		; close access
		lda 	BasicFileStream 			; close the open file
		jsr 	KNLCloseFile
		pla 								; get error code
_BLErrorExit:		
		ply 								; restore position and exit.
		rts

; ************************************************************************************************
;
;							Open page read/write at Mantissa,x
;
; ************************************************************************************************

BLAccessPage = 2 							; page to use for actual memory (not slot 3, used for module banking)

BLOpenPhysicalMemory:
		lda 	BLAccessPage+8 				; save current mapping
		sta 	BLNormalMapping

		lda 	NSMantissa0,x 				; copy address, 13 bit adjusted for page -> (zTemp2),BLYOffset
		sta 	BLYOffset 					; zTemp2 0 is *always* zero.
		stz 	zTemp2
		lda 	NSMantissa1,x
		and 	#$1F
		ora 	#BLAccessPage << 5
		sta 	zTemp2+1

		lda 	NSMantissa2,x 				; shift M2:M1 right 3 times to give page # required
		asl 	NSMantissa1,x
		rol 	a
		asl 	NSMantissa1,x
		rol 	a
		asl 	NSMantissa1,x
		rol 	a
		sta 	BLAccessPage+8 				; access that page
		rts

; ************************************************************************************************
;
;										Close opened page.
;
; ************************************************************************************************

BLClosePhysicalMemory:
		lda 	BLNormalMapping
		sta 	BLAccessPage+8
		rts

; ************************************************************************************************
;
;					Advance current address (when Y index ticks over to zero)
;
; ************************************************************************************************

BLAdvancePhysicalMemory:
		pha
		inc		zTemp2+1 					; bump MSB
		lda 	zTemp2+1
		cmp 	#(BLAccessPage+1) << 5 		; reached next page ?
		bne 	_BLAPMExit 					; (e.g. end of the mapped page.)

		inc 	BLAccessPage+8 				; next physical page
		lda 	#BLAccessPage << 5 			; page back to start of transfer page
		sta 	zTemp2+1

_BLAPMExit:
		pla
		rts

		.send code

		.section storage
BLNormalMapping:							; page the access page is normally mapped to.
		.fill 	1
BLYOffset: 									; position in zTemp2 page.
		.fill 	1
BLCopyCounter: 								; count of bytes to output.
		.fill 	1		
		.send storage

; ************************************************************************************************
;
;									Changes and Updates
;
; ************************************************************************************************
;
;		Date			Notes
;		==== 			=====
;		29/01/23 		BLOAD is now stand alone, returning A = 0 or error code.
;
; ************************************************************************************************
