#!/usr/bin/env bash
# Compatibility wrapper. Main RPM builder lives in packaging/rpm/build-rpm.sh.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
exec "$PROJECT_ROOT/packaging/rpm/build-rpm.sh" "$@"
