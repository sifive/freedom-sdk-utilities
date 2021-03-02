# Setup the Freedom build script environment
include scripts/Freedom.mk

# Include version identifiers to build up the full version string
include Version.mk
PACKAGE_WORDING := SDK Utilities
PACKAGE_HEADING := sdk-utilities
PACKAGE_VERSION := $(RISCV_ISA_SIM_VERSION)-$(FREEDOM_SDK_UTILITIES_ID)$(EXTRA_SUFFIX)
PACKAGE_COMMENT := \# SiFive Freedom Package Properties File

# Source code directory references
SRCNAME_ISA_SIM := riscv-isa-sim
SRCPATH_ISA_SIM := src/$(SRCNAME_ISA_SIM)
SRCNAME_ELF2HEX := freedom-elf2hex
SRCPATH_ELF2HEX := src/$(SRCNAME_ELF2HEX)

# Some special package configure flags for specific targets
$(WIN64)-dtc-configure   := CROSSPREFIX=x86_64-w64-mingw32- BINEXT=.exe CC=gcc
$(WIN64)-fe2h-configure  := CROSSPREFIX=x86_64-w64-mingw32- BINEXT=.exe CC=gcc
$(WIN64)-sdasm-configure := CROSSPREFIX=x86_64-w64-mingw32- BINEXT=.exe CXX=g++

# Setup the package targets and switch into secondary makefile targets
# Targets $(PACKAGE_HEADING)/install.stamp and $(PACKAGE_HEADING)/libs.stamp
include scripts/Package.mk

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/install.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/$(SRCNAME_ISA_SIM)/build.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/install.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/install.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_PROPERTIES := $(patsubst %/build/$(PACKAGE_HEADING)/install.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).properties,$@))
	mkdir -p $(dir $@)
	git log --format="[%ad] %s" > $(abspath $($@_INSTALL))/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).changelog
	cp README.md $(abspath $($@_INSTALL))/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).readme.md
	rm -f $(abspath $($@_PROPERTIES))
	echo "$(PACKAGE_COMMENT)" > $(abspath $($@_PROPERTIES))
	echo "PACKAGE_TYPE = freedom-tools" >> $(abspath $($@_PROPERTIES))
	echo "PACKAGE_DESC_SEG = $(PACKAGE_WORDING)" >> $(abspath $($@_PROPERTIES))
	echo "PACKAGE_FIXED_ID = $(PACKAGE_HEADING)" >> $(abspath $($@_PROPERTIES))
	echo "PACKAGE_BUILD_ID = $(FREEDOM_SDK_UTILITIES_ID)$(EXTRA_SUFFIX)" >> $(abspath $($@_PROPERTIES))
	echo "PACKAGE_CORE_VER = $(RISCV_ISA_SIM_VERSION)" >> $(abspath $($@_PROPERTIES))
	echo "PACKAGE_TARGET = $($@_TARGET)" >> $(abspath $($@_PROPERTIES))
	echo "PACKAGE_VENDOR = SiFive" >> $(abspath $($@_PROPERTIES))
	echo "PACKAGE_RIGHTS = sifive-v00 eclipse-v20" >> $(abspath $($@_PROPERTIES))
	echo "RISCV_TAGS = $(FREEDOM_SDK_UTILITIES_RISCV_TAGS)" >> $(abspath $($@_PROPERTIES))
	echo "TOOLS_TAGS = $(FREEDOM_SDK_UTILITIES_TOOLS_TAGS)" >> $(abspath $($@_PROPERTIES))
	cp $(abspath $($@_PROPERTIES)) $(abspath $($@_INSTALL))/
	tclsh scripts/check-maximum-path-length.tcl $(abspath $($@_INSTALL)) "$(PACKAGE_HEADING)" "$(RISCV_ISA_SIM_VERSION)" "$(FREEDOM_SDK_UTILITIES_ID)$(EXTRA_SUFFIX)"
	tclsh scripts/check-same-name-different-case.tcl $(abspath $($@_INSTALL))
	date > $@

