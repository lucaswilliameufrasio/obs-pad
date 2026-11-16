FLUTTER ?= flutter
DART ?= dart
GO ?= go
DEVICE ?=
ARGS ?=

.DEFAULT_GOAL := help
.PHONY: help get doctor devices run run-desktop l10n format format-check \
	analyze test validate test-real-obs apk-debug apk-release appbundle \
	build-ios build-desktop-linux build-desktop-macos build-desktop-windows \
	signing-key

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

get: ## Install dependencies for both apps and the shared package
	$(FLUTTER) pub get
	cd packages/obs_pad_companion && $(DART) pub get
	cd companion && $(FLUTTER) pub get

doctor: ## Diagnose the Flutter installation
	$(FLUTTER) doctor

devices: ## List available devices
	$(FLUTTER) devices

run: ## Choose a device and run the phone app (optional: DEVICE=<id>)
	@if [ -n "$(DEVICE)" ]; then \
		$(FLUTTER) run -d "$(DEVICE)" $(ARGS); \
	else \
		OBS_PAD_FLUTTER="$(FLUTTER)" OBS_PAD_DEVICE_KIND=phone $(DART) tool/select_device.dart $(ARGS); \
	fi

run-desktop: ## Choose a device and run the desktop app (optional: DEVICE=<id>)
	@if [ -n "$(DEVICE)" ]; then \
		cd companion && $(FLUTTER) run -d "$(DEVICE)" $(ARGS); \
	else \
		cd companion && OBS_PAD_FLUTTER="$(FLUTTER)" OBS_PAD_DEVICE_KIND=desktop $(DART) ../tool/select_device.dart $(ARGS); \
	fi

l10n: ## Generate phone app translations
	$(FLUTTER) gen-l10n

format: ## Format Dart and Go source files
	$(DART) format lib test tool/select_device.dart companion/lib companion/test packages/obs_pad_companion/lib packages/obs_pad_companion/test
	cd tool/signing-key && gofmt -w .

format-check: ## Check Dart and Go formatting without changing files
	$(DART) format --output=none --set-exit-if-changed lib test tool/select_device.dart companion/lib companion/test packages/obs_pad_companion/lib packages/obs_pad_companion/test
	@cd tool/signing-key && files="$$(gofmt -l .)" && { [ -z "$$files" ] || { printf '%s\n' "$$files"; exit 1; }; }

analyze: ## Analyze both apps, the shared package and the signing tool
	$(FLUTTER) analyze
	cd packages/obs_pad_companion && $(DART) analyze
	cd companion && $(FLUTTER) analyze
	cd tool/signing-key && $(GO) vet ./...

test: ## Run app, shared package, desktop and signing tool tests
	$(FLUTTER) test
	cd packages/obs_pad_companion && $(DART) test
	cd companion && $(FLUTTER) test
	cd tool/signing-key && $(GO) test ./...

validate: format-check analyze test ## Run local formatting, analysis and tests

test-real-obs: ## Run real OBS Docker tests (replaces the named test container)
	tool/obs-docker/run-tests.sh $(ARGS)

apk-debug: ## Build a debug Android APK
	$(FLUTTER) build apk --debug $(ARGS)

apk-release: ## Build a release Android APK (debug-signed if no key is configured)
	$(FLUTTER) build apk --release $(ARGS)

appbundle: ## Build a release Android app bundle
	$(FLUTTER) build appbundle --release $(ARGS)

build-ios: ## Build the iOS app (requires macOS, Xcode and signing)
	$(FLUTTER) build ios --release $(ARGS)

build-desktop-linux: ## Build the Linux desktop app on Linux
	cd companion && $(FLUTTER) build linux --release $(ARGS)

build-desktop-macos: ## Build the macOS desktop app on macOS
	cd companion && $(FLUTTER) build macos --release $(ARGS)

build-desktop-windows: ## Build the Windows desktop app on Windows
	cd companion && $(FLUTTER) build windows --release $(ARGS)

signing-key: ## Open the Android test signing key tool
	mise run chave
