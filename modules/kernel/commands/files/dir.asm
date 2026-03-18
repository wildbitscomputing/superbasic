; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		dir.asm
;		Purpose:	List directory of default drive (kernel module implementation)
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
;									DIR command
;
; ************************************************************************************************

Export_DirImpl:
		phy
		stz 	dirFileCount 				; reset file counter
		stz 	dirFileCount+1
		lda     KNLDefaultDrive				; set drive to list.
		sta     kernel.args.directory.open.drive
		;									; path_len already set by interface code
		jsr     kernel.Directory.Open
		bcs     _CDExit

_CDEventLoop:
		jsr     GetNextEvent
		bcc     _CDProcessEvent
		jsr     kernel.Yield        		; Polite, not actually needed.
		bra     _CDEventLoop

_CDProcessEvent
		lda     KNLEvent.type
		cmp     #kernel.event.directory.CLOSED
		beq    	_CDSuccess
		;
		cmp 	#kernel.event.key.PRESSED 	; check for Ctrl+C break
		bne 	_CDNotKey
		lda 	KNLEvent.key.ascii
		cmp 	#3
		beq 	_CDBreak
		bra 	_CDEventLoop 				; ignore other keys
_CDNotKey:
		jsr     _CDMessages 				; handle various messages
		bra     _CDEventLoop
_CDSuccess:
		ply
		lda     #0
		clc
		rts
_CDExit:
		ply
		jmp 	WarmStart

_CDBreak:
		lda 	dirStreamID 				; close the directory stream
		sta 	kernel.args.directory.close.stream
		jsr 	kernel.Directory.Close
_CDBreakWait:
		jsr 	GetNextEvent 				; drain events until CLOSED
		bcc 	_CDBreakCheck
		jsr 	kernel.Yield
		bra 	_CDBreakWait
_CDBreakCheck:
		lda 	KNLEvent.type
		cmp 	#kernel.event.directory.CLOSED
		bne 	_CDBreakWait
		ply
		.error_break

;
;		Dispatch messages
;
_CDEVErr:
		lda     KNLEvent.directory.stream
		sta     kernel.args.directory.close.stream
		jmp     kernel.Directory.Close


_CDMessages:
		cmp     #kernel.event.directory.OPENED
		beq     _CDEVRead
		cmp     #kernel.event.directory.VOLUME
		beq     _CDEVVolume
		cmp     #kernel.event.directory.FILE
		beq     _CDEVFile
		cmp     #kernel.event.directory.FREE
		beq     _CDEVFreeJmp
		cmp     #kernel.event.directory.EOF
		beq     _CDEVEOFJmp
		cmp     #kernel.event.directory.ERROR
		beq     _CDEVErr
		rts
_CDEVFreeJmp:
		jmp 	_CDEVFree
_CDEVEOFJmp:
		jmp 	_CDEVEOF


_CDEVRead:
		lda     KNLEvent.directory.stream
		sta 	dirStreamID 				; save stream for break handler
		sta     kernel.args.directory.read.stream
		jmp     kernel.Directory.Read

_CDEVVolume:
		lda 	#"["
		jsr 	EXTPrintCharacter
		lda     KNLEvent.directory.volume.len
		jsr     _CDReadData
		jsr 	PrintStringXA
		lda 	#"]"
		jsr 	EXTPrintCharacter
		lda 	#13
		jsr 	EXTPrintCharacter
		jmp     _CDEVRead

_CDEVEOF:
		lda     KNLEvent.directory.stream
		sta     kernel.args.directory.close.stream
		jmp     kernel.Directory.Close


_CDEVFile:
		inc 	dirFileCount 				; count files
		bne 	_CDEVFileNoCy
		inc 	dirFileCount+1
_CDEVFileNoCy:
		lda 	#32
		jsr 	EXTPrintCharacter
		lda     KNLEvent.directory.file.len
		pha
		jsr     _CDReadData
		jsr 	PrintStringXA
		pla
		eor 	#$FF
		sec
		adc 	#26
		tax
_CDEVTab:
		lda 	#32
		jsr 	EXTPrintCharacter
		dex
		bpl 	_CDEVTab
		jsr 	_CDReadExtended
		lda 	lineBuffer
		ldx 	lineBuffer+1
		jsr 	ConvertInt16
		jsr 	_CDPrintRightAligned
		lda 	#13
		jsr 	EXTPrintCharacter
		jmp     _CDEVRead
_CDEVFree:
		lda 	#13 						; blank line before summary
		jsr 	EXTPrintCharacter
		lda 	dirFileCount 				; print file count
		ldx 	dirFileCount+1
		jsr 	ConvertInt16
		jsr 	PrintStringXA
		ldx 	#_CDFilesMsg >> 8
		lda 	#_CDFilesMsg & $FF
		jsr 	PrintStringXA
		jsr     _CDReadExtended 			; print free blocks
		lda 	lineBuffer
		ldx 	lineBuffer+1
		jsr 	ConvertInt16
		jsr 	PrintStringXA
		ldx 	#_CDEVFreeMessage >> 8
		lda 	#_CDEVFreeMessage & $FF
		jsr 	PrintStringXA
		bra     _CDEVEOF

_CDFilesMsg:
		.text 	" files, ",0
_CDEVFreeMessage:
		.text 	" blocks free.",13,0

;
; 		IN: A = # of bytes to read
;
_CDReadData:

		sta     kernel.args.recv.buflen

		lda     #lineBuffer & $FF
		sta     kernel.args.recv.buf+0
		lda     #lineBuffer >> 8
		sta     kernel.args.recv.buf+1
		jsr     kernel.ReadData

		ldx     kernel.args.recv.buflen
		stz     lineBuffer,x

		lda 	#lineBuffer & $FF
		ldx 	#lineBuffer >> 8
		rts

_CDReadExtended:
		lda     #2
		sta     kernel.args.recv.buflen
		lda     #lineBuffer & $FF
		sta     kernel.args.recv.buf+0
		lda     #lineBuffer >> 8
		sta     kernel.args.recv.buf+1
		jmp     kernel.ReadExt


;
;		Print number string (in numberBuffer) right-aligned in 5-char field
;
_CDPrintRightAligned:
		ldx 	#$FF
_CDPRALen:
		inx
		lda 	numberBuffer,x
		bne 	_CDPRALen
		txa 								; X = length
		eor 	#$FF
		sec
		adc 	#5 							; A = 5 - length
		beq 	_CDPRAPrint
		tax
_CDPRAPad:
		lda 	#32
		jsr 	EXTPrintCharacter
		dex
		bne 	_CDPRAPad
_CDPRAPrint:
		ldx 	#numberBuffer >> 8
		lda 	#numberBuffer & $FF
		jmp 	PrintStringXA

	.send code

	.section storage
dirStreamID:
		.fill 	1
dirFileCount:
		.fill 	2
	.send storage

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
