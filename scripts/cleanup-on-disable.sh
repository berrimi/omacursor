#!/bin/sh
# Cleanup for omacursor teardown. With --check, exits 0 iff the plugin is
# still wanted (present in shell.json), without touching anything: the
# service gates every apply on it. Without args, waits a few seconds, then
# restores the stock cursor unless the plugin is still wanted — so disable
# and remove clean up while a shell restart (entry intact) is a no-op.
# Best-effort throughout: never fail loudly from a teardown path.
ID="io.github.berrimi.omacursor"
CFG="$HOME/.config/omarchy/shell.json"
DIR="$HOME/.config/omarchy/plugins/$ID"
RUNDIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/omacursor"

wanted() {
  # The bar entry is the source of truth: disabling drops it while leaving a
  # stale plugins[] entry behind, so plugins[] must not count here.
  [ -d "$DIR" ] || return 1
  [ -f "$CFG" ] || return 1
  command -v jq >/dev/null 2>&1 || return 0
  jq -e --arg id "$ID" '([.bar.layout[][]?.id] | index($id)) != null' "$CFG" >/dev/null 2>&1
}

if [ "$1" = "--check" ]; then
  if wanted; then exit 0; else exit 1; fi
fi

sleep 3
if wanted; then exit 0; fi
BASELINE="default"
SIZE="24"
STATE="$RUNDIR/cursor-theme.json"
if [ -f "$STATE" ] && command -v jq >/dev/null 2>&1; then
  BASELINE="$(jq -r '.baselineTheme // "default"' "$STATE" 2>/dev/null || echo default)"
  SIZE="$(jq -r '.baselineSize // 24' "$STATE" 2>/dev/null || echo 24)"
fi
if command -v hyprctl >/dev/null 2>&1; then
  hyprctl setcursor "$BASELINE" "$SIZE" >/dev/null 2>&1
  # Re-resolve without moving the pointer: blink invisible, restore baseline.
  if command -v jq >/dev/null 2>&1; then
    VIS="$(hyprctl -j getoption cursor:invisible 2>/dev/null | jq -r '.bool' 2>/dev/null)"
    if [ "$VIS" = true ] || [ "$VIS" = false ]; then
      hyprctl eval "hl.config { cursor = { invisible = true } }" >/dev/null 2>&1
      sleep 0.04
      hyprctl eval "hl.config { cursor = { invisible = $VIS } }" >/dev/null 2>&1
    fi
  fi
fi
rm -rf "$HOME/.local/share/icons/omacursor-runtime" "$RUNDIR"
exit 0
