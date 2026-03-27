; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		wrapper.asm
;		Purpose:	Kernel functionality wrapper
;		Created:	7th January 2023
;		Reviewed: 	No.
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

; ************************************************************************************************
;
;						Set errors so not directly accessing variables.
;
; ************************************************************************************************

KERR_GENERAL = kernel.event.file.ERROR 		; Event $38
KERR_CLOSED = kernel.event.file.CLOSED 		; Event $32
KERR_NOTFOUND = kernel.event.file.NOT_FOUND ; Event $28
KERR_EOF = kernel.event.file.EOF 			; Event $30

KNLReadBufferLen = 64 								; read buffer size.

; ************************************************************************************************
;
;								Set the Drive to use to A
;
; ************************************************************************************************

KNLSetDrive:
		sta 	KNLDefaultDrive
		rts

; ************************************************************************************************
;
;									Open file for input/output
;		
;		Succeeded : Carry Clear, A contains stream to read.
;		Failed :	Carry Set, A contains error event.
;
; ************************************************************************************************

KNLOpenFileWrite:
		pha
		lda 	#kernel.args.file.open.WRITE
		bra 	KNLOpenStart
		
KNLOpenFileRead:
		pha
		lda     #kernel.args.file.open.READ ; set READ mode.
KNLOpenStart:   
		sta     kernel.args.file.open.mode
		pla

		phy

		jsr 	KNLSetupFileName
		jsr 	KNLSetEventPointer

		lda 	KNLDefaultDrive 			; currently drive zero only.
		sta 	kernel.args.file.open.drive

		jsr     kernel.File.Open 			; open the file and exit.
		bcs     _kernel_error
		tay
		
_loop
		jsr     GetNextEvent
		bcc     _process_event				; only yield when no events available
		jsr     kernel.Yield    			; event wait
		bra     _loop

_process_event:
		lda 	KNLEvent.type 
		cmp     #kernel.event.file.OPENED
		beq 	_success
		cmp     #kernel.event.file.NOT_FOUND
		beq 	_error_exit
		cmp     #kernel.event.file.ERROR 
		bne 	_loop

		;
		;	The FAT32 driver returns ERROR when opening a non-existent file, we map the error to NOT_FOUND
		;
		lda		#kernel.event.file.NOT_FOUND
		bra		_error_exit

_kernel_error
		lda     #kernel.event.file.ERROR
		bra		_error_exit

_success
		tya
		clc
		bra 	_exit
_error_exit
		sec
_exit
		ply
		rts

; ************************************************************************************************
;
;									Set pointer for events
;
; ************************************************************************************************

KNLSetEventPointer:
		pha
		lda     #KNLEvent & $FF 			; tell kernel where to store event data
		sta     kernel.args.events+0
		lda     #KNLEvent >> 8
		sta     kernel.args.events+1
		pla
		rts

; ************************************************************************************************
;
;					Converts ASCIIZ filename in XA to Kernel internal format.
;
; ************************************************************************************************

KNLSetupFileName:
		phy 								; save Y on stack
		sta 	zTemp0 						; save filename position in temp, and in kenrel slot
		stx 	zTemp0+1
		sta     kernel.args.file.open.fname+0            
		stx     kernel.args.file.open.fname+1
		;
		ldy 	#$FF 						; get the filename length => Kernel slot
_KNLGetLength:
		iny
		lda 	(zTemp0),y 					
		bne 	_KNLGetLength
		sty 	kernel.args.file.open.fname_len
		ply
		rts


; ************************************************************************************************
;
;				Read one block from stream A, X bytes. CC = succeeded, A = bytes read. 
;				CS = failed, A = Event error
;              	CS when finished (A = EOF)
;
;				Do not mix block or byte reads - use one or the other :)
;
; ************************************************************************************************

KNLReadBlock:
						 					; set stream to read from and bytes to read.
		sta     kernel.args.file.read.stream
		stx     kernel.args.file.read.buflen

		jsr     kernel.File.Read 			; read request
		lda     #kernel.event.file.ERROR    ; Kernel out of events/buffers; shouldn't happen
		bcs     _KGNBExitFail               ; report as general error

