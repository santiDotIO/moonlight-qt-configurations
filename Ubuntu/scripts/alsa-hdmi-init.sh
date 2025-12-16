#!/usr/bin/env bash
set -euo pipefail

# alsa-hdmi-init.sh
#
# Purpose:
# - Ensure HDMI/SPDIF (IEC958) outputs are enabled (often default to "off" after boot)
# - Persist the mixer state so it survives reboot (alsactl store)
#
# Adjust CARD if your ALSA card name differs.
CARD="${CARD:-PCH}"

log() { echo "[alsa-hdmi-init] $*"; }

# Wait for ALSA card/mixer controls to be ready
for _ in $(seq 1 80); do
  if amixer -c "$CARD" scontrols >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done

if ! amixer -c "$CARD" scontrols >/dev/null 2>&1; then
  log "ERROR: ALSA mixer controls not available for CARD=$CARD"
  exit 1
fi

# Force IEC958 switches ON (these can gate HDMI audio on some systems)
# Not all systems expose all indices; ignore failures.
for idx in 0 1 2; do
  amixer -c "$CARD" -q sset "IEC958",${idx} on || true
done
amixer -c "$CARD" -q sset "IEC958" on || true

# Persist state for next reboot
alsactl store "$CARD" >/dev/null 2>&1 || alsactl store >/dev/null 2>&1 || true
log "OK: IEC958 enabled and state stored (CARD=$CARD)"
