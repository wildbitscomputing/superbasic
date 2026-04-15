; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		pagesplit.asm
;		Purpose:	Split a program page to make room for mid-page line insertion
;		Created:	8th April 2026
;		Author:		Matthias Brukner (mbrukner@gmail.com)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;	Page split: move content from insert point to end of current page onto a
;	newly allocated page inserted after it in the page table.
;
;	On entry:
;		codePtr    = insert position on current page
;		codePtr+2  = logical page index (N)
;		zTemp2     = end of data on current page (from IMemoryFindEnd)
;
;	On exit:
;		CC = success: codePtr and MMU set for insert retry
;		CS = failure: out of memory
;
; ************************************************************************************************

Export_PageSplitImpl:
		; --- Save state ---
		lda		codePtr+2
		sta		_psPageIdx
		lda		codePtr
		sta		_psInsertLo
		lda		codePtr+1
		sta		_psInsertHi

		; --- Calculate bytes to copy: zTemp2 - codePtr + 1 ---
		sec
		lda		zTemp2
		sbc		codePtr
		sta		_psCopyLen
		lda		zTemp2+1
		sbc		codePtr+1
		sta		_psCopyLen+1
		inc		_psCopyLen
		bne		+
		inc		_psCopyLen+1
+
		; --- Allocate new physical page ---
		jsr		MemoryAllocPage
		bcc		_psAllocOK
		rts									; CS = out of memory

_psAllocOK:
		; --- Get new page's physical page number ---
		ldx		pageCount
		dex
		lda		pageTable,x
		sta		_psDstPage

		; --- Shift page table: [N+1..pC-2] -> [N+2..pC-1] ---
_psShift:
		dex
		cpx		_psPageIdx
		beq		_psShiftDone
		lda		pageTable,x
		sta		pageTable+1,x
		bra		_psShift
_psShiftDone:

		; --- Place new page at [N+1], get source page ---
		lda		_psDstPage
		ldx		_psPageIdx
		sta		pageTable+1,x
		lda		pageTable,x
		sta		_psSrcPage

		; --- Set up copy pointers ---
		lda		_psInsertLo
		sta		zTemp0
		lda		_psInsertHi
		sta		zTemp0+1

		stz		zTemp1						; dest low = $00 (BasicStart & $FF)
		lda		#>BasicStart
		sta		zTemp1+1					; dest high = $20

		; --- Copy bytes, alternating MMU on slot 1 ---
_psCopy:
		lda		_psCopyLen
		ora		_psCopyLen+1
		beq		_psCopyDone

		lda		_psSrcPage
		sta		MMU_Slot1
		lda		(zTemp0)
		pha

		lda		_psDstPage
		sta		MMU_Slot1
		pla
		sta		(zTemp1)

		inc		zTemp0
		bne		+
		inc		zTemp0+1
+		inc		zTemp1
		bne		+
		inc		zTemp1+1
+
		lda		_psCopyLen
		bne		+
		dec		_psCopyLen+1
+		dec		_psCopyLen

		bra		_psCopy

_psCopyDone:
		; --- Truncate source page at insert point ---
		lda		_psSrcPage
		sta		MMU_Slot1
		lda		_psInsertLo
		sta		codePtr
		lda		_psInsertHi
		sta		codePtr+1
		lda		_psPageIdx
		sta		codePtr+2
		lda		#0
		sta		(codePtr)					; write end-of-page terminator

		; --- Check if new line fits on this page ---
		; Available space = BasicEnd - codePtr
		sec
		lda		#<BasicEnd
		sbc		codePtr
		sta		zTemp0						; available low
		lda		#>BasicEnd
		sbc		codePtr+1					; available high
		bne		_psResync					; >= 256 bytes free, fits
		lda		zTemp0
		cmp		tokenOffset
		bcs		_psResync					; available >= tokenOffset, fits

		; --- Not enough room: move insert to next page ---
		inc		codePtr+2
		jsr		ResetCodePtrAndSync
		clc
		rts

_psResync:
		jsr		DoResync
		clc
		rts

		.send code

; ************************************************************************************************
;
;		Temporary storage for page split operation
;
; ************************************************************************************************

		.section storage
_psSrcPage:		.fill 1
_psDstPage:		.fill 1
_psPageIdx:		.fill 1
_psInsertLo:	.fill 1
_psInsertHi:	.fill 1
_psCopyLen:		.fill 2
		.send storage
