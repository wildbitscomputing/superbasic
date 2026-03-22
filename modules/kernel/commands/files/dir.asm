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
;		Parallel arrays indexed by entry number (0-based, 8-bit X).
;
;		$4000-$407F: Name pointer low bytes  (128 bytes, 127 entries + 1 sort overflow)
;		$4080-$40FF: Name pointer high bytes (128 bytes)
;		$4100-$417F: Block count low bytes   (128 bytes)
;		$4180-$41FF: Block count high bytes  (128 bytes)
;		$4200-$427F: Flags (FAT32 attributes)(128 bytes)
;		$4280-$5FFD: Packed null-terminated name strings
;		$5FFE-$5FFF: Free block count (2 bytes)
;
DIR_BUF_BASE	= $4000
DIR_NAME_LO	= DIR_BUF_BASE				; name pointer low bytes
DIR_NAME_HI	= DIR_BUF_BASE + $80		; name pointer high bytes
DIR_BLK_LO	= DIR_BUF_BASE + $100		; block count low bytes
DIR_BLK_HI	= DIR_BUF_BASE + $180		; block count high bytes
DIR_FLAGS		= DIR_BUF_BASE + $200		; FAT32 attributes
DIR_NAMES		= DIR_BUF_BASE + $280		; packed name strings
DIR_NAMES_END	= DIR_BUF_BASE + $1FFE		; end of name area
DIR_FREE_BLK	= DIR_BUF_BASE + $1FFE		; free block count (2 bytes)
DIR_MAX_ENTRIES	= 127						; max entries (128th slot reserved for sort overflow)
DIR_RAM_PAGE	= 4							; unused RAM page for buffer
DIR_ATTR_HIDDEN	= $02						; FAT32 hidden attribute bit
DIR_ATTR_DIR	= $10						; FAT32 directory attribute bit
DIR_SORT_NONE	= 0							; no sorting
DIR_SORT_NAME	= 1							; sort by name (case-insensitive)
DIR_SORT_SIZE	= 2							; sort by size (descending)

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
		jsr 	kernel.Yield
		bra     _RDEventLoop

_RDDone:
		;		Directory stream closed — sort and optionally print
		jsr 	_SortEntries
		lda 	dirLoadOnly
		bne 	_RDExit
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
		lda 	dirLoadOnly
		bne 	_RDVolSkip
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
_RDVolSkip:
		;		Still must consume the volume data from the stream
		lda     KNLEvent.directory.volume.len
		jsr     _ReadDataToLineBuffer
		jmp     _RDRead

_RDFile:
		;		Skip hidden files
		lda 	KNLEvent.directory.file.flags
		and 	#DIR_ATTR_HIDDEN
		bne 	_RDFileSkipJmp
		;		Check if index is full
		lda 	dirFileCount
		cmp 	#DIR_MAX_ENTRIES
		bcc 	_RDFileOk
_RDFileSkipJmp:
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

		;		Save flags before ReadExt (which may overwrite event data)
		lda 	KNLEvent.directory.file.flags
		pha

		;		Read block count into lineBuffer
		jsr 	_ReadExtToLineBuffer

		;		Build entry in parallel arrays
		ldx 	dirFileCount
		lda 	dirNamePtr
		sta 	DIR_NAME_LO,x
		lda 	dirNamePtr+1
		sta 	DIR_NAME_HI,x
		lda 	lineBuffer 					; blocks lo (from ReadExt)
		sta 	DIR_BLK_LO,x
		lda 	lineBuffer+1 				; blocks hi
		sta 	DIR_BLK_HI,x
		pla 								; flags (saved before ReadExt)
		sta 	DIR_FLAGS,x

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
		lda 	dirSortMode
		beq 	_SortRts 					; mode 0 = no sorting
		lda 	dirFileCount
		cmp 	#2
		bcs 	_SortStart
_SortRts:
		rts 								; need at least 2 entries
_SortStart:

		ldx 	#1 							; start with entry 1
_SortOuter:
		;		Save current entry to temps
		lda 	DIR_NAME_LO,x
		sta 	dirSortNameLo
		lda 	DIR_NAME_HI,x
		sta 	dirSortNameHi
		lda 	DIR_BLK_LO,x
		sta 	dirSortBlkLo
		lda 	DIR_BLK_HI,x
		sta 	dirSortBlkHi
		lda 	DIR_FLAGS,x
		sta 	dirSortFlags

		stx 	dirSortI 					; save outer index
		txa
_SortInner:
		dec 	a
		bmi 	_SortAtZero 				; reached beginning → insert at 0
		tax

		;		Directories always sort before files
		lda 	DIR_FLAGS,x
		and 	#DIR_ATTR_DIR
		sta 	dirCmpTmp 					; entry[x] is dir?
		lda 	dirSortFlags
		and 	#DIR_ATTR_DIR 				; saved is dir?
		cmp 	dirCmpTmp
		beq 	_SortSameType 				; both same type → compare normally
		bcs 	_SortShift 					; saved is dir, entry[x] is not → shift right
		bra 	_SortInsertAfter 			; entry[x] is dir, saved is not → insert after

