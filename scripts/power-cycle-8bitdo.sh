#!/bin/bash

# Working port for 8BitDo dongle
HUB_PORT="1-1"
TARGET_PORT="2"

echo "Power-cycling 8BitDo dongle on port $HUB_PORT:$TARGET_PORT..."

uhubctl -l "$HUB_PORT" -p "$TARGET_PORT" -a 0
sleep 2
uhubctl -l "$HUB_PORT" -p "$TARGET_PORT" -a 1
sleep 3

echo "✅ Power cycle complete"