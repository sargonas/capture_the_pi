#!/bin/bash

# MODULE 6: Network Setup - WiFi Access Point

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "[Module 6] Network Setup - WiFi Access Point"

# Stop services while configuring
sudo systemctl stop hostapd 2>/dev/null || true
sudo systemctl stop dnsmasq 2>/dev/null || true
sudo systemctl stop wpa_supplicant 2>/dev/null || true

# Check if wlan1 interface exists
if ! ip link show wlan1 >/dev/null 2>&1; then
    echo -e "${RED}ERROR: wlan1 interface not found!${NC}"
    echo "Please ensure:"
    echo "1. USB WiFi adapter is connected"
    echo "2. Driver is loaded (check with 'lsusb' and 'iwconfig')"
    echo "3. Interface shows up in 'ip link' output"
    echo ""
    echo "Available network interfaces:"
    ip link show | grep -E "^[0-9]+:"
    exit 1
fi

# Ensure wlan1 is down and not managed by wpa_supplicant
sudo ip link set wlan1 down 2>/dev/null || true
sudo pkill -f "wpa_supplicant.*wlan1" 2>/dev/null || true
sleep 1

# Configure isolated network interface
if ! grep -q "interface wlan1" /etc/dhcpcd.conf; then
    cat << 'EOF' | sudo tee -a /etc/dhcpcd.conf

# Honeypot AP Interface
interface wlan1
static ip_address=192.168.4.1/24
nohook wpa_supplicant
EOF
fi

# Restart dhcpcd to apply interface config
sudo systemctl restart dhcpcd
sleep 2

# Detect WiFi driver for hostapd
WIFI_DRIVER="nl80211"
if lsusb | grep -i realtek >/dev/null 2>&1; then
    echo "Realtek adapter detected - using rtl871xdrv driver"
    WIFI_DRIVER="rtl871xdrv"
elif lsusb | grep -i ralink >/dev/null 2>&1; then
    echo "Ralink adapter detected - using nl80211 driver"
    WIFI_DRIVER="nl80211"
else
    echo "Using default nl80211 driver"
fi

# Get the WiFi adapter capabilities
WIFI_MODES=$(iw phy$(iw dev wlan1 info | grep wiphy | awk '{print $2}') info | grep "Supported interface modes" -A 10 | grep -E "(AP|master)" || true)

if [ -z "$WIFI_MODES" ]; then
    echo -e "${YELLOW}WARNING: WiFi adapter may not support AP mode${NC}"
    echo "This adapter might not work as an access point."
    echo "Continue anyway? (y/n)"
    read -r -n 1 response
    echo ""
    if [[ ! $response =~ ^[Yy]$ ]]; then
        echo "Skipping WiFi AP setup"
        exit 0
    fi
fi

# Configure hostapd for open AP with detected driver
cat << EOF | sudo tee /etc/hostapd/hostapd.conf
interface=wlan1
driver=${WIFI_DRIVER}
ssid=Open_Playground
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=0
ieee80211n=1
ieee80211d=1
country_code=US
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

# Enable services
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl enable dnsmasq

# Test hostapd configuration before starting
echo "Testing hostapd configuration..."
if sudo hostapd -t /etc/hostapd/hostapd.conf; then
    echo -e "${GREEN}✓ hostapd configuration test passed${NC}"
else
    echo -e "${RED}✗ hostapd configuration test failed${NC}"
    echo "Trying fallback configuration..."
    
    # Fallback configuration without advanced features
    cat << EOF | sudo tee /etc/hostapd/hostapd.conf
interface=wlan1
driver=nl80211
ssid=Open_Playground
hw_mode=g
channel=6
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=0
EOF
    
    # Test fallback config
    if sudo hostapd -t /etc/hostapd/hostapd.conf; then
        echo -e "${YELLOW}✓ Fallback hostapd configuration works${NC}"
    else
        echo -e "${RED}✗ Even fallback configuration failed${NC}"
        echo "WiFi adapter may not be compatible with AP mode"
        echo "Continue without WiFi AP? (y/n)"
        read -r -n 1 response
        echo ""
        if [[ ! $response =~ ^[Yy]$ ]]; then
            exit 1
        else
            echo -e "${YELLOW}Skipping WiFi AP setup - continuing with wired network only${NC}"
            exit 0
        fi
    fi
fi

# Start services
echo "Starting hostapd..."
sudo systemctl start hostapd
sleep 3

# Check if hostapd started successfully
if sudo systemctl is-active hostapd >/dev/null 2>&1; then
    echo -e "${GREEN}✓ hostapd started successfully${NC}"
else
    echo -e "${RED}✗ hostapd failed to start${NC}"
    echo "Checking hostapd logs..."
    sudo journalctl -u hostapd --no-pager -l -n 10
    
    # Try to identify common issues
    if sudo journalctl -u hostapd | grep -q "nl80211: Could not configure driver mode"; then
        echo ""
        echo -e "${YELLOW}Common solution: Try a different WiFi adapter that supports AP mode${NC}"
        echo "Recommended: Adapters based on RTL8188EUS, AR9271, or MT7601U chipsets"
    fi
    
    echo ""
    echo "Continue without WiFi AP? (y/n)"
    read -r -n 1 response
    echo ""
    if [[ ! $response =~ ^[Yy]$ ]]; then
        exit 1
    else
        echo -e "${YELLOW}Continuing without WiFi AP - honeypot will work on wired network${NC}"
        exit 0
    fi
fi

echo "Starting dnsmasq..."
sudo systemctl start dnsmasq
sleep 2

if sudo systemctl is-active dnsmasq >/dev/null 2>&1; then
    echo -e "${GREEN}✓ dnsmasq started successfully${NC}"
else
    echo -e "${YELLOW}⚠ dnsmasq failed to start (may be normal without clients)${NC}"
fi

echo "[Module 6] Network configuration complete"
echo "  Honeypot AP: wlan1 (USB adapter) - SSID: Open_Playground"
echo "  Honeypot network: 192.168.4.0/24"
echo ""
echo "Test AP with: iwlist scan | grep Open_Playground"