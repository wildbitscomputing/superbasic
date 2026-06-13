;;
; Display the startup banner.
;
; Banner data is in the boot section ($6000-$7FFF, slot 3), which is
; auto-mapped by the kernel at startup. No paging needed — data is
; accessed directly. Slot 3 is remapped to RAM after boot completes.
;;

.section code

;;
; Display the banner graphics.
;
; Unpacks the RLE-compressed character/attribute data into screen memory.
;
; \sideeffects  - Modifies zero-page locations $0001, `zTemp0`, and `zTemp1`
;               - Modifies `A`, `X`, and `Y` registers
;               - Writes to $C000 screen memory.
;;
Export_EXTShowStartupBanner:
		; unpack banner chars into screen memory
		ldx 	#<Banner.Chars
		ldy 	#>Banner.Chars
		lda 	#2
		jsr 	_ESHCopyBlock

		; unpack banner attrs into screen memory
		ldx 	#<Banner.Attrs
		ldy 	#>Banner.Attrs
		lda 	#3
		jsr 	_ESHCopyBlock

		rts

;;
; Copy and unpack RLE-compressed banner data to screen memory.
;
; Reads RLE-compressed data pointed to by `X`/`Y` registers and writes the
; unpacked bytes to screen memory at $C000.
;
; \sideeffects  - Modifies zero-page locations $0001, `zTemp0`, and `zTemp1`
;               - Modifies `A`, `X`, and `Y` registers
_ESHCopyBlock:
		sta 	$0001
		stx 	zTemp0 						; zTemp0 is RLE packed data
		sty 	zTemp0+1
		.set16 	zTemp1,$C000 				; where it goes.
_ESHCopyLoop:
		lda 	(zTemp0) 					; get next character
		cmp 	#Banner.RLE_Marker 			; packed ?
		beq 	_ESHUnpack
		sta 	(zTemp1) 					; copy it out.
		lda 	#1 							; source add 1
		ldy 	#1 							; dest add 1
_ESHNext:
		clc 								; zTemp0 + A
		adc 	zTemp0
		sta 	zTemp0
		bcc 	_ESHNoCarry
		inc 	zTemp0+1
_ESHNoCarry:
		tya 								; zTemp1 + Y
		clc
		adc 	zTemp1
		sta 	zTemp1
		bcc 	_ESHCopyLoop
		inc 	zTemp1+1
		bra 	_ESHCopyLoop
		;
_ESHUnpack:
		ldy 	#2 							; get count into X
		lda 	(zTemp0),y
		tax
		dey 								; byte into A
		lda 	(zTemp0),y
		beq 	_ESHExit 					; exit if zero.
		ldy 	#0 							; copy start position
_ESHCopyOut:
		sta 	(zTemp1),y
		iny
		dex
		bne 	_ESHCopyOut
		lda 	#3 							; Y is bytes on screen, 3 bytes from source
		bra 	_ESHNext
		;
_ESHExit:
		rts

;;
; Loads the startup palette.
;
; \sideeffects  - Modifies zero-page locations $0001
;               - Modifies `A` and `X` registers
;               - Writes to $D800/$D840 palette registers.
;;
EXTLoadStartupPalette:
				stz 	$0001
				ldx 	#16*4-1                     ; the palette is 16 dwords long
	_copy_LUT:
				lda 	Banner.Palette,x
				sta 	$D800,x
				sta 	$D840,x
				dex
				bpl 	_copy_LUT

				rts

.send code
