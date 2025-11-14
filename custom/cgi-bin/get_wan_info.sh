#!/bin/sh
echo "Content-type: application/json"
echo ""

# Get WAN interface name
WAN_IFACE=$(uci get network.wan.device 2>/dev/null || uci get network.wan.ifname 2>/dev/null || echo "")
WAN_PROTO=$(uci get network.wan.proto 2>/dev/null || echo "none")

# Initialize variables
WAN_STATUS="disconnected"
WAN_TYPE="Belum Dikonfigurasi"
WAN_IP=""
WAN_GATEWAY=""
WAN_DNS=""
WAN_UPTIME=""
WAN_USERNAME=""
WAN_PASSWORD=""

# Check WAN protocol type
case "$WAN_PROTO" in
    "dhcp")
        WAN_TYPE="DHCP (IPoE)"
        # Check if interface is up
        if ifconfig $WAN_IFACE 2>/dev/null | grep -q "inet addr"; then
            WAN_STATUS="connected"
            WAN_IP=$(ifconfig $WAN_IFACE 2>/dev/null | grep "inet addr" | awk '{print $2}' | cut -d: -f2)
            WAN_GATEWAY=$(route -n | grep "^0.0.0.0" | grep "$WAN_IFACE" | awk '{print $2}' | head -1)
            WAN_DNS=$(cat /tmp/resolv.conf.auto 2>/dev/null | grep "nameserver" | head -1 | awk '{print $2}')
        fi
        ;;
    "pppoe")
        WAN_TYPE="PPPoE"
        WAN_USERNAME=$(uci get network.wan.username 2>/dev/null || echo "")
        WAN_PASSWORD=$(uci get network.wan.password 2>/dev/null || echo "")
        
        # Check PPPoE connection status
        PPP_IFACE=$(ifconfig 2>/dev/null | grep -o "pppoe-wan" | head -1)
        if [ -n "$PPP_IFACE" ]; then
            if ifconfig $PPP_IFACE 2>/dev/null | grep -q "inet addr"; then
                WAN_STATUS="connected"
                WAN_IP=$(ifconfig $PPP_IFACE 2>/dev/null | grep "inet addr" | awk '{print $2}' | cut -d: -f2)
                WAN_GATEWAY=$(ifconfig $PPP_IFACE 2>/dev/null | grep "P-t-P" | awk '{print $3}' | cut -d: -f2)
                WAN_DNS=$(cat /tmp/resolv.conf.auto 2>/dev/null | grep "nameserver" | head -1 | awk '{print $2}')
                
                # Get PPPoE uptime
                if [ -f /var/run/pppoe-wan.pid ]; then
                    PPP_PID=$(cat /var/run/pppoe-wan.pid)
                    if [ -d "/proc/$PPP_PID" ]; then
                        PPP_START=$(stat -c %Y /proc/$PPP_PID 2>/dev/null)
                        if [ -n "$PPP_START" ]; then
                            CURRENT_TIME=$(date +%s)
                            UPTIME_SEC=$((CURRENT_TIME - PPP_START))
                            DAYS=$((UPTIME_SEC / 86400))
                            HOURS=$(((UPTIME_SEC % 86400) / 3600))
                            MINS=$(((UPTIME_SEC % 3600) / 60))
                            WAN_UPTIME="${DAYS}d ${HOURS}h ${MINS}m"
                        fi
                    fi
                fi
            else
                WAN_STATUS="disconnected"
            fi
        else
            WAN_STATUS="disconnected"
        fi
        
        # Hide password (show asterisks)
        if [ -n "$WAN_PASSWORD" ]; then
            PASS_LEN=${#WAN_PASSWORD}
            WAN_PASSWORD=$(printf '%*s' "$PASS_LEN" | tr ' ' '*')
        fi
        ;;
    "static")
        WAN_TYPE="Static IP"
        WAN_IP=$(uci get network.wan.ipaddr 2>/dev/null || echo "")
        WAN_GATEWAY=$(uci get network.wan.gateway 2>/dev/null || echo "")
        WAN_DNS=$(uci get network.wan.dns 2>/dev/null | awk '{print $1}')
        
        if [ -n "$WAN_IP" ] && ifconfig $WAN_IFACE 2>/dev/null | grep -q "inet addr"; then
            WAN_STATUS="connected"
        fi
        ;;
    "none"|"")
        WAN_TYPE="Belum Dikonfigurasi"
        WAN_STATUS="not_configured"
        ;;
    *)
        WAN_TYPE="$WAN_PROTO"
        WAN_STATUS="unknown"
        ;;
esac

# Return JSON
cat <<EOF
{
  "wan_type": "$WAN_TYPE",
  "wan_status": "$WAN_STATUS",
  "wan_ip": "${WAN_IP:-N/A}",
  "wan_gateway": "${WAN_GATEWAY:-N/A}",
  "wan_dns": "${WAN_DNS:-N/A}",
  "wan_uptime": "${WAN_UPTIME:-N/A}",
  "wan_username": "${WAN_USERNAME:-N/A}",
  "wan_password": "${WAN_PASSWORD:-N/A}"
}
EOF