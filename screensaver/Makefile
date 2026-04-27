NAME    := TrendsScreensaver
SAVER   := build/$(NAME).saver
BIN     := $(SAVER)/Contents/MacOS/$(NAME)
RES     := $(SAVER)/Contents/Resources
SRC     := Sources/TrendsView.swift
WEB_SRC := ../web
INSTALL_DIR := $(HOME)/Library/Screen Savers
ARCH    := $(shell uname -m)

.PHONY: all clean install uninstall

all: $(BIN)

$(BIN): $(SRC) Resources/Info.plist $(WEB_SRC)/index.html $(WEB_SRC)/styles.css $(WEB_SRC)/app.js
	@rm -rf $(SAVER)
	@mkdir -p $(SAVER)/Contents/MacOS
	@mkdir -p $(RES)/web
	cp Resources/Info.plist $(SAVER)/Contents/Info.plist
	cp $(WEB_SRC)/index.html $(WEB_SRC)/styles.css $(WEB_SRC)/app.js $(RES)/web/
	@if [ -f $(WEB_SRC)/trends.json ]; then cp $(WEB_SRC)/trends.json $(RES)/web/; fi
	swiftc -emit-library -Xlinker -bundle \
		-module-name $(NAME) \
		-target $(ARCH)-apple-macosx11.0 \
		-framework ScreenSaver -framework AppKit \
		-o $(BIN) \
		$(SRC)
	codesign --force --sign - $(SAVER)
	@echo "Built $(SAVER)"

install: all
	rm -rf "$(INSTALL_DIR)/$(NAME).saver"
	mkdir -p "$(INSTALL_DIR)"
	cp -R $(SAVER) "$(INSTALL_DIR)/"
	@echo "Installed to $(INSTALL_DIR)/$(NAME).saver"
	@echo "Open System Settings → Screen Saver to select it."

uninstall:
	rm -rf "$(INSTALL_DIR)/$(NAME).saver"

clean:
	rm -rf build
