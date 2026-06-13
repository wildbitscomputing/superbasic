;;
; Start up code
;;

.section boot

;;
; Kernel Header (boot section, slot 3)
;
; The header lives in the boot section ($6000-$7FFF) along with startup banner.
; Slot 3 is remapped to RAM after boot, freeing $6000-$7FFF for arrays/temp.
;;
KernelHeader:
		.text	$f2,$56         			; Signature
		.byte   5               			; 5 blocks
		.byte   3               			; mount at $6000
		.word   Boot 	      				; Start here (in code section)
		.byte   1 			               	; version
		.byte   0               			; reserved
		.byte   0               			; reserved
		.byte   0               			; reserved
		.text   "basic",0 					; name of program.
		.text   0							; arguments
		.text	"The SuperBASIC environment.",0	; description

.send boot


.section code

;;
; Main Program (code section, slots 4-5)
;;
Boot:	jmp 	Start
		.include "../../modules/.build/_exports.module.asm"
		.include "./_slot3banking.asm"

Start:	ldx 	#$FF 						; stack reset
		txs
		jsr 	Slot3Init					; compute slot 3 module page

		.if 	soundIntegrated==1 			; silence PSG immediately on boot
		lda 	#$0F 						; (SN76489 may start in noisy state)
		jsr 	SNDCommand
		.endif

		jsr 	EXTInitialize 				; hardware initialization
		jsr 	EXTShowStartupBanner        ; reads banner data from slot 3

		lda 	#3 							; remap slot 3 to RAM page 3
		sta 	$0008+3 					; (frees $6000-$7FFF for arrays/temp buffers)

		jsr 	DisplayBannerText           ; print hardware, ROM & build info

		lda 	0  							; turn on editing of MMU LUT
		ora 	#$80
		sta 	0

		;
		; run machine code on boot if requested, see example in storage/mcboot.as
		;
		lda 	$2002 						; if $2002..5 is BT65 then jump to $2000
		cmp 	#"B"
		bne 	_NoMachineCode
		lda 	$2003
		cmp 	#"T"
		bne 	_NoMachineCode
		lda 	$2004
		cmp 	#"6"
		bne 	_NoMachineCode
		lda 	$2005
		cmp 	#"5"
		bne 	_NoMachineCode
		jmp 	$2000

	_NoMachineCode:
		lda 	#0 							; zero the default drive.
		jsr 	KNLSetDrive

		jsr 	TKInitialise 				; initialise tokeniser.

		.if 	graphicsIntegrated==1 		; if installed
		lda 	#0 							; graphics system initialise.
		tax
		tay
		jsr 	GXGraphicDraw
		.endif

		.tickinitialise 					; initialise tick handler
											; (mandatory)

		jsr 	ResetIOTracking 			; reset the I/O tracking.

		lda 	#FirstFreePage 				; one-time init of page allocator
		sta 	nextFreePage
		lda 	#MaxUsablePages
		sta 	maxUsablePages

		jsr 	NewProgram 					; erase current program

		.if 	AUTORUN==1 					; run straight off
		jsr 	BackloadProgram
		jmp 	RunCurrentProgram
		.else
		jmp 	WarmStart					; make same size.
		jmp 	WarmStart
		.endif

;;
; Print hardware, ROM & build info at designated banner positions
;;
DisplayBannerText:
		.print_machine_name
		.print_machine_info
		.print_kernel_info
		.print_build_version
		.print_build_timestamp

		; position cursor below the banner
		.set_line #Banner.Height-1
		.print_char #13

		rts

print_char .macro
		lda 	\1
		jsr 	EXTPrintCharacter
		.endm

print_hex .macro
		lda 	\1
		jsr 	PrintHex
		.endm

set_color .macro
		print_char 	\1+128
		.endm

set_column .macro
		lda 	\1
		sta		EXTColumn
		.endm

set_line .macro
		lda 	\1
		sta 	EXTRow
		jsr 	EXTSetCurrentLine
		.endm

is_jr	.macro
		stz 	$0001
		lda 	$D6A7
		and 	#$10
		.endm

print_machine_name .macro
		.set_line   #Banner.Machine_Name_Line
		.set_column #Banner.Machine_Name_Column
		.set_color  #Banner.Machine_Name_Colors[0]
		stz 	$0001
		lda 	$D6A7
		and 	#$32
		cmp     #$10
		beq 	_wld
		cmp     #$22
		beq 	_wld
		lda 	#<Machine_Name_Prefix.FNX
        ldx 	#>Machine_Name_Prefix.FNX
        bra     +
	_wld:
		lda 	#<Machine_Name_Prefix.WLD
        ldx 	#>Machine_Name_Prefix.WLD
    +   jsr 	PrintStringXA

		.set_color  #Banner.Machine_Name_Colors[1]
		stz 	$0001
		lda 	$D6A7
		bit 	#$10
		beq 	_jr_or_jr2
		bit 	#$02
		beq 	_k2
		lda 	#<Machine_Name.K
        ldx 	#>Machine_Name.K
        bra     +
    _k2:
        lda 	#<Machine_Name.K2
        ldx 	#>Machine_Name.K2
        bra     +
    _jr_or_jr2:
        bit 	#$20
        beq 	_jr
		lda 	#<Machine_Name.Jr2
        ldx 	#>Machine_Name.Jr2
        bra     +
    _jr:
	    lda 	#<Machine_Name.Jr
        ldx 	#>Machine_Name.Jr
    +   jsr 	PrintStringXA

		.endm

print_machine_info .macro
		.set_color  #Banner.Machine_Info_Color
		.set_line   #Banner.Machine_Info_Line
		.set_column #Banner.Machine_Info_Column

		stz 	$0001

		.print_hex $D6AD
        .print_hex $D6AC
        .print_hex $D6AB
        .print_hex $D6AA
        .print_char #' '
        .print_char $D6A8
        .print_char $D6A9

        .print_char #' '
        ;
        ; print core version (1x vs 2x)
        ;
        lda		#'1'						; default to '1'
        bit 	$D6A7 						; test the 7th bit of machine ID
        bpl 	+
        lda		#'2'
    +   jsr 	EXTPrintCharacter
        .print_char #'x'

        .endm

print_kernel_info .macro
		.set_color  #Banner.Kernel_Info_Color
		.set_line   #Banner.Kernel_Info_Line
		.set_column #Banner.Kernel_Info_Column

        lda 	#$08
		ldx 	#$E0
		jsr 	PrintStringXA
		.endm

print_build_version .macro
		.set_color  #Banner.Build_Version_Color
		.set_line   #Banner.Build_Version_Line
		.set_column #Banner.Build_Version_Column

        lda 	#<Build_Version
		ldx 	#>Build_Version
		jsr 	PrintStringXA
		.endm

print_build_timestamp .macro
		.set_color  #Banner.Build_Timestamp_Color
		.set_line   #Banner.Build_Timestamp_Line
		.set_column #Banner.Build_Timestamp_Column

        lda 	#<Build_Timestamp
		ldx 	#>Build_Timestamp
		jsr 	PrintStringXA
		.endm

Machine_Name_Prefix .namespace
FNX:    .text 	"FOENIX ", 0
WLD:    .text 	"wildbits/", 0
.endn

Machine_Name .namespace
K:      .text 	"F256K", 0
Jr:     .text 	"F256Jr", 0
K2:     .text 	"k2", 0
Jr2:    .text 	"jr2", 0
.endn

Build_Version:
		.include "../generated/version.asm"
		.text 	0

Build_Timestamp:
		.include "../generated/timestamp.asm"
		.text 	0


.send code
