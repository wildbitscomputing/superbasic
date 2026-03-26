# Makefile for F256 SuperBASIC

ifeq ($(OS),Windows_NT)
include ..\documents\common.make
else
include ../documents/common.make
endif
#
#		Current version
#
MAJOR_VERSION = 1
MINOR_VERSION = 2
VERSION ?= $(MAJOR_VERSION).$(MINOR_VERSION)

# Hardware platform: 0 = F256
HARDWARE = 0
# Hardware generation: 1 = J/K, 2 = J2/K2
HARDWARE_GEN ?= 1
LANGUAGE = en
DOLLAR = $$
ASFLAGS += -D HARDWARE=$(HARDWARE) -D HARDWARE_GEN=$(HARDWARE_GEN) \
			'-D MONITOR_ADDRESS=$(DOLLAR)$(LMONITOR)' '-D LOCKOUT_ADDRESS=$(DOLLAR)$(LLOCKOUT)' \
			'-D BASIC_ADDRESS=$(DOLLAR)$(LBASIC)' '-D SOURCE_ADDRESS=$(DOLLAR)$(LSOURCE)' \
			'-D SPRITE_ADDRESS=$(DOLLAR)$(LSPRITES)' '-D TILEMAP_ADDRESS=$(DOLLAR)$(LTILEMAP)' \
			'-D TILEIMAGES_ADDRESS=$(DOLLAR)$(LTILEIMAGES)' \
			-L $(BUILDDIR)debug$(S)basic.lst -l $(BUILDDIR)debug$(S)basic.lbl

MODULES = +hardware +tokeniser +graphics +kernel:2 +sound:2
BUILD_OUT = $(BUILDDIR)basic.rom
SCRIPTDIR = scripts$(S)
MAME_PATH=../../mame
KERNEL_PATH=../../F256_MicroKernel
BASIC_TESTS_PATH=$(PWD)/../test
IMAGE := $(BASIC_TESTS_PATH)/.output/tests.img

all:  build

#
#		Update api.asm
#
updatekernel:
	$(call updatekernel,common$(S)api)
	@echo "Updated kernel"

#
#		Update bootscreen assets
#
updateassets:
	$(Q)$(MAKE) -B -C ..$(S)modules$(S)hardware$(S)header updateassets
	@echo "Updated bootscreen assets"

#
#		Create sprites
#
sprites:
	$(Q)$(MAKE) -B -C ..$(S)spritebuild
#
#		Build and download tools
#
tools: fnxmgr

#
#		Update FoenixMgr "binary"
#
fnxmgr:
	$(Q)$(CURL) -o $(BINDIR)fnxmgr.zip $(LDR_REPO)/raw/refs/heads/master/FoenixMgr.zip

#
#		Show various things
#
stack:
	$(Q)$(PYTHON) $(SCRIPTDIR)showstack.py

strings:
	$(Q)$(PYTHON) $(SCRIPTDIR)showstring.py

vars:
	$(Q)$(PYTHON) $(SCRIPTDIR)showvar.py

#
#		Regular build
#
build: ASFLAGS += -D AUTORUN=0
build: prelim
	$(call cleandir,$(BUILDDIR))
	$(call cleandir,$(BUILDDIR)debug$(S))

	@echo "Compiling assembly"
	$(Q)$(ASM) $(ASFLAGS) _basic.asm -o $(BUILD_OUT)

	@echo "Splitting ROM"
	$(Q)$(PYTHON) $(SCRIPTDIR)splitrom.py $(BUILDDIR)

#
#		Scripts run in advance generating tables etc.
#
prelim:
	@echo "Generating assembly sources"
	$(Q)$(PYTHON) $(SCRIPTDIR)errors.py $(LANGUAGE)
	$(Q)$(PYTHON) $(SCRIPTDIR)opcodes.py >common$(S)generated$(S)asmcore.asm
	$(Q)$(PYTHON) $(SCRIPTDIR)makebuild.py $(MODULES)

	@echo "Building submodules"
	$(Q)$(MAKE) -B -C ..$(S)modules clean all

	$(Q)$(PYTHON) $(SCRIPTDIR)tokens.py
	$(Q)$(PYTHON) $(SCRIPTDIR)constants.py
	$(Q)$(PYTHON) $(SCRIPTDIR)version.py $(VERSION)

#
#		Print base version to console
#
baseversion:
	@: $(info $(MAJOR_VERSION).$(MINOR_VERSION))

