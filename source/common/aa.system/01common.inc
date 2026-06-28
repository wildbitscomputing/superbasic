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
;		Boot section at $6000 (slot 3, remapped to RAM after boot)
;
BootStart = $6000
;
;		Resident shared code (slot 4, $8000-$9FFF)
;
ResidentSharedStart = $8000
;
;		Resident swappable code (slot 5, $A000-$BFFF)
;
ResidentSwappableStart = $A000
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

;;
; RAM storage, declarations/dynamic data only, cannot contain statically initialized data
;;
		* = ZeroPageMandatory 				; *must* be in zero page
		.dsection zeropage

		* = ZeroPagePreference 				; not required to be in zero page, but preferable
		.dsection zeropref

		* = ArgumentStorage 				; not required to be in zero page, but preferable
		.dsection arguments

		* = MemoryStorage 					; doesn't matter if zero page or not
		.dsection storage


; ROM image sections: code and static data
;
;   $4000-$5FFF: module page 2 code (`page2` section)
;   $6000-$7FFF: KernelHeader + headerdata (`boot` section)
;   $8000-$9FFF: resident code 1 (`resident_shared` section)
;   $A000-$BFFF: resident code 2 (`resident_swappable` section)
;   $C000-$DFFF: module page 1 code (`page1` section)
;
; Banking/visibility rules:
;
; - `resident_shared` is always visible. Banking thunks, interrupt handlers,
;   and code/data needed by paged modules live here.
;
; - `resident_swappable` is unavailable while `page1` is mapped.
;
; - `page2` hides array RAM at $6000-$7FFF while executing.
;
; - `page1` has the full array storage ($4000-$7FFF) visible, but only if it
;    doesn't have `page2` code in its call stack.
;
; - Calls from outside `page1` or `page2` must go through the corresponding
;   banking thunk.
;
; - A `page1` thunk may only be entered while `resident_swappable` is mapped.
;   Consequently, `page1` cannot be re-entered through a thunk, including
;   through a `page1` -> `page2` -> `page1` call chain.
;
; - `page2` may call `page1` through a thunk iff `page1` is not already
;   mapped. The called code cannot access array RAM at $6000-$7FFF because
;   `page2` still occupies slot 3.


		; Page 2 section at $4000
		;
		; Mapped to `BootStart` (slot 3) when called and therefore cannot
		; directly access higher half of the RAM/array data at $6000-$7FFF

		* = $4000
		.logical BootStart
		.dsection page2
		.endlogical

		; define the corresponding namespace
Page2	.namespace
		.endnamespace


		; Boot section at $6000 (KernelHeader + headerdata)
		;
		; RAM (array/`alloc` storage in slot 3) is mapped here after boot and
		; page 2 code is mapped here when called

		* = BootStart
		.dsection boot


		; Shared resident code at $8000
		;
		; The only code section that stays resident in CPU memory throughout
		; the lifetime of the interpreter

		* = ResidentSharedStart				; shared resident code at $8000
		.dsection resident_shared


		; Swappable resident code at $A000
		;
		; Page 1 modules are mapped here on demand

		* = ResidentSwappableStart
		.dsection resident_swappable


		; Page 1 section at $C000
		;
		; Mapped to `ResidentSwappableStart` when called and therefore cannot
		; depend on `resident_swappable` routines

		* = $C000
		.logical ResidentSwappableStart
		.dsection page1
		.endlogical

		; define the corresponding namespace
Page1	.namespace
		.endnamespace

