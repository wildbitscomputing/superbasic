; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		scroll.asm
;		Purpose:	Scroll one part of screen
;		Created:	16th November 2022
;		Reviewed: 	No
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;						Scroll screen in current i/o page, fill with A
;
; ************************************************************************************************

Export_EXTScrollFill:
		tax									; save value to fill with

		lda 	zTemp0 						; save zTemp0 (dest) zTemp1 (src)
		pha
		lda 	zTemp0+1
		pha
		lda 	zTemp1
		pha
		lda 	zTemp1+1
		pha

		lda 	#$C0 						; copy from C000+length to C000
		sta 	zTemp0+1
		sta 	zTemp1+1
		stz 	zTemp0
		lda 	EXTScreenWidth
		sta 	zTemp1
		ldy 	#0
_EXSFCopy1: 								; do one page
		lda 	(zTemp1),y
		sta 	(zTemp0),y
		iny
		bne 	_EXSFCopy1
		inc 	zTemp0+1 					; next page
		inc 	zTemp1+1
		lda 	zTemp1+1
		cmp 	#$D3
		bne 	_EXSFCopy1

		ldy 	EXTScreenWidth 				; blank the bottom line.
		txa
_EXSFFill1:	
		dey 
		sta 	(EXTAddress),y		
		cpy 	#0
		bpl 	_EXSFFill1

		pla 	
		sta 	zTemp1+1
		pla
		sta 	zTemp1
		pla 	
		sta 	zTemp0+1
		pla
		sta 	zTemp0

		rts

; ************************************************************************************************
;
;					Scroll screen DOWN in current i/o page, fill top with A
;			(Copies screen memory from top to bottom, blanks top row)
;
; ************************************************************************************************

Export_EXTScrollDown:
		tax									; save value to fill with

		lda 	zTemp0 						; save zTemp0 (dest) zTemp1 (src)
		pha
		lda 	zTemp0+1
		pha
		lda 	zTemp1
		pha
		lda 	zTemp1+1
		pha

		; Calculate end of screen - we'll work backwards
		; Screen goes from $C000 to $C000 + (height * width) - 1
		; For 80x60 that's $C000 to $D2BF (4800 bytes = $12C0)
		; We copy from $D2BF-width down to $D2BF, then $D2BF-2*width to $D2BF-width, etc.

		; Set up source = last byte of second-to-last row = $D2BF - width
		; Set up dest = last byte of last row = $D2BF

		lda 	#$D2 						; dest = $D2xx (last page)
		sta 	zTemp0+1
		sta 	zTemp1+1

		; Calculate offset: $BF = $C0 - 1 (last column of last row in the $D2xx page)
		lda 	#$BF
		sta 	zTemp0 						; dest = $D2BF (end of screen)

		sec 								; src = dest - width
		sbc 	EXTScreenWidth
		sta 	zTemp1
		bcs 	_EXSDNoCarry1
		dec 	zTemp1+1
_EXSDNoCarry1:

		; Copy backwards from $D2BF down to $C000
_EXSDCopyLoop:
		lda 	zTemp1+1 					; check if src < $C0xx
		cmp 	#$C0
		bcc 	_EXSDDone 					; if src high byte < $C0, we're done
		lda 	(zTemp1) 					; get byte from source
		sta 	(zTemp0) 					; store to destination

		; Decrement both pointers
		lda 	zTemp0
		bne 	_EXSDNoDec0
		dec 	zTemp0+1
_EXSDNoDec0:
		dec 	zTemp0

		lda 	zTemp1
		bne 	_EXSDNoDec1
		dec 	zTemp1+1
_EXSDNoDec1:
		dec 	zTemp1

		bra 	_EXSDCopyLoop

_EXSDDone:
		; Blank the top line with X (saved fill value)
		ldy 	EXTScreenWidth 				; fill top row
		txa
		lda 	#$C0 						; point to start of screen
		sta 	zTemp0+1
		stz 	zTemp0
_EXSDFill1:
		dey
		txa
		sta 	(zTemp0),y
		cpy 	#0
		bne 	_EXSDFill1

		pla
		sta 	zTemp1+1
		pla
		sta 	zTemp1
		pla
		sta 	zTemp0+1
		pla
		sta 	zTemp0

		rts

		.send code

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
