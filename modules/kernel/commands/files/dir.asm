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
;		Buffered DIR command — three phases:
;		1. Read: collect all directory entries into RAM page 4 buffer
;		2. Sort: insertion sort by filename
;		3. Print: display sorted entries with shift-pause support
;
; ************************************************************************************************

;
;		Buffer layout in RAM page 4 mapped to slot 2 ($4000-$5FFF):
;
;		$4000-$41FF: Index array (128 entries × 4 bytes)
;					 [name_ptr_lo] [name_ptr_hi] [blocks_lo] [blocks_hi]
;		$4200-$5FFD: Packed null-terminated name strings
;		$5FFE-$5FFF: Free block count (2 bytes)
;
DIR_BUF_BASE	= $4000
DIR_INDEX		= DIR_BUF_BASE				; index array starts here
DIR_NAMES		= DIR_BUF_BASE + $200		; names start at $4200
DIR_NAMES_END	= DIR_BUF_BASE + $1FFE		; end of name area
DIR_FREE_BLK	= DIR_BUF_BASE + $1FFE		; free block count (2 bytes)
DIR_MAX_ENTRIES	= 128						; max entries in index
DIR_ENTRY_SIZE	= 4							; bytes per index entry
DIR_RAM_PAGE	= 4							; unused RAM page for buffer

; ************************************************************************************************
;
;								Phase 1: Read directory into buffer
;
; ************************************************************************************************

Export_DirImpl:
		phy
		;
		;		Map RAM page 4 into slot 2 for buffering
		;
		lda 	8+2 						; save current slot 2 mapping
		sta 	dirSavedSlot2
		lda 	#DIR_RAM_PAGE
		sta 	8+2 						; $4000-$5FFF = RAM page 4
		;
		stz 	dirFileCount 				; reset counters
		stz 	dirFileCount+1
		lda 	#DIR_NAMES & $FF 			; name write pointer
		sta 	dirNamePtr
		lda 	#DIR_NAMES >> 8
		sta 	dirNamePtr+1
		;
		lda     KNLDefaultDrive
		sta     kernel.args.directory.open.drive
		jsr     kernel.Directory.Open
		bcs     _RDExit

_RDEventLoop:
		jsr     GetNextEvent
		bcc     _RDProcessEvent
		jsr     kernel.Yield
		bra     _RDEventLoop

_RDProcessEvent:
		lda     KNLEvent.type
		cmp     #kernel.event.directory.CLOSED
		beq    	_RDDone
		cmp 	#kernel.event.key.PRESSED
		bne 	_RDNotKey
		lda 	KNLEvent.key.ascii
		cmp 	#3
		beq 	_RDBreak
		bra 	_RDEventLoop
_RDNotKey:
		jsr     _RDMessages
		bra     _RDEventLoop

_RDDone:
		;		Directory stream closed — sort and print
		jsr 	_SortEntries
		jsr 	_PrintEntries

_RDExit:
		lda 	dirSavedSlot2 				; restore slot 2
		sta 	8+2
		ply
		jmp 	WarmStart

_RDBreak:
		lda 	dirStreamID
		sta 	kernel.args.directory.close.stream
		jsr 	kernel.Directory.Close
_RDBreakWait:
		jsr 	GetNextEvent
		bcc 	_RDBreakCheck
		jsr 	kernel.Yield
		bra 	_RDBreakWait
_RDBreakCheck:
		lda 	KNLEvent.type
		cmp 	#kernel.event.directory.CLOSED
		bne 	_RDBreakWait
		lda 	dirSavedSlot2
		sta 	8+2
		ply
		.error_break

;
;		Read-phase message dispatch
;
_RDMessages:
		cmp     #kernel.event.directory.OPENED
		beq     _RDRead
		cmp     #kernel.event.directory.VOLUME
		beq     _RDVolume
		cmp     #kernel.event.directory.FILE
		beq     _RDFileJmp
		cmp     #kernel.event.directory.FREE
		beq     _RDFreeJmp
		cmp     #kernel.event.directory.EOF
		beq     _RDEOFJmp
		cmp     #kernel.event.directory.ERROR
		beq     _RDErr
		rts
_RDFileJmp:
		jmp 	_RDFile
_RDFreeJmp:
		jmp 	_RDFree
_RDEOFJmp:
		jmp 	_RDEOF
_RDErr:
		lda     KNLEvent.directory.stream
		sta     kernel.args.directory.close.stream
		jmp     kernel.Directory.Close

_RDRead:
		lda     KNLEvent.directory.stream
		sta 	dirStreamID
		sta     kernel.args.directory.read.stream
		jmp     kernel.Directory.Read

