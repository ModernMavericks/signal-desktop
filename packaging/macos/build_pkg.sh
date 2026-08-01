#!/bin/sh
# Build the mavericks-signal-desktop .pkg from the repo's bin/signal-desktop launcher + signal-desktop/ build
# context. Usage: build_pkg.sh <version> <out.pkg>
# NOTE: like mavericks-1password, this stages the launcher + container recipe + the
# shared recovery watcher; the native Porthole viewer is built separately (CMake) and
# located by bin/signal-desktop at runtime.
set -eu
VERSION=$1; OUT=$2
HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../.." && pwd)

# Stage the payload exactly as it should land on disk.
# BSD mktemp (all macOS, incl. 10.9) requires an explicit template.
ROOT=$(mktemp -d "${TMPDIR:-/tmp}/sig-root.XXXXXX")
LIBEXEC="$ROOT/usr/local/libexec/mavericks-signal-desktop"
install -d "$LIBEXEC/bin" "$LIBEXEC/signal-desktop" "$ROOT/usr/local/bin"
install -m 0755 "$REPO/bin/signal-desktop"                     "$LIBEXEC/bin/signal-desktop"
install -m 0755 "${PORTHOLE_DIR:-$REPO/../mavericks-porthole}/bin/porthole-recover-watch" "$LIBEXEC/bin/porthole-recover-watch"
install -m 0644 "$REPO/signal-desktop/Dockerfile"              "$LIBEXEC/signal-desktop/Dockerfile"
install -m 0755 "$REPO/signal-desktop/start-signal-desktop-gui.sh"     "$LIBEXEC/signal-desktop/start-signal-desktop-gui.sh"
install -m 0755 "$REPO/signal-desktop/signal-desktop-child.sh"         "$LIBEXEC/signal-desktop/signal-desktop-child.sh"
install -m 0644 "$REPO/signal-desktop/mac-fonts.conf"          "$LIBEXEC/signal-desktop/mac-fonts.conf"
# bin/signal-desktop finds signal-desktop/ by resolving this relative symlink to bin/signal-desktop, then ../signal-desktop.
ln -s ../libexec/mavericks-signal-desktop/bin/signal-desktop "$ROOT/usr/local/bin/signal-desktop"

COMPONENT_DIR=$(mktemp -d "${TMPDIR:-/tmp}/sig-pkg.XXXXXX")
pkgbuild --root "$ROOT" \
    --identifier dev.modernmavericks.signal-desktop \
    --version "$VERSION" \
    --scripts "$HERE/scripts" \
    --install-location / \
    "$COMPONENT_DIR/mavericks-signal-desktop-component.pkg"

productbuild --distribution "$HERE/distribution.xml" \
    --package-path "$COMPONENT_DIR" \
    "$OUT"

echo "Built $OUT"
