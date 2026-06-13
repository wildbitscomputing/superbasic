; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		tokenise.asm
;		Purpose:	Tokenise Line
;		Created:	18th September 2022
;		Reviewed: 	23rd November 2022
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code


; ************************************************************************************************
;
;								Tokenise ASCIIZ line in lineBuffer
;
; ************************************************************************************************

Export_TKTokeniseLine:
		;
		;		Make the line buffer UpperCase outside quoted strings
		;
		jsr 	LCLFixLineBufferCase 		; fix line case
		;
		;		Erase the tokenised line to empty
		;
		lda 	#3 							; reset the token buffer to empty
		sta 	tokenOffset 				; (3 bytes for line number & offset)
		stz 	tokenLineNumber
		stz 	tokenLineNumber+1
		;
		;		Find the first non space character
		;
		ldx 	#$FF
_TKFindFirst:
		inx
		lda 	lineBuffer,x
		beq 	_TKExit
		cmp 	#' '
		bcc 	_TKFindFirst
		;
		;		If it is 0-9 extract a 2 byte integer into the token line number
		;		(because the input line is an editing one)
		;
		cmp 	#'0'
		bcc 	_TKNoLineNumber
		cmp 	#'9'+1
		bcs 	_TKNoLineNumber
		jsr 	TOKExtractLineNumber
_TKNoLineNumber:		
		;----------------------------------------------------------------------------------------
		;
		;							Main tokenising loop
		;
		;----------------------------------------------------------------------------------------

_TKTokeniseLoop:
		lda 	lineBuffer,x 				; next character, exit if zero EOL.
		beq 	_TKExit
		inx
		cmp 	#' '
		beq 	_TKTokeniseLoop 			; keep looping if space found.
		dex 								; undo last get, A contains character, X is position.
		;
		cmp 	#'_'						; _ A-Z is identifier *or* token
		beq 	_TKTokeniseIdentifier 		; (already case converted outside string constants)
		cmp 	#'A'
		bcc 	_TKTokenisePunctuation 
		cmp 	#'Z'+1
		bcc 	_TKTokeniseIdentifier

		;----------------------------------------------------------------------------------------
		;
		;		So we now have a punctuation character. Special cases are those >= 64 and < or > 
		;		followed by = > or < and quoted strings. 
		;
		; 		For 64 conversion see the punctuation.ods
		;
		;----------------------------------------------------------------------------------------

_TKTokenisePunctuation:
		cmp 	#'"'						; quoted string ?
		beq 	_TKString
		cmp 	#'$'						; hexadecimal constant ($ only appears at end of identifiers)
		beq 	_TKHexConstant
		cmp 	#'<' 						; check for < > handlers - these are for <> <= >= >> <<
		beq 	_TKCheckDouble
		cmp 	#'>'
		beq 	_TKCheckDouble
_TKStandardPunctuation:
		lda 	lineBuffer,x 				; get the punctuation token back.
		cmp 	#64 						; are we >= 64
		bcc 	_TKNoShift
		pha 								; save. we are about to convert this punctuation token from
											; 64-127 to 16-31 (see punctuation.ods)
		and 	#7 							; lower 3 bits in zTemp0
		sta 	zTemp0
		pla
		and 	#32 						; bit 5
		lsr 	a 							; shift into bit 3
		lsr 	a
		ora 	zTemp0 
		ora 	#$10						; now in the range 16-31
_TKNoShift:		
		jsr 	TOKWriteByte 				; write the punctuation character
		inx 								; consume the character
		cmp 	#KWD_QUOTE 					; quote found ?
		bne 	_TKTokeniseLoop 			; and loop round again.
		jsr 	TOKCheckComment 			; comment checl
		bra 	_TKTokeniseLoop
		;
		;		String tokeniser.
		;
_TKString: 									; tokenise a string "Hello world"
		jsr 	TOKTokenString
		bra 	_TKTokeniseLoop
_TKHexConstant: 							; tokenise hex constant #A277
		jsr 	TOKHexConstant
		bra 	_TKTokeniseLoop

		;----------------------------------------------------------------------------------------
		;
		;		Exit point, writes EOL and returns
		;
		;----------------------------------------------------------------------------------------

_TKExit:lda 	#KWC_EOL 					; write end of line byte
		jmp 	TOKWriteByte

		;----------------------------------------------------------------------------------------
		;
		;		Have < or >. Check following character is < = >. These are mapped onto 
		;		codes 0-5 for << >> <= >= <> , see punctuation.ods
		;
		;----------------------------------------------------------------------------------------

