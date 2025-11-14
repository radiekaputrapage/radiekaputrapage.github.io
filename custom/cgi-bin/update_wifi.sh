#!/bin/sh
echo "Content-type: text/html"
echo ""

# Parse POST data
read POST_DATA

# Decode URL encoded data
SSID=$(echo "$POST_DATA" | grep -o 'ssid=[^&]*' | cut -d= -f2 | sed 's/+/ /g')
SSID=$(printf "$(echo "$SSID" | sed 's/%/\\x/g')")

PASS=$(echo "$POST_DATA" | grep -o 'pass=[^&]*' | cut -d= -f2 | sed 's/+/ /g')
PASS=$(printf "$(echo "$PASS" | sed 's/%/\\x/g')" 2>/dev/null || echo "$PASS")

# Validate minimum password length
PASS_LEN=${#PASS}
if [ "$PASS_LEN" -lt 8 ]; then
    echo "<script>alert('Kata sandi minimal 8 karakter!'); window.location='/wifi.html';</script>"
    exit 1
fi

# Find first wifi-iface section
IFACE=$(uci show wireless | grep "=wifi-iface" | head -1 | cut -d. -f2 | cut -d= -f1)

if [ -n "$IFACE" ]; then
    # Update WiFi config
    uci set wireless.$IFACE.ssid="$SSID"
    uci set wireless.$IFACE.key="$PASS"
    uci commit wireless
    wifi reload
    
    echo "<script>alert('Konfigurasi WiFi berhasil diperbarui!\\nSSID: $SSID'); window.location='/wifi.html';</script>"
else
    echo "<script>alert('Error: Interface WiFi tidak ditemukan!'); window.location='/wifi.html';</script>"
fi