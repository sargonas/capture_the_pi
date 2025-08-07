#!/bin/bash

# MODULE 5: Network Setup - WiFi Access Point

set -e

echo "[Module 6] Network Setup - WiFi Access Point"

# Stop services while configuring
sudo systemctl stop hostapd 2>/dev/null || true
sudo systemctl stop dnsmasq 2>/dev/null || true

# Configure isolated network interface
if ! grep -q "interface wlan1" /etc/dhcpcd.conf; then
    cat << 'EOF' | sudo tee -a /etc/dhcpcd.conf

# Honeypot AP Interface
interface wlan1
static ip_address=192.168.4.1/24
nohook wpa_supplicant
EOF
fi

# Configure hostapd for open AP
cat << 'EOF' | sudo tee /etc/hostapd/hostapd.conf
interface=wlan1
driver=nl80211
ssid=Open_Playground
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=0
EOF

# Set hostapd config path
sudo sed -i 's|#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd

# Configure dnsmasq for DHCP on AP
if ! grep -q "interface=wlan1" /etc/dnsmasq.conf; then
    cat << 'EOF' | sudo tee -a /etc/dnsmasq.conf

# Honeypot AP DHCP
interface=wlan1
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
EOF
fi

# Enable IP forwarding (if needed for network routing)
if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
fi

# Enable and start services
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl enable dnsmasq
sudo systemctl start hostapd
sudo systemctl start dnsmasq

echo "[Module 6] Network configuration complete"
echo "  Honeypot AP: wlan1 (USB adapter) - SSID: Open_Playground"
echo "  Honeypot network: 192.168.4.0/24"