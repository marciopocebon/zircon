# Copyright 2018 The Fuchsia Authors
#
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT

ifeq ($(PLATFORM_BOARD_NAME),)
$(error PLATFORM_BOARD_NAME not defined)
endif

BOARD_KERNEL_BOOTDATA := $(BUILDDIR)/$(PLATFORM_BOARD_NAME)-kernel-bootdata.bin
BOARD_BOOTDATA := $(BUILDDIR)/$(PLATFORM_BOARD_NAME)-bootdata.bin
BOARD_COMBO_BOOTDATA := $(BUILDDIR)/$(PLATFORM_BOARD_NAME)-combo-bootdata.bin

ifeq ($(PLATFORM_USE_SHIM),true)
ifeq ($(TARGET),arm64)
include kernel/target/arm64/boot-shim/rules.mk
else
$(error PLATFORM_USE_SHIM not supported for target $(TARGET))
endif
BOARD_BOOT_SHIM_OPTS := --header $(BOOT_SHIM_BIN) --header-align $(KERNEL_ALIGN)
else
BOARD_BOOT_SHIM_OPTS :=
endif

# capture board specific variables for the build rules
$(BOARD_KERNEL_BOOTDATA): BOARD_KERNEL_BOOTDATA:=$(BOARD_KERNEL_BOOTDATA)
$(BOARD_BOOTDATA): BOARD_BOOTDATA:=$(BOARD_BOOTDATA)
$(BOARD_BOOTDATA): BOARD_KERNEL_BOOTDATA:=$(BOARD_KERNEL_BOOTDATA)
$(BOARD_COMBO_BOOTDATA): BOARD_COMBO_BOOTDATA:=$(BOARD_COMBO_BOOTDATA)
$(BOARD_COMBO_BOOTDATA): BOARD_BOOTDATA:=$(BOARD_BOOTDATA)
$(BOARD_COMBO_BOOTDATA): BOARD_BOOT_SHIM_OPTS:=$(BOARD_BOOT_SHIM_OPTS)

# kernel bootdata for fuchsia build
# TODO: remove this once Fuchsia build no longer needs this
$(BOARD_KERNEL_BOOTDATA): $(MKBOOTFS)
	$(call BUILDECHO,generating $@)
	@$(MKDIR)
	$(NOECHO)$(MKBOOTFS) -o $@ --empty

# full bootdata (kernel bootdata + bootfs)
# TODO: replace this with common bootdata for all boards
$(BOARD_BOOTDATA): $(MKBOOTFS) $(BOARD_KERNEL_BOOTDATA) $(USER_BOOTDATA)
	$(call BUILDECHO,generating $@)
	@$(MKDIR)
	$(NOECHO)$(MKBOOTFS) -o $@ $(BOARD_KERNEL_BOOTDATA) $(USER_BOOTDATA)

# combo bootdata package (kernel + bootdata)
$(BOARD_COMBO_BOOTDATA): $(MKBOOTFS) $(OUTLKBIN) $(BOARD_BOOTDATA) $(BOOT_SHIM_BIN)
	$(call BUILDECHO,generating $@)
	@$(MKDIR)
	$(NOECHO)$(MKBOOTFS) -o $@ $(OUTLKBIN) $(BOARD_BOOTDATA) $(BOARD_BOOT_SHIM_OPTS)

kernel-only: $(BOARD_KERNEL_BOOTDATA)
kernel: $(KERNEL_BOOTDATA)

GENERATED += $(BOARD_KERNEL_BOOTDATA) $(BOARD_BOOTDATA) $(BOARD_COMBO_BOOTDATA)
EXTRA_BUILDDEPS += $(BOARD_KERNEL_BOOTDATA) $(BOARD_BOOTDATA) $(BOARD_COMBO_BOOTDATA)

# clear variables that were passed in to us
PLATFORM_BOARD_NAME :=
PLATFORM_USE_SHIM :=

# clear variables we set here
BOARD_KERNEL_BOOTDATA :=
BOARD_BOOTDATA :=
BOARD_COMBO_BOOTDATA :=
BOARD_BOOT_SHIM_OPTS :=