_KGRBEventLoop:
		jsr     GetNextEvent
		bcc     _KNLRBProcessEvent			; only yield when no events available
		jsr     kernel.Yield    			; event wait
		bra     _KGRBEventLoop

_KNLRBProcessEvent:
		lda 	KNLEvent.type 				; get event		

		cmp     #kernel.event.file.DATA 	; data, return data
		beq     _KNLRBGetNextByte

		cmp     #kernel.event.file.ERROR  	; errors on file i/o, return as appropriate.
		beq 	_KGNBExitFail

		cmp     #kernel.event.file.EOF
		beq 	_KGNBExitFail

		bra 	_KGRBEventLoop
		;
		;		Get the next data block into the buffer
		;
_KNLRBGetNextByte:

		lda     #<KNLReadBuffer 			; Set the target buffer
		sta     kernel.args.recv.buf+0
		lda     #>KNLReadBuffer
		sta     kernel.args.recv.buf+1

		lda     KNLEvent.file.data.read 	; Set the target length
		sta     kernel.args.recv.buflen	  										

		jsr     kernel.ReadData		       	; Get the data from the kernel  (Synchronous call, no error)
		lda     KNLEvent.file.data.read 	; Return # of bytes read (in A)

		clc
		rts

_KGNBExitFail:
		sec
		rts

; ************************************************************************************************
;
;							Write data at (zTemp0) to Stream A, X bytes.
;
;					  On error CS ; A = code. On success, CC, A = bytes read.
;
; ************************************************************************************************

KNLWriteBlock:
		phx
		phy
		;
		;		Already handled OPENED so can write out.
		;
		sta     kernel.args.file.write.stream ; save the stream.

		lda     zTemp0 						; save the data location.
		sta     kernel.args.file.write.buf+0
		lda     zTemp0+1
		sta     kernel.args.file.write.buf+1
	  
		stx     kernel.args.file.write.buflen ; Set the buffer length

		jsr     kernel.File.Write 			; write it out.
		lda 	#kernel.event.file.ERROR 	; in case it fails.
		bcs 	_KWBFailed

_KNLWLoop:									; wait for an event.
		jsr     GetNextEvent
		bcc     _KNLWProcessEvent			; only yield when no events available
		jsr     kernel.Yield    			; event wait
		bra     _KNLWLoop

_KNLWProcessEvent:
		lda     KNLEvent.type 				; various errors.
		cmp     #kernel.event.file.CLOSED
		beq 	_KWBFailed
		cmp     #kernel.event.file.ERROR
		beq 	_KWBFailed
		cmp     #kernel.event.file.EOF
		beq 	_KWBFailed

		cmp     #kernel.event.file.WROTE 	; wait until block write succeeds
		bne 	_KNLWLoop      
		clc
		lda     KNLEvent.file.wrote.wrote 	; get bytes written.
		bra 	_KWBExit

_KWBFailed:
		sec
_KWBExit:
		ply
		plx
		rts

; ************************************************************************************************
;
;						Close currently open file - A should countain stream
;
; ************************************************************************************************

KNLCloseFile:
		sta     kernel.args.file.close.stream
		jmp     kernel.File.Close

; ************************************************************************************************
;
;						Read Game Controller A -> A (Button1/Right/Left/Down/Up)
;
; ************************************************************************************************

KNLReadController:
		phx
		ldx 	1 							; save current I/O in X
		stz 	1 							; switch to I/O 0
		lda 	$DC00  						; read VIA register
		eor 	#$FF 						; make active '1'
		ora 	KeyJoystick 				; use key joystick.
		stx 	1 							; repair old I/O and exit
		plx
		rts

		.send code


		.section storage

KNLReadBuffer:      						; buffer 
		.fill   256				
KNLDefaultDrive: 							; current default drive.
		.byte 	?							
KNLEvent   .dstruct    kernel.event.event_t   

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
