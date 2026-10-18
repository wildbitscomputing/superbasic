; BLOAD transfer loop, banked to leave room for file-command interfaces.
; Argument evaluation and physical-memory helpers remain in the main bank.
		.section code
Export_BLoadImpl:

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

		.send code
