; General floating-point mantissa multiplication using the F256 integer unit.
; FloatMultiply has already normalised both nonzero operands to 31 bits.
; In that case MultiplyShort always performs 31 right shifts: its exact result
; is floor(A*B/2^31). Preserve that truncation (including the bit lost if the
; caller subsequently normalises left once), rather than changing rounding.
;
; Input: math slots X and X+1, normalised nonzero mantissas.
; Output: slot X mantissa/sign; A=31, C=0 for the caller's exponent adjustment.
; Preserves X, Y, both exponents, slot X+1, and all trig scratch storage.
; Slot X+2 is scratch in the software path but is not needed here.
; Uses eight private RAM bytes; nested bank-2 entry from trig is supported.
;
; IRQs are masked while I/O page 0 and the shared multiplier are in use.
; Restore operands (and thus their product), I/O mapping and the caller's I.
; NMI handlers must not change I/O mapping or use the shared math unit here.
MathMulA = $de00
MathMulB = $de02
MathMulResult = $de10

		.section code
Export_MathMultiplyMantissa:
		phy
		php
		sei
		lda $01
		pha
		stz $01
		ldy #0
_FMSave:
		lda MathMulA,y
		pha
		iny
		cpy #4
		bne _FMSave
; A low * B low -> bytes 0..3 of the full 64-bit product.
		lda NSMantissa0,x
		sta MathMulA
		lda NSMantissa1,x
		sta MathMulA+1
		lda NSMantissa0+1,x
		sta MathMulB
		lda NSMantissa1+1,x
		sta MathMulB+1
		ldy #3
_FMLow:
		lda MathMulResult,y
		sta floatProduct,y
		dey
		bpl _FMLow
		stz floatProduct+4
		stz floatProduct+5
		stz floatProduct+6
		stz floatProduct+7
; A high * B low -> add at byte 2, retaining all cross-product carries.
		lda NSMantissa2,x
		sta MathMulA
		lda NSMantissa3,x
		sta MathMulA+1
		jsr FloatAddMiddleProduct
; A high * B high -> add at byte 4.
		lda NSMantissa2+1,x
		sta MathMulB
		lda NSMantissa3+1,x
		sta MathMulB+1
		clc
		lda MathMulResult
		adc floatProduct+4
		sta floatProduct+4
		lda MathMulResult+1
		adc floatProduct+5
		sta floatProduct+5
		lda MathMulResult+2
		adc floatProduct+6
		sta floatProduct+6
		lda MathMulResult+3
		adc floatProduct+7
		sta floatProduct+7
; A low * B high -> add at byte 2.
		lda NSMantissa0,x
		sta MathMulA
		lda NSMantissa1,x
		sta MathMulA+1
		jsr FloatAddMiddleProduct
		ldy #3
_FMRestore:
		pla
		sta MathMulA,y
		dey
		bpl _FMRestore
		pla
		sta $01
		plp
; Copy bits 31..61 to the result, truncating the low 31 product bits.
		lda floatProduct+3
		asl a
		lda floatProduct+4
		rol a
		sta NSMantissa0,x
		lda floatProduct+5
		rol a
		sta NSMantissa1,x
		lda floatProduct+6
		rol a
		sta NSMantissa2,x
		lda floatProduct+7
		rol a
		sta NSMantissa3,x
		jsr CalculateSign
		lda #31
		clc
		ply
		rts

FloatAddMiddleProduct:
		clc
		lda MathMulResult
		adc floatProduct+2
		sta floatProduct+2
		lda MathMulResult+1
		adc floatProduct+3
		sta floatProduct+3
		lda MathMulResult+2
		adc floatProduct+4
		sta floatProduct+4
		lda MathMulResult+3
		adc floatProduct+5
		sta floatProduct+5
		lda floatProduct+6
		adc #0
		sta floatProduct+6
		lda floatProduct+7
		adc #0
		sta floatProduct+7
		rts
		.send code

		.section storage
floatProduct: .fill 8
		.send storage
