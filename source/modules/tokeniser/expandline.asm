; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		expandline.asm
;		Purpose:	Expand line at code-Ptr to tokenBuffer
;		Created:	4th October 2022
;		Reviewed:	26th November 2022
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

setcolour .macro
		lda 	\1
		jsr 	LCLWriteColour
		.endm

; ************************************************************************************************
;
;									Reset tokeniser/detokeniser
;
; ************************************************************************************************

Export_TKInitialise:
		ldx 	#7
_ETKISetDefault:
		lda 	CLIDefault,x
		sta 	CLIFComment,x
		dex
		bpl 	_ETKISetDefault
		rts


; ************************************************************************************************
;
;							Convert one line back to text. Indent is A
;
; ************************************************************************************************

Export_TKListConvertLine:
		pha 								; save indent on the stack
		stz 	tbOffset
		stz 	tokenBuffer
		stz 	currentListColour
		.setcolour CLILineNumber
		;
		;		Do the line number
		;
		ldy 	#2 							; convert line number to string
		.cget
		tax
		dey
		.cget
		jsr 	LCLWriteNumberXA
				;
		;		Pad out for indentation.
		;
		pla 								; adjustment to indent
		pha 								; save on stack
		;
		;		Handle ELSE - decrement before printing so ELSE aligns with IF
		;
		lda 	listElseFound				; was ELSE found on this line?
		beq 	_LCNoElsePre				; skip if not
		lda 	listIndent					; decrement listIndent
		beq 	_LCNoElsePre				; but don't go below 0
		dec 	listIndent
_LCNoElsePre:
		pla 								; get adjustment back
		pha 								; save on stack again
		bpl 	_LCNoAdjust 				; don't adjust indent if +ve, do after.
		clc 								; add to list indent and make 0 if goes -ve.
		adc 	listIndent
		sta 	listIndent
		bpl 	_LCNoAdjust
		stz 	listIndent
_LCNoAdjust:
		clc		 							; work out actual indent.
		lda 	listIndent
		asl 	a
		adc 	#7
		sta 	zTemp0

_LCPadOut:
		lda 	#' '						; pad out to 6+indent characters
		jsr 	LCLWrite
		lda 	tbOffset
		cmp 	zTemp0
		bne 	_LCPadOut
		ldy 	#3 							; start position.
		;	-------------------------------------------------------------------
		;
		;							Main List Loop
		;
		;	-------------------------------------------------------------------

_LCMainLoop:
		.setcolour CLIPunctuation 			; default listing colour
		.cget 								; get next character
		cmp 	#KWC_EOL 					; end of line ?
		beq 	_LCExit
		;
		cmp 	#16 						; 0-5 are the double punctuations
		bcc 	_LCDoubles
		cmp 	#32 						; 16-31 are shifted punctuation from 64-91
		bcc 	_LCShiftPunc
		cmp 	#64 						; 32-64 are as stored, punc and digits
		bcc 	_LCPunctuation
		cmp 	#128 						; 64-127 are variable identifiers.
		bcc 	_LCIdentifiers
		cmp 	#254 						; 128-253 are tokenised words
		bcs 	_LCToData 					; 254-5 are data objects (local trampoline)
		jmp 	_LCTokens 					; tokens need longer jump now
		;
_LCToData:
		jmp 	_LCData						; trampoline to actual data handler
		;
		;		Exit - do +ve indent here.
		;
_LCExit:
		pla 								; get old indent adjust
		bmi 	_LCExit2
		clc 								; add to indent if +ve
		adc 	listIndent
		sta 	listIndent
_LCExit2:
		;
		;		Handle ELSE - increment after to restore indent for subsequent lines
		;
		lda 	listElseFound				; was ELSE found on this line?
		beq 	_LCExit3					; skip if not
		inc 	listIndent					; restore indent level
_LCExit3:
		rts
		;	-------------------------------------------------------------------
		;
		;					  Doubles << >> <= >= <> (0-5)
		;
		;	-------------------------------------------------------------------

