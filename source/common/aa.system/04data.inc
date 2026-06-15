
;		Mandatory zero-page data

		.section zeropage

codePtr:	 								; address of current line (allow for 32 bit)
		.fill 	4
basicStack: 								; BASIC stack address
		.fill 	2
zTemp0: 									; temporary words used in the interpreter.
		.fill 	2
zTemp1:
		.fill 	2
zTemp2:
		.fill 	2
zsTemp:	 									; allocated string temporary.
		.fill 	2
zaTemp: 									; allocated array temporary
		.fill 	2

safePtr = codePtr 							; minimise direct tinkering

		.send zeropage


; 		Preferably zero-page data

		.section zeropref

; Number stack status masks

NSBIsNegative 	= $80 						; bit 7: sign of mantissa (where numeric)
NSBIsReference 	= $20 						; bit 5: is a reference
NSBIsString 	= $10 						; bit 4: set if string (procedures don't go on the stack)
NSBTypeMask 	= $18 						; bits 4,3: 00 int 01 float 10 string 11 procedure
NSBRefMask	 	= $03 						; bits 0,1: Bytes of reference, 00 = 4,01 = 1,10=2
NSBIsArray 		= $04

NSTInteger 		= $00 						; base types for bits 3..4
NSTFloat 		= $08
NSTString 		= $10
NSTProcedure 	= $18

;;
; The number stack (works up from zero)
;;
NSStatus: 									; Status bits of stack.
		.fill 	MathStackSize

; 4 mantissa bytes (little-endian, 31 bits + sign)
;
; Stores an integer magnitude. Normalized non-zero mantissa always has bit 30 set.
;
; Note that on the number stack, the sign is kept in `NSStatus` (`NSBIsNegative` mask), so the
; mantissa itself only carries magnitude; when a float is written out to a variable, the sign
; bit gets packed into the top bit of the highest mantissa byte.
NSMantissa0:
		.fill 	MathStackSize
NSMantissa1:
		.fill 	MathStackSize
NSMantissa2:
		.fill 	MathStackSize
NSMantissa3:
		.fill 	MathStackSize


; a signed 8-bit base-2 exponent stored in two's complement format; 0 if mantissa is integer
;
; floating-point value = mantissa x 2^decoded exponent, where
; decoded exponent = exponent if exponent < 128 else exponent - 256
NSExponent:
		.fill 	MathStackSize

; saved stack level for function evaluation
fnStackLevel:
		.fill 	1

		.send zeropref


; 		Non-zero page data

		.section storage

identStart: 								; start of identifier in line buffer
		.fill 	1
identTypeStart: 							; start of type information (#$ and ( in the line buffer)
		.fill 	1
identTypeEnd: 								; character after end of type information in the line buffer
		.fill 	1
identHash: 									; hash of identifier (including the type characters)
		.fill 	1
identTypeByte: 								; type descriptor in format used in identifier record
		.fill 	1	 						; (see tokenising.pdf)

encodeState: 								; state for simple encoding FSM
		.fill 	1
digitTemp: 									; temporary in number conversion
		.fill 	1
decimalCount:								; decimal digit count
		.fill 	1

lowMemPtr: 									; memory allocation after program.
		.fill 	2
arrayMemPtr: 								; array/alloc storage pointer (slots 2-3, $4000-$7FFF)
		.fill 	2
stringMemory: 								; allocate concrete strings from here
		.fill 	2
stringInitialised: 							; string
		.fill 	1
stringTempPointer:							; temporary string
		.fill 	2

breakCheck:									; break check counter/shift
		.fill 	1

decimalPlaces: 								; no of decimals.
		.fill 	1
dbOffset:									; offset into decimal buffer.
		.fill 	1

lastParameter: 								; final stack offset when all parameters handled.
		.fill 	1

dataPointer:								; operates like code pointer for DATA statements
		.fill 	5
inDataStatement:							; non zero when in data statement, e.g. pointing to data
		.fill 	1

tbOffset:									; offset into token buffer
		.fill 	1

AssemblerAddress:							; address being assembled at
		.fill 	2
AssemblerControl:							; assembler control byte - bit 0 (errors ok), bit 1 (listing on)
		.fill 	1
ParamStart: 								; offset of parameter.
		.fill 	2
IsGroup1:		 							; flag set if group.1
		.fill 	1
BaseOpcode: 								; base opcode
		.fill 	1
ModeMask: 									; modes allowed
		.fill 	1
listIndent:	 								; list indent level.
		.fill 	1
listElseFound:								; flag set when ELSE found on line (for indent fix)
		.fill 	1
listEndToken:								; closing token for LIST proc/fn
		.fill 	1
lcLastCharacter: 							; last character output.
		.fill 	1
isPrintFlag:	 							; zero if input, non-zero if print, bit 6 zero = character print
		.fill 	1
currentListColour: 							; current set colour when listing.
		.fill 	1
;
;		New tokenised line - these three *must* be contiguous as they are used as a single entity
;
tokenOffset: 								; used for tokenising - tokenised result goes here
		.fill 	1
tokenLineNumber:
		.fill 	2
tokenBuffer:
		.fill 	253

lineBuffer: 								; used for input - ASCII line goes here
		.fill 	253

programChanged:
		.fill	1							; tracks whether program has been changed since last save

;		Slot 3 module bank switching state (placed before buffers so that
;		a numberBuffer/decimalBuffer overflow cannot corrupt them).
Slot3ModulePage:
		.fill 	1
Slot3Depth:
		.fill 	1
Slot3Saved:
		.fill 	1

numberBuffer:								; buffer for numbers (32 bit binary + sign + ASCIIZ)
		.fill 	34
decimalBuffer: 								; buffer for number -> string conversion.
		.fill 	24

		.send 	storage
