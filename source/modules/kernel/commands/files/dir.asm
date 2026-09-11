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
;		DIR has two deliberately separate modes:
;		* Interactive DIR streams and prints every entry as it is read.
;		* DIR LOAD stores a bounded snapshot for DIR$() and DIR().
;
;		The interactive path owns the event queue. It never calls ProcessEvents or
;		.breakcheck while the directory is open. Before pausing it consumes the
;		current entry and does not request another one, so the Shift wait cannot
;		accidentally discard a directory event.
;
; ************************************************************************************************

;		DIR LOAD buffer layout in RAM page 4 mapped to slot 2 ($4000-$5FFF):
;		Parallel arrays indexed by entry number (0-based, 8-bit X).
;
;		$4000-$407F: Name pointer low bytes  (128 bytes)
;		$4080-$40FF: Name pointer high bytes (128 bytes)
;		$4100-$417F: Block count low bytes   (128 bytes)
;		$4180-$41FF: Block count high bytes  (128 bytes)
;		$4200-$427F: Flags (FAT32 attributes)(128 bytes)
;		$4280-$5FFD: Packed null-terminated name strings
;		$5FFE-$5FFF: Free block count (2 bytes)
;
DIR_BUF_BASE	= $4000
DIR_NAME_LO	= DIR_BUF_BASE
DIR_NAME_HI	= DIR_BUF_BASE + $80
DIR_BLK_LO	= DIR_BUF_BASE + $100
DIR_BLK_HI	= DIR_BUF_BASE + $180
DIR_FLAGS		= DIR_BUF_BASE + $200
DIR_NAMES		= DIR_BUF_BASE + $280
DIR_NAMES_END	= DIR_BUF_BASE + $1FFE		; first byte after packed names
DIR_FREE_BLK	= DIR_BUF_BASE + $1FFE
DIR_MAX_ENTRIES	= 127
DIR_RAM_PAGE	= 4
DIR_ATTR_HIDDEN	= $02
DIR_ATTR_DIR	= $10

; ************************************************************************************************
;
;								Entry point
;
; ************************************************************************************************

Export_DirImpl:
		lda 	dirLoadOnly
		beq 	+
		jmp 	_DLStart
	+
		jmp 	_SDStart

; ************************************************************************************************
;
;						Interactive streaming DIR
;
; ************************************************************************************************

_SDStart:
		phy
		stz 	dirListCount
		stz 	dirListCount+1
		lda     KNLDefaultDrive
		sta     kernel.args.directory.open.drive
		jsr     kernel.Directory.Open
		bcc     +
		jmp     _SDExit
	+

_SDEventLoop:
		stz 	KNLEvent.directory.file.flags ; older kernels do not set flags
		jsr     GetNextEvent
		bcc     _SDProcessEvent
		jsr     kernel.Yield
		bra     _SDEventLoop

_SDProcessEvent:
		lda     KNLEvent.type
		cmp     #kernel.event.directory.CLOSED
		bne     +
		jmp     _SDDone
	+
		cmp     #kernel.event.directory.OPENED
		beq     _SDOpened
		cmp     #kernel.event.directory.VOLUME
		beq     _SDVolume
		cmp     #kernel.event.directory.FILE
		beq     _SDFile
		cmp     #kernel.event.directory.FREE
		bne     +
		jmp     _SDFree
	+
		cmp     #kernel.event.directory.EOF
		bne     +
		jmp     _SDEOF
	+
		cmp     #kernel.event.directory.ERROR
		bne     +
		jmp     _SDError
	+
		cmp 	#kernel.event.key.PRESSED
		bne 	_SDEventLoop
		lda 	KNLEvent.key.ascii
		cmp 	#3
		bne 	_SDEventLoop
		jmp 	_SDBreak

_SDOpened:
		lda     KNLEvent.directory.stream
		sta 	dirStreamID
		bra 	_SDRead

_SDRead:
		lda 	dirStreamID
		sta     kernel.args.directory.read.stream
		jsr     kernel.Directory.Read
		bra 	_SDEventLoop

