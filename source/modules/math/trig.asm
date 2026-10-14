; Radian trigonometry, bank 2. Only math slots X..X+2 are clobbered.
; Reduce/fold once, then evaluate around one of 65 quarter-wave anchors.
; The main cubic uses signed Q2.30 values and a 32x24-bit fixed multiplier.
; Angles below 1/64 use floating point to retain relative precision.
		.section code
Export_MathFunction:
		phy
		sta trigMode
		ldy #TrigPi
		cmp #0
		bne _TrigArgument
		jsr TrigConstant
		jmp _TrigExit
_TrigArgument:
		cpx #MathStackSize-2
		bcc _TrigRoom
		.error_parameters
_TrigRoom:
		jsr TrigReduce
		jsr TrigFold
		ldy #TrigInput
		jsr TrigSave
		lda trigMode
		cmp #2
		beq _TrigCos
		jsr TrigQuarter
		lda trigSign
		jsr TrigApplySign
		lda trigMode
		cmp #1
		beq _TrigExit
		ldy #TrigResult
		jsr TrigSave
		ldy #TrigInput
		jsr TrigLoad
_TrigCos:
; cos(alpha) = sin(PI/2-alpha); signs were determined by TrigFold.
		inx
		ldy #TrigHalfPi
		jsr TrigConstant
		dex
		jsr FloatSubtract
		stz NSStatus,x
		jsr NSNormalise
		jsr TrigQuarter
		lda trigCosSign
		jsr TrigApplySign
		lda trigMode
		cmp #2
		beq _TrigExit
		jsr NSMIsZero
		bne _TrigQuotient
		.error_divzero
_TrigQuotient:
		ldy #TrigArgument
		jsr TrigSave
		inx
		ldy #TrigArgument
		jsr TrigLoad
		dex
		ldy #TrigResult
		jsr TrigLoad
		jsr FloatDivide
_TrigExit:
		ply
		rts

TrigApplySign:
		tay
		jsr NSMIsZero
		beq _TASZero
		tya
		ora #8
		sta NSStatus,x
		rts
_TASZero:
		lda #8
		sta NSStatus,x
		rts

; Reduce magnitude modulo the represented 2*PI, preserving sign.
; Subtract a power-of-two multiple each iteration instead of dividing:
; no exponent overflow/underflow, and no cancellation of a tiny argument.
TrigReduce:
		jsr NSNormalise
		beq _TRReturn
		lda NSStatus,x
		and #$80
		sta trigSign
		stz NSStatus,x
_TRLoop:
		inx
		ldy #TrigTwoPi
		jsr TrigConstant
		dex
		jsr TrigCompare
		bcc _TRDone
		lda NSExponent,x
		sta NSExponent+1,x
		jsr TrigCompare
		bcs _TRSubtract
		dec NSExponent+1,x
_TRSubtract:
		jsr FloatSubtract
		jsr NSNormalise
		bne _TRLoop
_TRDone:
		lda trigSign
		ora #8
		sta NSStatus,x
_TRReturn:
		rts

; Fold a reduced signed angle onto [0,PI/2], keeping both result signs.
TrigFold:
		stz trigCosSign
		lda NSStatus,x
		and #$80
		sta trigSign
		stz NSStatus,x
		jsr NSMIsZero
		beq _TFReturn
		inx
		ldy #TrigPi
		jsr TrigConstant
		dex
		jsr TrigCompare
		bcc _TFHalf
		jsr FloatSubtract
		lda trigSign
		eor #$80
		sta trigSign
		lda #$80
		sta trigCosSign
		jsr NSNormalise
		beq _TFReturn
_TFHalf:
		inx
		ldy #TrigHalfPi
		jsr TrigConstant
		dex
		jsr TrigCompare
		bcc _TFReturn
		; Keep exact PI/2: reflecting through PI would discard a low bit.
		beq _TFReturn
		inx
		ldy #TrigPi
		jsr TrigConstant
		dex
		jsr FloatSubtract
		stz NSStatus,x
		lda trigCosSign
		eor #$80
		sta trigCosSign
		jsr NSNormalise
