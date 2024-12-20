#!env make
.POSIX:

include config.mk

#
# Source makefile should include lists of these variables:
#	TEST - name of the test
#   SRCS - list of source files
#
include $(MKFILE)

TARGET=$(builddir)/$(TEST)

OBJS != echo $(SRCS:.c=.o) | sed -e 's|\([^ ]\+\)|$(builddir)\/\1|g'
DEPS != echo $(SRCS:.c=.d) | sed -e 's/$(SUBDIR)\//$(builddir)\/$(SUBDIR)\//g'
PPS != echo $(SRCS:.c=.c.pp) | sed -e 's/$(SUBDIR)\//$(builddir)\/$(SUBDIR)\//g'

.SUFFIXES:
.PHONY: all tests clean

all: $(TARGET)

$(TARGET): $(OBJS) $(LIBS)
	$(CC) $(CFLAGS) -MMD -MF $(builddir)/$*.d -o $@ $^

$(builddir)/%.o: %.c
	@mkdir -p $(@D)
	$(PP) $(CFLAGS) $< > $(builddir)/$*.c.pp
	$(CC) $(CFLAGS) -MMD -MF $(builddir)/$*.d -c -o $@ $<

dist: $(SRCS) $(MKFILE)
	@test -d "$(tempdir)"
	cp -v -pr --parents $^ "$(tempdir)"

clean:
	rm -rf $(TARGET)

-include $(DEPS)
