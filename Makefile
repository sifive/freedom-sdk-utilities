# Setup the Freedom build script environment
include scripts/Freedom.mk

# Include version identifiers to build up the full version string
include Version.mk
PACKAGE_WORDING := SDK Utilities
PACKAGE_HEADING := sdk-utilities
PACKAGE_VERSION := $(RISCV_ISA_SIM_VERSION)-$(FREEDOM_SDK_UTILITIES_ID)$(EXTRA_SUFFIX)

# Source code directory references
SRCNAME_ISA_SIM := riscv-isa-sim
SRCPATH_ISA_SIM := $(SRCDIR)/$(SRCNAME_ISA_SIM)

# Some special package configure flags for specific targets
$(WIN64)-dtc-configure   := CROSSPREFIX=x86_64-w64-mingw32- BINEXT=.exe CC=gcc
$(WIN64)-sdasm-configure := HOST_PREFIX=x86_64-w64-mingw32- EXEC_SUFFIX=.exe

# Setup the package targets and switch into secondary makefile targets
# Targets $(PACKAGE_HEADING)/install.stamp and $(PACKAGE_HEADING)/libs.stamp
include scripts/Package.mk

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/install.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/$(SRCNAME_ISA_SIM)/build.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/install.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/install.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	mkdir -p $(dir $@)
	mkdir -p $(dir $@)/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).bundle/features
	git log --format="[%ad] %s" > $(abspath $($@_INSTALL))/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).changelog
	cp README.md $(abspath $($@_INSTALL))/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).readme.md
	tclsh scripts/generate-feature-xml.tcl "$(PACKAGE_WORDING)" "$(PACKAGE_HEADING)" "$(RISCV_ISA_SIM_VERSION)" "$(FREEDOM_SDK_UTILITIES_ID)" $($@_TARGET) $(abspath $($@_INSTALL))
	tclsh scripts/generate-chmod755-sh.tcl $(abspath $($@_INSTALL))
	tclsh scripts/generate-site-xml.tcl "$(PACKAGE_WORDING)" "$(PACKAGE_HEADING)" "$(RISCV_ISA_SIM_VERSION)" "$(FREEDOM_SDK_UTILITIES_ID)" $($@_TARGET) $(abspath $(dir $@))/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).bundle
	tclsh scripts/generate-bundle-mk.tcl $(abspath $($@_INSTALL)) RISCV_TAGS "$(FREEDOM_SDK_UTILITIES_RISCV_TAGS)" TOOLS_TAGS "$(FREEDOM_SDK_UTILITIES_TOOLS_TAGS)"
	cp $(abspath $($@_INSTALL))/bundle.mk $(abspath $(dir $@))/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).bundle
	cd $($@_INSTALL); zip -rq $(abspath $(dir $@))/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET).bundle/features/$(PACKAGE_HEADING)_$(FREEDOM_SDK_UTILITIES_ID)_$(RISCV_ISA_SIM_VERSION).jar *
	tclsh scripts/check-maximum-path-length.tcl $(abspath $($@_INSTALL)) "$(PACKAGE_HEADING)" "$(RISCV_ISA_SIM_VERSION)" "$(FREEDOM_SDK_UTILITIES_ID)"
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
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/source.stamp,%/rec/$(PACKAGE_HEADING),$@)))
	tclsh scripts/check-naming-and-version-syntax.tcl "$(PACKAGE_WORDING)" "$(PACKAGE_HEADING)" "$(RISCV_ISA_SIM_VERSION)" "$(FREEDOM_SDK_UTILITIES_ID)"
	rm -rf $($@_INSTALL)
	mkdir -p $($@_INSTALL)
	rm -rf $($@_REC)
	mkdir -p $($@_REC)
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	git log > $($@_REC)/$(PACKAGE_HEADING)-git-commit.log
	cp .gitmodules $($@_REC)/$(PACKAGE_HEADING)-git-modules.log
	git remote -v > $($@_REC)/$(PACKAGE_HEADING)-git-remote.log
	git submodule status > $($@_REC)/$(PACKAGE_HEADING)-git-submodule.log
	cd $($@_REC); curl -L -f -s -o dtc-1.5.0.tar.gz https://github.com/dgibson/dtc/archive/v1.5.0.tar.gz
	cd $(dir $@); $(TAR) -xf $($@_REC)/dtc-1.5.0.tar.gz
	cd $(dir $@); mv dtc-1.5.0 dtc
	rm -rf $(dir $@)/dtc/Makefile
	cp -a $(PATCHESDIR)/dtc.mk $(dir $@)/dtc/Makefile
	$(SED) -i -f $(PATCHESDIR)/dtc-fstree.sed $(dir $@)/dtc/fstree.c
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

