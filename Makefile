prefix ?= /usr/local
linux_prefix ?= /usr
bindir = $(prefix)/bin
libdir = $(prefix)/lib
uname_str = $(shell uname -s)
linux_lib_dir = $(linux_prefix)/lib/swift/linux

build:
	swift build -c release --disable-sandbox

install: build
	install -d "$(bindir)/"
	install -d "$(libdir)/"

	install ".build/release/swiftfunc" "$(bindir)"

    ifeq ($(uname_str),Linux)
		install ".build/x86_64-unknown-linux-gnu/release/libSwiftPM.so" "$(linux_lib_dir)"
    endif
    ifeq ($(uname_str),Darwin)
		install ".build/x86_64-apple-macosx/release/libSwiftPM.dylib" "$(libdir)"
		install_name_tool -change \
			".build/x86_64-apple-macosx/release/libSwiftPM.dylib" \
			"$(libdir)/libSwiftPM.dylib" \
			"$(bindir)/swiftfunc"
    endif
	

uninstall:
	rm -rf "$(bindir)/swiftfunc"

clean:
	rm -rf .build

.PHONY: build install uninstall clean