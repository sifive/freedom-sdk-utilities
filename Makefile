# Setup the Freedom build script environment
include scripts/Freedom.mk

# Include version identifiers to build up the full version string
include Version.mk
PACKAGE_HEADING := freedom-spike-dasm
PACKAGE_VERSION := $(RISCV_ISA_SIM_VERSION)-$(FREEDOM_SPIKE_DASM_CODELINE)$(FREEDOM_SPIKE_DASM_GENERATION)b$(FREEDOM_SPIKE_DASM_BUILD)

# Source code directory references
SRCNAME_ISA_SIM := riscv-isa-sim
SRCPATH_ISA_SIM := $(SRCDIR)/$(SRCNAME_ISA_SIM)

# Some special package configure flags for specific targets
$(WIN64)-sdasm-configure := HOST_PREFIX=x86_64-w64-mingw32- EXEC_SUFFIX=.exe

# Setup the package targets and switch into secondary makefile targets
# Targets $(PACKAGE_HEADING)/install.stamp and $(PACKAGE_HEADING)/libs.stamp
include scripts/Package.mk

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/install.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/$(SRCNAME_ISA_SIM)/build.stamp
	mkdir -p $(dir $@)
	date > $@

# We might need some extra target libraries for this package
$(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/libs.stamp: \
		$(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/install.stamp
	date > $@

$(OBJ_WIN64)/build/$(PACKAGE_HEADING)/libs.stamp: \
		$(OBJ_WIN64)/build/$(PACKAGE_HEADING)/install.stamp
	$(WIN64)-gcc -print-search-dirs | grep ^libraries | cut -d= -f2- | tr : "\n" | xargs -I {} find {} -iname "libgcc_s_seh*.dll" | xargs cp -t $(OBJDIR)/$(WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64)/bin
	$(WIN64)-gcc -print-search-dirs | grep ^libraries | cut -d= -f2- | tr : "\n" | xargs -I {} find {} -iname "libstdc*.dll" | xargs cp -t $(OBJDIR)/$(WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64)/bin
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp:
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/source.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	rm -rf $($@_INSTALL)
	mkdir -p $($@_INSTALL)
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	cp -a $(SRCPATH_ISA_SIM) $(dir $@)
	rm -rf $(dir $@)/$(SRCNAME_ISA_SIM)/Makefile
	cp $(PATCHESDIR)/spike-dasm.mk $(dir $@)/$(SRCNAME_ISA_SIM)/Makefile
	rm -rf $(dir $@)/$(SRCNAME_ISA_SIM)/config.h
	cp $(PATCHESDIR)/spike-dasm-config.h $(dir $@)/$(SRCNAME_ISA_SIM)/config.h
	rm -rf $(dir $@)/$(SRCNAME_ISA_SIM)/riscv/extension.h
	cp $(PATCHESDIR)/spike-dasm-extension.h $(dir $@)/$(SRCNAME_ISA_SIM)/riscv/extension.h
	rm -rf $(dir $@)/$(SRCNAME_ISA_SIM)/riscv/extensions.cc
	cp $(PATCHESDIR)/spike-dasm-extensions.cc $(dir $@)/$(SRCNAME_ISA_SIM)/riscv/extensions.cc
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/$(SRCNAME_ISA_SIM)/build.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/$(SRCNAME_ISA_SIM)/build.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/$(SRCNAME_ISA_SIM)/build.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(MAKE) -C $(dir $@) -j1 install \
			EXEC_PREFIX=z \
			SOURCE_PATH=$(abspath $(dir $@)) \
			INSTALL_PATH=$(abspath $($@_INSTALL)) \
			$($($@_TARGET)-sdasm-configure) &>$(dir $@)/make-install.log
	date > $@