_TFReturn:
		rts

TrigQuarter:
		jsr NSMIsZero
		beq _TQReturn
		lda NSExponent,x
		eor #$80
		cmp #((-46 & $ff)^$80)
		bcc _TQReturn
		cmp #((-36 & $ff)^$80)
		bcs _TQFixed
; Below 1/64: x*(1-x*x/6). Avoid quantising small values to Q2.30.
; Below 2^-16 (above), sin(x)=x to within the mantissa's precision.
		ldy #TrigArgument
		jsr TrigSave
		inx
		ldy #TrigArgument
		jsr TrigLoad
		dex
		jsr FloatMultiply
		inx
		ldy #TrigMinusSixth
		jsr TrigConstant
		dex
		jsr FloatMultiply
		inx
		ldy #TrigOne
		jsr TrigConstant
		dex
		jsr FloatAdd
		inx
		ldy #TrigArgument
		jsr TrigLoad
		dex
		jsr FloatMultiply
_TQReturn:
		rts
_TQFixed:
; Convert the folded angle to Q2.30 (at most six right shifts).
		ldy NSExponent,x
_TQShift:
		cpy #(-30 & $ff)
		beq _TQConverted
		jsr NSMShiftRight
		iny
		bra _TQShift
_TQConverted:
		lda NSMantissa0,x
		sta trigAngle+0
		lda NSMantissa1,x
		sta trigAngle+1
		lda NSMantissa2,x
		sta trigAngle+2
		lda NSMantissa3,x
		sta trigAngle+3
		jsr TrigAnchor
; s + d*(c + d*(-s/2 - d*c/6)).
; The precomputed c/6 avoids a division or fourth multiply per result.
		lda #64
		sec
		sbc trigIndex
		tay
		sec
		lda #0
		sbc TrigSixth0,y
		sta trigWork+0
		lda #0
		sbc TrigSixth1,y
		sta trigWork+1
		lda #0
		sbc TrigSixth2,y
		sta trigWork+2
		lda #0
		sbc TrigSixth3,y
		sta trigWork+3
		jsr TrigFixedMultiply
		ldy trigIndex
		lda TrigSines0,y
		sta trigFactor+0
		lda TrigSines1,y
		sta trigFactor+1
		lda TrigSines2,y
		sta trigFactor+2
		lda TrigSines3,y
		sta trigFactor+3
		lsr trigFactor+3
		ror trigFactor+2
		ror trigFactor+1
		ror trigFactor
		sec
		lda trigWork+0
		sbc trigFactor+0
		sta trigWork+0
		lda trigWork+1
		sbc trigFactor+1
		sta trigWork+1
		lda trigWork+2
		sbc trigFactor+2
		sta trigWork+2
		lda trigWork+3
		sbc trigFactor+3
		sta trigWork+3
		jsr TrigFixedMultiply
		lda #64
		sec
		sbc trigIndex
		tay
		clc
		lda trigWork+0
		adc TrigSines0,y
		sta trigWork+0
		lda trigWork+1
		adc TrigSines1,y
		sta trigWork+1
		lda trigWork+2
		adc TrigSines2,y
		sta trigWork+2
		lda trigWork+3
		adc TrigSines3,y
		sta trigWork+3
		jsr TrigFixedMultiply
		ldy trigIndex
		clc
		lda trigWork+0
		adc TrigSines0,y
		sta NSMantissa0,x
		lda trigWork+1
		adc TrigSines1,y
		sta NSMantissa1,x
		lda trigWork+2
		adc TrigSines2,y
		sta NSMantissa2,x
		lda trigWork+3
		adc TrigSines3,y
		sta NSMantissa3,x
		lda #(-30 & $ff)
		sta NSExponent,x
		stz NSStatus,x
		jmp NSNormalise

