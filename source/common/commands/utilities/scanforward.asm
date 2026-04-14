;;
; Token scanning utilities
;;

		.section code

;;
; Scan forward to the next matching token at the current structure level.
;
; Scans program tokens starting at the current parsing position until one of
; the two target tokens supplied in `A` and `X` is found at structure depth
; zero. Nested structures are tracked via `zTemp1`, and complex tokens are
; skipped by delegating to `ScanForwardOne`.
;
; \in A         First token to match.
; \in X         Second token to match.
; \in Y         Current parsing position.
; \out A        Matching token when a target is found.
; \out Y        Parsing position at the matched token, or just before `KWC_EOL`
;               when end-of-line is the matched target.
; \sideeffects  - Resets `zTemp1` before scanning.
;               - Uses `zTemp0`/`zTemp0+1` to store the target tokens.
;               - Advances across lines and nested structures while scanning.
;               - May raise a structure error via `ScanForwardOne` if program
;                 end is reached without a top-level match.
;               - Modifies registers `A`, `X`, and `Y`.
; \see          ScanForwardOne, ScanGetCurrentLineStep
;;

ScanForward:
		stz 	zTemp1 						; zero the structure count - goes up with WHILE/FOR down with WEND/NEXT etc.
		stx 	zTemp0+1
		sta 	zTemp0 						; save X & A as the two possible matches.
		;
		; 		Main Scanning Loop
		;
_ScanLoop:
		.cget 								; get next and consume it
		iny

		ldx 	zTemp1 						; if the count is > 0 cannot match as in substructure
		bne 	_ScanGoNext
		;
		cmp 	zTemp0 						; see if either matches
		beq 	_ScanMatch
		cmp 	zTemp0+1
		bne 	_ScanGoNext
_ScanMatch:									; if so, exit after skipping that token.
		cmp 	#KWC_EOL 					; if asked for EOL, backtrack.
		bne 	_ScanNotEndEOL
		dey
_ScanNotEndEOL:
		rts
_ScanGoNext:
		jsr  	ScanForwardOne 				; allows for shifts and so on.
		bra 	_ScanLoop

;;
; Advance scan state by one (already-consumed) token.
;
; Interprets the token currently in `A` and updates the forward-scan state.
; Depending on token class, may skip additional bytes or data blocks, move to
; the next line, adjust the nested structure depth in `zTemp1`, or record that
; an `ELSE` was encountered while listing.
;
; \in A         Token already consumed by the caller.
; \in Y         Parsing position immediately after the consumed token.
; \inout zTemp1 Current nested structure depth; incremented for opening
;               structures and decremented for closing structures.
; \out Y        Advanced past any additional bytes associated with the token.
; \sideeffects  - May advance to the next program line for `KWC_EOL`.
;               - May set `listElseFound` when `KWD_ELSE` is encountered.
;               - May raise a structure error if scanning reaches program end
;                 at top level without a match.
;               - Modifies register `A` when using token/data skip helpers.
; \see          ScanForward, ScanGetCurrentLineStep
;;

ScanForwardOne:
		cmp 	#$40 						; if 00-3F, punctuation characters, already done.
		bcc 	_SFWExit
		;
		cmp 	#KWC_FIRST_UNARY 			; if 40-82, skip one extra as these are 2 byte
		bcc 	_ScanSkipOne	 			; offsets into the identifier table or shifts.
		;
		cmp 	#$FC 						; FC-FF are data skips (hex consts, strings etc.)
		bcs 	_ScanSkipData
		;
		cmp 	#KWC_FIRST_STRUCTURE 		; structure keyword ?
		bcc 	_SFWCheckElse 				; if not, check if ELSE
		cmp 	#KWC_LAST_STRUCTURE+1
		bcs 	_SFWCheckElse				; if beyond structure range, check if ELSE
		;
		;		Structure code - can go up and down.
		;
		dec 	zTemp1 						; decrement the sructure count
		cmp 	#KWC_FIRST_STRUCTURE_DEC 	; back if it is a dec structure (e.g. WEND/NEXT)
		bcs 	_SFWExit
		inc 	zTemp1 						; so it's an increment structure
		inc 	zTemp1 						; twice to undo the dec
		bra 	_SFWExit
		;
		;		+2 ; for 40-7F (Variable) 80 (New line) and 81-82 (Shifts)
		;
_ScanSkipOne:
		iny 								; consume the extra one.
		cmp 	#KWC_EOL 					; if not EOL loop back
		bne 	_SFWExit
		;
		.cnextline 							; go to next line
		ldy 	#3 							; scan start position.
		.cget0 								; read the offset
		bne 	_SFWExit 					; if not zero, more to scan
		.error_struct 						; couldn't find either token at level zero end of program.
		;
		;		Skip data structure
		;
_ScanSkipData:
		;
		dey 								; point at data token
		.cskipdatablock 					; skip block
		rts
		;
		;		Check for ELSE keyword (needs special indent handling)
		;
_SFWCheckElse:
		cmp 	#KWD_ELSE					; is it ELSE?
		bne 	_SFWExit
		pha 								; preserve A
		lda 	#1
		sta 	listElseFound 				; flag that ELSE was found on this line
		pla 								; restore A
_SFWExit:
		rts

;;
; Calculate the indentation step contributed by the current line.
;
; Scans the current tokenized line and returns the net structure-depth change
; it contributes for LIST indentation. Opening structures increase the step,
; closing structures decrease it, and single-line `FN ... = expr` definitions
; are treated specially so they do not affect indentation.
;
; \out A        Net indentation adjustment for the current line.
; \out zTemp1   Same adjustment value accumulated while scanning.
; \sideeffects  - Clears `zTemp1` before scanning.
;               - Clears `listElseFound` before scanning and may set it if an
;                 `ELSE` token is encountered.
;               - Resets `Y` to the line scan start position and advances it
;                 while processing tokens.
;               - Modifies registers `A` and `Y`.
; \see          ScanForwardOne, SkipParamList
;;

ScanGetCurrentLineStep:
		stz 	zTemp1
		stz 	listElseFound 				; clear ELSE flag before scanning line
		ldy 	#3
		;
		;		Single-line FN (= expr) should not change indent. FN is in {+}
		;		so ScanForwardOne will add +1; pre-decrement here to offset it.
		;
		.cget
		cmp 	#KWD_FN
		bne 	_SGCLSLoop
		iny 								; skip FN token
		iny 								; skip var ref high
		iny 								; skip var ref low
		jsr 	SkipParamList 				; skip params and ')'
		.cget
		cmp 	#KWD_EQUAL
		bne 	_SGCLSFnDone 				; multi-line: no adjustment needed
		dec 	zTemp1 						; single-line: -1 to offset the +1 from {+}
_SGCLSFnDone:
		ldy 	#3 							; reset scan position
_SGCLSLoop:
		.cget 								; next and consume ?
		iny
		cmp 	#KWC_EOL	 				; if EOL exit
		beq 	_SGCLSExit
		jsr 	ScanForwardOne
		bra 	_SGCLSLoop
_SGCLSExit:
		lda 	zTemp1 						; return the adjustment
		rts

		.send code
