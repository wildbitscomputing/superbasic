;;
; Common includes/defines/setups
;;

; ************************************************************************************************
;
;										Configuration options
;
;			  Addresses should be on page boundaries (except for ZeroPageMandatory)
;
; ************************************************************************************************
;
;		Variables that have to be in zero page because it's used in (xx),y
;
ZeroPageMandatory = $0030
;
; 		Variables that would be nice to be in zero page, but it's not required
;
ZeroPagePreference = $0050

; 6502 hardware stack ($0100-$01FF)
HardwareStack = $0100

;
;		Command line arguments for pexec - page aligned, and by convention these should reside
;       at $200 for maximum compatibility
;
ArgumentStorage = $0200
;
;		Control Variables - low usage control variables.
;
ControlStorage = $0400
;
;		Variables that can go anywhere
;
MemoryStorage = $0420
;
;		Where program memory starts and stops (banked through MMU slot 1)
;
BasicStart = $2000
BasicEnd = $4000
;
;		Banking constants
;
MMU_Slot1 = $0009 						; MMU LUT0 register for slot 1 ($2000-$3FFF)
PageSize = $2000 						; 8KB per page
MaxPages = 32 							; max logical pages (256KB program space)
;
;		Array/ALLOC storage in slots 2-3 ($4000-$7FFF)
;
ArrayStart = $4000
ArrayEnd = $8000
;
;		Build address of ROM (slots 4-5, $8000-$BFFF)
;		Boot section at $6000 (slot 3, remapped to RAM after boot)
;
BootStart = $6000
CodeStart = $8000
;
;		Start of variable/string space. This is a fixed location in memory.
;
VariableSpace = $1000
;
;		End of variable space
;
EndVariableSpace = $2000
;
;		Basic Math Stack Size
;
MathStackSize = 16
;
;		Basic Position and Return Stack Size
;
BasicStackSize = 512
BasicStackBase = $1000-BasicStackSize
;
;		Max Input Line Length
;
MaxLineSize = 80

; ************************************************************************************************
;
;									Set up code and data sections
;
; ************************************************************************************************

		* = ZeroPageMandatory 				; *must* be in zero page
		.dsection zeropage

		* = ZeroPagePreference 				; not required to be in zero page, but preferable
		.dsection zeropref

		* = ArgumentStorage 				; not required to be in zero page, but preferable
		.dsection arguments

		* = MemoryStorage 					; doesn't matter if zero page or not
		.dsection storage

		* = $4000							; page 2 modules at $4000 (output before boot)
		.dsection page2

		* = BootStart						; boot section at $6000 (KernelHeader + headerdata)
		.dsection boot

		* = CodeStart						; main code at $8000
		.dsection code
