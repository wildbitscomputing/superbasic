;;
; Slot 3 module bank switching
;
; Note that slot 3 (page 2) banking is about 4x slower than slot 5 (page 1),
; ~29 cycles vs ~112 cycles per thunk.
;
; `Slot3ModulePage`, `Slot3Depth`, and `Slot3Saved` are declared in
; `04data.inc` (placed before `numberBuffer`/`decimalBuffer` to survive
; buffer overflows).
;;

; Page 1 modules use slot 5 (inc/dec 8+5).
; Page 2 modules use slot 3 (save/restore 8+3 with depth counter).


.if PagingEnabled==1 && HasPage2==1

Slot3Init:
	stz Slot3Depth
	lda 8+4
	clc
	adc #3
	sta Slot3ModulePage
	rts

Slot3BankIn:
	phy
	pha
	inc Slot3Depth
	lda Slot3Depth
	cmp #1
	bne +
	ldy 8+3
	sty Slot3Saved
	ldy Slot3ModulePage
	sty 8+3
+	pla
	ply
	rts

Slot3BankOut:
	pha
	phy
	dec Slot3Depth
	bne +
	ldy Slot3Saved
	sty 8+3
+	ply
	pla
	rts

.endif