# We might need some extra target libraries for this package
$(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/libs.stamp: \
		$(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/install.stamp
	date > $@

$(OBJ_WIN64)/build/$(PACKAGE_HEADING)/libs.stamp: \
		$(OBJ_WIN64)/build/$(PACKAGE_HEADING)/install.stamp
	-$(WIN64)-gcc -print-search-dirs | grep ^programs | cut -d= -f2- | tr : "\n" | xargs -I {} find {} -iname "libwinpthread*.dll" | xargs cp -t $(OBJDIR)/$(WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64)/bin
	-$(WIN64)-gcc -print-search-dirs | grep ^libraries | cut -d= -f2- | tr : "\n" | xargs -I {} find {} -iname "libgcc_s_seh*.dll" | xargs cp -t $(OBJDIR)/$(WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64)/bin
	-$(WIN64)-gcc -print-search-dirs | grep ^libraries | cut -d= -f2- | tr : "\n" | xargs -I {} find {} -iname "libstdc*.dll" | xargs cp -t $(OBJDIR)/$(WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64)/bin
	-$(WIN64)-gcc -print-search-dirs | grep ^libraries | cut -d= -f2- | tr : "\n" | xargs -I {} find {} -iname "libssp*.dll" | xargs cp -t $(OBJDIR)/$(WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64)/bin
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp:
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/source.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_BUILDLOG := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/source.stamp,%/buildlog/$(PACKAGE_HEADING),$@)))
	tclsh scripts/check-naming-and-version-syntax.tcl "$(PACKAGE_WORDING)" "$(PACKAGE_HEADING)" "$(RISCV_ISA_SIM_VERSION)" "$(FREEDOM_SDK_UTILITIES_ID)$(EXTRA_SUFFIX)"
	rm -rf $($@_INSTALL)
	mkdir -p $($@_INSTALL)
	rm -rf $($@_BUILDLOG)
	mkdir -p $($@_BUILDLOG)
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	git log > $($@_BUILDLOG)/$(PACKAGE_HEADING)-git-commit.log
	cp .gitmodules $($@_BUILDLOG)/$(PACKAGE_HEADING)-git-modules.log
	git remote -v > $($@_BUILDLOG)/$(PACKAGE_HEADING)-git-remote.log
	git submodule status > $($@_BUILDLOG)/$(PACKAGE_HEADING)-git-submodule.log
	cd $(dir $@); curl -L -f -s -o dtc-1.5.0.tar.gz https://github.com/dgibson/dtc/archive/v1.5.0.tar.gz
	cd $(dir $@); $(TAR) -xf dtc-1.5.0.tar.gz
	cd $(dir $@); mv dtc-1.5.0 dtc
	rm -rf $(dir $@)/dtc/Makefile
	cp -a patches/dtc.mk $(dir $@)/dtc/Makefile
	$(SED) -i -f patches/dtc-fstree.sed $(dir $@)/dtc/fstree.c
	cp -a $(SRCPATH_ELF2HEX) $(SRCPATH_ISA_SIM) $(dir $@)
	rm -rf $(dir $@)/$(SRCNAME_ISA_SIM)/Makefile
	cp patches/spike-dasm.mk $(dir $@)/$(SRCNAME_ISA_SIM)/Makefile
	rm -rf $(dir $@)/$(SRCNAME_ISA_SIM)/config.h
	cp patches/spike-dasm-config.h $(dir $@)/$(SRCNAME_ISA_SIM)/config.h
	rm -rf $(dir $@)/$(SRCNAME_ISA_SIM)/riscv/extension.h
	cp patches/spike-dasm-extension.h $(dir $@)/$(SRCNAME_ISA_SIM)/riscv/extension.h
	rm -rf $(dir $@)/$(SRCNAME_ISA_SIM)/riscv/extensions.cc
	cp patches/spike-dasm-extensions.cc $(dir $@)/$(SRCNAME_ISA_SIM)/riscv/extensions.cc
	date > $@

