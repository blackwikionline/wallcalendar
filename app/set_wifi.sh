#!/usr/bin/env bash
set -euo pipefail

SSID="${1:-}"
PASS="${2:-}"
IFACE="${3:-wlan0}"
CONF="/etc/wpa_supplicant/wpa_supplicant.conf"
COUNTRY="${COUNTRY:-US}"

if [[ -z "$SSID" || -z "$PASS" ]]; then
  echo "Usage: $0 <SSID> <PASSWORD> [iface]"
  exit 1
fi

# must be root
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Run as root: sudo $0 \"$SSID\" \"$PASS\" [$IFACE]"
  exit 1
fi

# Build network block using wpa_passphrase (removes plaintext #psk line)
NETWORK_BLOCK="$(wpa_passphrase "$SSID" "$PASS" | sed '/^\s*#psk=/d')"

# Write a fresh config (atomic write)
TMP="$(mktemp)"
cat > "$TMP" <<EOF
# WiFi country code, set here in case the access point does send one
country=$COUNTRY
# Grant all members of group "netdev" permissions to configure WiFi, e.g. via wpa_cli or wpa_gui
ctrl_interface=DIR=/run/wpa_supplicant GROUP=netdev
# Allow wpa_cli/wpa_gui to overwrite this config file
update_config=1

$NETWORK_BLOCK
EOF

# Lock down permissions (optional but recommended)
chmod 600 "$TMP"
chown root:root "$TMP"

# Backup existing config (optional)
cp -a "$CONF" "${CONF}.bak.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true

# Move into place
mv "$TMP" "$CONF"

# Reload wpa_supplicant
wpa_cli -i "$IFACE" reconfigure >/dev/null || {
  echo "wpa_cli reconfigure failed; trying to bounce interface..."
  ifdown "$IFACE" 2>/dev/null || true
  ifup "$IFACE" 2>/dev/null || true
}

echo "Updated $CONF for SSID '$SSID' on iface '$IFACE'."
wpa_cli -i "$IFACE" status | egrep 'wpa_state=|ssid=|ip_address=' || true