#
#		Make sure a release with the current version does not already exist
#
versioncheck:
	@$(GIT) fetch --tags --quiet
	$(if $(strip $(shell $(GIT) rev-parse -q --verify refs/tags/v$(VERSION))), \
        $(error Release tag v$(VERSION) already exists. See README for how to prepare a new release),)


log_step = @echo "> $1"

#
#		Build gen-specific release, copy to the corresponding release dir
#
build_release: OUTPUTDIR := $(RELEASEDIR)gen$(HARDWARE_GEN)$(S)
build_release:
	$(call log_step, "Building gen $(HARDWARE_GEN) release")
	$(Q)$(MAKE) -C . build VERSION=$(VERSION) HARDWARE_GEN=$(HARDWARE_GEN)
	$(call cleandir,$(OUTPUTDIR))
	$(call cleandir,$(OUTPUTDIR)debug$(S))

	@echo "Copying build artifacts"
	$(Q)$(CCOPY) $(BUILDDIR)*.* $(OUTPUTDIR)
	$(Q)$(CCOPY) $(BUILDDIR)debug$(S)*.* $(OUTPUTDIR)debug

#
#		Create a versioned release
#
release: VERSION := $(shell $(PYTHON) $(SCRIPTDIR)version.py)
release: versioncheck
	$(call log_step, "Creating v$(VERSION) release binaries")
	$(Q)$(MAKE) -C . build_release VERSION=$(VERSION) HARDWARE_GEN=1
	$(Q)$(MAKE) -C . build_release VERSION=$(VERSION) HARDWARE_GEN=2

	$(call cleandir,$(RELEASEDIR))
	$(call cleandir,$(RELEASEDIR)syntax$(S))
	$(call cleandir,$(RELEASEDIR)manual$(S))

	$(call log_step, "Copying common release artifacts")
	$(Q)$(CCOPY) ..$(S)reference$(S)source$(S)*.pdf $(RELEASEDIR)manual
	$(Q)$(CCOPY) ..$(S)documents$(S)superbasic.sublime-syntax $(RELEASEDIR)syntax

	$(Q)$(PYTHON) -c "with open('$(RELEASEDIR)VERSION', 'w') as f: f.write('$(VERSION)')"

	$(call log_step, "Done")

#
#		Run various tests.
#
test:
	$(PYTHON) $(SCRIPTDIR)simpletests.py

astest:
	$(PYTHON) $(SCRIPTDIR)assign.py

sastest:
	$(PYTHON) $(SCRIPTDIR)assign.py all

artest:
	$(PYTHON) $(SCRIPTDIR)array.py

benchmark:
	$(CCOPY) ..$(S)documents$(S)benchmarks$(S)bm$(ID).bas storage$(S)load.dat

paging:
	$(PYTHON) $(SCRIPTDIR)checkpaging.py

#
#		Test on real hardware
#
run: build
	foenixmgr binary --address 5000 $(BUILD_OUT)

flash: build
	foenixmgr flash-bulk build/basic.csv

#
#		Build kernel and copy ROMs to MAME
#
kernel:
	$(Q)$(MAKE) -C $(KERNEL_PATH)
	$(Q)$(CCOPY) $(KERNEL_PATH)/bin/*.bin $(MAME_PATH)/roms/f256k
	$(Q)$(CDEL) $(MAME_PATH)/nvram/f256k/flash

#
#		Test in emulator
#
emu: build $(IMAGE)
	$(Q)$(CCOPY) $(BUILDDIR)/sb*.bin $(MAME_PATH)/roms/f256k
	$(Q)$(CDEL) $(MAME_PATH)/nvram/f256k/flash
	cd $(MAME_PATH) && ./f256k f256k -window -resolution 1280x720 -skip_gameinfo -harddisk $(BASIC_TESTS_PATH)/.output/tests.img -rompath roms

emu2: build $(IMAGE)
	$(Q)$(CDEL) $(MAME_PATH)/nvram/f256k/flash
	cd $(MAME_PATH) && ./f256k f256k -window -resolution 1280x720 -skip_gameinfo -harddisk $(BASIC_TESTS_PATH)/.output/tests.img -rompath roms

$(IMAGE): $(BASIC_TESTS_PATH)/ashanghai
	$(PYTHON) $(BASIC_TESTS_PATH)/prepare-disk.py -t $<