; Approximate index = round((angle >> 16)*163/65536).
; The estimate is within 0.011 of the real index on [0,PI/2].
; Correct it by one anchor if necessary using the full Q2.30 residual.
TrigAnchor:
		lda trigAngle+2
		sta trigFactor
		lda trigAngle+3
		sta trigFactor+1
		stz trigFactor+2
		stz trigProduct
		stz trigProduct+1
		stz trigProduct+2
		lda #163
		sta trigCounter
_TAIndex:
		lsr trigCounter
		bcc _TANoAdd
		clc
		lda trigProduct+0
		adc trigFactor+0
		sta trigProduct+0
		lda trigProduct+1
		adc trigFactor+1
		sta trigProduct+1
		lda trigProduct+2
		adc trigFactor+2
		sta trigProduct+2
_TANoAdd:
		asl trigFactor
		rol trigFactor+1
		rol trigFactor+2
		lda trigCounter
		bne _TAIndex
		lda trigProduct+1
		asl a
		lda trigProduct+2
		adc #0
		sta trigIndex
_TAResidual:
		ldy trigIndex
		sec
		lda trigAngle+0
		sbc TrigAngles0,y
		sta trigWork+0
		lda trigAngle+1
		sbc TrigAngles1,y
		sta trigWork+1
		lda trigAngle+2
		sbc TrigAngles2,y
		sta trigWork+2
		lda trigAngle+3
		sbc TrigAngles3,y
		sta trigWork+3
		and #$80
		sta trigDeltaSign
		beq _TAPositive
		jsr TrigNegateWork
_TAPositive:
; PI/256 in Q2.30, rounded. Only the low 24 bits are needed.
		lda trigWork+2
		cmp #((13176795 >> 16)&$ff)
		bne _TACompared
		lda trigWork+1
		cmp #((13176795 >> 8)&$ff)
		bne _TACompared
		lda trigWork
		cmp #(13176795&$ff)
_TACompared:
		bcc _TAReady
		beq _TAReady
		lda trigDeltaSign
		bmi _TAPrevious
		inc trigIndex
		bra _TAResidual
_TAPrevious:
		dec trigIndex
		bra _TAResidual
_TAReady:
		lda trigWork+0
		sta trigDelta+0
		lda trigWork+1
		sta trigDelta+1
		lda trigWork+2
		sta trigDelta+2
		rts

; Signed Q2.30 work *= delta. |delta| <= PI/256, so its magnitude fits
; in 24 bits. Exact unsigned 32x24 multiply, rounded at bit 29, then
; restore sign. Uses a seven-byte product and 24 shift/add iterations.
; Preserves X, angle/index, delta and the outer sine/cosine signs.
TrigFixedMultiply:
		lda trigWork+3
		and #$80
		eor trigDeltaSign
		sta trigProductSign
		lda trigWork+3
		bpl _TMPositive
		jsr TrigNegateWork
_TMPositive:
		lda trigWork+0
		sta trigFactor+0
		stz trigProduct+0
		lda trigWork+1
		sta trigFactor+1
		stz trigProduct+1
		lda trigWork+2
		sta trigFactor+2
		stz trigProduct+2
		lda trigWork+3
		sta trigFactor+3
		stz trigProduct+3
		lda trigDelta+0
		sta trigLow+0
		lda trigDelta+1
		sta trigLow+1
		lda trigDelta+2
		sta trigLow+2
		ldy #24
_TMLoop:
		lda trigLow
		lsr a
		bcc _TMShift
		clc
		lda trigProduct+0
		adc trigFactor+0
		sta trigProduct+0
		lda trigProduct+1
		adc trigFactor+1
		sta trigProduct+1
		lda trigProduct+2
		adc trigFactor+2
		sta trigProduct+2
		lda trigProduct+3
		adc trigFactor+3
		sta trigProduct+3
_TMShift:
		ror trigProduct+3
		ror trigProduct+2
		ror trigProduct+1
		ror trigProduct
		ror trigLow+2
		ror trigLow+1
		ror trigLow
		dey
		bne _TMLoop
