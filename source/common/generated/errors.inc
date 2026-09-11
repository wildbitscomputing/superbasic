;
;	This is automatically generated.
;
ERRID_BREAK = 1
error_break .macro
	lda	#1
	jmp	ErrorHandler
	.endm
ERRID_SYNTAX = 2
error_syntax .macro
	lda	#2
	jmp	ErrorHandler
	.endm
ERRID_DIVZERO = 3
error_divzero .macro
	lda	#3
	jmp	ErrorHandler
	.endm
ERRID_RANGE = 4
error_range .macro
	lda	#4
	jmp	ErrorHandler
	.endm
ERRID_TYPE = 5
error_type .macro
	lda	#5
	jmp	ErrorHandler
	.endm
ERRID_MEMORY = 6
error_memory .macro
	lda	#6
	jmp	ErrorHandler
	.endm
ERRID_ARGUMENT = 7
error_argument .macro
	lda	#7
	jmp	ErrorHandler
	.endm
ERRID_STOP = 8
error_stop .macro
	lda	#8
	jmp	ErrorHandler
	.endm
ERRID_STRING = 9
error_string .macro
	lda	#9
	jmp	ErrorHandler
	.endm
ERRID_ASSERT = 10
error_assert .macro
	lda	#10
	jmp	ErrorHandler
	.endm
ERRID_DATA = 11
error_data .macro
	lda	#11
	jmp	ErrorHandler
	.endm
ERRID_NOTDONE = 12
error_notdone .macro
	lda	#12
	jmp	ErrorHandler
	.endm
ERRID_LINE = 13
error_line .macro
	lda	#13
	jmp	ErrorHandler
	.endm
ERRID_GOSUB = 14
error_gosub .macro
	lda	#14
	jmp	ErrorHandler
	.endm
ERRID_REPEAT = 15
error_repeat .macro
	lda	#15
	jmp	ErrorHandler
	.endm
ERRID_WHILE = 16
error_while .macro
	lda	#16
	jmp	ErrorHandler
	.endm
ERRID_FOR = 17
error_for .macro
	lda	#17
	jmp	ErrorHandler
	.endm
ERRID_STACK = 18
error_stack .macro
	lda	#18
	jmp	ErrorHandler
	.endm
ERRID_STRUCT = 19
error_struct .macro
	lda	#19
	jmp	ErrorHandler
	.endm
ERRID_PROC = 20
error_proc .macro
	lda	#20
	jmp	ErrorHandler
	.endm
ERRID_REDEFINE = 21
error_redefine .macro
	lda	#21
	jmp	ErrorHandler
	.endm
ERRID_ARRAYSIZE = 22
error_arraysize .macro
	lda	#22
	jmp	ErrorHandler
	.endm
ERRID_ARRAYIDX = 23
error_arrayidx .macro
	lda	#23
	jmp	ErrorHandler
	.endm
ERRID_ARRAYDEC = 24
error_arraydec .macro
	lda	#24
	jmp	ErrorHandler
	.endm
ERRID_NOTFOUND = 25
error_notfound .macro
	lda	#25
	jmp	ErrorHandler
	.endm
ERRID_DRIVEIO = 26
error_driveio .macro
	lda	#26
	jmp	ErrorHandler
	.endm
ERRID_VERIFY = 27
error_verify .macro
	lda	#27
	jmp	ErrorHandler
	.endm
ERRID_NOPROGRAM = 28
error_noprogram .macro
	lda	#28
	jmp	ErrorHandler
	.endm
ERRID_PARAMETERS = 29
error_parameters .macro
	lda	#29
	jmp	ErrorHandler
	.endm
ERRID_TOOCOMPLEX = 30
error_toocomplex .macro
	lda	#30
	jmp	ErrorHandler
	.endm
ERRID_INITERROR = 31
error_initerror .macro
	lda	#31
	jmp	ErrorHandler
	.endm
ERRID_DIRFULL = 32
error_dirfull .macro
	lda	#32
	jmp	ErrorHandler
	.endm