$(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/dtc/build.stamp: \
		$(OBJ_NATIVE)/build/$(PACKAGE_HEADING)/source.stamp
	$(MAKE) -j1 -C $(dir $@) install PREFIX=$(abspath $(OBJ_NATIVE)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(NATIVE)) \
		$($(NATIVE)-dtc-configure) NO_PYTHON=1 NO_YAML=1 NO_VALGRIND=1 &>$(OBJ_NATIVE)/rec/$(PACKAGE_HEADING)/dtc-make-install.log
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
	$(SED) -i -f $(PATCHESDIR)/dtc-lexer.sed $(dir $@)/dtc-lexer.l
	$(MAKE) -j1 -C $(dir $@) install PREFIX=$(abspath $(OBJ_WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64)) \
		$($(WIN64)-dtc-configure) NO_PYTHON=1 NO_YAML=1 NO_VALGRIND=1 &>$(OBJ_WIN64)/rec/$(PACKAGE_HEADING)/dtc-make-install.log
	rm -f $(abspath $(OBJ_WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64))/lib/lib*.dylib*
	rm -f $(abspath $(OBJ_WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64))/lib/lib*.so*
	rm -f $(abspath $(OBJ_WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64))/lib64/lib*.so*
	tclsh scripts/dyn-lib-check-$(WIN64).tcl $(abspath $(OBJ_WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64))/bin/dtc
	tclsh scripts/dyn-lib-check-$(WIN64).tcl $(abspath $(OBJ_WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64))/bin/fdtdump
	tclsh scripts/dyn-lib-check-$(WIN64).tcl $(abspath $(OBJ_WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64))/bin/fdtget
	tclsh scripts/dyn-lib-check-$(WIN64).tcl $(abspath $(OBJ_WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64))/bin/fdtoverlay
	tclsh scripts/dyn-lib-check-$(WIN64).tcl $(abspath $(OBJ_WIN64)/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(WIN64))/bin/fdtput
	date > $@

$(OBJDIR)/%/build/$(PACKAGE_HEADING)/$(SRCNAME_ISA_SIM)/build.stamp: \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/dtc/build.stamp \
		$(OBJDIR)/%/build/$(PACKAGE_HEADING)/source.stamp
	$(eval $@_TARGET := $(patsubst $(OBJDIR)/%/build/$(PACKAGE_HEADING)/$(SRCNAME_ISA_SIM)/build.stamp,%,$@))
	$(eval $@_INSTALL := $(patsubst %/build/$(PACKAGE_HEADING)/$(SRCNAME_ISA_SIM)/build.stamp,%/install/$(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$($@_TARGET),$@))
	$(eval $@_REC := $(abspath $(patsubst %/build/$(PACKAGE_HEADING)/$(SRCNAME_ISA_SIM)/build.stamp,%/rec/$(PACKAGE_HEADING),$@)))
	$(MAKE) -C $(dir $@) -j1 install \
			EXEC_PREFIX=z \
			SOURCE_PATH=$(abspath $(dir $@)) \
			INSTALL_PATH=$(abspath $($@_INSTALL)) \
			$($($@_TARGET)-sdasm-configure) &>$($@_REC)/$(SRCNAME_ISA_SIM)-make-install.log
	tclsh scripts/dyn-lib-check-$($@_TARGET).tcl $(abspath $($@_INSTALL))/bin/zspike-dasm
	date > $@

$(OBJDIR)/$(NATIVE)/test/$(PACKAGE_HEADING)/test.stamp: \
		$(OBJDIR)/$(NATIVE)/test/$(PACKAGE_HEADING)/launch.stamp
	mkdir -p $(dir $@)
#	PATH=$(abspath $(OBJDIR)/$(NATIVE)/launch/$(PACKAGE_TARNAME)/bin):$(PATH) zspike-dasm -h
	@echo "zspike-dasm executable cannot be run with a -v option without failing!"
	@echo "Finished testing $(PACKAGE_HEADING)-$(PACKAGE_VERSION)-$(NATIVE).tar.gz tarball"
	date > $@
