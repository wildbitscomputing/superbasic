;;
; Macros for tick-tasks
;;

;;
; Timer init (no op)
;;
tickinitialise 	.macro
		.endm

;;
; Called 1 in every 8 instructions, firing each clock
;;
tickcheck		.macro
		lda 	1 							; save I/O 0
		pha
		stz 	1 							; access I/O Page 0
		sec 								; calculate timer - LastTick
		lda 	$D659
		cmp 	LastTick
		beq 	_NoFireTick 				; if < 3 clocks don't fire.
		sta 	LastTick 					; update last timer
		jsr 	\1 							; go do the code.
_NoFireTick:
		pla 								; restore I/O 0
		sta 	1
		.endm
