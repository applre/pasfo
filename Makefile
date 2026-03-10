APP_NAME = pasfo
BUILD_DIR = .build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
SIGN_IDENTITY = Developer ID Application: YUMENG LI (ASDYG8KG8Q)
NOTARY_PROFILE = pasfo-notary

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

dmg: build
	codesign --force --deep --options runtime --sign "$(SIGN_IDENTITY)" "$(APP_BUNDLE)"
	rm -f "$(BUILD_DIR)/Pasfo.dmg"
	mkdir -p "$(BUILD_DIR)/dmg"
	cp -r "$(APP_BUNDLE)" "$(BUILD_DIR)/dmg/"
	ln -sf /Applications "$(BUILD_DIR)/dmg/Applications"
	hdiutil create -volname "Pasfo" -srcfolder "$(BUILD_DIR)/dmg" -ov -format UDZO "$(BUILD_DIR)/Pasfo.dmg"
	rm -rf "$(BUILD_DIR)/dmg"
	@echo "Created $(BUILD_DIR)/Pasfo.dmg"

notarize: dmg
	xcrun notarytool submit "$(BUILD_DIR)/Pasfo.dmg" --keychain-profile "$(NOTARY_PROFILE)" --wait
	xcrun stapler staple "$(BUILD_DIR)/Pasfo.dmg"
	@echo "Notarized $(BUILD_DIR)/Pasfo.dmg"

install: build
	cp -r "$(APP_BUNDLE)" /Applications/
	@echo "Installed to /Applications/$(APP_NAME).app"
