#!/usr/bin/env bats
# Product tests for Linux Signal: the generated container recipe + launcher.
# Self-contained (builds its own stubs); nothing touches a real container.

@test "Signal Dockerfile installs signal-desktop from Signal's apt repo, not 1Password/VNC" {
  df="${BATS_TEST_DIRNAME}/../signal-desktop/Dockerfile"
  grep -q 'updates.signal.org/desktop/apt' "$df" || return 1
  grep -q 'apt-get install -y signal-desktop xpra=6.5.2-r0-1 xvfb' "$df" || return 1
  # must NOT drag in the 1Password/VNC baggage -- check non-comment lines only
  # (comments legitimately mention what we dropped).
  ! grep -v '^[[:space:]]*#' "$df" | grep -qiE '1password|tigervnc|openbox|cups' || return 1
}

@test "Signal entrypoint + child are valid sh and launch signal-desktop under xpra" {
  sh -n "${BATS_TEST_DIRNAME}/../signal-desktop/start-signal-desktop-gui.sh" || return 1
  sh -n "${BATS_TEST_DIRNAME}/../signal-desktop/signal-desktop-child.sh" || return 1
  grep -q 'xpra start' "${BATS_TEST_DIRNAME}/../signal-desktop/start-signal-desktop-gui.sh" || return 1
  grep -q 'encodings=rgb' "${BATS_TEST_DIRNAME}/../signal-desktop/start-signal-desktop-gui.sh" || return 1
  grep -q 'exec signal-desktop' "${BATS_TEST_DIRNAME}/../signal-desktop/signal-desktop-child.sh" || return 1
}

@test "bin/signal launches the Signal viewer pointed at the xpra tunnel" {
  tmp="$(mktemp -d -t signaltest)"
  cat > "$tmp/docker" <<'EOF'
#!/bin/sh
case "$1 $2" in
  "container inspect") exit 0 ;;
esac
case "$*" in
  *"inspect -f"*) echo true ;;
  *"ps -eo args"*) exit 0 ;;
  *) : ;;
esac
exit 0
EOF
  cat > "$tmp/open" <<EOF
#!/bin/sh
echo "open \$*" >> "$tmp/log"
EOF
  printf '#!/bin/sh\nexit 0\n' > "$tmp/socat"
  printf '#!/bin/sh\nexit 0\n' > "$tmp/docker-machine"
  chmod +x "$tmp"/docker "$tmp"/open "$tmp"/socat "$tmp"/docker-machine
  mkdir -p "$tmp/app/build-native-signal-desktop/porthole/viewer/Porthole.app"
  run env PATH="$tmp:$PATH" SIGNAL_DESKTOP_NO_PREFLIGHT=1 \
        SIGNAL_DESKTOP_APP="$tmp/app/build-native-signal-desktop/porthole/viewer/Porthole.app" \
        "${BATS_TEST_DIRNAME}/../bin/signal-desktop"
  [ "$status" -eq 0 ] || { echo "$output"; return 1; }
  grep -q 'open .*Porthole.app --args .*/signal-desktop-xpra.sock' "$tmp/log" || { cat "$tmp/log"; return 1; }
  [[ "$output" == *"launched -> "*"/signal-desktop-xpra.sock"* ]] || return 1
}

@test "bin/signal stops the Signal container when the viewer quits (on-demand)" {
  b="${BATS_TEST_DIRNAME}/../bin/signal-desktop"
  grep -q 'RW_ONDEMAND=1' "$b" || return 1
  grep -q 'porthole-recover-watch' "$b" || return 1
  # guarded so the launcher test's stub app (no binary) doesn't spawn a watcher
  grep -q 'if \[ -x "$_bin" \]' "$b" || return 1
}

@test "bin/signal auto-recovers the viewer on a lost backend (marker)" {
  b="${BATS_TEST_DIRNAME}/../bin/signal-desktop"
  grep -q 'MARKER="${XPRA_SOCK%-xpra.sock}-viewer-lost"' "$b" || return 1
  grep -q 'RW_RELAUNCH="$0"' "$b" || return 1       # recovery re-invokes the launcher
  grep -q 'WATCH_PID' "$b" || return 1              # spawn guarded (no stacking)
}
