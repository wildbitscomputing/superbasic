; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		bload.asm
;		Purpose:	BLOAD command (load binary)
;		Created:	2nd January 2023
;		Reviewed: 	No
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

; ************************************************************************************************
;
;									LOAD a Binary File
;
; ************************************************************************************************

		.section code

Command_BLoad: ;; [BLOAD]
		jsr 	BLOADHandler
		cmp 	#0
		bne 	_BLError
		rts
_BLError:		
		jmp 	CLErrorHandler

; ************************************************************************************************
;
;							BLOAD code ; returns A = 0 or error
;
; ************************************************************************************************

BLOADHandler:
		ldx 	#0
		jsr 	EvaluateString 				; file name to load
		jsr 	CheckComma 					; consume comma
		inx 							
		jsr 	EvaluateInteger 			; load address (full physical address)
		jmp BLoadImpl
; ************************************************************************************************
;
;							Open page read/write at Mantissa,x
;
; ************************************************************************************************

BLAccessPage = 2 							; page to use for actual memory (not slot 3, used for module banking)

BLOpenPhysicalMemory:
		lda 	BLAccessPage+8 				; save current mapping
		sta 	BLNormalMapping

		lda 	NSMantissa0,x 				; copy address, 13 bit adjusted for page -> (zTemp2),BLYOffset
		sta 	BLYOffset 					; zTemp2 0 is *always* zero.
		stz 	zTemp2
		lda 	NSMantissa1,x
		and 	#$1F
		ora 	#BLAccessPage << 5
		sta 	zTemp2+1

		lda 	NSMantissa2,x 				; shift M2:M1 right 3 times to give page # required
		asl 	NSMantissa1,x
		rol 	a
		asl 	NSMantissa1,x
		rol 	a
		asl 	NSMantissa1,x
		rol 	a
		sta 	BLAccessPage+8 				; access that page
		rts

; ************************************************************************************************
;
;										Close opened page.
;
; ************************************************************************************************

BLClosePhysicalMemory:
		lda 	BLNormalMapping
		sta 	BLAccessPage+8
		rts

; ************************************************************************************************
;
;					Advance current address (when Y index ticks over to zero)
;
; ************************************************************************************************

BLAdvancePhysicalMemory:
		pha
		inc		zTemp2+1 					; bump MSB
		lda 	zTemp2+1
		cmp 	#(BLAccessPage+1) << 5 		; reached next page ?
		bne 	_BLAPMExit 					; (e.g. end of the mapped page.)

		inc 	BLAccessPage+8 				; next physical page
		lda 	#BLAccessPage << 5 			; page back to start of transfer page
		sta 	zTemp2+1

_BLAPMExit:
		pla
		rts

		.send code

		.section storage
BLNormalMapping:							; page the access page is normally mapped to.
		.fill 	1
BLYOffset: 									; position in zTemp2 page.
		.fill 	1
BLCopyCounter: 								; count of bytes to output.
		.fill 	1		
		.send storage

; ************************************************************************************************
;
;									Changes and Updates
;
; ************************************************************************************************
;
;		Date			Notes
;		==== 			=====
;		29/01/23 		BLOAD is now stand alone, returning A = 0 or error code.
;
; ************************************************************************************************
