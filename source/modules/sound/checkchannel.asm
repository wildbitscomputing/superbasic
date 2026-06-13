; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		checkchannel.asm
;		Purpose:	Check if channel should play a note
;		Created:	21st November 2022
;		Reviewed: 	No
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;		For channel A, if off, check if there is a sound request in the queue and set up 
;		appropriately.
;
; ************************************************************************************************

SNDCheckChannel:
		tax
		lda 	SNDTimeLeft,x 				; currently playing a note
		bne 	_SNDCCExit
		;
		phx 								; save current channel
		txa 								; put in A
		jsr 	SNDFindNextNoteForA 		; is there a note for A in the queue ?
		pla 								; channel # in A
		bcc 	_SNDCCExit  				; nothing in the queue for this channel, exit.
		;
		tay 								; Y is the channel #
		;
		lda 	SNDQueue+1,x 				; copy data into the slot.
		sta 	SNDPitchLow,y
		lda 	SNDQueue+2,x
		sta 	SNDPitchHigh,y
		lda 	SNDQueue+3,x
		sta 	SNDVolume,y
		lda 	SNDQueue+4,x
		sta 	SNDTimeLeft,y
		lda 	SNDQueue+5,x
		sta 	SNDAdjustLow,y
		lda 	SNDQueue+6,x
		sta 	SNDAdjustHigh,y
		;
		phy 								; save channel #
		jsr 	SNDDeleteXFromQueue 		; delete record at X from queue
		dec 	SNDLength 					; reduce the queue length.
		pla
		jsr 	SNDUpdateNote 				; update channel A
		;
_SNDCCExit:		
		rts

; ************************************************************************************************
;
;									Update note A from status
;
; ************************************************************************************************

SNDUpdateNote:
		tax 								; so we can access records

		asl 	a 							; convert it to a channel bit pair in 5,6
		asl 	a
		asl 	a
		asl 	a
		asl 	a
		sta 	SNDChannelBits

		lda 	SNDTimeLeft,x 				; are we silent
		beq 	_SNDUNIsSilent
		;
		;		Turn on
		;
		lda 	SNDChannelBits 				; push channel bits on stack
		pha
		;
		lda 	SNDPitchLow,x 				; get 4 lowest bits of pitch.
		and 	#$0F
		ora 	SNDChannelBits 				; set channel bits
		ora 	#$80 						; write to pitch register
		jsr 	SNDWritePorts
		;
		lda 	SNDPitchHigh,x 				; pitch high => channel temp.
		sta 	SNDChannelBits
		lda 	SNDPitchLow,x
		;
		lsr 	SNDChannelBits 				; shift 2 LSBs into MSB of A
		ror 	a
		lsr 	SNDChannelBits
		ror 	a
		;
		lsr 	a 							; put in bits 0-5
		lsr 	a
		jsr 	SNDWritePorts 				; write as rest of pitch register
		;
		pla
		ora 	#$90 						; set to write minimum attentuation.
		jmp 	SNDWritePorts
		;
		;		Turn off
		;
_SNDUNIsSilent:
		lda 	SNDChannelBits 				; channel bits
		ora 	#$9F 						; maximum attenuation
		jmp 	SNDWritePorts 				; write to the ports

; ************************************************************************************************
;
;		Find next note for channel A in the Queue. If found, X is the 'slot' and CS, else CC.
;
; ************************************************************************************************
		
SNDFindNextNoteForA:
		ldy 	SNDLength 					; queue size into Y
		beq 	_SNDFNNFail 				; queue empty.
		ldx 	#0
_SNDFNNSearch:
		cmp 	SNDQueue,x 					; does it match the channel
		sec
		beq 	_SNDFNNExit 				; if so exit with CS.		
		;
		inx 								; next queue slot.
		inx
		inx
		inx

		inx
		inx
		inx
		inx

		dey 								; done the whole queue
		bne 	_SNDFNNSearch 				; no, go back.
_SNDFNNFail:		
		clc
_SNDFNNExit:		
		rts

; ************************************************************************************************
;
;							Delete record offset X from queue
;
; ************************************************************************************************

SNDDeleteXFromQueue:
		cpx 	#SNDQueueSize*8-8 			; reached the end.
		beq 	_SNDDXExit
		lda 	SNDQueue+8,x
		sta 	SNDQueue,x
		inx
		bra 	SNDDeleteXFromQueue
_SNDDXExit:
		rts		
		.send code

		.section storage
SNDChannelBits:
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
;
; ************************************************************************************************
