; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		lomem.asm
;		Purpose:	LOMEM implementation (module code)
;		Created:	9th March 2026
;		Author:		Matthias Brukner (mbrukner@gmail.com)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;		Set the physical page from which new program pages are allocated.
;		On entry: address in NSMantissa0-2 at stack level X=0.
;		Converts address >> 13 to a page number, validates, and stores.
;
; ************************************************************************************************

Export_EXTLomem:
		;
		;		Convert address to page number: page = address >> 13
		;		= (NSMantissa1 >> 5) | (NSMantissa2 << 3)
		;
		lda 	NSMantissa1 				; bits 8-15 of address
		lsr 	a
		lsr 	a
		lsr 	a
		lsr 	a
		lsr 	a 							; top 3 bits now in bits 0-2
		sta 	zTemp0
		lda 	NSMantissa2 				; bits 16-23 of address
		asl 	a
		asl 	a
		asl 	a 							; low 5 bits now in bits 3-7
		ora 	zTemp0 						; A = page number
		;
		;		Validate: page must be in [8, MaxPhysPage)
		;
		cmp 	#8 							; below system pages?
		bcc 	_EHRange
		cmp 	#MaxPhysPage 				; above physical RAM?
		bcs 	_EHRange
		;
		;		Store validated page number
		;
		sta 	nextFreePage
		;
		;		Update maxUsablePages: min(MaxPhysPage - nextFreePage + 1, MaxPages)
		;
		eor 	#$FF 						; negate: A = -nextFreePage - 1
		sec
		adc 	#MaxPhysPage 				; A = MaxPhysPage - nextFreePage
		inc 	a 							; A = MaxPhysPage - nextFreePage + 1
		cmp 	#MaxPages
		bcc 	_EHStore 					; if < MaxPages, use it
		lda 	#MaxPages 					; cap at page table size
_EHStore:
		sta 	maxUsablePages
		clc 								; success
		rts
_EHRange:
		sec 								; signal error to caller
		rts

		.send code