_SDVolume:
		lda 	#"["
		jsr 	EXTPrintCharacter
		lda     KNLEvent.directory.volume.len
		jsr     _ReadDataToLineBuffer
		jsr 	PrintStringXA
		lda 	#"]"
		jsr 	EXTPrintCharacter
		ldx 	#_CDBlocksHdr >> 8
		lda 	#_CDBlocksHdr & $FF
		jsr 	PrintStringXA
		lda 	#13
		jsr 	EXTPrintCharacter
		bra 	_SDRead

_SDFile:
		;		Consume all bulk data before handling input. ReadExt must use a
		;		separate destination so the filename remains in lineBuffer.
		lda 	KNLEvent.directory.file.flags
		sta 	dirEntryFlags
		lda     KNLEvent.directory.file.len
		sta 	dirEntryNameLen
		jsr 	_ReadDataToLineBuffer
		jsr 	_ReadExtToEntryBlocks
		;		Hidden entries are consumed but not displayed or counted.
		lda 	dirEntryFlags
		and 	#DIR_ATTR_HIDDEN
		bne 	_SDRead

_SDPauseDrain:
		;		No directory read is outstanding here. Drain already queued input
		;		so a Shift press behind the FILE event applies before printing.
		lda 	kernel.args.events.pending
		beq 	_SDPauseCheck
		jsr 	GetNextEvent
		bcs 	_SDPauseCheck
		lda 	KNLEvent.type
		cmp 	#kernel.event.key.PRESSED
		bne 	_SDPauseDrain
		lda 	KNLEvent.key.ascii
		cmp 	#3
		bne 	_SDPauseDrain
		jmp 	_SDBreak

_SDPauseCheck:
		jsr 	IsShiftPressed
		beq 	_SDPrintEntry
		jsr 	GetNextEvent
		bcc 	_SDPauseEvent
		jsr 	kernel.Yield
		bra 	_SDPauseCheck
_SDPauseEvent:
		lda 	KNLEvent.type
		cmp 	#kernel.event.key.PRESSED
		bne 	_SDPauseCheck
		lda 	KNLEvent.key.ascii
		cmp 	#3
		bne 	_SDPauseCheck
		jmp 	_SDBreak

_SDPrintEntry:
		lda 	#32
		jsr 	EXTPrintCharacter
		ldx 	#lineBuffer >> 8
		lda 	#lineBuffer & $FF
		jsr 	PrintStringXA
		;		Pad names shorter than 26 characters.
		lda 	dirEntryNameLen
		cmp 	#26
		bcs 	_SDPadDone
		eor 	#$FF
		sec
		adc 	#26
		tax
_SDPad:
		lda 	#32
		jsr 	EXTPrintCharacter
		dex
		bne 	_SDPad
_SDPadDone:
		lda 	dirEntryFlags
		and 	#DIR_ATTR_DIR
		beq 	_SDPrintBlocks
		lda 	#32
		jsr 	EXTPrintCharacter
		ldx 	#_CDDirTag >> 8
		lda 	#_CDDirTag & $FF
		jsr 	PrintStringXA
		bra 	_SDEndLine
_SDPrintBlocks:
		lda 	dirEntryBlocks
		ldx 	dirEntryBlocks+1
		jsr 	ConvertInt16
		jsr 	_CDPrintRightAligned
_SDEndLine:
		lda 	#13
		jsr 	EXTPrintCharacter
		inc 	dirListCount
		beq 	+
		jmp 	_SDRead
	+
		inc 	dirListCount+1
		jmp 	_SDRead

_SDFree:
		jsr 	_ReadExtToEntryBlocks
		lda 	#13
		jsr 	EXTPrintCharacter
		lda 	dirListCount
		ldx 	dirListCount+1
		jsr 	ConvertInt16
		jsr 	PrintStringXA
		ldx 	#_CDFilesMsg >> 8
		lda 	#_CDFilesMsg & $FF
		jsr 	PrintStringXA
		lda 	dirEntryBlocks
		ldx 	dirEntryBlocks+1
		jsr 	ConvertInt16
		jsr 	PrintStringXA
		ldx 	#_CDFreeMsg >> 8
		lda 	#_CDFreeMsg & $FF
		jsr 	PrintStringXA
		bra 	_SDEOF

_SDError:
		lda     KNLEvent.directory.stream
		sta 	dirStreamID
