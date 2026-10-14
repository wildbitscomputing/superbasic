; Radian trigonometry. Evaluate arguments before entering the banked module:
; nested expressions may then safely share its private scratch storage.
		.section code
PiUnary: ;; [pi]
		plx
		lda #0
		jmp MathFunction
SinUnary: ;; [sin(]
		lda #1
		bra TrigUnary
CosUnary: ;; [cos(]
		lda #2
		bra TrigUnary
TanUnary: ;; [tan(]
		lda #3
TrigUnary:
		plx
		pha
		jsr EvaluateNumber
		jsr CheckRightBracket
		pla
		jmp MathFunction
		.send code
