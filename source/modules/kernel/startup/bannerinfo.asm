; ************************************************************************************************
; ************************************************************************************************
;
;		Name:		bannerinfo.asm
;		Purpose:	Print hardware/ROM/build info banner (slot 3 module)
;		Created:	10th July 2026
;		Author:		Matthias Brukner (mbrukner@gmail.com)
;
;		Moved out of the resident code section (00start.asm) to relieve the
;		non-paged code overflow past $C000. Called once at boot via the
;		generated slot-3 thunk. String/build data stays resident in
;		00start.asm and is read from here (resident code is visible).
;
; ************************************************************************************************
; ************************************************************************************************

		.section code

;;
; Print hardware, ROM & build info at designated banner positions
;;
Export_DisplayBannerText:
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

		.send code
