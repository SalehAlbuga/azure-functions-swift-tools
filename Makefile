prefix ?= /usr/local
bindir = $(prefix)/bin
libdir = $(prefix)/lib

build:
	swift build -c release --disable-sandbox

install: build
	install -d "$(bindir)"
	install -d "$(libdir)"
	install ".build/release/swiftfunc" "$(bindir)"
	install ".build/release/libSwiftPM.dylib" "$(libdir)"
	install_name_tool -change \
		".build/x86_64-apple-macosx/release/libSwiftPM.dylib" \
		"$(libdir)/libSwiftPM.dylib" \
		"$(bindir)/swiftfunc"

uninstall:
	rm -rf "$(bindir)/swiftfunc"
	rm -rf "$(libdir)/libSwiftPM.dylib"

clean:
	rm -rf .build

.PHONY: build install uninstall clean