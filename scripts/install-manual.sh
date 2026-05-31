#!/usr/bin/env bash
# Manual installer for glpi-additional-oem.
set -euo pipefail

PREFIX="/usr"
SYSCONFDIR="/etc"
SYSTEMD_DIR="/usr/lib/systemd/system"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

usage() {
    cat <<'USAGE'
Usage:
  sudo ./scripts/install-manual.sh [options]

Options:
  --prefix PATH        Default: /usr
  --sysconfdir PATH    Default: /etc
  --systemd-dir PATH   Default: /usr/lib/systemd/system
  --no-systemd         Do not install systemd drop-in
  --restart-agent      Restart glpi-agent after install
  --no-disable-old     Do not comment old additional-content directives
  -h, --help           Show help
USAGE
}

INSTALL_SYSTEMD=1
RESTART_AGENT=0
DISABLE_OLD=1

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
        --no-systemd)
            INSTALL_SYSTEMD=0
            shift
            ;;
        --restart-agent)
            RESTART_AGENT=1
            shift
            ;;
        --no-disable-old)
            DISABLE_OLD=0
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

install -Dm0755 "$ROOT_DIR/src/glpi-additional-oem" \
    "$PREFIX/lib/glpi-agent/glpi-additional-oem"

install -Dm0755 "$ROOT_DIR/src/glpi-additional-oem-disable-old" \
    "$PREFIX/lib/glpi-agent/glpi-additional-oem-disable-old"

install -Dm0644 "$ROOT_DIR/config/20-additional-oem.cfg" \
    "$SYSCONFDIR/glpi-agent/conf.d/20-additional-oem.cfg"

install -Dm0644 "$ROOT_DIR/config/bad-uuids.list" \
    "$SYSCONFDIR/glpi-additional-oem/bad-uuids.list"

install -Dm0644 "$ROOT_DIR/config/bad-values.list" \
    "$SYSCONFDIR/glpi-additional-oem/bad-values.list"

if [[ "$INSTALL_SYSTEMD" -eq 1 ]]; then
    install -Dm0644 "$ROOT_DIR/systemd/10-additional-oem.conf" \
        "$SYSTEMD_DIR/glpi-agent.service.d/10-additional-oem.conf"

    if command -v systemctl >/dev/null 2>&1; then
        systemctl daemon-reload || true
    fi
fi

if [[ "$DISABLE_OLD" -eq 1 ]]; then
    "$PREFIX/lib/glpi-agent/glpi-additional-oem-disable-old" || true
fi

echo "OK: glpi-additional-oem installed"
echo "Check: sudo $PREFIX/lib/glpi-agent/glpi-additional-oem --dry-run --debug"

if [[ "$RESTART_AGENT" -eq 1 ]]; then
    if command -v systemctl >/dev/null 2>&1; then
        systemctl restart glpi-agent
        echo "OK: glpi-agent restarted"
    else
        echo "WARN: systemctl not found, glpi-agent was not restarted" >&2
    fi
else
    echo "Apply: sudo systemctl restart glpi-agent"
fi
