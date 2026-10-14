; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		clear.asm
;		Purpose:	Tidying up before Running code
;		Created:	18th September 2022
;		Reviewed: 	23rd November 2022
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;									Clear variables prior to RUN.
;
; ************************************************************************************************

ClearSystem:
		jsr BranchCacheClear
		;
		;		Scan through all the variables resetting them to zero.
		;
		.set16 	zTemp0,VariableSpace 		; zTemp0 points to the variable list
_ClearZeroLoop:		
		lda 	(zTemp0) 					; end of variables if offset is zero.
		beq 	_ClearZeroEnd

		ldy 	#3 							; erase the variables
		lda 	#0 							; set all the data to zero.
_ClearOneVariable:	
		sta 	(zTemp0),y
		iny
		cpy 	#8
		bne 	_ClearOneVariable	

		ldy 	#2 							; has it been marked procedure or function
		lda 	(zTemp0),y
		and 	#NSBTypeMask 				; check type bits only (catches both $18 and $1C)
		cmp 	#NSTProcedure
		bne 	_ClearNotProcedure
		lda 	#NSTInteger+NSBIsArray 		; if so set it back to an integer array
		sta 	(zTemp0),y 					; will be fixed on the pre-run scan.
_ClearNotProcedure:

		clc 								; go to the next variable
		lda 	(zTemp0) 					; offset to next, add to zTemp0
		adc 	zTemp0
		sta 	zTemp0
		bcc 	_ClearZeroLoop
		inc 	zTemp0+1
		bra 	_ClearZeroLoop
_ClearZeroEnd:
		;
		;		Reset the low memory allocation pointer, which is the byte after
		;		the identifiers.
		;
		clc
		lda 	zTemp0
		adc 	#1
		sta 	lowMemPtr
		lda 	zTemp0+1
		adc 	#0
		sta 	lowMemPtr+1
		;
		;		Reset the array memory pointer to start of slots 2-3.
		;
		.set16 	arrayMemPtr,ArrayStart
		;
		;		Reset the BASIC Stack pointer
		;
		jsr 	StackReset
		;
		;		Reset the function nesting level
		;
		stz 	fnNestLevel
		lda 	#$FF
		sta 	fnSavedSP
		;
		;		Reset the BASIC string pointer
		;
		jsr 	StringSystemInitialise		
		;
		;		Scan the program code for Procedures which will reconvert any intarray procedures back.
		;
		jsr 	ProcedureScan
		;
		;		Restore the DATA pointer
		;
		jsr 	Command_Restore	
		;
		;		Reset the assembler control and location values.
		;
		stz 	AssemblerAddress	
		stz 	AssemblerAddress+1
		stz 	AssemblerControl	
		;
		;		Empty the keyboard queie.
		;
		stz 	KeyboardQueueEntries
		;
		; 		Check we aren't out of memory already.
		;
		jsr 	CheckIdentifierStringSpace 	; check identifier/string space 
		;
		;		Reset bitmap/sprites/tiles pages
		;			
		.if graphicsIntegrated==1
		jmp 	ResetBitmapSpritesTiles
		.else
		rts
		.endif

		.send code

; ************************************************************************************************
;
;									Changes and Updates
;
; ************************************************************************************************
;
;		Date			Notes
;		==== 			=====
;		29/01/23 		No longer a stand alone command.
;
; ************************************************************************************************
