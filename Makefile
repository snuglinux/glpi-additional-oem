PREFIX ?= /usr
SYSCONFDIR ?= /etc
SYSTEMD_DIR ?= /usr/lib/systemd/system
DESTDIR ?=

.PHONY: install uninstall check dist

install:
	install -Dm0755 src/glpi-additional-oem "$(DESTDIR)$(PREFIX)/lib/glpi-agent/glpi-additional-oem"
	install -Dm0644 config/20-additional-oem.cfg "$(DESTDIR)$(SYSCONFDIR)/glpi-agent/conf.d/20-additional-oem.cfg"
	install -Dm0644 config/bad-uuids.list "$(DESTDIR)$(SYSCONFDIR)/glpi-additional-oem/bad-uuids.list"
	install -Dm0644 config/bad-values.list "$(DESTDIR)$(SYSCONFDIR)/glpi-additional-oem/bad-values.list"
	install -Dm0644 systemd/10-additional-oem.conf "$(DESTDIR)$(SYSTEMD_DIR)/glpi-agent.service.d/10-additional-oem.conf"

uninstall:
	rm -f "$(DESTDIR)$(PREFIX)/lib/glpi-agent/glpi-additional-oem"
	rm -f "$(DESTDIR)$(SYSTEMD_DIR)/glpi-agent.service.d/10-additional-oem.conf"

check:
	bash -n src/glpi-additional-oem
	bash -n scripts/install-manual.sh
	bash -n scripts/uninstall-manual.sh
	bash -n scripts/build-rpm.sh
	bash -n packaging/rpm/build-rpm.sh

dist:
	tar --exclude='.git' -czf glpi-additional-oem.tar.gz .
