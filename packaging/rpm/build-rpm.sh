#!/usr/bin/env bash
#
# packaging/rpm/build-rpm.sh
#
# Build RPM/SRPM packages for glpi-additional-oem.
# Works on ClearOS/RHEL/CentOS/Fedora-like systems with rpmbuild installed.
#
# Usage:
#   ./packaging/rpm/build-rpm.sh
#   ./packaging/rpm/build-rpm.sh --topdir /tmp/rpmbuild
#   ./packaging/rpm/build-rpm.sh --srpm
#   ./packaging/rpm/build-rpm.sh --binary
#   ./packaging/rpm/build-rpm.sh --no-deps
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
SPEC_FILE="$SCRIPT_DIR/glpi-additional-oem.spec"

TOPDIR="${RPMBUILD_TOPDIR:-$HOME/rpmbuild}"
BUILD_MODE="-ba"
NODEPS=0
KEEP_TMP=0

usage() {
    cat <<'USAGE'
Використання:
  packaging/rpm/build-rpm.sh [опції]

Опції:
  --topdir DIR    Каталог rpmbuild, типово: ~/rpmbuild або $RPMBUILD_TOPDIR
  --srpm          Зібрати тільки source RPM (-bs)
  --binary        Зібрати тільки binary RPM (-bb)
  --no-deps       Передати rpmbuild параметр --nodeps
  --keep-tmp      Не видаляти тимчасовий каталог
  -h, --help      Показати допомогу

Приклади:
  ./packaging/rpm/build-rpm.sh
  ./packaging/rpm/build-rpm.sh --topdir /tmp/rpmbuild
  ./packaging/rpm/build-rpm.sh --srpm
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --topdir)
            [[ $# -ge 2 ]] || { echo "❌ Для --topdir потрібен шлях" >&2; exit 1; }
            TOPDIR="$2"
            shift 2
            ;;
        --srpm)
            BUILD_MODE="-bs"
            shift
            ;;
        --binary)
            BUILD_MODE="-bb"
            shift
            ;;
        --no-deps)
            NODEPS=1
            shift
            ;;
        --keep-tmp)
            KEEP_TMP=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "❌ Невідома опція: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

need_cmd() {
    local cmd="$1"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "❌ Не знайдено команду: $cmd" >&2
        echo >&2
        echo "Встановлення залежностей:" >&2
        echo "  ClearOS/RHEL/CentOS: yum install rpm-build tar gzip awk findutils" >&2
        echo "  Fedora:              dnf install rpm-build tar gzip awk findutils" >&2
        echo "  Arch Linux:          pacman -S rpm-tools tar gzip gawk findutils" >&2
        exit 1
    fi
}

read_spec_field() {
    local field="$1"

    awk -v f="$field" '
        BEGIN { IGNORECASE = 1 }
        $1 == f":" {
            $1=""
            sub(/^[[:space:]]+/, "")
            print
            exit
        }
    ' "$SPEC_FILE"
}

need_cmd rpmbuild
need_cmd tar
need_cmd gzip
need_cmd awk
need_cmd find
need_cmd install
need_cmd mktemp

[[ -f "$SPEC_FILE" ]] || {
    echo "❌ Не знайдено spec файл: $SPEC_FILE" >&2
    exit 1
}

[[ -x "$PROJECT_ROOT/src/glpi-additional-oem" || -f "$PROJECT_ROOT/src/glpi-additional-oem" ]] || {
    echo "❌ Не знайдено основний скрипт: $PROJECT_ROOT/src/glpi-additional-oem" >&2
    exit 1
}

PKGNAME="$(read_spec_field Name)"
PKGVER="$(read_spec_field Version)"

if [[ -z "$PKGNAME" || -z "$PKGVER" ]]; then
    echo "❌ Не вдалося прочитати Name/Version із: $SPEC_FILE" >&2
    exit 1
fi

BUILDROOT="$TOPDIR"
SOURCE_DIRNAME="$PKGNAME-$PKGVER"
SOURCE_TARBALL="$BUILDROOT/SOURCES/$SOURCE_DIRNAME.tar.gz"
SPEC_DST="$BUILDROOT/SPECS/$PKGNAME.spec"
TMPDIR="$(mktemp -d)"

cleanup() {
    if [[ "$KEEP_TMP" -eq 0 ]]; then
        rm -rf "$TMPDIR"
    else
        echo "ℹ️ Тимчасовий каталог залишено: $TMPDIR"
    fi
}
trap cleanup EXIT

mkdir -p \
    "$BUILDROOT/BUILD" \
    "$BUILDROOT/BUILDROOT" \
    "$BUILDROOT/RPMS" \
    "$BUILDROOT/SOURCES" \
    "$BUILDROOT/SPECS" \
    "$BUILDROOT/SRPMS"

mkdir -p "$TMPDIR/$SOURCE_DIRNAME"

# Copy project files without git/build artifacts.
(
    cd "$PROJECT_ROOT"
    tar \
        --exclude='.git' \
        --exclude='.github' \
        --exclude='*.pkg.tar*' \
        --exclude='*.rpm' \
        --exclude='*.src.rpm' \
        --exclude='*.tar.gz' \
        --exclude='rpmbuild' \
        --exclude='pkg' \
        --exclude='srcpkg' \
        --exclude='src/*.tar.gz' \
        -cf - .
) | tar -C "$TMPDIR/$SOURCE_DIRNAME" -xf -

# Create source tarball with directory name expected by %setup -q.
tar -C "$TMPDIR" -czf "$SOURCE_TARBALL" "$SOURCE_DIRNAME"

install -m 0644 "$SPEC_FILE" "$SPEC_DST"

RPMBUILD_ARGS=("$BUILD_MODE" --define "_topdir $BUILDROOT")
if [[ "$NODEPS" -eq 1 ]]; then
    RPMBUILD_ARGS+=(--nodeps)
fi
RPMBUILD_ARGS+=("$SPEC_DST")

cat <<EOF2
============================================================
 Build RPM: $PKGNAME $PKGVER
============================================================
Project root : $PROJECT_ROOT
RPM topdir   : $BUILDROOT
Source       : $SOURCE_TARBALL
Spec         : $SPEC_DST
Mode         : $BUILD_MODE
Nodeps       : $NODEPS
============================================================
EOF2

rpmbuild "${RPMBUILD_ARGS[@]}"

echo
echo "✅ RPM build завершено."
echo
echo "Готові файли:"
find "$BUILDROOT/RPMS" "$BUILDROOT/SRPMS" \
    -type f \( -name '*.rpm' -o -name '*.src.rpm' \) \
    -print 2>/dev/null | sort || true