$(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/dtc/build.stamp: \
		$(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/source.stamp
	$(MAKE) -j1 -C $(dir $@) install PREFIX=$(abspath $(OBJ_NATIVE)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(NATIVE)) \
		$($(NATIVE)-dtc-configure) NO_PYTHON=1 NO_YAML=1 NO_VALGRIND=1 &>$(OBJ_NATIVE)/buildlog/$(PACKAGE_HEADING)/dtc-make-install.log
	rm -f $(abspath $(OBJ_NATIVE)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(NATIVE))/lib/lib*.dylib*
	rm -f $(abspath $(OBJ_NATIVE)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(NATIVE))/lib/lib*.so*
	rm -f $(abspath $(OBJ_NATIVE)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(NATIVE))/lib64/lib*.so*
	tclsh scripts/dyn-lib-check-$(NATIVE).tcl $(abspath $(OBJ_NATIVE)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(NATIVE))/bin/dtc
	tclsh scripts/dyn-lib-check-$(NATIVE).tcl $(abspath $(OBJ_NATIVE)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(NATIVE))/bin/fdtdump
	tclsh scripts/dyn-lib-check-$(NATIVE).tcl $(abspath $(OBJ_NATIVE)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(NATIVE))/bin/fdtget
	tclsh scripts/dyn-lib-check-$(NATIVE).tcl $(abspath $(OBJ_NATIVE)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(NATIVE))/bin/fdtoverlay
	tclsh scripts/dyn-lib-check-$(NATIVE).tcl $(abspath $(OBJ_NATIVE)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(NATIVE))/bin/fdtput
	date > $@

$(OBJ_WIN64)/build/$(PACKAGE_HEADING)/dtc/build.stamp: \
		$(OBJ_WIN64)/build/$(PACKAGE_HEADING)/source.stamp
	$(SED) -i -f patches/dtc-lexer.sed $(dir $@)/dtc-lexer.l
	$(MAKE) -j1 -C $(dir $@) install PREFIX=$(abspath $(OBJ_WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64)) \
		$($(WIN64)-dtc-configure) NO_PYTHON=1 NO_YAML=1 NO_VALGRIND=1 &>$(OBJ_WIN64)/buildlog/$(PACKAGE_HEADING)/dtc-make-install.log
	rm -f $(abspath $(OBJ_WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64))/lib/lib*.dylib*
	rm -f $(abspath $(OBJ_WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64))/lib/lib*.so*
	rm -f $(abspath $(OBJ_WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64))/lib64/lib*.so*
	tclsh scripts/dyn-lib-check-$(WIN64).tcl $(abspath $(OBJ_WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64))/bin/dtc
	tclsh scripts/dyn-lib-check-$(WIN64).tcl $(abspath $(OBJ_WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64))/bin/fdtdump
	tclsh scripts/dyn-lib-check-$(WIN64).tcl $(abspath $(OBJ_WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64))/bin/fdtget
	tclsh scripts/dyn-lib-check-$(WIN64).tcl $(abspath $(OBJ_WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64))/bin/fdtoverlay
	tclsh scripts/dyn-lib-check-$(WIN64).tcl $(abspath $(OBJ_WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64))/bin/fdtput
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/$(SRCNAME_ELF2HEX)/build.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/$(SRCNAME_ELF2HEX)/build.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/$(SRCNAME_ELF2HEX)/build.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_BUILDLOG := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/$(SRCNAME_ELF2HEX)/build.stamp,%/buildlog/$(PACKAGE_HEADING),$@)))
	$(MAKE) -C $(dir $@) -j1 install INSTALL_PATH=$(abspath $($@_INSTALL)) \
		$($($@_TARGET)-fe2h-configure) &>$($@_BUILDLOG)/$(SRCNAME_ELF2HEX)-make-install.log
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/util/freedom-bin2hex
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/$(SRCNAME_ISA_SIM)/build.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/dtc/build.stamp \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/$(SRCNAME_ELF2HEX)/build.stamp \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/$(SRCNAME_ISA_SIM)/build.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/$(SRCNAME_ISA_SIM)/build.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_BUILDLOG := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/$(SRCNAME_ISA_SIM)/build.stamp,%/buildlog/$(PACKAGE_HEADING),$@)))
	$(MAKE) -C $(dir $@) -j1 install \
			EXEC_PREFIX=z \
			SOURCE_PATH=$(abspath $(dir $@)) \
			INSTALL_PATH=$(abspath $($@_INSTALL)) \
			$($($@_TARGET)-sdasm-configure) &>$($@_BUILDLOG)/$(SRCNAME_ISA_SIM)-make-install.log
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/zspike-dasm
	date > $@

$(OBJDIR)/$(NATIVE)/test/$(PACKAGE_HEADING)/test.stamp: \
		$(OBJDIR)/$(NATIVE)/test/$(PACKAGE_HEADING)/launch.stamp
	mkdir -p $(dir $@)
#	PATH=$(abspath $(OBJDIR)/$(NATIVE)/launch/$(PACKAGE_TARNAME)/bin):$(PATH) zspike-dasm -h
	@echo "zspike-dasm executable cannot be run with a -v option without failing!"
	@echo "Finished testing $(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(NATIVE).tar.gz tarball"
	date > $@
