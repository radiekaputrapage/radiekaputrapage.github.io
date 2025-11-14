#!/bin/sh

LOG="/tmp/tasiklink_installer.log"
echo "=== TasikLink Installer Log ===" > $LOG

log() {
    echo "$1"
    echo "$1" >> $LOG
}

# ================================
# 0. Fungsi cek download
# ================================
validate_file() {
    FILE="$1"
    MIN_SIZE="$2"

    if [ ! -f "$FILE" ]; then
        log "ERROR: File $FILE tidak ditemukan"
        return 1
    fi

    SIZE=$(wc -c < "$FILE")
    if [ "$SIZE" -lt "$MIN_SIZE" ]; then
        log "ERROR: File $FILE corrupt (size: $SIZE bytes)"
        return 1
    fi

    return 0
}

# ================================
# 1. Siapkan direktori UI custom
# ================================

BASE_DIR="/www/custom"
BASE_URL="https://radiekaputrapage.github.io/custom"

log "[1] Membuat struktur direktori..."
mkdir -p "$BASE_DIR/assets"
mkdir -p "$BASE_DIR/cgi-bin"

log "[2] Mendownload HTML..."
wget -q -O "$BASE_DIR/index.html" "$BASE_URL/index.html"
wget -q -O "$BASE_DIR/wifi.html" "$BASE_URL/wifi.html"

validate_file "$BASE_DIR/index.html" 50 || exit 1
validate_file "$BASE_DIR/wifi.html" 50 || exit 1

log "[3] Mendownload assets..."
wget -q -O "$BASE_DIR/assets/logo.png" "$BASE_URL/assets/logo.png"
validate_file "$BASE_DIR/assets/logo.png" 100 || exit 1

log "[4] Download CGI..."
CGI_FILES="
login.sh
get_wifi.sh
update_wifi.sh
get_sysinfo.sh
get_wan_info.sh
get_traffic.sh
get_clients.sh
"

for f in $CGI_FILES; do
    log "  → $f"
    wget -q -O "$BASE_DIR/cgi-bin/$f" "$BASE_URL/cgi-bin/$f"
    validate_file "$BASE_DIR/cgi-bin/$f" 30 || exit 1
done

log "[5] chmod +x CGI..."
chmod +x "$BASE_DIR/cgi-bin/"*.sh


# ================================
# 2. Backup & Replace uhttpd
# ================================

UHTTPD_NEW="https://radiekaputrapage.github.io/filekhusus/uhttpd"
UHTTPD_FILE="/etc/config/uhttpd"

log "[6] Backup uhttpd lama..."
if [ -f "$UHTTPD_FILE" ]; then
    cp "$UHTTPD_FILE" "$UHTTPD_FILE.bak"
    log "  → Backup ke /etc/config/uhttpd.bak"
fi

log "  → Download uhttpd baru..."
wget -q -O "$UHTTPD_FILE" "$UHTTPD_NEW"
validate_file "$UHTTPD_FILE" 50 || {
    log "  → Restore backup karena file rusak!"
    cp "$UHTTPD_FILE.bak" "$UHTTPD_FILE"
    exit 1
}

chmod 600 "$UHTTPD_FILE"


# ================================
# 3. Backup & Ganti LAN IP
# ================================

log "[7] Backup network config..."
cp /etc/config/network /etc/config/network.bak

log "[8] Mengubah LAN IP → 192.168.100.1..."
uci set network.lan.ipaddr='192.168.100.1'
uci set network.lan.netmask='255.255.255.0'
uci commit network


# ================================
# 4. Restart Services
# ================================

log "[9] Restart uhttpd..."
/etc/init.d/uhttpd restart

log "[10] Restart network..."
log "PERINGATAN: SSH akan terputus karena IP berubah!"
sleep 3
/etc/init.d/network restart


log "=============================================="
log " ✓ Installer selesai tanpa error"
log " ✓ Semua file tervalidasi"
log " ✓ IP LAN kini: 192.168.100.1"
log " ✓ Log tersimpan di $LOG"
log "=============================================="
