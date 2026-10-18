; Delete exactly one closed file. The kernel owns and releases the request
; stream; no File.Close is needed. Return zero or the kernel error event.
		.section code
Export_DeleteImpl:
		phy
; EvaluateString left the filename address in zTemp0. Reject command-channel
; syntax as well as wildcards: IEC scratch accepts comma-separated names.
		ldy #0
		sty deleteLeaf
		lda (zTemp0),y
		beq _DeleteRange
_DeleteValidate:
		lda (zTemp0),y
		beq _DeleteEndName
		cmp #32
		bcc _DeleteRange
		cmp #127
		beq _DeleteRange
		cmp #"*"
		beq _DeleteRange
		cmp #"?"
		beq _DeleteRange
		cmp #","
		beq _DeleteRange
		cmp #":"
		beq _DeleteRange
		cmp #"/"
		bne _DeleteNext
		tya
		inc a
		sta deleteLeaf
_DeleteNext:
		iny
		bne _DeleteValidate
_DeleteRange:
		jmp RangeError
_DeleteEndName:
; Do not pass directory-like names to file-delete, even on old kernels.
		ldy deleteLeaf
		lda (zTemp0),y
		beq _DeleteRange
		cmp #"."
		bne _DeleteRequest
		iny
		lda (zTemp0),y
		beq _DeleteRange
		cmp #"."
		bne _DeleteRequest
		iny
		lda (zTemp0),y
		beq _DeleteRange
_DeleteRequest:
		lda zTemp0
		ldx zTemp0+1
		jsr KNLSetupFileName
		jsr KNLSetEventPointer
		lda KNLDefaultDrive
		sta kernel.args.file.delete.drive
		jsr kernel.File.Delete
		bcc _DeleteWaitStart
		lda #KERR_GENERAL
		bra _DeleteReturn
_DeleteWaitStart:
		sta deleteStream
_DeleteWait:
		jsr GetNextEvent
		bcc _DeleteEvent
		jsr kernel.Yield
		bra _DeleteWait
_DeleteEvent:
		lda KNLEvent.file.stream
		cmp deleteStream
		bne _DeleteWait
		lda KNLEvent.type
		cmp #kernel.event.file.ERROR
		beq _DeleteReturn
		cmp #kernel.event.file.NOT_FOUND
		beq _DeleteReturn
		cmp #kernel.event.file.DELETED
		bne _DeleteWait
		lda #0
_DeleteReturn:
		ply
		rts
		.send code
		.section storage
deleteStream:
		.fill 1
deleteLeaf:
		.fill 1
		.send storage
