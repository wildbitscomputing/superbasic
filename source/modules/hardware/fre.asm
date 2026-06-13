; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		fre.asm
;		Purpose:	Free memory calculation (module code)
;		Created:	27th February 2026
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;		Calculate free memory in bytes.
;		On entry: X = math stack level, parameter on math stack at level X.
;		Returns: result in NSMantissa0..3,x / NSExponent,x / NSStatus,x
;
;		FRE(0)  = free program memory (page-scanning)
;		FRE(-1) = free variable/string space (stringMemory - lowMemPtr)
;		FRE(-2) = free array/ALLOC space (ArrayEnd - arrayMemPtr)
;		Other   = same as FRE(0)
;
; ************************************************************************************************

Export_EXTFreMemory:
		;
		;		Check parameter: if negative, check for -1 or -2.
		;
		lda 	NSStatus,x 					; check sign bit
		bpl 	_FMFreeProgramMemory 		; positive or zero → FRE(0)
		;
		lda 	NSMantissa1,x 				; bytes 1-3 must be zero for -1 or -2
		ora 	NSMantissa2,x
		ora 	NSMantissa3,x
		bne 	_FMFreeProgramMemory 		; not a small negative → FRE(0)
		;
		lda 	NSMantissa0,x 				; check low byte (magnitude)
		cmp 	#1
		beq 	_FMFreeVarSpace 			; -1 → variable/string space
		cmp 	#2
		beq 	_FMFreeArraySpace 			; -2 → array space
		bra 	_FMFreeProgramMemory 		; other → FRE(0)
		;
		; ------------------------------------------------------------------
		;		FRE(-1): free variable/string space = stringMemory - lowMemPtr
		; ------------------------------------------------------------------
		;
_FMFreeVarSpace:
		sec
		lda 	stringMemory
		sbc 	lowMemPtr
		sta 	NSMantissa0,x
		lda 	stringMemory+1
		sbc 	lowMemPtr+1
		sta 	NSMantissa1,x
		bra 	_FMWrite16BitResult
		;
		; ------------------------------------------------------------------
		;		FRE(-2): free array space = ArrayEnd - arrayMemPtr
		; ------------------------------------------------------------------
		;
_FMFreeArraySpace:
		sec
		lda 	#<ArrayEnd
		sbc 	arrayMemPtr
		sta 	NSMantissa0,x
		lda 	#>ArrayEnd
		sbc 	arrayMemPtr+1
		sta 	NSMantissa1,x
		;
		; ------------------------------------------------------------------
		;		Common tail: write 16-bit unsigned result (bytes 2-3 = 0)
		; ------------------------------------------------------------------
		;
_FMWrite16BitResult:
		stz 	NSMantissa2,x
		stz 	NSMantissa3,x
		stz 	NSExponent,x
		stz 	NSStatus,x
		rts
		;
		; ------------------------------------------------------------------
		;		FRE(0): free program memory (existing logic)
		; ------------------------------------------------------------------
		;
_FMFreeProgramMemory:
		;
		;		Save MMU slot 1 state and scan last page to find end of program.
		;
		lda 	MMU_Slot1 					; save current slot 1 mapping
		pha
		;
		ldy 	pageCount 					; go to last page
		dey
		lda 	pageTable,y 				; get physical page
		sta 	MMU_Slot1 					; map it
		;
		.set16 	zTemp2,BasicStart 			; scan from page start
_FMFindEnd:
		lda 	(zTemp2)					; offset byte
		beq 	_FMFoundEnd 				; zero = end of program on this page
		clc
		adc 	zTemp2
		sta 	zTemp2
		bcc 	_FMFindEnd
		inc 	zTemp2+1
		bra 	_FMFindEnd
		;
_FMFoundEnd:
		;
		;		Remaining on page = $4000 - zTemp2.
		;
		sec
		lda 	#<BasicEnd
		sbc 	zTemp2
		sta 	zTemp2 						; result byte 0 (low)
		lda 	#>BasicEnd
		sbc 	zTemp2+1
		sta 	zTemp2+1 					; result byte 1 (mid)
		;
		;		Add unallocated pages: (MaxPages - pageCount) * $2000.
		;		free_pages * $2000: byte 2 = free_pages >> 3, byte 1 += (free_pages & 7) << 5.
		;		Split avoids overflow since (0..7) << 5 = 0..224 fits in a byte.
		;
		lda 	maxUsablePages
		sec
		sbc 	pageCount 					; A = free pages
		pha 								; save free_pages
		lsr 	a
		lsr 	a
		lsr 	a 							; byte 2 = free_pages >> 3 (0..3)
		sta 	zTemp0 						; save byte 2
		;
		pla 								; restore free_pages
		and 	#$07 						; low 3 bits only
		asl 	a
		asl 	a
		asl 	a
		asl 	a
		asl 	a 							; (free_pages & 7) << 5, max 224
		clc
		adc 	zTemp2+1 					; add to result byte 1
		sta 	zTemp2+1
		bcc 	_FMNoCarry
		inc 	zTemp0 						; propagate carry to byte 2
_FMNoCarry:
		;
		;		Restore MMU and write result to math stack.
		;
		pla 								; restore MMU slot 1
		sta 	MMU_Slot1
		;
		stz 	NSExponent,x
		stz 	NSStatus,x
		lda 	zTemp2
		sta 	NSMantissa0,x
		lda 	zTemp2+1
		sta 	NSMantissa1,x
		lda 	zTemp0
		sta 	NSMantissa2,x
		stz 	NSMantissa3,x
		rts

		.send code