_LCDoubles:
		pha
		lsr 	a 							; put bit 2 into bit 1
		and 	#2
		ora 	#60 						; make < >
		jsr 	LCLWrite
		pla 								; restore, do lower bit
		and 	#3
		ora 	#60
		bra		_LCPunctuation 				; print, increment, loop

		;	-------------------------------------------------------------------
		;
		;				Upper punctuation (was 64-127) (16-31)
		;
		;	-------------------------------------------------------------------

_LCShiftPunc:
		tax 								; save in X
		and 	#7 							; lower 3 bits
		beq 	_LCNoAdd
		ora 	#24 						; adds $18 to it.
_LCNoAdd:
		cpx 	#24 						; if >= 24 add $20
		bcc 	_LCNoAdd2
		ora 	#32 						; adds $20
_LCNoAdd2:
		ora 	#$40 						; shift into 64-127 range and fall through.

		;	-------------------------------------------------------------------
		;
		;							Punctuation (32-63)
		;
		;	-------------------------------------------------------------------

_LCPunctuation:
		cmp 	#':' 						; check if :
		bne 	_LCPContinue
		jsr 	LCLDeleteLastSpace 			; if so delete any preceding spaces
_LCPContinue:
		cmp 	#'.'
		beq 	_LCPIsConstant
		cmp 	#'0'
		bcc 	_LCPNotConstant
		cmp 	#'9'+1
		bcs 	_LCPNotConstant
_LCPIsConstant:
		pha
		.setcolour CLIConstant
		pla
_LCPNotConstant:
        cmp     #KWD_QUOTE                  ; apostrophe (comment to end of line)
        bne     _LCPWrite
        jsr     LCLAddSpaceIfNeeded
_LCPWrite:
		iny 								; consume character
		jsr 	LCLWrite 					; write it out.
		bra 	_LCMainLoop 				; go round again.

		;	-------------------------------------------------------------------
		;
		;							Identifiers (64-127)
		;
		;	-------------------------------------------------------------------

_LCIdentifiers:
		clc 								; convert to physical address
		adc 	#((VariableSpace >> 8) - $40) & $FF
		sta 	zTemp0+1
		iny
		.cget
		sta 	zTemp0
		iny
		phy 								; save position
		.setcolour CLIIdentifier 			; set list colour
		ldy 	#7 							; output the identifier at +8
_LCOutIdentifier:
		iny
		lda 	(zTemp0),y					; bit 7 set = end.
		and 	#$7F
		jsr 	LCLLowerCase
		jsr 	LCLWrite
		lda 	(zTemp0),y				 	; ends when bit 7 set.
		bpl 	_LCOutIdentifier
		ply 								; restore position
		jmp 	_LCMainLoop

		;	-------------------------------------------------------------------
		;
		;							Tokens (129-253)
		;
		;	-------------------------------------------------------------------

_LCTokens:
		tax 								; token in X
		.set16 	zTemp0,KeywordSet2 			; identify keyword set
		cpx 	#$82
		beq 	_LCUseShift
		.set16 	zTemp0,KeywordSet1
		cpx 	#$81
		beq 	_LCUseShift
		.set16  zTemp0,KeywordSet0
		bra 	_LCNoShift
_LCUseShift:								; skip over token if using $81/$82 shifts
		iny
_LCNoShift:
		jsr 	LCLCheckSpaceRequired 		; do we need a space ?
		.cget 								; get the token again
		tax 								; into X
_LCFindText:
		dex
		bpl 	_LCFoundText 				; found text.
		lda 	(zTemp0) 					; length of text
		inc 	a 							; one extra for size
		sec 								; one extra for checksum
		adc 	zTemp0 						; go to next token
		sta 	zTemp0
		bcc 	_LCFindText
		inc 	zTemp0+1
		bra 	_LCFindText
