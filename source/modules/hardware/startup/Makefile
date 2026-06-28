# Boot Header Data Generator

ifeq ($(OS),Windows_NT)
include ..\..\..\definitions.mk
else
include ../../../definitions.mk
endif

INPUT_DIR = lvllvl
BUILD_DIR = .build

all:
	$(Q)$(PYTHON) generate_banner_data.py $(INPUT_DIR) $(BUILD_DIR)

clean:
	$(Q)$(CDEL) $(BUILD_DIR)$(S)*.*

.PHONY: all clean
