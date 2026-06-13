; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		utility.asm
;		Purpose:	Tokeniser Utilities
;		Created:	19th September 2022
;		Reviewed: 	23rd November 2022
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;					   Calculate Hash of part of buffer selected for identifier
;
; ************************************************************************************************

TOKCalculateHash:
		phx
		ldx 	identStart 					; needs to be same as in tokens.py - simple sum at present.
		lda 	#0 					
_TCHLoop:
		clc
		adc 	lineBuffer,x
		inx
		cpx 	identTypeEnd 				; do the whole thing including type and array markers.
		bne 	_TCHLoop	
		sta 	identHash 					; save the hash
		plx	
		rts

; ************************************************************************************************
;
;					   Fix case of line in LineBuffer to U/C outside quotes
;
; ************************************************************************************************

LCLFixLineBufferCase:
		ldx 	#0
		;
		;		Loop (out of quotes)
		;
_FLBCLoop:
		lda 	lineBuffer,x 				; get next character
		beq 	_FLBCExit 					; end of string.
		cmp 	#'"'						; quote, go to in quotes
		beq 	_FLBCInQuotes
		inx
		cmp 	#'a'						; needs capitalising ?
		bcc 	_FLBCLoop
		cmp 	#'z'+1
		bcs 	_FLBCLoop
		sec 								; make U/C
		sbc 	#32		
		sta	 	lineBuffer-1,x 				; write back
		bra 	_FLBCLoop
		;
		;		Loop (in quotes)
		;
_FLBCInQuotes:
		inx 								; advance
		lda 	lineBuffer,x 				; get next
		beq 	_FLBCExit 					; exit on EOS
		cmp 	#'"' 				 		; until " found
		bne 	_FLBCInQuotes 		
		inx 								; skip over it
		bra 	_FLBCLoop
		;
_FLBCExit:
		rts

; ************************************************************************************************
;
;		  Extract line number from lineBuffer,x - we know there's at least *one* digit
;		 				Does not zero the initial value (in tokenLineNumber)
;
; ************************************************************************************************

TOKExtractLineNumber:
		lda 	tokenLineNumber+1 			; push current value on stack
		pha
		lda 	tokenLineNumber
		pha
		jsr 	_LCLNTimes2 				; line # x 2
		jsr 	_LCLNTimes2 				; line # x 4
		;
		clc 								; add stacked value
		pla 
		adc 	tokenLineNumber
		sta 	tokenLineNumber
		pla 
		adc 	tokenLineNumber+1
		sta 	tokenLineNumber+1 			; line # x 5
		jsr 	_LCLNTimes2 				; line # x 10
		;
		lda 	lineBuffer,x 				; get and consume character
		inx
		and 	#15 						; add to line #
		clc
		adc 	tokenLineNumber
		sta 	tokenLineNumber
		bcc 	_TLENNoCarry
		inc 	tokenLineNumber+1
_TLENNoCarry:		
		lda 	lineBuffer,x 				; more digits ?
		cmp 	#'0'
		bcc 	_TLENExit
		cmp 	#'9'+1
		bcc 	TOKExtractLineNumber
_TLENExit:
		rts

_LCLNTimes2:		
		asl 	tokenLineNumber 			; doubles tokenLineNumber.
		rol 	tokenLineNumber+1
		rts

; ************************************************************************************************
;
;								Write Byte to tokenBuffer
;
; ************************************************************************************************

TOKWriteByte:	
		phx
		ldx 	tokenOffset 				; next slot to write to
		sta 	tokenOffset,x 				; write byte out
		inc 	tokenOffset 				; advance slot.
		plx
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