_SDEOF:
		lda 	dirStreamID
		sta     kernel.args.directory.close.stream
		jsr     kernel.Directory.Close
		jmp 	_SDEventLoop

_SDDone:
_SDExit:
		ply
		rts

_SDBreak:
		lda 	dirStreamID
		sta 	kernel.args.directory.close.stream
		jsr 	kernel.Directory.Close
_SDBreakWait:
		jsr 	GetNextEvent
		bcc 	_SDBreakCheck
		jsr 	kernel.Yield
		bra 	_SDBreakWait
_SDBreakCheck:
		lda 	KNLEvent.type
		cmp 	#kernel.event.directory.CLOSED
		bne 	_SDBreakWait
		ply
		.error_break

; ************************************************************************************************
;
;						Bounded DIR LOAD snapshot
;
; ************************************************************************************************

_DLStart:
		phy
		lda 	8+2
		sta 	dirSavedSlot2
		lda 	#DIR_RAM_PAGE
		sta 	8+2
		stz 	dirFileCount
		stz 	dirFileCount+1
		stz 	DIR_FREE_BLK
		stz 	DIR_FREE_BLK+1
		lda 	#DIR_NAMES & $FF
		sta 	dirNamePtr
		lda 	#DIR_NAMES >> 8
		sta 	dirNamePtr+1
		lda     KNLDefaultDrive
		sta     kernel.args.directory.open.drive
		jsr     kernel.Directory.Open
		bcc     +
		jmp     _DLExit
	+

_DLEventLoop:
		stz 	KNLEvent.directory.file.flags ; older kernels do not set flags
		jsr     GetNextEvent
		bcc     _DLProcessEvent
		jsr     kernel.Yield
		bra     _DLEventLoop

_DLProcessEvent:
		lda     KNLEvent.type
		cmp     #kernel.event.directory.CLOSED
		bne     +
		jmp     _DLDone
	+
		cmp     #kernel.event.directory.OPENED
		beq     _DLOpened
		cmp     #kernel.event.directory.VOLUME
		beq     _DLVolume
		cmp     #kernel.event.directory.FILE
		beq     _DLFile
		cmp     #kernel.event.directory.FREE
		bne     +
		jmp     _DLFree
	+
		cmp     #kernel.event.directory.EOF
		bne     +
		jmp     _DLEOF
	+
		cmp     #kernel.event.directory.ERROR
		bne     +
		jmp     _DLError
	+
		cmp 	#kernel.event.key.PRESSED
		bne 	_DLEventLoop
		lda 	KNLEvent.key.ascii
		cmp 	#3
		bne 	_DLEventLoop
		jmp 	_DLBreak

_DLOpened:
		lda     KNLEvent.directory.stream
		sta 	dirStreamID
		bra 	_DLRead

_DLRead:
		lda 	dirStreamID
		sta     kernel.args.directory.read.stream
		jsr     kernel.Directory.Read
		bra 	_DLEventLoop

_DLVolume:
		lda     KNLEvent.directory.volume.len
		jsr     _ReadDataToLineBuffer
		bra 	_DLRead

_DLFile:
		lda 	KNLEvent.directory.file.flags
		sta 	dirEntryFlags
		lda 	KNLEvent.directory.file.len
		sta 	dirEntryNameLen
		lda 	dirEntryFlags
		and 	#DIR_ATTR_HIDDEN
		beq 	+
		jmp 	_DLDiscard
	+
		lda 	dirFileCount
		cmp 	#DIR_MAX_ENTRIES
		bcc 	+
		jmp 	_DLOverflowDiscard
	+
		;		Preflight name pointer + length + terminator. Equality with
		;		DIR_NAMES_END is valid because it denotes the next free byte.
		clc
		lda 	dirNamePtr
		adc 	dirEntryNameLen
		sta 	dirNextNamePtr
		lda 	dirNamePtr+1
		adc 	#0
		sta 	dirNextNamePtr+1
		inc 	dirNextNamePtr
		bne 	_DLCheckNameEnd
		inc 	dirNextNamePtr+1
_DLCheckNameEnd:
		lda 	dirNextNamePtr+1
		cmp 	#>DIR_NAMES_END
		bcc 	_DLStore
		bne 	_DLOverflowDiscard
		lda 	dirNextNamePtr
		cmp 	#<DIR_NAMES_END
		bcc 	_DLStore
		beq 	_DLStore
		bra 	_DLOverflowDiscard

