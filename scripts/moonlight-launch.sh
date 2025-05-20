#!/bin/bash

# Setup environment
USER_ID=$(id -u)
export XDG_RUNTIME_DIR="/run/user/$USER_ID"

if [ ! -d "$XDG_RUNTIME_DIR" ]; then
  echo "XDG_RUNTIME_DIR does not exist: $XDG_RUNTIME_DIR"
  echo "Audio may not work unless systemd user session is running"
fi

# Wait for GPU
while [ ! -e /dev/dri/card0 ]; do
  echo "Waiting for GPU /dev/dri/card0..."
  sleep 1
done

# Wait for audio
echo "Waiting for ALSA to detect audio devices..."
until aplay -l | grep -qE "card [01]:"; do
  sleep 1
done

# Prefer HDMI, fallback to headphones
if aplay -l | grep -q "vc4hdmi"; then
  echo "HDMI audio detected. Using hw:1,0"
  export AUDIODEV=plughw:1,0
else
  echo "Falling back to headphone jack (hw:0,0)"
  export AUDIODEV=plughw:0,0
fi

# Qt setup
export QT_QPA_PLATFORM=eglfs
export QT_QPA_EGLFS_PHYSICAL_WIDTH=1920
export QT_QPA_EGLFS_PHYSICAL_HEIGHT=1080
export QTMULTIMEDIA_PREFERRED_PLUGINS=alsa

# Log environment (optional)
env > /tmp/moonlight-env.log

# sudo uhubctl -l 1-1 -p 2 -a 0

# sleep 3

# sudo uhubctl -l 1-1 -p 2 -a 1

# Launch Moonlight Qt
exec moonlight-qt