_RDVolume:
		;		Print volume name immediately (not buffered)
		lda 	#"["
		jsr 	EXTPrintCharacter
		lda     KNLEvent.directory.volume.len
		jsr     _ReadDataToLineBuffer
		jsr 	PrintStringXA
		lda 	#"]"
		jsr 	EXTPrintCharacter
		ldx 	#_CDBlocksHdr >> 8 			; "Blocks" header right-aligned
		lda 	#_CDBlocksHdr & $FF
		jsr 	PrintStringXA
		lda 	#13
		jsr 	EXTPrintCharacter
		jmp     _RDRead

_RDFile:
		;		Check if index is full
		lda 	dirFileCount
		cmp 	#DIR_MAX_ENTRIES
		bcc 	_RDFileOk
		jmp 	_RDFileSkip
_RDFileOk:

		;		Read filename into lineBuffer
		lda     KNLEvent.directory.file.len
		jsr 	_ReadDataToLineBuffer
		lda     kernel.args.recv.buflen
		sta 	dirCmpTmp 					; save name length

		;		Copy name from lineBuffer to name buffer BEFORE reading blocks
		;		(ReadExt will overwrite lineBuffer)
		lda 	dirNamePtr
		sta 	zTemp0
		lda 	dirNamePtr+1
		sta 	zTemp0+1
		ldy 	dirCmpTmp 					; name length
		lda 	#0
		sta 	(zTemp0),y 					; null-terminate
		dey
		bmi 	_RDCopyDone
_RDCopyName:
		lda 	lineBuffer,y
		sta 	(zTemp0),y
		dey
		bpl 	_RDCopyName
_RDCopyDone:

		;		Now read block count into lineBuffer
		jsr 	_ReadExtToLineBuffer

		;		Build index entry
		lda 	dirFileCount
		asl 	a
		asl 	a
		tax
		lda 	dirNamePtr
		sta 	DIR_INDEX,x
		lda 	dirNamePtr+1
		sta 	DIR_INDEX+1,x
		lda 	lineBuffer 					; blocks lo (from ReadExt)
		sta 	DIR_INDEX+2,x
		lda 	lineBuffer+1 				; blocks hi
		sta 	DIR_INDEX+3,x

		;		Advance name pointer past name + null
		clc
		lda 	dirNamePtr
		adc 	dirCmpTmp 					; name length
		sta 	dirNamePtr
		lda 	dirNamePtr+1
		adc 	#0
		sta 	dirNamePtr+1
		inc 	dirNamePtr 					; skip null terminator
		bne 	_RDFileNoCy
		inc 	dirNamePtr+1
_RDFileNoCy:
		;		Check if name area is getting full
		lda 	dirNamePtr+1
		cmp 	#>(DIR_NAMES_END)
		bcc 	_RDFileCount
		lda 	dirNamePtr
		cmp 	#<(DIR_NAMES_END)
		bcs 	_RDFileSkip
_RDFileCount:
		inc 	dirFileCount
		bne 	_RDFileNoHi
		inc 	dirFileCount+1
_RDFileNoHi:
		jmp     _RDRead

_RDFileSkip:
		;		Skip this entry (read and discard)
		lda     KNLEvent.directory.file.len
		jsr     _ReadDataToLineBuffer
		jsr 	_ReadExtToLineBuffer
		jmp     _RDRead

_RDFree:
		;		Save free block count
		jsr 	_ReadExtToLineBuffer
		lda 	lineBuffer
		sta 	DIR_FREE_BLK
		lda 	lineBuffer+1
		sta 	DIR_FREE_BLK+1
		jmp 	_RDEOF

_RDEOF:
		lda     KNLEvent.directory.stream
		sta     kernel.args.directory.close.stream
		jmp     kernel.Directory.Close

; ************************************************************************************************
;
;					Phase 2: Sort index by filename (insertion sort)
;
; ************************************************************************************************

_SortEntries:
		lda 	dirFileCount
		cmp 	#2
		bcs 	_SortStart
		rts 								; need at least 2 entries
_SortStart:

		ldx 	#DIR_ENTRY_SIZE 			; start with entry 1
_SortOuter:
		;		Save current entry to temps
		lda 	DIR_INDEX,x
		sta 	dirSortNameLo
		lda 	DIR_INDEX+1,x
		sta 	dirSortNameHi
		lda 	DIR_INDEX+2,x
		sta 	dirSortBlkLo
		lda 	DIR_INDEX+3,x
		sta 	dirSortBlkHi

		stx 	dirSortI 					; save outer index
		txa
