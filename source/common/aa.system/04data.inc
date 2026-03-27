; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		04data.inc
;		Purpose:	Main Data
;		Created:	18th September 2022
;		Reviewed: 	23rd November 2022
;		Author:		Paul Robson (paul@robsons.org.uk)
;
; ************************************************************************************************
; ************************************************************************************************

; ************************************************************************************************
;
;									Mandatory Zero page code
;
; ************************************************************************************************

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

; ************************************************************************************************
;
;								   Preferable Zero page code
;
; ************************************************************************************************

NSBIsNegative = $80 						; bit 7 : sign of mantissa (where numeric)
NSBIsReference = $20 						; bit 5 : is a reference
NSBIsString = $10 							; bit 4 : set if string (procedures don't go on the stack)
NSBTypeMask = $18 							; bits 4,3 : 00 int 01 float 10 string 11 procedure
NSBRefMask = $03 							; bits 0,1 : Bytes of reference, 00 = 4,01 = 1,10=2
NSBIsArray = $04

NSTInteger = $00 							; base types for bits 3..4
NSTFloat = $08
NSTString = $10
NSTProcedure = $18

		.section zeropref

; ************************************************************************************************
;
;							The number stack (works up from zero)
;
; ************************************************************************************************

NSStatus: 									; Status bits of stack.
		.fill 	MathStackSize
NSMantissa0: 								; Mantissa on stack (address in 0,1 for string/reference)
		.fill 	MathStackSize 				; (this is my integer mantissa system)
NSMantissa1: 								; the order of the mantissa elements is required.
		.fill 	MathStackSize
NSMantissa2:
		.fill 	MathStackSize
NSMantissa3:
		.fill 	MathStackSize
NSExponent: 								; Exponent , 0 = Mantissa is integer
		.fill 	MathStackSize

fnStackLevel:								; saved stack level for function evaluation
		.fill 	1

		.send zeropref


; ************************************************************************************************
;
;										Non Zero Page Data
;
; ************************************************************************************************

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

; ************************************************************************************************
;
;									Changes and Updates
;
; ************************************************************************************************
;
;		Date			Notes
;		==== 			=====
;		1/12/2022 		Changed the recorded values used in the reference byte size which were
;						incorrect, no code change.
;		2/12/2022 		Made line buffer long again, as long lines can be entered via cross 
;						development which would crash the interpreter.
;
; ************************************************************************************************