_TKCheckDouble:
		lda 	lineBuffer+1,x 				; get next character
		cmp 	#'<'						; if not < = > which are ASCII consecutive go back
		bcc 	_TKStandardPunctuation 		; and do the normal punctuation handler.
		cmp 	#'>'+1
		bcs 	_TKStandardPunctuation
		;
		lda 	lineBuffer,x 				; this is < (60) or > (62)
		and 	#2 							; now < (0) or > (2)
		asl 	a 							; now < (0) or > (4), CC also
		adc 	lineBuffer+1,x 				; add < = > codes - < code
		sec
		sbc 	#'<' 
		jsr 	TOKWriteByte 				; this is in the range 0-7
		inx 								; consume both
		inx
		bra 	_TKTokeniseLoop

		;----------------------------------------------------------------------------------------
		;
		;		Found _ or A..Z, which means an identifier or a token.
		;
		;----------------------------------------------------------------------------------------

_TKTokeniseIdentifier:		
		stx 	identStart 					; save start
		stz 	identTypeByte 				; zero the type byte
_TKCheckLoop:
		inx 								; look at next, we know first is identifier already.
		lda  	lineBuffer,x
		cmp 	#"_" 						; legal char _ 0-9 A-Z
		beq 	_TKCheckLoop
		cmp	 	#"0"
		bcc 	_TKEndIdentifier
		cmp 	#"9"+1
		bcc 	_TKCheckLoop
		cmp	 	#"A"
		bcc 	_TKEndIdentifier
		cmp 	#"Z"+1
		bcc 	_TKCheckLoop
_TKEndIdentifier:
		;
		;		Look for # or $ type
		;
		stx 	identTypeStart 				; save start of type text (if any !)
		;
		ldy 	#$08 						; this is the identifier type byte for #
		cmp 	#"#"						; followed by #
		beq 	_TKHasTypeCharacter
		ldy 	#$10 						; this is the identifier type byte for $
		cmp 	#"$"						; followed by $ or #
		bne 	_TKNoTypeCharacter
_TKHasTypeCharacter:
		sty 	identTypeByte 				; has # or $, save the type
		inx 								; consume the type character		
		lda 	lineBuffer,x
		;
		;		Look for array
		;
