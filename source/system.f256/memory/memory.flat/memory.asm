; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		memory.asm
;		Purpose:	BASIC program space manipulation
;		Created:	19th September 2022
;		Reviewed: 	23rd November 2022
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;									Erase the current program
;
; ************************************************************************************************

MemoryNew:
		stz 	codePtr+2 					; reset to logical page 0
		stz 	codePtr 					; codePtr low = 0 (BasicStart & $FF)
		lda 	#>BasicStart 				; codePtr high = $20
		sta 	codePtr+1
		lda 	#ProgramPage0 				; always use the fixed boot page for page 0
		sta 	MMU_Slot1 					; map it into slot 1
		sta 	pageTable 					; save as page 0 in page table
		lda 	#0 							; zero program start (erase program)
		.cset0
		inc 	a 							; A = 1
		sta 	pageCount 					; one page allocated
		rts

; ************************************************************************************************
;
;							Get inline code address into current stack level.
;
;		Used for inline strings. If this is paged, it may have to go into temporary storage,
; 		a buffer or similar.
;
; ************************************************************************************************

MemoryInline:
		lda 	pageCount 					; multi-page program?
		cmp 	#2
		bcs 	_MIPageCross 				; yes, always copy — pointer may go stale on page switch
		;
		tya 								; put address into stack,x
		clc  								; get the offset, add codePtr
		adc 	codePtr
		sta 	NSMantissa0,x
		lda 	codePtr+1
		adc 	#0
		sta 	NSMantissa1,x 				; return direct address (safe: single page)
		stz 	NSMantissa2,x
		stz 	NSMantissa3,x
		rts
		;
		;		Multi-page or boundary case — copy string to lineBuffer via .cget
		;		so the pointer survives page switches (e.g. proc calls).
		;
_MIPageCross:
		phy 								; save Y (offset to first char)
		phx 								; save X (stack index)
		ldx 	#0
_MICopyLoop:
		.cget 								; read byte at (codePtr),y (handles paging)
		sta 	lineBuffer,x
		beq 	_MICopyDone 				; null terminator copied
		iny
		inx
		bne 	_MICopyLoop 				; max 255 chars
_MICopyDone:
		plx 								; restore stack index
		ply 								; restore Y
		lda 	#<lineBuffer
		sta 	NSMantissa0,x
		lda 	#>lineBuffer
		sta 	NSMantissa1,x
		stz 	NSMantissa2,x
		stz 	NSMantissa3,x
		rts

; ************************************************************************************************
;
;		Advance codePtr to the next line. Called via .cnextline macro.
;		On entry: codePtr points to current line (first byte is offset/length)
;		On exit: codePtr points to next line. A, X modified.
;		Handles page boundary crossing when codePtr+1 reaches $40 (end of slot 1).
;
; ************************************************************************************************

DoNextLine:
		clc
		lda 	(codePtr)					; get offset byte (line length)
		adc 	codePtr						; add to low byte of codePtr
		sta 	codePtr
		bcc 	_DNLDone					; no carry, done
		inc 	codePtr+1 					; handle carry into high byte
		bit 	codePtr+1 					; test bit 6: $40 = 0100_0000
		bvs 	_DNLCrossPage 				; V set = crossed $3FFF into $4000
_DNLDone:
		rts
		;
		;		Page boundary crossed — wrap to start of next logical page
		;
_DNLCrossPage:
		inc 	codePtr+2 					; advance to next logical page
		bra 	ResetHighAndSync 			; reset high byte and resync

; ************************************************************************************************
;
;		Reset codePtr to start of page ($2000) and map the correct physical page.
;		ResetCodePtrAndSync: resets both low and high bytes, then resyncs.
;		ResetHighAndSync: resets only high byte, then resyncs.
;		Called by DoCheckEnd, MemoryAllocPage, and _DNLCrossPage.
;		Clobbers A and X; preserves Y.
;
; ************************************************************************************************

ResetCodePtrAndSync:
		stz 	codePtr 					; reset low byte to 0

