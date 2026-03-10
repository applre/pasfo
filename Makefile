APP_NAME = pasfo
BUILD_DIR = .build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app

.PHONY: build run clean test

build:
	swift build -c release
	mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	cp $(BUILD_DIR)/release/$(APP_NAME) "$(APP_BUNDLE)/Contents/MacOS/"
	cp Resources/Info.plist "$(APP_BUNDLE)/Contents/"
	cp Resources/AppIcon.icns "$(APP_BUNDLE)/Contents/Resources/"

run: build
	open "$(APP_BUNDLE)"

debug:
	-@killall $(APP_NAME) 2>/dev/null; sleep 0.3
	swift build
	mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	cp $(BUILD_DIR)/debug/$(APP_NAME) "$(APP_BUNDLE)/Contents/MacOS/"
	cp Resources/Info.plist "$(APP_BUNDLE)/Contents/"
	cp Resources/AppIcon.icns "$(APP_BUNDLE)/Contents/Resources/"
	open "$(APP_BUNDLE)"

test:
	swift test

clean:
	swift package clean
	rm -rf "$(APP_BUNDLE)"

install: build
	cp -r "$(APP_BUNDLE)" /Applications/
	@echo "Installed to /Applications/$(APP_NAME).app"
