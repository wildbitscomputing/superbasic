# This makefile orchestrates the build process for all SuperBASIC modules:
# 1. Builds individual module components, if needed (graphics, hardware headers)
# 2. Copies required data files (keyword text for tokeniser)
# 3. Generates combined assembly files for each module (.module.asm)
# 4. Creates module interface code with bank switching support (_exports.module.asm)
#
# Each module is built into a single assembly file that can be loaded into
# a separate memory bank on the F256 system, enabling modular functionality
# within the interpreter's memory constraints.

ifeq ($(OS),Windows_NT)
include ..\documents\common.make
else
include ../documents/common.make
endif

BUILD_DIR = .build

all:
	$(Q)$(MAKE) -B -C graphics
	$(Q)$(MAKE) -B -C hardware$(S)startup

	$(Q)$(CCOPY) ..$(S)source$(S)common$(S)generated$(S)kwdtext.dat tokeniser$(S)__kwdtext.asm
	$(Q)$(PYTHON) _scripts$(S)makebuild.py tokeniser

	$(Q)$(PYTHON) _scripts$(S)makebuild.py graphics $(BUILD_DIR)
	$(Q)$(PYTHON) _scripts$(S)makebuild.py hardware $(BUILD_DIR)
	$(Q)$(PYTHON) _scripts$(S)makebuild.py kernel $(BUILD_DIR) --page 2
	$(Q)$(PYTHON) _scripts$(S)makebuild.py sound $(BUILD_DIR) --page 2

	$(Q)$(PYTHON) _scripts$(S)makeexport.py >$(BUILD_DIR)$(S)_exports.module.asm

clean:
	$(Q)$(MAKE) -C graphics clean
	$(Q)$(MAKE) -C hardware$(S)startup clean

	$(Q)$(CDEL) $(BUILD_DIR)$(S)*.*

.PHONY: all clean
