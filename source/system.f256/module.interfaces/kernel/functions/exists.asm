; Evaluate before banking so nested expressions can use the same scratch.
		.section code
ExistsUnary: ;; [exists(]
		plx
		jsr EvaluateString
		jsr CheckRightBracket
		jmp ExistsImpl
		.send code
