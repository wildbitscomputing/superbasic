ifeq ($(OS),Windows_NT)
include ..\..\common.make
else
include ../../common.make
endif

all:
	$(Q)$(PYTHON) scripts$(S)scancodes.py

clean:
	$(Q)$(CDEL) aa.main$(S)_*.*

.PHONY: all clean
