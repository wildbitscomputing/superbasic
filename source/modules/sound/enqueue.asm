; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		enqueue.asm
;		Purpose:	Queue a channel request
;		Created:	21st November 2022
;		Reviewed: 	No
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;									Queue a sound command to YX
;
; ************************************************************************************************

SNDQueueRequest:
		stx 	zTemp0						; save queue address
		sty 	zTemp0+1 
		;
		ldx 	SNDLength 					; queue is full, can't take any more.
		cpx 	#SNDQueueSize
		beq 	_SNDQRExit
		;
		and 	#3	 						; channel # and push on stack
		pha
		;
		txa  								; get offset in queue buffer/
		asl 	a
		asl 	a
		asl 	a
		tax
		;
		pla 								; get back and push again
		pha
		sta 	SNDQueue+0,x 				; save the channel #
		ldy 	#0 							; copy the rest in.
_SNDQCopy:
		lda 	(zTemp0),y
		inx
		iny
		sta 	SNDQueue,x		
		cpy 	#6
		bne 	_SNDQCopy
		;
		inc 	SNDLength 					; bump queue length.
		;
		pla 								; get channel # back
		jsr 	SNDCheckChannel 			; check if channel needs refreshing.
		
_SNDQRExit:
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
