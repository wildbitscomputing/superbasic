ifeq ($(OS),Windows_NT)
include ..\..\..\documents\common.make
else
include ../../../documents/common.make
endif

all:
	$(Q)$(PYTHON) scripts$(S)scancodes.py

clean:
	$(Q)$(CDEL) aa.main$(S)_*.*

.PHONY: all clean
