#!/bin/sh
echo "Content-type: application/json"
echo ""

# Get uptime
UPTIME=$(uptime | awk -F'( |,|:)+' '{if ($7=="min") m=$6; else {if ($7~/^day/) {d=$6;h=$8;m=$9} else {h=$6;m=$7}}} END {print d+0"d "h+0"h "m+0"m"}')

# Get load average
LOAD=$(uptime | awk -F'load average:' '{print $2}' | xargs)

# Get memory usage
MEM_TOTAL=$(free | awk '/Mem:/ {print $2}')
MEM_USED=$(free | awk '/Mem:/ {print $3}')
MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))
MEMORY="${MEM_PERCENT}%"

# Get storage usage
STORAGE=$(df -h / | awk 'NR==2 {print $5}')

# Return JSON
cat <<EOF
{
  "uptime": "$UPTIME",
  "load": "$LOAD",
  "memory": "$MEMORY",
  "storage": "$STORAGE"
}
EOF