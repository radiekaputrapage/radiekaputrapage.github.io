#!/bin/sh
echo "Content-type: text/html"
echo ""

# Parse POST data
read POST_DATA
USERNAME=$(echo "$POST_DATA" | grep -o 'username=[^&]*' | cut -d= -f2 | sed 's/+/ /g')
PASSWORD=$(echo "$POST_DATA" | grep -o 'password=[^&]*' | cut -d= -f2 | sed 's/+/ /g')

# URL decode
USERNAME=$(printf "$(echo "$USERNAME" | sed 's/%/\\x/g')" 2>/dev/null || echo "$USERNAME")
PASSWORD=$(printf "$(echo "$PASSWORD" | sed 's/%/\\x/g')" 2>/dev/null || echo "$PASSWORD")

# GANTI PASSWORD INI! Jangan pakai default
VALID_USER="admin"
VALID_PASS="admin"

# Check credentials
if [ "$USERNAME" = "$VALID_USER" ] && [ "$PASSWORD" = "$VALID_PASS" ]; then
    echo "Set-Cookie: auth=logged_in; Path=/; Max-Age=86400; HttpOnly"
    echo "<html><head><meta http-equiv='refresh' content='0;url=/wifi.html'></head></html>"
else
    echo "<html><head><meta http-equiv='refresh' content='0;url=/?error=invalid'></head></html>"
fi