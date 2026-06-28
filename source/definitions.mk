#		Shared command/variable definitions
#
ifeq ($(OS),Windows_NT)
CCOPY = copy
CDEL = del /Q
APPSTEM = .exe
S = \\
define mkdir
	@if not exist "$(1)" mkdir "$(1)"
endef
else
CCOPY = cp
CDEL = rm -f
APPSTEM =
S = /
define mkdir
	mkdir -p "$(1)"
endef
endif
#
#		Root dir
#
SELFDIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
ROOTDIR := $(abspath $(SELFDIR)..$(S))$(S)
#
#		External repositories
#
KRN_REPO = https://github.com/wildbitscomputing/MicroKernel
LDR_REPO = https://github.com/pweingar/FoenixMgr
#
#		Dirs
#
BINDIR = $(ROOTDIR)bin$(S)
BUILDDIR = $(ROOTDIR).build$(S)
RELEASEDIR = $(ROOTDIR).release$(S)
#
#		Tools
#
ASM ?= 64tass
ASFLAGS ?= -q -b -Wall -c -C
PYTHON ?= uv run
GIT ?= git
#
#		Load Addresses
#
LMONITOR = E000
LLOCKOUT = F000
LTILEMAP = 24000
LTILEIMAGES = 26000
LSOURCE = 28000
LSPRITES = 30000
LBASIC = 34000
#
#		Serial port
#
TTYPORT = /dev/ttyUSB0
#
#		Base curl command: follow redirects, show errors only
#
CURL = curl -L -sS
#
# 		Verbose mode support
#
V ?= 0
ifeq ($(V),1)
    Q =
else
    Q = @
endif
#
#		Download the kernel's latest `api.asm` into the specified dir
#
define updatekernel
	$(Q)$(CURL) -o $(1)$(S)api.asm $(KRN_REPO)/raw/refs/heads/master/kernel/api.asm
	$(Q)$(GIT) add --renormalize $(1)$(S)api.asm
endef
#
#		Make sure the directory exists and is empty
#
define cleandir
	$(Q)$(call mkdir,$(1))
	$(Q)$(CDEL) "$(1)"*.*
endef
