# ************************************************************************************************
# ************************************************************************************************
#
#		Name:		Makefile
#		Purpose:	Make Graphics File
#		Created:	9th October 2022
#		Author:		Paul Robson (paul@robsons.org.uk)
#
# ************************************************************************************************
# ************************************************************************************************

ifeq ($(OS),Windows_NT)
include ..\..\source\common.make
else
include ../../source/common.make
endif

all :
	python spritebuild.py sprites.def
	$(CCOPY) graphics.bin ..$(S)..$(S)bin
	$(CCOPY) spritebuild.py ..$(S)..$(S)bin