_SortInner:
		sec
		sbc 	#DIR_ENTRY_SIZE
		bcc 	_SortAtZeroJmp 				; reached beginning → insert at 0
		tax

		;		Compare based on sort mode
		lda 	dirSortMode
		cmp 	#DIR_SORT_SIZE
		beq 	_SortCmpSize

		;		Compare by name: index[x].name vs saved name
		lda 	DIR_INDEX,x
		sta 	zTemp0
		lda 	DIR_INDEX+1,x
		sta 	zTemp0+1
		lda 	dirSortNameLo
		sta 	zTemp1
		lda 	dirSortNameHi
		sta 	zTemp1+1
		jsr 	_StrCmpCI
		bmi 	_SortInsertAfter 			; entry[x] <= saved → insert after x
		beq 	_SortInsertAfter
		bra 	_SortShift

		;		Compare by size: index[x].blocks vs saved blocks (descending)
_SortCmpSize:
		lda 	DIR_INDEX+3,x 				; compare high byte first
		cmp 	dirSortBlkHi
		bcc 	_SortShift 					; entry[x] < saved → entry is smaller, shift right
		bne 	_SortInsertAfter 			; entry[x] > saved → insert after
		lda 	DIR_INDEX+2,x 				; high bytes equal, compare low
		cmp 	dirSortBlkLo
		bcc 	_SortShift 					; entry[x] < saved → shift right
		bra 	_SortInsertAfter 			; entry[x] >= saved → insert after

_SortShift:

		;		Shift entry[x] right
		lda 	DIR_INDEX,x
		sta 	DIR_INDEX+DIR_ENTRY_SIZE,x
		lda 	DIR_INDEX+1,x
		sta 	DIR_INDEX+DIR_ENTRY_SIZE+1,x
		lda 	DIR_INDEX+2,x
		sta 	DIR_INDEX+DIR_ENTRY_SIZE+2,x
		lda 	DIR_INDEX+3,x
		sta 	DIR_INDEX+DIR_ENTRY_SIZE+3,x

		txa
		bra 	_SortInner

_SortAtZeroJmp:
		ldx 	#0 							; insert at beginning
		bra 	_SortDoInsert
_SortInsertAfter:
		txa 								; insert after entry[x]
		clc
		adc 	#DIR_ENTRY_SIZE
		tax
_SortDoInsert:
		lda 	dirSortNameLo
		sta 	DIR_INDEX,x
		lda 	dirSortNameHi
		sta 	DIR_INDEX+1,x
		lda 	dirSortBlkLo
		sta 	DIR_INDEX+2,x
		lda 	dirSortBlkHi
		sta 	DIR_INDEX+3,x

		;		Next outer entry
		ldx 	dirSortI
		txa
		clc
		adc 	#DIR_ENTRY_SIZE
		tax
		txa
		lsr 	a
		lsr 	a
		cmp 	dirFileCount
		bcc 	_SortOuterJmp
		rts
_SortOuterJmp:
		jmp 	_SortOuter

;
;		Case-insensitive string compare: (zTemp0) vs (zTemp1)
;		Returns: N set if (zTemp0) < (zTemp1), Z set if equal
;
_StrCmpCI:
		ldy 	#0
_SCLoop:
		lda 	(zTemp0),y
		jsr 	_ToUpper
		pha 								; save uppercased char from zTemp0
		lda 	(zTemp1),y
		jsr 	_ToUpper
		sta 	dirCmpTmp 					; uppercased char from zTemp1
		pla 								; uppercased char from zTemp0
		cmp 	dirCmpTmp
		bne 	_SCDone 					; different → flags set from CMP
		ora 	#0 							; check if null (preserves flags for non-null)
		beq 	_SCDone 					; both null → equal (Z set)
		iny
		bra 	_SCLoop
_SCDone:
		rts

_ToUpper:
		cmp 	#'a'
		bcc 	_TURts
		cmp 	#'z'+1
		bcs 	_TURts
		and 	#$DF
_TURts:
		rts

; ************************************************************************************************
;
;					Phase 3: Print sorted entries with shift-pause
;
; ************************************************************************************************

_PrintEntries:
		lda 	dirFileCount
		ora 	dirFileCount+1
		beq 	_PESummary 					; no files

		stz 	dirPrintIdx
_PELoop:
		;		Check for Ctrl+C
		.breakcheck
		beq 	_PENoBreak
		jmp 	_PEBreak
_PENoBreak:

		;		Shift-pause (LIST-style — no directory stream active)
_PEShiftCheck:
		jsr 	IsShiftPressed
		beq 	_PENoPause
		jsr 	kernel.Yield
		jsr 	GetNextEvent
		bra 	_PEShiftCheck
_PENoPause:

		;		Get index entry
		lda 	dirPrintIdx
		asl 	a
		asl 	a
		tax

		;		Print: " name"
		lda 	#32
		jsr 	EXTPrintCharacter
		lda 	DIR_INDEX,x
		sta 	zTemp0
		lda 	DIR_INDEX+1,x
		sta 	zTemp0+1
		;		Find name length for padding
		phy
		ldy 	#0
