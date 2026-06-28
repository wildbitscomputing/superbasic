# ************************************************************************************************
# ************************************************************************************************
#
#		Name:		Makefile
#		Purpose:	Main make file
#		Created:	2nd January 2023
#		Author:		Paul Robson (paul@robsons.org.uk)
#
# ************************************************************************************************
# ************************************************************************************************

ifeq ($(OS),Windows_NT)
include ..\source\definitions.mk
else
include ../source/definitions.mk
endif

all :
	zip -j howto-crossdev-basic.zip crossdev-basic/*
