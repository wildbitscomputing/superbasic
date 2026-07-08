; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		dim.asm
;		Purpose:	DIM command
;		Created:	2nd October 2022
;		Reviewed: 	1st December 2022
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

DimCommand: ;; [dim]
		;
		;		Check syntax 
		;
		.cget 							; is there a variable following ?
		and 	#$C0
		cmp 	#$40 	
		bne 	_DCSyntax 				; n o, error.
		;
		.cget 							; copy to zaTemp as real address
		clc 								
		adc 	#((VariableSpace >> 8) - $40) & $FF
		sta 	zaTemp+1
		iny
		.cget
		iny
		sta 	zaTemp
		phy
		;
		;		Check type and not already defined
		;
		ldy 	#2 						; read type byte
		lda 	(zaTemp),y
		and 	#NSBTypeMask 			; check it's not a procedure
		cmp 	#NSTProcedure
		beq 	_DCSyntax
		;
		lda 	(zaTemp),y 				; check it's an array
		and 	#NSBIsArray
		beq 	_DCType
		;
		ldy 	#4 						; check not already defined
		lda 	(zaTemp),y
		bne 	_DCRedefine
		;
		;		Get first dimension
		;
		ply
		jsr 	_DCGetSize 				; get array size, check it.
		phy
		ldy 	#5 						; store in first array size slot
		sta 	(zaTemp),y 				; second will be zero.
		;
		;		If present, get second dimension.
		;
		ply 							; is there a second (e.g. ,x)
		.cget
		cmp 	#KWD_COMMA
		bne 	_DCOneDimension
		iny 							; skip comma
		jsr 	_DCGetSize 				; get 2nd array size
		phy
		ldy 	#6 						; store in 2nd array size
		sta 	(zaTemp),y
		ply
_DCOneDimension:
		phy 							; save position

		ldy 	#5 						; dimensions + 1 in AX (as zero based)
		lda 	(zaTemp),y
		tax
		iny
		lda 	(zaTemp),y
		inx 							; bump them.
		inc 	a
		jsr 	Multiply8x8 			; work out the total number of elements -> zTemp0
		;
		lda 	zTemp0+1 				; don't allow more than 8192 elements whatever
		and 	#$E0 
		bne 	_DCSize

		ldy 	#2 						; get base type
		lda 	(zaTemp),y
		jsr 	ScaleByBaseType 		; scale by base type
		;
		lda 	zTemp0
		ldx 	zTemp0+1
		jsr 	AllocateXABytes 		; allocate memory		
		;
		ldy 	#3 						; copy into the address.
		sta 	(zaTemp),y
		iny
		txa
		sta 	(zaTemp),y
		;
		ply 							; get position back
		jsr 	CheckRightBracket 		; check )
		.cget 							; followed by a comma
		iny 							; consume in case
		cmp 	#KWD_COMMA		 		; if so do another DIM.
		beq 	DimCommand
		dey 							; undo consume
		rts

_DCSize:
		.error_arraysize
_DCSyntax:		
		jmp 	SyntaxError
_DCRedefine:
		.error_redefine
_DCType:
		jmp 	TypeError

; ************************************************************************************************
;		
;									Get an array dimension.
;
; ************************************************************************************************

_DCGetSize:
		ldx 	#0 						; get first index.
		jsr 	Evaluate8BitInteger 	; get array dimension (Z set by lda)
		beq 	_DCSize 				; must be 1-254
		cmp 	#255 					; reject 255: size+1 wraps to 0 elements
		beq 	_DCSize
		rts

; ************************************************************************************************
;		
;	 zTemp0 contains an array index/offset for 2 - scale by type A (string, double others x 5)
;
; ************************************************************************************************

ScaleByBaseType:
		and 	#NSBIsString 			; is it string
		bne 	_SBBTString
		;
		lda 	zTemp0+1 				; push value on stack
		pha
		lda 	zTemp0
		pha
		;
		asl 	zTemp0 					; x 2
		rol 	zTemp0+1
		asl 	zTemp0 					; x 4
		rol 	zTemp0+1
		;
		pla 							; add stacked value = x 5
		adc 	zTemp0
		sta 	zTemp0
		pla
		adc 	zTemp0+1
		sta 	zTemp0+1
		rts

_SBBTString:
		asl 	zTemp0
		rol 	zTemp0+1
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
