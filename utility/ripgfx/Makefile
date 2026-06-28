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
include ..\..\source\definitions.mk
else
include ../../source/definitions.mk
endif

all :
	python ripgfx.py alien11:16,10 alien12:34,11 alien21:15,30 alien22:39,30 alien31:16,46 alien32:31,46 explosion:18,66 base:169,43 \
			bullet1:171,25 bullet21:62,13 bullet22:76,13 saucer:129,9
	$(CCOPY) ripgfx.py ..$(S)..$(S)bin
