prefix ?= /usr/local
bindir = $(prefix)/bin

build:
	swift build -c release --disable-sandbox

install: build
	install ".build/release/swiftfunc" "$(bindir)"

uninstall:
	rm -rf "$(bindir)/swiftfunc"

clean:
	rm -rf .build

.PHONY: build install uninstall clean