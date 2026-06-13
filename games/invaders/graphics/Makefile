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

GRAPHICS = alien11:21,16 alien12:59,11 alien21:31,50 alien22:68,50 saucer:142,42 \
		   base:121,90 explosion:15,116 missile1:44,116 missile2:72,116 \
		   alien31:32,75 alien32:70,75 bullet:102,113

BINDIR = ..$(S)..$(S)..$(S)bin$(S)

all :
	python $(BINDIR)ripgfx.py $(GRAPHICS)