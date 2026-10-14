; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		term.asm
;		Purpose:	Evaluate a term
;		Created:	20th September 2022
;		Reviewed: 	27th November 2022
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;								Dereference x and x+1 entries
;
; ************************************************************************************************

DereferenceTopTwo:
		inx
		jsr 	Dereference 				; deref x+1
		dex  								; falls through to deref x

; ************************************************************************************************
;
;									Dereference stack level X
;
;		Can be : a string reference (if $0000, this is changed to point to a null string)
;			   : byte (1 byte), word (2 bytes)
;			   : integer (do 4 mantissa and extract sign to negative flag)
;			   : float (do 4 mantissa = exponent, and extract sign to negative flag)
;
; ************************************************************************************************

Dereference:
		lda 	NSStatus,x 					; get the status byte
		and 	#NSBIsReference 			; is it a reference
		beq 	_DRFExit 					; not a reference, so exit.
		;
		phy
		; ------------------------------------------------------------------------
		;
		;		Stuff we do for everything
		;
		; ------------------------------------------------------------------------
		lda 	NSMantissa0,x 				; copy address to dereference into zTemp0
		sta 	zTemp0
		lda 	NSMantissa1,x
		sta 	zTemp0+1
		stz 	NSMantissa1,x 				; clear second byte.
		;
		lda 	(zTemp0) 					; do the first byte
		sta 	NSMantissa0,x		
		;
		; ------------------------------------------------------------------------
		;
		;		Figure out if string, float, or int, and if integer byte/word/int
		;
		; ------------------------------------------------------------------------

		lda 	NSStatus,x 					; get status byte.
		and 	#NSBTypeMask+3 				; type and byte/word indirection width
		beq 	_DRFFull 					; common full integer reference
		cmp 	#NSTString 					; if string, dereference two
		beq 	_DRFDereferenceTwo
		cmp 	#NSTFloat 					; if float, do full dereference.		
		beq 	_DRFFull 
		;
		;		Dereference integer
		;
		; A is already the byte/word width (1 or 2).

		; ------------------------------------------------------------------------
		;
		;		Doing 1 or 2 bytes - these come from ! and ? operators.
		;
		; ------------------------------------------------------------------------

		cmp 	#1 							; is it 10 (e.g. 2 bytes)
		beq		_DRFClear23 				; no, one byte, clear 2 & 3 and exit
		;
_DRFDereferenceTwo:
		ldy 	#1
		lda 	(zTemp0),y
		sta 	NSMantissa1,x
_DRFClear23:
		stz 	NSMantissa2,x 				; clear upper bytes, only read 1 or 2 bytes
		stz 	NSMantissa3,x

		lda 	NSStatus,x 					; make it a value of that type.
		and 	#NSBTypeMask
		sta 	NSStatus,x 					; and fall through.

		; ------------------------------------------------------------------------
		;
		;		For string reference, if the value stored there is $0000 return
		; 		a null string.
		;
		; ------------------------------------------------------------------------

		cmp 	#NSTString  				; is it a string
		bne 	_DRFNotString

		lda 	NSMantissa0,x 				; check address is zero
		ora 	NSMantissa1,x
		bne 	_DRFNotString

		lda 	#_DRFNullString & $FF 		; if so, return reference to ""
		sta 	NSMantissa0,x
		lda 	#_DRFNullString >> 8
		sta 	NSMantissa1,x

_DRFNotString		
		ply 								; restore Y and exit
_DRFExit:		
		rts


_DRFNullString: 							; a null string.
		.byte 	0		

		; ------------------------------------------------------------------------
		;
		;		Doing 4 (Integer, word) or 5 bytes (Float)
		;		
		; ------------------------------------------------------------------------
_DRFFull:
		ldy 	#1 							; get remaining 3 bytes.
		lda 	(zTemp0),y
		sta 	NSMantissa1,x
		iny
		lda 	(zTemp0),y
		sta 	NSMantissa2,x
		iny
		lda 	(zTemp0),y
		sta 	NSMantissa3,x
		;
		stz 	NSExponent,x 				; clear exponent.
		
		; ------------------------------------------------------------------------
		;
		;		Do we read a 5th byte for Floats ?
		;
		; ------------------------------------------------------------------------

		lda		NSStatus,x 					; see if type is integer
		and 	#NSBTypeMask  				; type information only
		sta 	NSStatus,x 					; update it back.
		beq 	_DRFNoExponent
		iny 								; if not, read the exponent as well.
		lda 	(zTemp0),y
		sta 	NSExponent,x
_DRFNoExponent:

		; ------------------------------------------------------------------------
		;
		;		Extract the sign bit from Mantissa3:7 to Status:7
		;
		; ------------------------------------------------------------------------
		lda 	NSMantissa3,x 				; is the most significant bit set ?
		bpl 	_DRFExit2 					; if not, then exit.
		and 	#$7F 						; clear that bit.
		sta 	NSMantissa3,x
		lda 	NSStatus,x 					; set the sign flag
		ora 	#NSBIsNegative
		sta 	NSStatus,x
_DRFExit2:
		ply
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
