# Moonlight Kiosk on Ubuntu (headless/TTY) with persistent HDMI audio

This repo folder contains the exact scripts and systemd services used to make:
- Moonlight start on **tty1** at boot (kiosk mode, no desktop GUI)
- Display reliably without needing an SSH session
- Audio reliably route to **HDMI (TV)** and **stay unmuted after reboot**

It assumes you're launching Moonlight via an **AppImage** extracted to `squashfs-root/AppRun`
and running it inside **Cage**.

## What you get

Files included:

- `etc/asound.conf`  
  Sets **ALSA default** output to the HDMI device.
- `usr/local/bin/alsa-hdmi-init.sh`  
  Forces IEC958 (HDMI/SPDIF digital switches) **ON** and persists via `alsactl store`.
- `etc/systemd/system/alsa-hdmi-init.service`  
  Runs the init script at boot (oneshot).
- `usr/local/bin/moonlight-launch.sh`  
  Sets runtime env + forces SDL audio to ALSA and launches Moonlight AppRun.
- `etc/systemd/system/moonlight-kiosk.service`  
  Runs Cage on tty1 and launches `moonlight-launch.sh` as your user.

## Assumptions

This guide matches your current machine:

- User: `santidotio`
- UID: `1000`
- Moonlight AppRun path:
  `/home/santidotio/apps/moonlight/squashfs-root/AppRun`
- Audio device:
  `card PCH`, `device 3` (HDMI 0, LG TV)

If any of those differ on a future setup, see **Customization**.

## 1) Install prerequisites

```bash
sudo apt update
sudo apt install -y cage xwayland alsa-utils
```

Notes:
- `cage` is the Wayland kiosk compositor.
- `xwayland` is needed because Moonlight (in your case) is running with `QT_QPA_PLATFORM=xcb`.

## 2) Put Moonlight AppImage in place

Example layout used here:

```bash
mkdir -p /home/santidotio/apps/moonlight
cd /home/santidotio/apps/moonlight
# Put Moonlight.AppImage here
```

If AppImage execution fails due to FUSE, extract it:

```bash
chmod +x Moonlight.AppImage
./Moonlight.AppImage --appimage-extract
```

That creates:

- `/home/santidotio/apps/moonlight/squashfs-root/AppRun`

Confirm:

```bash
test -x /home/santidotio/apps/moonlight/squashfs-root/AppRun && echo OK
```

## 3) Install the config + scripts from this folder

From the folder containing `etc/` and `usr/`:

```bash
# Copy /etc files
sudo cp -v etc/asound.conf /etc/asound.conf
sudo cp -v etc/systemd/system/alsa-hdmi-init.service /etc/systemd/system/alsa-hdmi-init.service
sudo cp -v etc/systemd/system/moonlight-kiosk.service /etc/systemd/system/moonlight-kiosk.service

# Copy scripts
sudo cp -v usr/local/bin/alsa-hdmi-init.sh /usr/local/bin/alsa-hdmi-init.sh
sudo cp -v usr/local/bin/moonlight-launch.sh /usr/local/bin/moonlight-launch.sh

# Permissions
sudo chmod 755 /usr/local/bin/alsa-hdmi-init.sh /usr/local/bin/moonlight-launch.sh
```

## 4) Enable and start services

```bash
sudo systemctl daemon-reload

# Audio init (persists IEC958 "on")
sudo systemctl enable --now alsa-hdmi-init.service

# Kiosk mode (Cage on tty1 + Moonlight)
sudo systemctl enable --now moonlight-kiosk.service
```

## 5) Reboot test (the real test)

```bash
sudo reboot
```

After reboot you should see Moonlight on the TV **without SSH**.

## Verification commands

### Confirm HDMI is the ALSA default

```bash
aplay -L | head -n 30
aplay -D default /usr/share/sounds/alsa/Front_Center.wav
```

### Confirm IEC958 is on

```bash
amixer -c PCH sget 'IEC958',0
```

You want: `Playback [on]`

### Check service logs

```bash
sudo journalctl -u alsa-hdmi-init.service -b --no-pager
sudo journalctl -u moonlight-kiosk.service -b --no-pager | tail -n 120
```

## Customization

### A) Different user / UID

In `etc/systemd/system/moonlight-kiosk.service`, change:

- `User=...`
- `Group=...`
- `ExecStartPre=... /run/user/1000`
- `Environment=HOME=...`
- `Environment=XDG_RUNTIME_DIR=...`

And in `usr/local/bin/moonlight-launch.sh`, update defaults:

- `MOONLIGHT_APP_RUN=...`
- `HOME` and `XDG_RUNTIME_DIR` fallback values

If you want to make this reusable across users, systemd supports specifiers like:
- `%u` (username)
- `%U` (UID)

You can replace `/run/user/1000` with `/run/user/%U` and set `User=YOURUSER`.

### B) Different HDMI device

Find your HDMI device:

```bash
aplay -l
```

Example output line:

- `card 0: PCH ... device 3: HDMI 0 [LG TV ...]`

Then edit `/etc/asound.conf`:

- Change `hw:PCH,3` to match your card/device.

Apply immediately by restarting apps (no daemon restart needed), but reboot is the real validation.

### C) Change resolution / Qt platform

In `usr/local/bin/moonlight-launch.sh`:

- `QT_QPA_PLATFORM=xcb` (current)
- You can experiment with `wayland` or `eglfs`, but with Cage you're typically fine with Wayland-backed flows.

## Troubleshooting

### Moonlight starts but no audio after reboot

1) Confirm `/etc/asound.conf` points to HDMI
2) Confirm IEC958 is on:
   ```bash
   amixer -c PCH sget 'IEC958',0
   ```
3) Force persist again:
   ```bash
   sudo /usr/local/bin/alsa-hdmi-init.sh
   sudo alsactl store PCH
   ```
4) Reboot and verify again.

### Moonlight doesn't show until you SSH

This is typically because the process doesn't have a real logind session or runtime dir at boot.
This setup fixes that via:
- `PAMName=login`
- creating `/run/user/1000` via `ExecStartPre`

Confirm the unit still contains those lines.

## Uninstall / disable

```bash
sudo systemctl disable --now moonlight-kiosk.service
sudo systemctl disable --now alsa-hdmi-init.service

sudo rm -f /etc/systemd/system/moonlight-kiosk.service
sudo rm -f /etc/systemd/system/alsa-hdmi-init.service
sudo rm -f /usr/local/bin/moonlight-launch.sh
sudo rm -f /usr/local/bin/alsa-hdmi-init.sh
sudo rm -f /etc/asound.conf

sudo systemctl daemon-reload
```

---
If you want, I can also generate a “parameterized” version of the service that uses `%u/%U`
so you can drop it onto any box with minimal edits.