_DLStore:
		lda 	dirEntryNameLen
		jsr 	_ReadDataToLineBuffer
		jsr 	_ReadExtToEntryBlocks
		lda 	dirNamePtr
		sta 	zTemp0
		lda 	dirNamePtr+1
		sta 	zTemp0+1
		ldy 	dirEntryNameLen
		lda 	#0
		sta 	(zTemp0),y
		dey
		bmi 	_DLCopyDone
_DLCopyName:
		lda 	lineBuffer,y
		sta 	(zTemp0),y
		dey
		bpl 	_DLCopyName
_DLCopyDone:
		ldx 	dirFileCount
		lda 	dirNamePtr
		sta 	DIR_NAME_LO,x
		lda 	dirNamePtr+1
		sta 	DIR_NAME_HI,x
		lda 	dirEntryBlocks
		sta 	DIR_BLK_LO,x
		lda 	dirEntryBlocks+1
		sta 	DIR_BLK_HI,x
		lda 	dirEntryFlags
		sta 	DIR_FLAGS,x
		lda 	dirNextNamePtr
		sta 	dirNamePtr
		lda 	dirNextNamePtr+1
		sta 	dirNamePtr+1
		inc 	dirFileCount
		jmp 	_DLRead

_DLDiscard:
		lda 	dirEntryNameLen
		jsr 	_ReadDataToLineBuffer
		jsr 	_ReadExtToEntryBlocks
		jmp 	_DLRead

_DLOverflowDiscard:
		lda 	dirEntryNameLen
		jsr 	_ReadDataToLineBuffer
		jsr 	_ReadExtToEntryBlocks
		lda 	dirStreamID
		sta 	kernel.args.directory.close.stream
		jsr 	kernel.Directory.Close
_DLOverflowWait:
		jsr 	GetNextEvent
		bcc 	_DLOverflowCheck
		jsr 	kernel.Yield
		bra 	_DLOverflowWait
_DLOverflowCheck:
		lda 	KNLEvent.type
		cmp 	#kernel.event.directory.CLOSED
		bne 	_DLOverflowWait
		lda 	dirSavedSlot2
		sta 	8+2
		stz 	dirFileCount
		stz 	dirFileCount+1
		ply
		.error_dirfull

_DLFree:
		jsr 	_ReadExtToEntryBlocks
		lda 	dirEntryBlocks
		sta 	DIR_FREE_BLK
		lda 	dirEntryBlocks+1
		sta 	DIR_FREE_BLK+1
		bra 	_DLEOF

_DLError:
		lda     KNLEvent.directory.stream
		sta 	dirStreamID
_DLEOF:
		lda 	dirStreamID
		sta     kernel.args.directory.close.stream
		jsr     kernel.Directory.Close
		jmp 	_DLEventLoop

_DLDone:
_DLExit:
		lda 	dirSavedSlot2
		sta 	8+2
		ply
		rts

_DLBreak:
		lda 	dirStreamID
		sta 	kernel.args.directory.close.stream
		jsr 	kernel.Directory.Close
_DLBreakWait:
		jsr 	GetNextEvent
		bcc 	_DLBreakCheck
		jsr 	kernel.Yield
		bra 	_DLBreakWait
_DLBreakCheck:
		lda 	KNLEvent.type
		cmp 	#kernel.event.directory.CLOSED
		bne 	_DLBreakWait
		lda 	dirSavedSlot2
		sta 	8+2
		ply
		.error_break

; ************************************************************************************************
;
;						Shared display and I/O helpers
;
; ************************************************************************************************

_CDFilesMsg:
		.text 	" files, ",0
_CDFreeMsg:
		.text 	" blocks free.",13,0
_CDBlocksHdr:
		.text 	"                   Blocks",0
_CDDirTag:
		.text 	"<dir>",0

_ReadDataToLineBuffer:
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

_ReadExtToEntryBlocks:
		lda     #2
		sta     kernel.args.recv.buflen
		lda     #dirEntryBlocks & $FF
		sta     kernel.args.recv.buf+0
		lda     #dirEntryBlocks >> 8
		sta     kernel.args.recv.buf+1
		jmp     kernel.ReadExt