_LCFoundText:
		phy 								; save List position
		lda 	(zTemp0)					; count to print
		tax
		.setcolour CLIToken
		ldy 	#2
_LCCopyToken:								; copy token out.
		lda 	(zTemp0),y
		jsr 	LCLLowerCase
		jsr 	LCLWrite
		iny
		dex
		bne 	_LCCopyToken
		cmp 	#"(" 						; if last char not ( print a space
		beq 	_LCNoSpace
		lda 	#' '
		jsr 	LCLWrite
_LCNoSpace:
		ply 								; restore position.
		iny 								; consume token
		jmp 	_LCMainLoop 				; and go around again.

		;	-------------------------------------------------------------------
		;
		;							Data (254-5)
		;
		;	-------------------------------------------------------------------

_LCData:
		pha 								; save type $FE/$FF
		ldx 	#'$' 						; figure out $ or "
		cmp 	#$FE
		beq 	_LCHaveOpener
		ldx 	#'"'
		.setcolour CLIData
		;
		;		Check for apostrophe comment
		;
		dey 								; what precedes it ?
		.cget
		iny
		cmp 	#KWD_QUOTE 					; if apostrophe
		bne 	_LCHaveOpener
		lda 	#' ' 						; add space before comment
		jsr 	LCLWrite
		lda 	CLIBComment
		bmi 	_LCHaveOpener
		ora 	#$90
		jsr 	LCLWrite
		.setcolour CLIFComment
