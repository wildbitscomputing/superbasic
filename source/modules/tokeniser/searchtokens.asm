; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		searchtokens.asm
;		Purpose:	Seach token table for a specific identifier
;		Created:	19th September 2022
;		Reviewed: 	23rd November 2022
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;	Search the token table at YA for the currently selected identifier. Returns CS and token ID
; 	in A if found, CC if not found
;
; ************************************************************************************************

TOKSearchTable:
		sty 	zTemp0+1 					; (zTemp0),y points to current token being tested.
		sta 	zTemp0
		ldy 	#0
		lda 	#$80 						; token # so we know which one we are looking at
		sta 	zTemp1
		;
		;		Token search loop
		;
_TSTLoop:
		lda 	(zTemp0),y 					; length, 0 (skip) -ve (end)
		bmi 	_TSTFail 					; -ve = end of table, so fail.
		beq 	_TSTNext 					; zero, check next as it's a dummy (e.g. EOL, SHIFT)
		;
		; 		Hash match ?
		;
		iny 								; get the hash
		lda 	(zTemp0),y
		dey
		cmp 	identHash 					; check they match with the identifier hash, if not go to next
		bne 	_TSTNext
		;
		;		Length match
		;
		lda 	identTypeEnd 				; get length of identifier from end-start
		sec
		sbc 	identStart
		cmp 	(zTemp0),y 					; compare against the length in the table, no match, then return.
		bne 	_TSTNext
		;
		;		Hash and length match, now compare actual text
		;
		phy 								; save Y , we might fail to match.
		iny 								; point to text 	
		iny
		ldx 	identStart 					; offset in line buffer in X
_TSTCompareName:
		lda 	lineBuffer,x 				; compare text.
		cmp 	(zTemp0),y
		bne 	_TSTNextPullY 				; fail, pullY and do next
		inx
		iny
		cpx 	identTypeEnd 				; complete match.
		bne 	_TSTCompareName
		ply 								; throw Y
		lda 	zTemp1 						; get token #
		sec 								; return with CS = passed.
		rts
		;
		;		Go onto next token, optionally restoring Y
		;
_TSTNextPullY:
		ply 								; restore current, fall through.		
		;
		;		Go to next token.
		;		
_TSTNext:
		inc 	zTemp1 						; token counter
		tya
		clc
		adc 	(zTemp0),y 					; add [Length] + 2 to Y
		inc 	a 							; +1
		inc 	a 							; +2
		tay 			
		bpl 	_TSTLoop 					; if Y < $80 loop back
		;
		;		The index into the token table is > 128, we now adjust this so
		;		this value is always < 128, allowing us to use fast index lookups.
		;
		tya 								; add Y to zTemp0 and reset Y
		ldy 	#0   						; so we can use Y to search fast
		clc  								; but have tables > 255 bytes
		adc 	zTemp0 						; when Y gets >= 128 we reset Y
		sta 	zTemp0 						; and adjust the table pointer/
		bcc 	_TSTLoop
		inc 	zTemp0+1
		bra 	_TSTLoop

_TSTFail:		
		clc
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
