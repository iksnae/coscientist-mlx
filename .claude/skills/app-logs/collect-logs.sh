#!/bin/sh
#
# Collect + filter logs for the CoScientist apps across macOS, the iOS Simulator, and real
# iOS devices. See SKILL.md for the troubleshooting playbook.
#
# Usage:
#   collect-logs.sh mac [minutes]              # macOS app (CoScientistDemo) — no sudo
#   collect-logs.sh sim [minutes]              # booted iOS Simulator — no sudo
#   collect-logs.sh device <udid> [minutes]    # real iOS device — prints the sudo command
#   collect-logs.sh show <archive.logarchive>  # query a collected device archive (no sudo)
#   collect-logs.sh crashes                    # find synced crash reports (.ips)
#   collect-logs.sh devices                    # list connected devices + booted sims
#
# The filter targets the apps + the MLX adapter; widen it inline if you need more.
set -e

FILTER='process CONTAINS[c] "CoScientist" OR senderImagePath CONTAINS[c] "MLX" OR eventMessage CONTAINS[c] "coscientist"'
ERRGREP='error|fail|throw|exception|fatal|crash|metal|gpu|IOGPU|missing|not found|decode|huggingface|cache|insufficient'

cmd="${1:-}"
case "$cmd" in
  mac)
    log show --last "${2:-15}m" --info --debug \
      --predicate 'process CONTAINS[c] "CoScientist"' 2>/dev/null \
      | grep -iE "$ERRGREP" || echo "(no matching lines — try a wider window or no grep)"
    ;;
  sim)
    xcrun simctl list devices booted
    xcrun simctl spawn booted log show --last "${2:-15}m" --info --debug \
      --predicate "$FILTER" 2>/dev/null | grep -iE "$ERRGREP" \
      || echo "(nothing — note: MLX model runs FAIL on the Simulator; use a real device)"
    ;;
  device)
    udid="${2:-}"
    [ -z "$udid" ] && { echo "usage: collect-logs.sh device <udid> [minutes]"; xcrun devicectl list devices; exit 2; }
    out="/tmp/dev-$udid.logarchive"
    echo "Device log collection needs root. Run this yourself (e.g. via '!' in the session):"
    echo "  sudo log collect --device-udid $udid --last ${3:-15}m --output $out"
    echo "Then analyze it (no sudo needed):"
    echo "  $0 show $out"
    ;;
  show)
    archive="${2:?path to a .logarchive}"
    log show "$archive" --info --debug --predicate "$FILTER" 2>/dev/null \
      | grep -iE "$ERRGREP" || echo "(no matching lines in $archive)"
    ;;
  crashes)
    echo "=== macOS (.ips) ==="; ls -t "$HOME"/Library/Logs/DiagnosticReports/CoScientist* 2>/dev/null | head
    echo "=== device (synced via Xcode/Finder) ==="; find "$HOME/Library/Logs/CrashReporter/MobileDevice" -iname "*coscientist*" 2>/dev/null | head
    ;;
  devices)
    echo "=== connected devices ==="; xcrun devicectl list devices 2>/dev/null
    echo "=== booted simulators ==="; xcrun simctl list devices booted 2>/dev/null
    ;;
  *)
    echo "usage: $0 {mac|sim|device <udid>|show <archive>|crashes|devices} [minutes]"; exit 2
    ;;
esac