_LCHaveOpener:
		txa 								; output prefix (# or ")
		jsr 	LCLWrite
		iny 								; get count
		.cget
		tax
		iny 								; point at first character
_LCOutData:
		.cget 								; get next
		cmp 	#0
		beq 	_LCNoPrint
		jsr 	LCLWrite
_LCNoPrint:
		iny
		dex
		bne 	_LCOutData
		pla 								; closing " required ?
		cmp 	#$FF 						; not required for hex constant.
		bne 	_LCNoQuote
		lda 	#'"'
		jsr 	LCLWrite
		lda 	EXTTextColour
		and 	#$0F
		ora 	#$90
		jsr 	LCLWrite
_LCNoQuote:
		jmp 	_LCMainLoop


LCLAddSpaceIfNeeded:
		cpy 	#3 							; don't add space if it's the first token on the line
		beq 	_exit
		pha
        lda     #' '                        ; add space before the next token
        jsr     LCLWrite
		pla
	_exit:
		rts


; ************************************************************************************************
;
;					Output write colour ($80-$8F) only if it has changed
;
; ************************************************************************************************

LCLWriteColour:
		and 	#$0F
		ora 	#$80
		cmp 	currentListColour 			; has the colour changed
		sta 	currentListColour 			; (update it anyway)
		bne 	LCLWrite 					; if different, output it
		rts

; ************************************************************************************************
;
;									Write to token buffer
;
; ************************************************************************************************

LCLWrite:
		phx
		ldx 	tbOffset 					; write out make ASCIIZ
		sta 	tokenBuffer,x
		stz 	tokenBuffer+1,x
		inc 	tbOffset 					; bump the position
		ora 	#0 							; don't update last character if colour data
		bmi 	_LCLNoColour
		sta 	lcLastCharacter
_LCLNoColour:
		plx
		rts

; ************************************************************************************************
;
;								 If last space then delete it.
;
; ************************************************************************************************

LCLDeleteLastSpace:
		pha
		phx
		ldx 	tbOffset
		beq 	_LCDLSExit
		lda 	tokenBuffer-1,x
		cmp 	#' '
		bne 	_LCDLSExit
		dec 	tbOffset
_LCDLSExit:
		plx
		pla
		rts

; ************************************************************************************************
;
;							Is a space required, if so print it
;
; ************************************************************************************************

LCLCheckSpaceRequired:
		lda 	lcLastCharacter 			; check last character
		cmp 	#'$' 						; $ # and ) require that token space.
		beq 	_LCCSRSpace
		cmp 	#')'
		beq 	_LCCSRSpace
		cmp 	#'#'
		beq 	_LCCSRSpace
		jsr 	LCLLowerCase 				; saves a little effort
		cmp 	#"0" 						; check if it was 0-9 A-Z a-z if so need space.
		bcc 	_LCCSRExit
		cmp 	#"9"+1
		bcc 	_LCCSRSpace
		cmp 	#"a"
		bcc 	_LCCSRExit
		cmp 	#"z"+1
		bcs 	_LCCSRExit
_LCCSRSpace: 								; output the space
		lda 	#' '
		jsr 	LCLWrite

_LCCSRExit:
		rts

; ************************************************************************************************
;
;										Convert to L/C or U/C
;
; ************************************************************************************************

LCLLowerCase:
		cmp 	#"A"
		bcc 	_LCLLCOut
		cmp 	#"Z"+1
		bcs 	_LCLLCOut
		adc 	#$20
_LCLLCOut:
		rts

LCLUpperCase:
		cmp 	#"a"
		bcc 	_LCLUCOut
		cmp 	#"z"+1
		bcs 	_LCLUCOut
		sbc 	#$1F
_LCLUCOut:
		rts

; ************************************************************************************************
;
;										Write out XA as string
;
; ************************************************************************************************

LCLWriteNumberXA:
		stz 	zTemp0+1 					; index into digit table.
_LCLWNLoop1:
		stz 	zTemp0 						; subtraction count.
_LCLWNLoop2:
		pha 								; save initial LSB
		sec
		ldy 	zTemp0+1 					; position in table.
		sbc 	_LCLWNTable,y
		pha
		txa
		sbc 	_LCLWNTable+1,y
		bcc 	_LCLWNUnderflow
		;
		inc 	zTemp0  					; subtracted one without borrow.
		tax 								; update X
		pla 								; restore A
		ply 								; throw original
		bra 	_LCLWNLoop2 				; try again.
_LCLWNUnderflow:
		ldy 	zTemp0 						; count of subtractions.
		bne 	_LCLWNOut
		lda 	tbOffset 					; suppress leading zeroes
		dec 	a
		beq 	_LCLWNNext
_LCLWNOut:
		tya
		jsr 	_LCLWNOutDigit
_LCLWNNext:
		ply 							 	; restore original value.
		pla
		ldy 	zTemp0+1  					; bump the index
		iny
		iny
		sty 	zTemp0+1
		cpy 	#8 							; done all 4
		bne 	_LCLWNLoop1
_LCLWNOutDigit:
		ora 	#'0'
		jmp 	LCLWrite

_LCLWNTable:
		.word 	10000
		.word 	1000
		.word 	100
		.word 	10

; ************************************************************************************************
;
;								   LIST syntax colouring
;
; ************************************************************************************************

CLIDefault:
		.byte	CONBrown, CONYellow, CONRed, CONOrange, CONCyan, CONYellow, CONPink, CONWhite

		.send code

; ************************************************************************************************
;
;								  LIST syntax values (in control storage)
;
; ************************************************************************************************

CLIFComment = ControlStorage + 0
CLIBComment = ControlStorage + 1
CLILineNumber = ControlStorage + 2
CLIToken = ControlStorage + 3
CLIConstant = ControlStorage + 4
CLIIdentifier = ControlStorage + 5
CLIPunctuation = ControlStorage + 6
CLIData = ControlStorage + 7

; ************************************************************************************************
;
;									Changes and Updates
;
; ************************************************************************************************
;
;		Date			Notes
;		==== 			=====
;		26/11/22 		Added LCLWriteColour to minimise colour changes, e.g. not one for each
;						punctuation character etc.
;		26/11/22 		Tweaked coloring of constants (test for 0-9 and . in punctuation)
;		26/11/22 		Highlighting SOL comments
;		27/11/22 		Added LCLWriteNumberXA to decouple module from the main body of code
;						(was using ConvertInt16)
;
; ************************************************************************************************
