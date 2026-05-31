#!/usr/bin/env bash
# Manual uninstaller for glpi-additional-oem.
set -euo pipefail

PREFIX="/usr"
SYSCONFDIR="/etc"
SYSTEMD_DIR="/usr/lib/systemd/system"
REMOVE_CONFIG=0

usage() {
    cat <<'USAGE'
Usage:
  sudo ./scripts/uninstall-manual.sh [options]

Options:
  --prefix PATH        Default: /usr
  --sysconfdir PATH    Default: /etc
  --systemd-dir PATH   Default: /usr/lib/systemd/system
  --remove-config      Remove /etc config files too
  -h, --help           Show help
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prefix)
            PREFIX="$2"
            shift 2
            ;;
        --sysconfdir)
            SYSCONFDIR="$2"
            shift 2
            ;;
        --systemd-dir)
            SYSTEMD_DIR="$2"
            shift 2
            ;;
        --remove-config)
            REMOVE_CONFIG=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "ERROR: run as root" >&2
    exit 1
fi

rm -f "$PREFIX/lib/glpi-agent/glpi-additional-oem"
rm -f "$PREFIX/lib/glpi-agent/glpi-additional-oem-disable-old"
rm -f "$SYSTEMD_DIR/glpi-agent.service.d/10-additional-oem.conf"

if [[ "$REMOVE_CONFIG" -eq 1 ]]; then
    rm -f "$SYSCONFDIR/glpi-agent/conf.d/20-additional-oem.cfg"
    rm -f "$SYSCONFDIR/glpi-additional-oem/bad-uuids.list"
    rm -f "$SYSCONFDIR/glpi-additional-oem/bad-values.list"
fi

if command -v systemctl >/dev/null 2>&1; then
    systemctl daemon-reload || true
fi

echo "OK: glpi-additional-oem removed"
echo "Apply: sudo systemctl restart glpi-agent"