_PENameLen:
		lda 	(zTemp0),y
		beq 	_PEGotLen
		iny
		bra 	_PENameLen
_PEGotLen:
		sty 	dirCmpTmp 					; save name length (reuse temp)
		;		Print name
		lda 	zTemp0
		ldx 	zTemp0+1
		jsr 	PrintStringXA
		;		Pad to column
		lda 	dirCmpTmp
		eor 	#$FF
		sec
		adc 	#26
		tax
		bmi 	_PEPadDone
		beq 	_PEPadDone
_PEPad:
		lda 	#32
		jsr 	EXTPrintCharacter
		dex
		bne 	_PEPad
_PEPadDone:
		ply

		;		Print right-aligned block count
		lda 	dirPrintIdx
		asl 	a
		asl 	a
		tax
		ldy 	DIR_INDEX+3,x 				; blocks hi → Y
		lda 	DIR_INDEX+2,x 				; blocks lo → A
		phy
		plx 								; X = blocks hi
		jsr 	ConvertInt16
		jsr 	_CDPrintRightAligned
		lda 	#13
		jsr 	EXTPrintCharacter

		;		Next entry
		inc 	dirPrintIdx
		lda 	dirPrintIdx
		cmp 	dirFileCount
		bcc 	_PELoop

_PESummary:
		lda 	#13
		jsr 	EXTPrintCharacter
		lda 	dirFileCount
		ldx 	dirFileCount+1
		jsr 	ConvertInt16
		jsr 	PrintStringXA
		ldx 	#_CDFilesMsg >> 8
		lda 	#_CDFilesMsg & $FF
		jsr 	PrintStringXA
		lda 	DIR_FREE_BLK
		ldx 	DIR_FREE_BLK+1
		jsr 	ConvertInt16
		jsr 	PrintStringXA
		ldx 	#_CDFreeMsg >> 8
		lda 	#_CDFreeMsg & $FF
		jsr 	PrintStringXA
		rts

_PEBreak:
		.error_break

; ************************************************************************************************
;
;									String constants
;
; ************************************************************************************************

_CDFilesMsg:
		.text 	" files, ",0
_CDFreeMsg:
		.text 	" blocks free.",13,0
_CDBlocksHdr:
		.text 	"                   Blocks",0

; ************************************************************************************************
;
;								Shared helper routines
;
; ************************************************************************************************

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

_ReadExtToLineBuffer:
		lda     #2
		sta     kernel.args.recv.buflen
		lda     #lineBuffer & $FF
		sta     kernel.args.recv.buf+0
		lda     #lineBuffer >> 8
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
;		These run in slot 3 module space but call main code for evaluation.
;
; ************************************************************************************************

Export_DirStringImpl:
		;		Argument already in dirFuncArg (set by interface)
		lda 	dirFuncArg
		cmp 	dirFileCount
		bcs 	_DSSEmpty

		;		Map buffer, read name, copy to lineBuffer
		pha
		lda 	8+2
		sta 	dirSavedSlot2
		lda 	#DIR_RAM_PAGE
		sta 	8+2

		pla
		asl 	a
		asl 	a
		tax
		lda 	DIR_INDEX,x
		sta 	zTemp0
		lda 	DIR_INDEX+1,x
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
		rts

_DSSEmpty:
		stz 	lineBuffer
		bra 	_DSSReturn

Export_DirNumImpl:
		;		Arguments in dirFuncArg (value) and dirFuncSign (sign)
		lda 	dirFuncSign
		bmi 	_DNNeg

		;		Positive: block count for entry n
		lda 	dirFuncArg
		cmp 	dirFileCount
		bcs 	_DNZero

		pha
		lda 	8+2
		sta 	dirSavedSlot2
		lda 	#DIR_RAM_PAGE
		sta 	8+2
		pla
		asl 	a
		asl 	a
		tay
		lda 	DIR_INDEX+2,y
		sta 	zTemp0
		lda 	DIR_INDEX+3,y
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
		lda 	dirFuncArg 					; mantissa (1 for -1, 2 for -2)
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
		rts

	.send code

	.section storage
dirStreamID:
		.fill 	1
dirSortMode:
		.fill 	1
dirFileCount:
		.fill 	2
dirNamePtr:
		.fill 	2
dirSavedSlot2:
		.fill 	1
dirPrintIdx:
		.fill 	1
dirSortI:
		.fill 	1
dirSortNameLo:
		.fill 	1
dirSortNameHi:
		.fill 	1
dirSortBlkLo:
		.fill 	1
dirSortBlkHi:
		.fill 	1
dirCmpTmp:
		.fill 	1
dirFuncArg:
		.fill 	1
dirFuncSign:
		.fill 	1
	.send storage
