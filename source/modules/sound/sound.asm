; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		sound.asm
;		Purpose:	Sound module entry point
;		Created:	21st November 2022
;		Reviewed: 	No
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;									Entry Point (command)
;
; ************************************************************************************************

Export_SNDCommand:
		phx 								; save XY
		phy
		
		cmp 	#$0F 						; $0F is initialise
		beq 	_SNDInitialise
		bcc 	_SNDExit
		cmp 	#$3F 						; $3F is silence all
		beq 	_SNDSilence
		bcs 	_SNDExit
		cmp 	#$20 						; $2x is check playing => A
		bcs 	_SNDQueryPlay
		cmp 	#$14 						; $10-$13 is queue sound
		bcs 	_SNDExit
		jsr 	SNDQueueRequest
		bra 	_SNDExit
;
;		Return A != 0 if channel currently playing a note.
;
_SNDQueryPlay:
		and 	#3 							; get channel #
		tax
		lda 	SNDTimeLeft,x 				; read time left, if zero then silent
		bra 	_SNDExit
;
;		Initialisation code (currently same as silence code)
;
_SNDInitialise:
;
;		Silence code
;
_SNDSilence:
		stz 	SNDLength 					; empty the queue.
		lda 	#$3 						; silence channel 0-3.
_SNDSilenceLoop:
		pha
		jsr 	SNDSilenceChannel
		pla
		dec 	a
		bpl 	_SNDSilenceLoop
_SNDExit:
		ply
		plx
		rts

		.send code

; ************************************************************************************************
;
;										Data area
;
; ************************************************************************************************

		.section storage
;
;		Queue of sounds to play
;
SNDQueueSize = 32 							; number of queue entries

SNDLength: 									; count currently in queue
		.fill 	1
SNDQueue: 	 								; 8 bytes per queue entry.
		.fill 	SNDQueueSize * 8
;
;		Current state of the four channels.
;
SNDPitchLow: 								; current pitch
		.fill 	4
SNDPitchHigh:
		.fill 	4

SNDVolume: 									; volume 0-15.
		.fill 	4

SNDTimeLeft: 								; time remaining, zero = no sound/get next
		.fill 	4

SNDAdjustLow:								; current slide
		.fill 	4
SNDAdjustHigh:		
		.fill 	4

		.send 	storage

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
