#!env make
.POSIX:

# Global configuration
include config.mk
#
# Source makefile should include lists of these variables:
#    LIB - name of the library (in lib directory)
#    HDRS - list of headers to install (in install directory)
#    SRCS - list of source files (not in distribution)
#	 DISTS - list of files to include in distribution
#	 GEN - generated files to remove on clean
#    PKGS - list of dependent libraries
#
# Also it can modify some variables:
#    CFLAGS - build flags for C files
#
include $(SUBDIR)/source.mk

esc_builddir != echo $(builddir) | sed -e 's|/|\\\/|g'

destdir != test -n "$(DESTDIR)" && echo "$(DESTDIR)/" | sed 's|/*$$|/|'

INSTALL_LST = install-$(PACKAGE).lst

INSTALL_HDRS != echo $(HDRS) | sed -e 's/include\///g'
INSTALL_LIBS != echo $(LIB) | sed -e 's/lib\///g'

LIB != echo $(LIB) | sed -e 's|\([^ ]\+\)|$(esc_builddir)\/\1|g'

OBJS != echo $(SRCS:.c=.o) | sed -e 's/$(SUBDIR)\//$(esc_builddir)\/$(SUBDIR)\//g'
DEPS != echo $(SRCS:.c=.d) | sed -e 's/$(SUBDIR)\//$(esc_builddir)\/$(SUBDIR)\//g'
PPS != echo $(SRCS:.c=.c.pp) | sed -e 's/$(SUBDIR)\//$(esc_builddir)\/$(SUBDIR)\//g'

.SUFFIXES:
.PHONY: all clean install install-hdrs install-libs uninstall 

INSTALL_LIBS_SCRIPT = \
	for lib in $(INSTALL_LIBS); do \
		target_dir="$(destdir)$(libdir)"; \
		target_lib="$$target_dir/$$lib"; \
		lib_dir="$$(dirname $$lib)"; \
		lib_filename="$$(basename $$lib)"; \
		\
		if [ ! -f "$$target_lib" ]; then \
			echo mkdir -p $$(dirname "$$target_lib"); \
			mkdir -p $$(dirname "$$target_lib"); \
			echo install $$iflags -m 644 "$(builddir)/lib/$$lib" "$$target_dir/$$lib_dir/"; \
			install $$iflags -m 644 "$(builddir)/lib/$$lib" "$$target_dir/$$lib_dir/" && \
				echo $$(realpath "$$target_dir/$$lib_dir/$$lib_filename") >> "$(INSTALL_LST)"; \
		fi \
	done

all: $(HDRS) $(LIB)

$(LIB): $(OBJS)
	mkdir -p $(@D)
	rm -f $@
	$(AR) -rcs $@ $^

$(builddir)/%.o: %.c
	@mkdir -p $(@D)
	$(PP) $(CFLAGS) $< > $(builddir)/$*.c.pp
	$(CC) $(CFLAGS) -MMD -MF $(builddir)/$*.d -c -o $@ $<

install-hdrs:
	@for header in $(INSTALL_HDRS); do \
		target_dir="$(destdir)$(includedir)"; \
		target_hdr="$$target_dir/$$header"; \
		hdr_dir="$$(dirname $$header)"; \
		hdr_filename="$$(basename $$header)"; \
		\
		if [ ! -f "$$target_hdr" ]; then \
			echo mkdir -p $$(dirname "$$target_hdr"); \
			mkdir -p $$(dirname "$$target_hdr"); \
			echo install -m 644 "include/$$header" "$$target_dir/$$hdr_dir/"; \
			install -m 644 "include/$$header" "$$target_dir/$$hdr_dir/" && \
				echo $$(realpath "$$target_dir/$$hdr_dir/$$hdr_filename") >> "$(INSTALL_LST)"; \
		fi \
	done

install-libs:
	@$(INSTALL_LIBS_SCRIPT)

install-strip-libs:
	@iflags=-s; $(INSTALL_LIBS_SCRIPT)
	
install: all install-hdrs install-libs

install-strip: all install-hdrs install-strip-libs

uninstall:
	@cat $(INSTALL_LST) | while IFS= read -r line; do \
		rm -v "$$line"; \
		dir="$$(dirname $$line)"; \
		while [ "$$(echo $$dir/*)" = "$$dir/*" ]; do \
			rm -v -d "$$dir"; \
			dir="$${dir%/*}"; \
		done \
	done
	@rm -v "$(INSTALL_LST)"

dist: $(HDRS) $(DISTS) $(SUBDIR)/source.mk
	test -d "$(tempdir)"
	cp -v -pr --parents $^ "$(tempdir)"

clean:
	rm -rf "$(builddir)/$(SUBDIR)" $(GEN) "$(LIB)" $(TESTS)

distclean:

-include $(DEPS)
