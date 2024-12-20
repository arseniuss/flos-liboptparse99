#!env make

#
# flos/liboptparse99
#
# Copyright (c) 2024 Armands Arseniuss Skolmeisters <arseniuss@arseniuss.id.lv>
# Copyright (c) 2022 hippie68 (https://github.com/hippie68/optparse99)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

.POSIX:

include config.mk

TARGET = lib/liboptparse99.a

tempdir != mktemp -d
tempfile != tempfile
real_srcdir != realpath "$(srcdir)"

.SUFFIXES:
.PHONY: all check install install-strip uninstall dist pkg clean distclean

TRIPLE != $(CC) -dumpmachine

TARGET != echo $(TARGET) | sed -e 's|\([^ ]\+\)|$(builddir)\/\1|g'

all: $(TARGET)

$(TARGET): libs.mk source/source.mk
	$(MAKE) -f libs.mk SUBDIR=source

check: # nothing yet

install: $(TARGET)
	$(MAKE) -f libs.mk SUBDIR=source install

install-strip: $(TARGET)
	$(MAKE) -f libs.mk SUBDIR=source install-strip

uninstall:
	$(MAKE) -f libs.mk SUBDIR=source uninstall

dist: $(EXTRA)
	cp -v -pr --parents $^ "$(tempdir)"
	$(MAKE) -f libs.mk SUBDIR=source dist tempdir="$(tempdir)"
	@for test in $(TESTS); do \
		echo $(MAKE) -f tests.mk MKFILE="$$test.mk" dist; \
		$(MAKE) -f tests.mk MKFILE="$$test.mk" dist tempdir="$(tempdir)"; \
	done
	cd "$(tempdir)" && find . -type f -print > ../pkg.lst
	cd "$(tempdir)" && tar zcvf $(real_srcdir)/$(PACKAGE)-$(VERSION).tar.gz `cat ../pkg.lst` | sort
	+rm -rf "$(tempdir)" "$(tempdir)/../pkg.lst"

pkg: all
	$(MAKE) install-strip DESTDIR="$(tempdir)" INSTALL_LST=$(tempfile)
	rm $(tempfile)
	cp package.cfg "$(tempdir)"
	cd "$(tempdir)" && find . -type f -print > ../pkg.lst
	cd "$(tempdir)" && tar zcvf $(real_srcdir)/$(PACKAGE)-$(VERSION)-$(TRIPLE).tar.gz `cat ../pkg.lst`
	+rm -rf "$(tempdir)" "$(tempdir)/../pkg.lst"

clean:
	$(MAKE) -f libs.mk SUBDIR=source clean
	rm -rf $(builddir)

distclean: clean
	rm -rf deps config.mk
