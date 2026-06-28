ifeq ($(OS),Windows_NT)
include ..\..\definitions.mk
else
include ../../definitions.mk
endif

all:
	$(Q)$(PYTHON) scripts$(S)scancodes.py

clean:
	$(Q)$(CDEL) aa.main$(S)_*.*

.PHONY: all clean
