#!/bin/sh
echo "Content-type: application/json"
echo ""

# Function to get WiFi clients
get_wifi_clients() {
    echo "["
    FIRST=1
    for iface in /sys/class/net/wlan*; do
        [ -d "$iface" ] || continue
        IFNAME=$(basename "$iface")
        
        iw dev "$IFNAME" station dump 2>/dev/null | awk -v first=$FIRST '
        /^Station/ {
            if (!first) print ",";
            first=0;
            mac=$2;
            signal="N/A"; rx="N/A"; tx="N/A"; time="N/A";
        }
        /signal avg:/ { signal=$3 " dBm" }
        /rx bitrate:/ { rx=$3" "$4 }
        /tx bitrate:/ { tx=$3" "$4 }
        /connected time:/ { time=$3" sec" }
        /^$/ && mac {
            printf "{\"mac\":\"%s\",\"signal\":\"%s\",\"rx_rate\":\"%s\",\"tx_rate\":\"%s\",\"connected_time\":\"%s\"}", mac, signal, rx, tx, time;
            mac="";
        }'
        FIRST=0
    done
    echo "]"
}

# Function to get LAN clients (DHCP leases)
get_lan_clients() {
    echo "["
    FIRST=1
    if [ -f /tmp/dhcp.leases ]; then
        while read lease; do
            [ -z "$lease" ] && continue
            [ $FIRST -eq 0 ] && echo ","
            FIRST=0
            
            EXPIRE=$(echo "$lease" | awk '{print $1}')
            MAC=$(echo "$lease" | awk '{print $2}')
            IP=$(echo "$lease" | awk '{print $3}')
            HOSTNAME=$(echo "$lease" | awk '{print $4}')
            
            # Convert expire timestamp to readable format
            CURRENT=$(date +%s)
            REMAINING=$((EXPIRE - CURRENT))
            if [ $REMAINING -gt 0 ]; then
                EXPIRE_STR="${REMAINING}s"
            else
                EXPIRE_STR="Expired"
            fi
            
            [ "$HOSTNAME" = "*" ] && HOSTNAME="Unknown"
            
            printf "{\"hostname\":\"%s\",\"ip\":\"%s\",\"mac\":\"%s\",\"expires\":\"%s\"}" "$HOSTNAME" "$IP" "$MAC" "$EXPIRE_STR"
        done < /tmp/dhcp.leases
    fi
    echo "]"
}

# Build JSON response
echo "{"
echo "\"wifi_clients\":"
get_wifi_clients
echo ","
echo "\"lan_clients\":"
get_lan_clients
echo "}"