_SortSameType:
		;		Both dirs: always compare by name. Both files: check sort mode.
		lda 	dirCmpTmp
		bne 	_SortCmpName 				; both are dirs → sort by name
		lda 	dirSortMode
		cmp 	#DIR_SORT_SIZE
		beq 	_SortCmpSize

		;		Compare by name: entry[x].name vs saved name
_SortCmpName:
		lda 	DIR_NAME_LO,x
		sta 	zTemp0
		lda 	DIR_NAME_HI,x
		sta 	zTemp0+1
		lda 	dirSortNameLo
		sta 	zTemp1
		lda 	dirSortNameHi
		sta 	zTemp1+1
		jsr 	_StrCmpCI
		bmi 	_SortInsertAfter 			; entry[x] <= saved → insert after x
		beq 	_SortInsertAfter
		bra 	_SortShift

		;		Compare by size: descending (largest first)
_SortCmpSize:
		lda 	DIR_BLK_HI,x 				; compare high byte first
		cmp 	dirSortBlkHi
		bcc 	_SortShift 					; entry[x] < saved → shift right
		bne 	_SortInsertAfter 			; entry[x] > saved → insert after
		lda 	DIR_BLK_LO,x 				; high bytes equal, compare low
		cmp 	dirSortBlkLo
		bcc 	_SortShift 					; entry[x] < saved → shift right
		bra 	_SortInsertAfter 			; entry[x] >= saved → insert after

_SortShift:
		;		Shift entry[x] right by one position
		lda 	DIR_NAME_LO,x
		sta 	DIR_NAME_LO+1,x
		lda 	DIR_NAME_HI,x
		sta 	DIR_NAME_HI+1,x
		lda 	DIR_BLK_LO,x
		sta 	DIR_BLK_LO+1,x
		lda 	DIR_BLK_HI,x
		sta 	DIR_BLK_HI+1,x
		lda 	DIR_FLAGS,x
		sta 	DIR_FLAGS+1,x

		txa
		bra 	_SortInner

_SortAtZero:
		ldx 	#0 							; insert at beginning
		bra 	_SortDoInsert
_SortInsertAfter:
		inx 								; insert after entry[x]
_SortDoInsert:
		lda 	dirSortNameLo
		sta 	DIR_NAME_LO,x
		lda 	dirSortNameHi
		sta 	DIR_NAME_HI,x
		lda 	dirSortBlkLo
		sta 	DIR_BLK_LO,x
		lda 	dirSortBlkHi
		sta 	DIR_BLK_HI,x
		lda 	dirSortFlags
		sta 	DIR_FLAGS,x

		;		Next outer entry
		ldx 	dirSortI
		inx
		cpx 	dirFileCount
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
		bne 	_PEHaveFiles
		jmp 	_PESummary 					; no files
_PEHaveFiles:

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

		;		Get entry
		ldx 	dirPrintIdx

		;		Print: " name"
		lda 	#32
		jsr 	EXTPrintCharacter
		lda 	DIR_NAME_LO,x
		sta 	zTemp0
		lda 	DIR_NAME_HI,x
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

		;		Check if entry is a directory
		ldx 	dirPrintIdx
		lda 	DIR_FLAGS,x
		and 	#DIR_ATTR_DIR
		beq 	_PENotDir
		;		Print " <DIR>" right-aligned
		lda 	#32
		jsr 	EXTPrintCharacter
		ldx 	#_CDDirTag >> 8
		lda 	#_CDDirTag & $FF
		jsr 	PrintStringXA
		bra 	_PEEndLine
_PENotDir:
		;		Print right-aligned block count
		ldx 	dirPrintIdx
		ldy 	DIR_BLK_HI,x 				; blocks hi → Y
		lda 	DIR_BLK_LO,x 				; blocks lo → A
		phy
		plx 								; X = blocks hi
		jsr 	ConvertInt16
		jsr 	_CDPrintRightAligned
_PEEndLine:
		lda 	#13
		jsr 	EXTPrintCharacter

		;		Next entry
		inc 	dirPrintIdx
		lda 	dirPrintIdx
		cmp 	dirFileCount
		bcs 	_PESummary
		jmp 	_PELoop

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
_CDDirTag:
		.text 	"<DIR>",0

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
		phy 								; preserve Y (code pointer)
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
		ply 								; restore Y (code pointer)
		rts

_DSSEmpty:
		stz 	lineBuffer
		bra 	_DSSReturn

Export_DirNumImpl:
		;		Arguments in dirFuncArg (value) and dirFuncSign (sign)
		phy 								; preserve Y (code pointer)
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
		ply 								; restore Y (code pointer)
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
dirSortFlags:
		.fill 	1
dirCmpTmp:
		.fill 	1
dirFuncArg:
		.fill 	1
dirFuncSign:
		.fill 	1
dirLoadOnly:
		.fill 	1
	.send storage