_CDPrintRightAligned:
		ldx 	#$FF
_CDPRALen:
		inx
		lda 	numberBuffer,x
		bne 	_CDPRALen
		txa
		eor 	#$FF
		sec
		adc 	#5
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

; ************************************************************************************************
;
;		DIR$(n) — return filename of entry n. DIR(n) — return numeric info.
;
; ************************************************************************************************

Export_DirStringImpl:
		phy
		lda 	dirFuncArg
		cmp 	dirFileCount
		bcs 	_DSSEmpty
		pha
		lda 	8+2
		sta 	dirSavedSlot2
		lda 	#DIR_RAM_PAGE
		sta 	8+2
		pla
		tax
		lda 	DIR_NAME_LO,x
		sta 	zTemp0
		lda 	DIR_NAME_HI,x
		sta 	zTemp0+1
		ldy 	#0
_DSSCopy:
		lda 	(zTemp0),y
		sta 	lineBuffer,y
		beq 	_DSSCopyDone
		iny
		bra 	_DSSCopy
_DSSCopyDone:
		lda 	dirSavedSlot2
		sta 	8+2
_DSSReturn:
		ldx 	#0
		lda 	#lineBuffer & $FF
		sta 	NSMantissa0,x
		lda 	#lineBuffer >> 8
		sta 	NSMantissa1,x
		lda 	#NSBIsString
		sta 	NSStatus,x
		ply
		rts
_DSSEmpty:
		stz 	lineBuffer
		bra 	_DSSReturn

Export_DirNumImpl:
		phy
		lda 	dirFuncSign
		bmi 	_DNNeg
		lda 	dirFuncArg
		cmp 	dirFileCount
		bcs 	_DNZero
		pha
		lda 	8+2
		sta 	dirSavedSlot2
		lda 	#DIR_RAM_PAGE
		sta 	8+2
		pla
		tax
		lda 	DIR_BLK_LO,x
		sta 	zTemp0
		lda 	DIR_BLK_HI,x
		sta 	zTemp1
		lda 	dirSavedSlot2
		sta 	8+2
		ldx 	#0
		lda 	zTemp0
		sta 	NSMantissa0,x
		lda 	zTemp1
		sta 	NSMantissa1,x
		bra 	_DNRetInt
_DNNeg:
		lda 	dirFuncArg
		cmp 	#1
		beq 	_DNFileCount
		cmp 	#2
		beq 	_DNFreeBlk
		bra 	_DNZero
_DNFileCount:
		ldx 	#0
		lda 	dirFileCount
		sta 	NSMantissa0,x
		lda 	dirFileCount+1
		sta 	NSMantissa1,x
		bra 	_DNRetInt
_DNFreeBlk:
		lda 	8+2
		sta 	dirSavedSlot2
		lda 	#DIR_RAM_PAGE
		sta 	8+2
		lda 	DIR_FREE_BLK
		sta 	zTemp0
		lda 	DIR_FREE_BLK+1
		sta 	zTemp1
		lda 	dirSavedSlot2
		sta 	8+2
		ldx 	#0
		lda 	zTemp0
		sta 	NSMantissa0,x
		lda 	zTemp1
		sta 	NSMantissa1,x
		bra 	_DNRetInt
_DNZero:
		ldx 	#0
		stz 	NSMantissa0,x
		stz 	NSMantissa1,x
_DNRetInt:
		stz 	NSMantissa2,x
		stz 	NSMantissa3,x
		stz 	NSExponent,x
		stz 	NSStatus,x
		ply
		rts

	.send code

	.section storage
dirStreamID:
		.fill 	1
dirFileCount:
		.fill 	2
dirListCount:
		.fill 	2
dirNamePtr:
		.fill 	2
dirNextNamePtr:
		.fill 	2
dirSavedSlot2:
		.fill 	1
dirEntryNameLen:
		.fill 	1
dirEntryFlags:
		.fill 	1
dirEntryBlocks:
		.fill 	2
dirFuncArg:
		.fill 	1
dirFuncSign:
		.fill 	1
dirLoadOnly:
		.fill 	1
	.send storage
