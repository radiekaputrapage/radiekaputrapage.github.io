#!/bin/sh
echo "Content-type: application/json"
echo ""

# Function to convert bytes to MB with proper formatting
bytes_to_mb() {
    local bytes=$1
    if [ -z "$bytes" ] || [ "$bytes" = "0" ]; then
        echo "0.00"
    else
        echo "$bytes" | awk '{printf "%.2f", $1/1048576}'
    fi
}

# Get WAN interface
WAN_IF=$(uci get network.wan.device 2>/dev/null || uci get network.wan.ifname 2>/dev/null)
if [ -z "$WAN_IF" ]; then
    for iface in eth1 eth0.2 pppoe-wan wan; do
        if [ -d "/sys/class/net/$iface" ]; then
            WAN_IF=$iface
            break
        fi
    done
fi

# Get WLAN interface
WLAN_IF=$(ls /sys/class/net/ 2>/dev/null | grep -E '^wlan[0-9]' | head -1)

# Get WAN traffic
if [ -n "$WAN_IF" ] && [ -f "/sys/class/net/$WAN_IF/statistics/rx_bytes" ]; then
    RX_BYTES=$(cat /sys/class/net/$WAN_IF/statistics/rx_bytes 2>/dev/null || echo 0)
    TX_BYTES=$(cat /sys/class/net/$WAN_IF/statistics/tx_bytes 2>/dev/null || echo 0)
else
    RX_BYTES=0
    TX_BYTES=0
fi

RX_TOTAL=$(bytes_to_mb $RX_BYTES)
TX_TOTAL=$(bytes_to_mb $TX_BYTES)

# Get WiFi traffic
if [ -n "$WLAN_IF" ] && [ -f "/sys/class/net/$WLAN_IF/statistics/rx_bytes" ]; then
    WLAN_RX=$(cat /sys/class/net/$WLAN_IF/statistics/rx_bytes 2>/dev/null || echo 0)
    WLAN_TX=$(cat /sys/class/net/$WLAN_IF/statistics/tx_bytes 2>/dev/null || echo 0)
else
    WLAN_RX=0
    WLAN_TX=0
fi

RX_WIFI=$(bytes_to_mb $WLAN_RX)
TX_WIFI=$(bytes_to_mb $WLAN_TX)

# Return JSON
cat <<EOF
{
  "rx_total": "$RX_TOTAL",
  "tx_total": "$TX_TOTAL",
  "rx_wifi": "$RX_WIFI",
  "tx_wifi": "$TX_WIFI"
}
EOF