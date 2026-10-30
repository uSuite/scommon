# scommon build entry points. Every command a session needs is a target here.

VERSION := $(shell cat VERSION)
CLT := /Library/Developer/CommandLineTools

# Use Xcode when it is usable (licence accepted), else fall back to the
# Command Line Tools, whose Swift Testing macros need an explicit plugin path.
XCODE_OK := $(shell xcrun swift --version >/dev/null 2>&1 && echo yes)
ifeq ($(XCODE_OK),yes)
SWIFT := swift
SWIFTC := xcrun swiftc
TEST_FLAGS :=
else
SWIFT := DEVELOPER_DIR=$(CLT) swift
SWIFTC := DEVELOPER_DIR=$(CLT) xcrun swiftc
TEST_FLAGS := -Xswiftc -plugin-path -Xswiftc $(CLT)/usr/lib/swift/host/plugins/testing
endif
SDK := $(shell xcrun --show-sdk-path)
SOURCES := $(wildcard Sources/SCommon/*.swift)

.PHONY: build test lint clean version

build:
	$(SWIFT) build

test:
	$(SWIFT) test $(TEST_FLAGS)

# Type-checks each file as the primary file of the module, so a file that
# leans on another file's imports fails here rather than in a consumer.
lint:
	@for file in $(SOURCES); do \
		others=$$(for other in $(SOURCES); do [ $$other = $$file ] || echo $$other; done); \
		$(SWIFTC) -frontend -typecheck -swift-version 6 -module-name SCommon \
			-sdk $(SDK) -target $(shell uname -m)-apple-macos26.0 \
			-primary-file $$file $$others || exit 1; \
		echo "ok $$file"; \
	done

clean:
	rm -rf .build build

version:
	@echo $(VERSION)
