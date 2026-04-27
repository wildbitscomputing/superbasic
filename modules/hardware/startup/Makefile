# Boot Header Data Generator

ifeq ($(OS),Windows_NT)
include ..\..\..\documents\common.make
else
include ../../../documents/common.make
endif

INPUT_DIR = lvllvl
BUILD_DIR = .build

all:
	$(Q)$(PYTHON) generate_banner_data.py $(INPUT_DIR) $(BUILD_DIR)

clean:
	$(Q)$(CDEL) $(BUILD_DIR)$(S)*.*

.PHONY: all clean
