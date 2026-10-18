; File existence probe: no file data is read or written. Do not use the
; legacy KNLOpenFileRead wrapper: it maps generic errors to NOT_FOUND.
		.section code
Export_ExistsImpl:
		phy
		phx
		lda NSMantissa0,x
		sta zTemp0
		lda NSMantissa1,x
		sta zTemp0+1
; An exact, nonempty filename is required, not a wildcard search.
		ldy #0
		lda (zTemp0),y
		beq _EXRange
_EXValidate:
		lda (zTemp0),y
		beq _EXOpen
		cmp #"*"
		beq _EXRange
		cmp #"?"
		beq _EXRange
		iny
		bne _EXValidate
_EXRange:
		jmp RangeError
_EXOpen:
		lda zTemp0
		ldx zTemp0+1
		jsr KNLSetupFileName
		jsr KNLSetEventPointer
		lda KNLDefaultDrive
		sta kernel.args.file.open.drive
		lda #kernel.args.file.open.READ
		sta kernel.args.file.open.mode
		jsr kernel.File.Open
		bcs _EXError
		sta existsStream
_EXOpening:
		jsr _EXEvent
		cmp #kernel.event.file.NOT_FOUND
		beq _EXAbsent
		cmp #kernel.event.file.ERROR
		beq _EXError
		cmp #kernel.event.file.OPENED
		bne _EXOpening
		lda existsStream
		jsr KNLCloseFile
		bcs _EXError
; Wait for close completion so repeated probes cannot exhaust handles or
; leave stale close events for subsequent file operations.
_EXClosing:
		jsr _EXEvent
		cmp #kernel.event.file.ERROR
		beq _EXError
		cmp #kernel.event.file.CLOSED
		bne _EXClosing
		plx
		ply
		jmp ReturnTrue
_EXAbsent:
		plx
		ply
		jmp ReturnFalse
_EXError:
		.error_driveio

; GetNextEvent maintains keyboard/mouse state while we own the queue.
; Only file events for our stream may complete the request.
_EXEvent:
		jsr GetNextEvent
		bcc _EXGotEvent
		jsr kernel.Yield
		bra _EXEvent
_EXGotEvent:
		lda KNLEvent.file.stream
		cmp existsStream
		bne _EXEvent
		lda KNLEvent.type
		rts
		.send code
		.section storage
existsStream:
		.fill 1
		.send storage
