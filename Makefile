# Prism Login Manager: make install [PREFIX=/usr] [DESTDIR=]
PREFIX  ?= /usr
DESTDIR ?=
SHARE   := $(DESTDIR)$(PREFIX)/share/plm
BIN     := $(DESTDIR)$(PREFIX)/bin

.PHONY: install uninstall shaders icons check

install:
	install -d $(SHARE) $(BIN)
	cp -r --no-preserve=ownership shell themes $(SHARE)/
	find $(SHARE) -name '__pycache__' -prune -exec rm -rf {} +
	install -Dm644 data/plm.json        $(SHARE)/data/plm.json
	install -Dm644 data/greetd.toml     $(SHARE)/data/greetd.toml
	install -Dm644 data/compositor/hyprland.lua $(SHARE)/data/compositor/hyprland.lua
	install -Dm644 data/compositor/sway.conf    $(SHARE)/data/compositor/sway.conf
	install -Dm644 data/systemd/plm-sync.path    $(SHARE)/data/systemd/plm-sync.path
	install -Dm644 data/systemd/plm-sync.service $(SHARE)/data/systemd/plm-sync.service
	chmod 755 $(SHARE)/shell/scripts/plm-helper $(SHARE)/shell/scripts/gen-icons.py $(SHARE)/shell/shaders/build.sh
	install -Dm755 bin/plm         $(BIN)/plm
	install -Dm755 bin/plm-session $(BIN)/plm-session
	install -Dm644 README.md $(DESTDIR)$(PREFIX)/share/doc/plm/README.md

uninstall:
	rm -rf $(SHARE) $(DESTDIR)$(PREFIX)/share/doc/plm
	rm -f $(BIN)/plm $(BIN)/plm-session

# developer helpers
shaders:
	shell/shaders/build.sh

icons:
	python3 shell/scripts/gen-icons.py

check:
	sh -n bin/plm-session shell/scripts/plm-helper install.sh
	python3 -m py_compile bin/plm
	Hyprland --verify-config -c data/compositor/hyprland.lua | tail -1
