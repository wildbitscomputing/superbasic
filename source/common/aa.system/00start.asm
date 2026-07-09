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

; Machine name, build version and timestamp data. Kept resident (read by the
; DisplayBannerText code, now in the slot 3 kernel module bannerinfo.asm).

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
