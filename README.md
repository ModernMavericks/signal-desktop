# Linux Signal on OS X Mavericks (Docker-backed)

Run the current Linux **Signal** desktop app on OS X 10.9, rendered natively
through the [Porthole](../mavericks-porthole) Cocoa Xpra viewer. Signal Desktop
runs in a Docker container (`signal-desktop-gui`) on the docker-machine VM; the Mac side
is a native menu-bar app, not a screen-share. No account/CLI plumbing — Signal
is a GUI-only app, so the launcher (`bin/signal-desktop`) is the whole Mac-side surface.

This is a [ModernMavericks](https://github.com/ModernMavericks) product built on
the **porthole** viewer generator: `signal-desktop.conf` declares the app, and porthole
generates the container recipe (`signal-desktop/`) and the launcher (`bin/signal-desktop`).

## Install

1. **Install Docker for Mavericks** (the `docker-machine` VM) if you haven't —
   this rig drives it and won't install without it.
2. **Download** `mavericks-signal-desktop-X.Y.Z.pkg` from the latest
   [GitHub Release](../../releases/latest).
3. **Right-click the pkg → Open** (first-run Gatekeeper on 10.9), then
   Continue → Install (admin password). Installs `signal-desktop` to `/usr/local/bin/signal-desktop`.
4. Run **`signal-desktop`** — first run builds the container image (a few minutes), then
   opens the native Signal window. It's on-demand: the container stops when you
   quit the viewer.

(From source instead: `make regen` to (re)generate `signal-desktop/` + `bin/signal-desktop` from
`signal-desktop.conf` via the porthole sibling, then `ln -s "$PWD/bin/signal-desktop" /usr/local/bin/signal-desktop`.)

## Use

    signal-desktop              # open Signal (builds the container on first run)
    signal-desktop --rebuild    # rebuild the container image (pick up a newer Signal)

The launcher preflights host prerequisites (Container Tools → VMware Fusion) and,
after a while, nudges you to `signal-desktop --rebuild` when the container is stale or its
xpra drifts from what the viewer speaks. Overrides (caps): `SIGNAL_DESKTOP_STALE_DAYS`,
`SIGNAL_DESKTOP_NO_PREFLIGHT`, `SIGNAL_DESKTOP_NO_RECOVER`, `SIGNAL_DESKTOP_APP`.

## Build

Cross-build the native Porthole viewer for 10.9 (needs the porthole sibling +
`mavericks-shared-cmake`):

    cmake --preset native && cmake --build build-native-signal-desktop --target Porthole
    make pkg            # -> mavericks-signal-desktop-X.Y.Z.pkg

## Tests

    make test          # bats tests/*.bats

BATS suite against stub docker/socat/open; nothing touches the real container.

## Licensing / third-party

`signal-desktop` launches the native Porthole client (built from the
[porthole](../mavericks-porthole) engine), a from-scratch Cocoa Xpra viewer. The
Signal name and icon belong to Signal Messenger; the icon is taken at build time
from your own installed copy and is not redistributed in this repository.