_TKNoTypeCharacter:
		cmp 	#"("						; is it open parenthesis (e.g. array)
		bne 	_TKNoArray
		inx 								; skip the (
		lda 	identTypeByte 				; set bit 2 (e.g. array) in type byte
		ora 	#$04
		sta 	identTypeByte
_TKNoArray:		
		stx 	identTypeEnd 				; save end marker, e.g. continue from here.
		jsr 	TOKCalculateHash 			; calculate the has for those tokens

		;----------------------------------------------------------------------------------------
		;
		;			Search the token tables, to see if this is actually a keyword.
		;			*all* keywords are identifier-compliant.
		;
		;----------------------------------------------------------------------------------------

checktokens .macro 			
		ldy 	#(\1) >> 8
		lda 	#(\1) & $FF
		jsr 	TOKSearchTable
		.endm

		.checktokens KeywordSet0			; check the three token tables for the keyword.
		ldx 	#0 							
		bcs 	_TKFoundToken
		.checktokens KeywordSet1
		ldx 	#$81
		bcs 	_TKFoundToken
		.checktokens KeywordSet2
		ldx 	#$82
		bcs 	_TKFoundToken

		;----------------------------------------------------------------------------------------
		;
		;			 No shift found, so it's a procedure or a variable declaration
		;
		;----------------------------------------------------------------------------------------

		jsr 	TOKCheckCreateVariableRecord ; failed all, it's a variable, create record if does not exist.
		ldx 	identTypeEnd 				; X points to following byte
		jmp 	_TKTokeniseLoop 			; and go round again.

		;----------------------------------------------------------------------------------------
		;
		;			Found a token, X contains the shift ($8x or 0), A the token
		;
		;----------------------------------------------------------------------------------------

_TKFoundToken:
		pha 								; save token
		txa 								; shift in X, is there one ?
		beq 	_TKNoTShift
		jsr 	TOKWriteByte 				; if so, write it out
_TKNoTShift:
		pla 								; restore and write token
		jsr 	TOKWriteByte
		cpx 	#0 							; check for REM and '
		bne 	_TKNotRem 			 		; not shifted ?
		cmp 	#KWD_REM
		bne 	_TKNotRem
		ldx 	identTypeEnd 				; check if comment follows.
		jsr 	TOKCheckComment
		jmp 	_TKTokeniseLoop

_TKNotRem:		
		ldx 	identTypeEnd 				; X points to following byte
		jmp 	_TKTokeniseLoop 			; and go round again.

; ************************************************************************************************
;
;		Comment check for REM and ' - check if quoted string/EOL follows, if not, insert
;		rest of line as comment.
;
; ************************************************************************************************

TOKCheckComment:
		lda 	lineBuffer,x 				; skip over space
		inx
		cmp 	#' '
		beq 	TOKCheckComment
		dex 								; first non space character
		cmp 	#'"'						; quote mark
		beq 	_TOKCCExit 					; then we are okay
		cmp 	#0 							; EOL
		beq 	_TOKCCExit 					; then we are okay
		phx
_TOKCCLowerCase: 							; the pre-processing capitalises it. I did think
		lda 	lineBuffer,x 				; about making it lower case it all, but I thought
		cmp 	#"A"		 				; that was a bit risky. So it's converted to L/C here.
		bcc 	_TOKKCNotUC
		cmp 	#"Z"+1
		bcs 	_TOKKCNotUC
		eor 	#$20
		sta 	lineBuffer,x
_TOKKCNotUC:		
		inx
		cmp 	#0
		bne 	_TOKCCLowerCase
		plx
		dex 								; tokenise string expects initial skip.
		jsr 	TOKTokenString 				; tokenise rest of line as a string.
_TOKCCExit:		
		rts

; ************************************************************************************************
;
;									Tokenise a string.
;
; ************************************************************************************************

TOKTokenString:
		lda 	#KWC_STRING 				; string token.
		jsr 	TOKWriteByte
		inx									; start of quoted string.
		phx 								; push start of string on top
		dex 								; because we pre-increment
_TSFindEnd:							
		inx
		lda 	lineBuffer,x 				; next character
		beq 	_TSEndOfString 				; no matching quote, we don't mind.
		cmp 	#'"' 						; go back if quote not found
		bne 	_TSFindEnd
		;
_TSEndOfString:
		ply  								; so now Y is first character, X is character after end.		
		pha 								; save terminating character
		jsr 	TOKWriteBlockXY 			; write X to Y as a data block
		pla 								; terminating character
		beq 	_TSNotQuote					; if it wasn't EOS skip it
		inx
_TSNotQuote:		
		rts		

; ************************************************************************************************
;
;				Write Y to X with a trailing NULL - used for any block data.
;
; ************************************************************************************************

TOKWriteBlockXY:
		stx 	zTemp0 						; save end character
		tya 								; use 2's complement to work out the byte size
		eor 	#$FF
		sec
		adc 	zTemp0
		inc 	a 							; one extra for NULL
		jsr 	TOKWriteByte
_TOBlockLoop:
		cpy 	zTemp0 						; exit if reached the end
		beq 	_TOBlockExit
		lda 	lineBuffer,y 				; write byte out.
		jsr 	TOKWriteByte				
		iny
		bra 	_TOBlockLoop
_TOBlockExit:
		lda 	#0 							; add NULL.
		jmp 	TOKWriteByte

; ************************************************************************************************
;
;									Tokenise a hex constant
;
; ************************************************************************************************

TOKHexConstant:
		lda 	#KWC_HEXCONST 				; hex constant token.
		jsr 	TOKWriteByte
		inx									; start of quoted string.
		phx 								; push start of constant on top
		dex
_THFindLoop:							
		inx 	 							; this is stored in a block, so find out how long
		lda 	lineBuffer,x 				; the hex constant is.
		cmp 	#"0"
		bcc 	_THFoundEnd
		cmp 	#"9"+1
		bcc 	_THFindLoop
		cmp 	#"A"
		bcc 	_THFoundEnd
		cmp 	#"F"+1
		bcc 	_THFindLoop
_THFoundEnd:
		ply 								; restore start
		jsr 	TOKWriteBlockXY 			; output the block
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
; 		17/12/22 		Added TOKCheckComment which checks for non-quoted comments. Inserted at
;						2 positions are checks - end of tokenising and end of punctuation processing.
; 		30/12/22 		dex before call to tokenise just before _TOKCCExit - rem abcd was tokenising
;						as rem "bcd" e.g. missing the first character.
; 		04/03/23 		Changed to allow modification to colourising of listings.
;
; ************************************************************************************************
