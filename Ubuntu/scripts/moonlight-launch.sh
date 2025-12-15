#!/bin/bash
set -euo pipefail

# Make sure we have a reasonable PATH in systemd contexts
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Ensure HOME is set (some service contexts can be weird)
export HOME="${HOME:-$(getent passwd "$(id -u)" | cut -d: -f6)}"

# Setup environment
USER_ID="$(id -u)"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/${USER_ID}}"

if [ ! -d "$XDG_RUNTIME_DIR" ]; then
  echo "XDG_RUNTIME_DIR missing: $XDG_RUNTIME_DIR (run this as a user service with linger)"
fi

DRM_CARD="$(ls /dev/dri/card* 2>/dev/null | head -n1 || true)"
while [ -z "$DRM_CARD" ]; do
  echo "Waiting for DRM card device..."
  sleep 1
  DRM_CARD="$(ls /dev/dri/card* 2>/dev/null | head -n1 || true)"
done
echo "Using DRM device: $DRM_CARD"

# Wait for ALSA devices (do not assume card 0/1)
while ! aplay -l 2>/dev/null | grep -q '^card '; do
  echo "Waiting for ALSA cards..."
  sleep 1
done

# Pick an HDMI-like ALSA device if available, else fallback to first card:device
pick_alsa_dev() {
  local line card dev

  # Prefer HDMI devices if they exist
  line="$(aplay -l 2>/dev/null | grep -iE 'hdmi|displayport|dp' | head -n1 || true)"
  if [ -z "$line" ]; then
    # Otherwise pick the first playback device
    line="$(aplay -l 2>/dev/null | grep -E '^card [0-9]+: ' | head -n1 || true)"
  fi

  # Extract card N and device M from the chosen line
  card="$(echo "$line" | sed -n 's/^card \([0-9]\+\):.*/\1/p')"
  dev="$(echo "$line"  | sed -n 's/.*device \([0-9]\+\):.*/\1/p')"

  if [ -n "$card" ] && [ -n "$dev" ]; then
    echo "plughw:${card},${dev}"
    return 0
  fi

  # Last resort
  echo "default"
}

export AUDIODEV="$(pick_alsa_dev)"
echo "Using AUDIODEV=$AUDIODEV"

# Qt platform selection:
# - If you are truly headless/kiosk on a TTY, eglfs is right.
# - If you're on Ubuntu Desktop (GNOME, etc), xcb/wayland is usually right.
if [ -n "${DISPLAY:-}" ]; then
  # Most Ubuntu Desktop sessions
  export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-xcb}"
else
  # Headless / direct-to-HDMI kiosk
  export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-eglfs}"
fi

# Optional: only set these if you actually need them
export QT_QPA_EGLFS_PHYSICAL_WIDTH="${QT_QPA_EGLFS_PHYSICAL_WIDTH:-1920}"
export QT_QPA_EGLFS_PHYSICAL_HEIGHT="${QT_QPA_EGLFS_PHYSICAL_HEIGHT:-1080}"

# Audio backend
export QTMULTIMEDIA_PREFERRED_PLUGINS=alsa

# Debug dump
env > /tmp/moonlight-env.log

sleep 3

echo "Launching Moonlight Qt..."
exec moonlight-qt