ResetHighAndSync:
		lda 	#>BasicStart 				; reset high byte to $20
		sta 	codePtr+1
		;										fall through to DoResync

; ************************************************************************************************
;
;		Map the correct physical page for the current codePtr+2 (logical page index).
;		Called via .cresync macro. Clobbers A and X; preserves Y.
;
; ************************************************************************************************

DoResync:
		ldx 	codePtr+2 					; logical page index
		lda 	pageTable,x 				; physical page number
		sta 	MMU_Slot1 					; map into slot 1
		rts

; ************************************************************************************************
;
;		Check if current position is end of program or end of page.
;		Called via .cget0 macro.
;		- If offset != 0: returns A=offset, Z clear (more lines on this page)
;		- If offset = 0 and last page: returns A=0, Z set (end of program)
;		- If offset = 0 and more pages: advances to next page, returns A=new offset
;		Clobbers A and X; preserves Y.
;
; ************************************************************************************************

DoCheckEnd:
		lda 	(codePtr) 					; get offset byte
		bne 	_DCERet 					; non-zero = have more lines, done
		;
		;		Offset is 0. Check if there are more pages.
		;
		ldx 	codePtr+2 					; current logical page
		inx
		cpx 	pageCount 					; page+1 >= pageCount = truly end
		bcs 	_DCERet 					; A=0, Z set = end of program
		;
		;		More pages exist. Advance to next page.
		;
		stx 	codePtr+2 					; store new page index
		jsr 	ResetCodePtrAndSync 		; reset codePtr and map page
		lda 	(codePtr) 					; load offset from new page
_DCERet:
		rts

; ************************************************************************************************
;
;		Allocate a new physical page for program storage.
;		On exit: A = physical page number, carry set if out of memory.
;		Clobbers A and X.
;
; ************************************************************************************************

MemoryAllocPage:
		ldx 	pageCount 					; check if we've hit the max
		cpx 	maxUsablePages
		bcs 	_MAPFail 					; too many logical pages
		stx 	codePtr+2 					; set logical page index
		lda 	nextFreePage 				; get next physical page
		sta 	pageTable,x 				; store in page table (X = pageCount)
		inc 	pageCount 					; one more page
		inc 	nextFreePage 				; advance allocator
		jsr 	ResetCodePtrAndSync 		; reset codePtr and map page
		lda 	#0
		sta 	(codePtr) 					; write end-of-page terminator
		clc 								; success
		rts
_MAPFail:
		sec 								; out of memory
		rts

		.send code

; ************************************************************************************************
;
;		Page table and banking state (in storage section)
;
; ************************************************************************************************

		.section storage

pageTable: 									; maps logical page index -> physical page number
		.fill 	MaxPages
pageCount: 									; number of allocated logical pages
		.fill 	1
nextFreePage: 								; next physical page to allocate
		.fill 	1
maxUsablePages:								; runtime max logical pages (updated by LOMEM)
		.fill 	1

		.send storage

; ************************************************************************************************
;
;		Physical page allocation constants.
;		Pages 0-7: slots 0-3 (system RAM, variables, program base, scratch)
;		Pages 8-13: graphics (bitmap at $10000 = page 8)
;		Pages 18-19: tile maps ($24000)
;		Pages 20-21: source load area ($28000)
;		Pages 24-25: sprites ($30000)
;		Pages 26-27: BASIC I/O area ($34000)
;		All F256 systems have at least 512KB RAM.
;		We allocate from page 48 upward to stay clear of all reservations.
;
; ************************************************************************************************

ProgramPage0 = BasicStart >> 13 			; physical page for slot 1 at boot (identity mapping)
FirstFreePage = 48 							; first safe physical page for program data ($60000)
MaxPhysPage = 60 							; 64×8KB pages; $3d-$3f reserved for the NMI break monitor (screen save + code)
_AvailablePages = MaxPhysPage - FirstFreePage + 1 ; dynamic pages + page 0
.if _AvailablePages < MaxPages
MaxUsablePages = _AvailablePages
.else
MaxUsablePages = MaxPages
.endif

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
