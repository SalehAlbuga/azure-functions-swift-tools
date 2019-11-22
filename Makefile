SHELL = /bin/bash

prefix ?= /usr/local
bindir ?= $(prefix)/bin/
srcdir = Sources

REPODIR = $(shell pwd)
BUILDDIR = $(REPODIR)/.build
SOURCES = $(wildcard $(srcdir)/**/*.swift)

.DEFAULT_GOAL = all

.PHONY: all
all: swiftfunc

swiftfunc: $(SOURCES)
	@swift build \
		-c release \
		--disable-sandbox \
		--build-path "$(BUILDDIR)"

.PHONY: install
install: swiftfunc
	@install "$(BUILDDIR)/release/swiftfunc" "$(bindir)"

.PHONY: uninstall
uninstall:
	@rm -rf "$(bindir)/swiftfunc"

.PHONY: clean
distclean:
	@rm -f $(BUILDDIR)/release

.PHONY: clean
clean: distclean
	@rm -rf $(BUILDDIR)
