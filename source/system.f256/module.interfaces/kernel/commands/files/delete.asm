		.section code
Command_Delete: ;; [delete]
		jsr DeleteHandler
		cmp #0
		beq _DeleteDone
		jmp CLErrorHandler
_DeleteDone:
		rts

DeleteHandler:
		ldx #0
		jsr EvaluateString
		jmp DeleteImpl
		.send code
