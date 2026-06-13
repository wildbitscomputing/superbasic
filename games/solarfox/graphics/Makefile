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
include ..\..\..\source\common.make
else
include ../../../source/common.make
endif

GRAPHICS = ship:13,11 enemy:40,12 life:65,12 collect1:33,31 collect2:13,33 missile:46,31
BINDIR = ..$(S)..$(S)..$(S)bin$(S)

all :
	python $(BINDIR)ripgfx.py $(GRAPHICS)