; Product currently holds floor(full_product/2^24).
		clc
		lda trigProduct
		adc #32
		sta trigProduct
		lda trigProduct+1
		adc #0
		sta trigProduct+1
		lda trigProduct+2
		adc #0
		sta trigProduct+2
		lda trigProduct+3
		adc #0
		sta trigProduct+3
		ldy #6
_TMRound:
		lsr trigProduct+3
		ror trigProduct+2
		ror trigProduct+1
		ror trigProduct
		dey
		bne _TMRound
		lda trigProduct+0
		sta trigWork+0
		lda trigProduct+1
		sta trigWork+1
		lda trigProduct+2
		sta trigWork+2
		lda trigProduct+3
		sta trigWork+3
		lda trigProductSign
		bmi TrigNegateWork
		rts
TrigNegateWork:
		sec
		lda #0
		sbc trigWork+0
		sta trigWork+0
		lda #0
		sbc trigWork+1
		sta trigWork+1
		lda #0
		sbc trigWork+2
		sta trigWork+2
		lda #0
		sbc trigWork+3
		sta trigWork+3
		rts

; Exact comparison of positive normalised values, C set iff X >= X+1.
; Unlike CompareFloat, does not subtract or discard low mantissa bits.
TrigCompare:
		lda NSExponent+1,x
		eor #$80
		sta trigCompareExponent
		lda NSExponent,x
		eor #$80
		cmp trigCompareExponent
		bne _TCExit
		lda NSMantissa3,x
		cmp NSMantissa3+1,x
		bne _TCExit
		lda NSMantissa2,x
		cmp NSMantissa2+1,x
		bne _TCExit
		lda NSMantissa1,x
		cmp NSMantissa1+1,x
		bne _TCExit
		lda NSMantissa0,x
		cmp NSMantissa0+1,x
_TCExit:
		rts
TrigLoad:
		lda trigScratch,y
		sta NSMantissa0,x
		iny
		lda trigScratch,y
		sta NSMantissa1,x
		iny
		lda trigScratch,y
		sta NSMantissa2,x
		iny
		lda trigScratch,y
		sta NSMantissa3,x
		iny
		lda trigScratch,y
		sta NSExponent,x
		iny
		lda trigScratch,y
		sta NSStatus,x
		rts
TrigSave:
		lda NSMantissa0,x
		sta trigScratch,y
		iny
		lda NSMantissa1,x
		sta trigScratch,y
		iny
		lda NSMantissa2,x
		sta trigScratch,y
		iny
		lda NSMantissa3,x
		sta trigScratch,y
		iny
		lda NSExponent,x
		sta trigScratch,y
		iny
		lda NSStatus,x
		sta trigScratch,y
		rts
TrigConstant:
		lda trigConstants,y
		sta NSMantissa0,x
		iny
		lda trigConstants,y
		sta NSMantissa1,x
		iny
		lda trigConstants,y
		sta NSMantissa2,x
		iny
		lda trigConstants,y
		sta NSMantissa3,x
		iny
		lda trigConstants,y
		sta NSExponent,x
		iny
		lda trigConstants,y
		sta NSStatus,x
		rts
trigConstants:
TrigPi = 0
		.dword $6487ed51
		.byte -29&$ff, 8
TrigHalfPi = 6
		.dword $6487ed51
		.byte -30&$ff, 8
TrigTwoPi = 12
		.dword $6487ed51
		.byte -28&$ff, 8
TrigMinusSixth = 18
		.dword $55555555
		.byte -33&$ff, $88
TrigOne = 24
		.dword $40000000
		.byte -30&$ff, 8
		.send code

		.section storage
trigMode: .fill 1
trigSign: .fill 1
trigCosSign: .fill 1
trigCompareExponent: .fill 1
trigIndex: .fill 1
trigCounter: .fill 1
trigDeltaSign: .fill 1
trigProductSign: .fill 1
trigAngle: .fill 4
trigWork: .fill 4
trigFactor: .fill 4
trigProduct: .fill 4
trigLow: .fill 3
trigDelta: .fill 3
TrigInput = 0
TrigResult = 6
TrigArgument = 12
trigScratch: .fill 18
		.send storage
