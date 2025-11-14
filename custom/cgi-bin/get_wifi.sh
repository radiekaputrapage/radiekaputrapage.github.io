#!/bin/sh
echo "Content-type: application/json"
echo ""

# Find first wifi-iface section
IFACE=$(uci show wireless | grep "=wifi-iface" | head -1 | cut -d. -f2 | cut -d= -f1)

if [ -n "$IFACE" ]; then
    SSID=$(uci get wireless.$IFACE.ssid 2>/dev/null)
    PASS=$(uci get wireless.$IFACE.key 2>/dev/null)
else
    SSID="No WiFi configured"
    PASS="No password set"
fi

# Return JSON
echo "{\"ssid\":\"${SSID:-Not set}\",\"password\":\"${PASS:-Not set}\"}"