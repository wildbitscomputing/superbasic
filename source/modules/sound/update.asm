; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		update.asm
;		Purpose:	Possibly update all channels
;		Created:	21st November 2022
;		Reviewed: 	No
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;									Update / check all 4 channels
;
; ************************************************************************************************

Export_SNDUpdate:
PagedSNDUpdate:
		lda 	SNDTimeLeft+0 				; look at time remaining
		beq 	_SNDUNot0 					; not playing
		ldx 	#0 							; so we know which channel to update
		jsr 	SNDUpdateChannel 			; update it.
_SNDUNot0:

		lda 	SNDTimeLeft+1
		beq 	_SNDUNot1
		ldx 	#1
		jsr 	SNDUpdateChannel
_SNDUNot1:

		lda 	SNDTimeLeft+2
		beq 	_SNDUNot2
		ldx 	#2
		jsr 	SNDUpdateChannel
_SNDUNot2:

		lda 	SNDTimeLeft+3
		beq 	_SNDUNot3
		ldx 	#3
		jsr 	SNDUpdateChannel
_SNDUNot3:
		rts

; ************************************************************************************************
;
;									Update Channel X
;
; ************************************************************************************************

SNDUpdateChannel:
		cmp 	#$FF 						; sound $FF play forever until turned off manually
		beq 	_SNDUCExit
		dec 	a 							; decrement and update timer
		sta 	SNDTimeLeft,x 
		beq 	_SNDUCUpdate 				; if zero, silence channel
		;
		lda 	SNDAdjustLow,x 				; adjust ?
		ora 	SNDAdjustHigh,x
		beq 	_SNDUCExit 					; if zero carry on at current tone.

		clc 								; add adjust, forcing into a 10 bit range
		lda 	SNDPitchLow,x
		adc 	SNDAdjustLow,x
		sta 	SNDPitchLow,x
		lda 	SNDPitchHigh,x
		adc 	SNDAdjustHigh,x
		and 	#3
		sta 	SNDPitchHigh,x

_SNDUCUpdate:
		txa 								; which channel.
		pha
		jsr 	SNDUpdateNote 				; update the current note
		pla
		jsr 	SNDCheckChannel 			; more to do ?
_SNDUCExit:
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
