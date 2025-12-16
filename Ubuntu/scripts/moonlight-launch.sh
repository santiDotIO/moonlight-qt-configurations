#!/usr/bin/env bash
set -euo pipefail

# moonlight-launch.sh
#
# Purpose:
# - Run Moonlight (AppImage extracted AppRun) inside Cage
# - Force audio through ALSA (and therefore /etc/asound.conf default -> HDMI)
# - Provide stable boot behavior for kiosk usage
#
# You can override MOONLIGHT_APP_RUN via Environment= in the systemd unit if you want.
MOONLIGHT_APP_RUN="${MOONLIGHT_APP_RUN:-/home/santidotio/apps/moonlight/squashfs-root/AppRun}"

log() { echo "[moonlight-launch] $*"; }

# Ensure environment is sane when started from systemd on tty1
export HOME="${HOME:-/home/santidotio}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}"

# Force Moonlight/SDL audio to ALSA (not PipeWire/Pulse)
export PULSE_SERVER=none
export SDL_AUDIODRIVER=alsa

# Light-touch safety: re-assert IEC958 on (harmless if already on)
amixer -c PCH -q sset 'IEC958',0 on || true
amixer -c PCH -q sset 'IEC958',1 on || true
amixer -c PCH -q sset 'IEC958',2 on || true

# Qt env (what you requested)
export QT_QPA_PLATFORM=xcb
export QT_QPA_EGLFS_PHYSICAL_WIDTH=1920
export QT_QPA_EGLFS_PHYSICAL_HEIGHT=1080
export QTMULTIMEDIA_PREFERRED_PLUGINS=alsa
export QT_AUTO_SCREEN_SCALE_FACTOR=1

if [ ! -x "$MOONLIGHT_APP_RUN" ]; then
  log "ERROR: Moonlight AppRun not found or not executable: $MOONLIGHT_APP_RUN"
  exit 1
fi

log "Launching Moonlight: $MOONLIGHT_APP_RUN"
exec "$MOONLIGHT_APP_RUN"
