prefix ?= /usr/local
bindir = $(prefix)/bin

build:
	swift build -c release --disable-sandbox

install: build
	install ".build/release/swiftfunc" "$(bindir)/swiftfunc"

uninstall:
	rm -rf "$(bindir)/swiftfunc"

clean:
	rm -rf .build

.PHONY: build install uninstall clean