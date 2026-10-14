; Cache repeated structured IF/ELSE skips without changing program tokens.
; Only these two runtime callers use this entry point: each source position
; has a fixed pair of scan targets. The general/listing scanner stays uncached.
; Keys include the logical program page, not just the bank-window address.

		.section code
BranchCacheClear:
		phx
		ldx #63
		lda #0
_BCCLoop:
		sta branchKeyHi,x
		dex
		bpl _BCCLoop
		plx
		rts

BranchScanForward:
		jsr Slot3BankIn
		jsr BranchScanForwardImpl
		php
		jsr Slot3BankOut
		plp
		rts
		.send code

		.section page2
		.logical * + $2000
BranchScanForwardImpl:
		; Direct-mode buffers are mutable and outside the program window.
		pha
		lda codePtr+1
		cmp #>BasicStart
		bcc _BCUncached
		cmp #>BasicEnd
		bcs _BCUncached
		; Preserve scanner targets while finding the direct-mapped slot.
		phx
		tya
		eor codePtr
		eor codePtr+1
		and #63
		tax
		lda branchKeyLo,x
		cmp codePtr
		bne _BCMiss
		lda branchKeyHi,x
		cmp codePtr+1
		bne _BCMiss
		lda branchKeyPage,x
		cmp codePtr+2
		bne _BCMiss
		tya
		cmp branchKeyY,x
		bne _BCMiss
		; Discard the saved scan targets on a hit.
		pla
		pla
		lda branchDestLo,x
		sta codePtr
		lda branchDestHi,x
		sta codePtr+1
		lda branchDestPage,x
		sta codePtr+2
		phx
		.cresync
		plx
		ldy branchDestY,x
		lda branchToken,x
		ldx #0
		rts

_BCUncached:
		pla
		jmp ScanForward

_BCMiss:
		stx branchPendingSlot
		sty branchPendingY
		lda codePtr
		sta branchPendingLo
		lda codePtr+1
		sta branchPendingHi
		lda codePtr+2
		sta branchPendingPage
		plx
		pla
		jsr ScanForward
		ldx branchPendingSlot
		sta branchToken,x
		tya
		sta branchDestY,x
		lda codePtr
		sta branchDestLo,x
		lda codePtr+1
		sta branchDestHi,x
		lda codePtr+2
		sta branchDestPage,x
		lda branchPendingLo
		sta branchKeyLo,x
		lda branchPendingHi
		sta branchKeyHi,x
		lda branchPendingPage
		sta branchKeyPage,x
		lda branchPendingY
		sta branchKeyY,x
		lda branchToken,x
		ldx #0
		rts
		.endlogical
		.send page2

		.section storage
branchKeyLo: .fill 64
branchKeyHi: .fill 64
branchKeyPage: .fill 64
branchKeyY: .fill 64
branchDestLo: .fill 64
branchDestHi: .fill 64
branchDestPage: .fill 64
branchDestY: .fill 64
branchToken: .fill 64
branchPendingSlot: .fill 1
branchPendingLo: .fill 1
branchPendingHi: .fill 1
branchPendingPage: .fill 1
branchPendingY: .fill 1
		.send storage
