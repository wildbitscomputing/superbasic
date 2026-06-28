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

START = $(EMULATOR) $(BINDIR)basic.rom@b storage$(S)load.dat@x graphics.bin@s
# 3000 is hardcoded in backload.asm

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
	python $(BINDIR)basconv.py pong.bas >storage$(S)load.dat
#
#		Run program (if built autorunning BASIC)
#
run: sprites program
	$(START)