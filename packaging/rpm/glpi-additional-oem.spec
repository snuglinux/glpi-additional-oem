Name:           glpi-additional-oem
Version:        0.1.1
Release:        1%{?dist}
Summary:        Generate OEM-based GLPI Agent inventory identity data for systems with invalid DMI serials or UUIDs
License:        GPL-3.0-or-later
URL:            https://github.com/snuglinux/glpi-additional-oem
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch

Requires:       bash
Requires:       glpi-agent
Requires:       ethtool
Requires(post): systemd
Requires(postun): systemd

%description
Generate an additional-content JSON file for GLPI Agent on systems with invalid,
missing, or template OEM DMI serials and UUIDs.

%prep
%setup -q

%build
# Nothing to build.

%install
install -Dm0755 src/glpi-additional-oem \
  %{buildroot}%{_prefix}/lib/glpi-agent/glpi-additional-oem

install -Dm0644 config/20-additional-oem.cfg \
  %{buildroot}%{_sysconfdir}/glpi-agent/conf.d/20-additional-oem.cfg

install -Dm0644 config/bad-uuids.list \
  %{buildroot}%{_sysconfdir}/glpi-additional-oem/bad-uuids.list

install -Dm0644 config/bad-values.list \
  %{buildroot}%{_sysconfdir}/glpi-additional-oem/bad-values.list

install -Dm0644 systemd/10-additional-oem.conf \
  %{buildroot}%{_unitdir}/glpi-agent.service.d/10-additional-oem.conf

install -Dm0644 README.md \
  %{buildroot}%{_docdir}/%{name}/README.md

install -Dm0644 LICENSE \
  %{buildroot}%{_licensedir}/%{name}/LICENSE

%post
systemctl daemon-reload >/dev/null 2>&1 || true
cat <<'MSG'
glpi-additional-oem installed.
Check: sudo /usr/lib/glpi-agent/glpi-additional-oem --dry-run --debug
Apply: sudo systemctl restart glpi-agent
MSG

%postun
systemctl daemon-reload >/dev/null 2>&1 || true

%files
%license %{_licensedir}/%{name}/LICENSE
%doc %{_docdir}/%{name}/README.md
%{_prefix}/lib/glpi-agent/glpi-additional-oem
%config(noreplace) %{_sysconfdir}/glpi-agent/conf.d/20-additional-oem.cfg
%config(noreplace) %{_sysconfdir}/glpi-additional-oem/bad-uuids.list
%config(noreplace) %{_sysconfdir}/glpi-additional-oem/bad-values.list
%{_unitdir}/glpi-agent.service.d/10-additional-oem.conf

%changelog
* Sun May 31 2026 snuglinux <snuglinux@users.noreply.github.com> - 0.1.1-1
- Initial package
