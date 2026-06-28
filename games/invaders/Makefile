# ************************************************************************************************
# ************************************************************************************************
#
#		Name:		Makefile
#		Purpose:	Main make file
#		Created:	18th September 2022
#		Author:		Paul Robson (paul@robsons.org.uk)
#
# ************************************************************************************************
# ************************************************************************************************

ifeq ($(OS),Windows_NT)
include ..\..\source\definitions.mk
else
include ../../source/definitions.mk
endif

LANGUAGE = en
SOURCE = main.bas  ..$(S)common$(S)title.bas

START = $(EMULATOR) $(BINDIR)basic.rom@b storage$(S)load.dat@x graphics.bin@s
# $(LSOURCE) is hardcoded in backload.asm

#
#		Extract Graphics, perhaps
#
graphics:
	make -B -C graphics
#
#		Create sprites
#
sprites:
	python $(BINDIR)spritebuild.py sprites.def
#
#		Create autorunning test basic
#
auto:
	make -B -C ..$(S)..$(S)source testbasic
#
#		Build program
#
program:
	python $(BINDIR)basconv.py $(SOURCE) >storage$(S)load.dat
#
#		Run program (if built autorunning BASIC)
#
run: sprites program
	$(START)
#
#		Run on kernel hardware
#
fgo: sprites program
	$(CCOPY) $(BINDIR)foenixmgr.ini .
	python $(BINDIR)fnxmgr.zip --port $(TTYPORT) --binary graphics.bin --address $(LSPRITES)
	python $(BINDIR)fnxmgr.zip --port $(TTYPORT) --binary storage$(S)load.dat --address $(LSOURCE)
#
#		Create for SDCard Upload
#
sdcard:
	$(CCOPY) $(BINDIR)fnxmgr.zip upload
	$(CCOPY) foenixmgr.ini upload
	make -n -s fgo >upload$(S)files.lst
	make -C upload