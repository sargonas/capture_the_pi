#!/bin/bash

# WiFi Access Point Troubleshooting Script
# Use this to diagnose WiFi AP issues

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() { echo -e "${BLUE}=== $1 ===${NC}"; }
print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}           WiFi Access Point Troubleshooting${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# 1. Check USB devices
print_header "USB WiFi Adapters"
echo "USB devices:"
lsusb | grep -i -E "(wireless|wifi|802\.11|realtek|ralink|atheros|broadcom)"
if [ $? -ne 0 ]; then
    print_warning "No obvious WiFi adapters found in USB devices"
    echo "All USB devices:"
    lsusb
fi
echo ""

# 2. Check network interfaces
print_header "Network Interfaces"
echo "Available network interfaces:"
ip link show | grep -E "^[0-9]+:" | while read line; do
    interface=$(echo $line | awk -F': ' '{print $2}')
    if [[ $interface == wlan* ]]; then
        print_status "$line"
    else
        echo "$line"
    fi
done

if ! ip link show wlan1 >/dev/null 2>&1; then
    print_error "wlan1 interface not found!"
    echo "Possible solutions:"
    echo "1. Connect USB WiFi adapter"
    echo "2. Check if driver is loaded: lsmod | grep 8188"
    echo "3. Try different USB port"
else
    print_status "wlan1 interface found"
fi
echo ""

# 3. Check drivers
print_header "WiFi Drivers"
echo "Loaded WiFi-related kernel modules:"
lsmod | grep -E "(80211|cfg80211|mac80211|rtl|ath|brcm)" || echo "No WiFi modules found"
echo ""

# 4. Check wireless capabilities
if ip link show wlan1 >/dev/null 2>&1; then
    print_header "WiFi Capabilities"
    echo "wlan1 interface info:"
    iw dev wlan1 info 2>/dev/null || echo "Could not get interface info"
    
    if command -v iw >/dev/null; then
        PHY=$(iw dev wlan1 info 2>/dev/null | grep wiphy | awk '{print $2}')
        if [ -n "$PHY" ]; then
            echo ""
            echo "Supported interface modes:"
            iw phy$PHY info | grep "Supported interface modes" -A 10 | head -15
            
            if iw phy$PHY info | grep -E "(AP|master)" >/dev/null; then
                print_status "Interface supports AP mode"
            else
                print_error "Interface does NOT support AP mode"
                echo "This adapter cannot be used as an access point"
            fi
        fi
    fi
else
    print_error "wlan1 not available - skipping capability check"
fi
echo ""

# 5. Check hostapd
print_header "hostapd Status"
if [ -f /etc/hostapd/hostapd.conf ]; then
    print_status "hostapd config exists"
    echo "Configuration:"
    grep -E "^(interface|driver|ssid)" /etc/hostapd/hostapd.conf 2>/dev/null || echo "Could not read config"
    
    echo ""
    echo "Testing hostapd configuration:"
    if sudo hostapd -t /etc/hostapd/hostapd.conf >/dev/null 2>&1; then
        print_status "hostapd configuration is valid"
    else
        print_error "hostapd configuration has errors"
        echo "Configuration test output:"
        sudo hostapd -t /etc/hostapd/hostapd.conf
    fi
else
    print_error "hostapd config not found"
fi

echo ""
echo "hostapd service status:"
sudo systemctl status hostapd --no-pager -l | head -10

echo ""
echo "Recent hostapd logs:"
sudo journalctl -u hostapd --no-pager -l -n 5
echo ""

# 6. Check processes
print_header "Process Check"
echo "WiFi-related processes:"
ps aux | grep -E "(hostapd|wpa_supplicant|dnsmasq)" | grep -v grep

if pgrep wpa_supplicant >/dev/null; then
    print_warning "wpa_supplicant is running - this may conflict with hostapd"
    echo "Kill wpa_supplicant: sudo pkill wpa_supplicant"
fi
echo ""

# 7. Network configuration
print_header "Network Configuration"
echo "wlan1 IP configuration:"
ip addr show wlan1 2>/dev/null || echo "wlan1 not configured"

echo ""
echo "DHCP configuration for wlan1:"
grep -A 5 -B 5 "interface wlan1" /etc/dhcpcd.conf 2>/dev/null || echo "No wlan1 config in dhcpcd.conf"
echo ""

# 8. Recommendations
print_header "Troubleshooting Recommendations"

if ! ip link show wlan1 >/dev/null 2>&1; then
    echo "❌ No wlan1 interface:"
    echo "   1. Check USB WiFi adapter is connected"
    echo "   2. Try: sudo modprobe rtl8188eu (or appropriate driver)"
    echo "   3. Reboot and check again"
    echo ""
fi

if [ -f /etc/hostapd/hostapd.conf ]; then
    if ! sudo hostapd -t /etc/hostapd/hostapd.conf >/dev/null 2>&1; then
        echo "❌ hostapd config issues:"
        echo "   1. Try different driver (nl80211 vs rtl871xdrv)"
        echo "   2. Change channel (try 1, 6, or 11)"
        echo "   3. Remove advanced options (ieee80211n, etc.)"
        echo ""
    fi
fi

if pgrep wpa_supplicant >/dev/null; then
    echo "⚠️  wpa_supplicant conflict:"
    echo "   Run: sudo pkill wpa_supplicant"
    echo "   Then: sudo systemctl restart hostapd"
    echo ""
fi

echo "🔧 Common fixes to try:"
echo "   1. sudo systemctl stop wpa_supplicant"
echo "   2. sudo ip link set wlan1 down"
echo "   3. sudo systemctl restart hostapd"
echo "   4. Check: sudo systemctl status hostapd"
echo ""

echo "📱 Test if AP is working:"
echo "   iwlist scan | grep Open_Playground"
echo "   (Run from another device or Pi)"
echo ""

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"