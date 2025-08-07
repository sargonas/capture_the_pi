#!/bin/bash

# Quick WiFi Adapter Compatibility Checker
# Run this BEFORE installing to check if your WiFi adapter supports AP mode

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}WiFi Access Point Compatibility Checker${NC}"
echo "========================================"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo -e "${YELLOW}Note: Running as root. Consider running as regular user.${NC}"
    echo ""
fi

# 1. Check USB WiFi adapters
echo "🔍 Checking for USB WiFi adapters..."
WIFI_DEVICES=$(lsusb | grep -i -E "(wireless|wifi|802\.11|realtek|ralink|atheros|broadcom)")

if [ -z "$WIFI_DEVICES" ]; then
    echo -e "${RED}❌ No USB WiFi adapters found${NC}"
    echo ""
    echo "Solutions:"
    echo "1. Connect a USB WiFi adapter"
    echo "2. Use built-in WiFi (if available)"
    echo "3. Purchase a compatible adapter"
    echo ""
    echo "Recommended adapters:"
    echo "• Panda PAU09 (Ralink RT5372)"
    echo "• TP-Link AC600T2U (Realtek RTL8811AU)"  
    echo "• Any adapter with RTL8188EUS/AR9271/MT7601U chips"
    exit 1
else
    echo -e "${GREEN}✅ Found WiFi adapters:${NC}"
    echo "$WIFI_DEVICES"
    echo ""
fi

# 2. Check network interfaces
echo "🔍 Checking network interfaces..."
WLAN_INTERFACES=$(ip link show | grep -E "^[0-9]+: wlan" | awk -F': ' '{print $2}')

if [ -z "$WLAN_INTERFACES" ]; then
    echo -e "${RED}❌ No wlan interfaces found${NC}"
    echo "The WiFi adapter may need drivers or may not be recognized"
    exit 1
else
    echo -e "${GREEN}✅ Found WiFi interfaces:${NC}"
    for interface in $WLAN_INTERFACES; do
        echo "  • $interface"
    done
    echo ""
fi

# 3. Check for wlan1 specifically
if echo "$WLAN_INTERFACES" | grep -q "wlan1"; then
    echo -e "${GREEN}✅ wlan1 interface found (required for AP)${NC}"
    WLAN_DEVICE="wlan1"
elif echo "$WLAN_INTERFACES" | grep -q "wlan0"; then
    echo -e "${YELLOW}⚠️  Only wlan0 found (wlan1 preferred)${NC}"
    echo "You may need to use wlan0 or connect a second adapter"
    WLAN_DEVICE="wlan0"
else
    WLAN_DEVICE=$(echo "$WLAN_INTERFACES" | head -1)
    echo -e "${YELLOW}⚠️  Using $WLAN_DEVICE (non-standard name)${NC}"
fi
echo ""

# 4. Check AP mode support
echo "🔍 Checking AP mode support for $WLAN_DEVICE..."
if command -v iw >/dev/null; then
    PHY=$(iw dev $WLAN_DEVICE info 2>/dev/null | grep wiphy | awk '{print $2}')
    if [ -n "$PHY" ]; then
        AP_SUPPORT=$(iw phy$PHY info 2>/dev/null | grep "Supported interface modes" -A 10 | grep -E "(AP|master)")
        
        if [ -n "$AP_SUPPORT" ]; then
            echo -e "${GREEN}✅ $WLAN_DEVICE supports AP mode!${NC}"
            echo "Supported modes that include AP:"
            echo "$AP_SUPPORT"
        else
            echo -e "${RED}❌ $WLAN_DEVICE does NOT support AP mode${NC}"
            echo "This adapter cannot create a WiFi access point"
            echo ""
            echo "All supported modes:"
            iw phy$PHY info 2>/dev/null | grep "Supported interface modes" -A 10
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠️  Could not determine PHY for $WLAN_DEVICE${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  'iw' command not found - install with: sudo apt-get install iw${NC}"
fi
echo ""

# 5. Check driver compatibility
echo "🔍 Checking drivers..."
LOADED_MODULES=$(lsmod | grep -E "(80211|cfg80211|rtl|ath|brcm)")
if [ -n "$LOADED_MODULES" ]; then
    echo -e "${GREEN}✅ WiFi kernel modules loaded:${NC}"
    echo "$LOADED_MODULES" | while read line; do
        echo "  • $line"
    done
else
    echo -e "${YELLOW}⚠️  No obvious WiFi modules found${NC}"
fi
echo ""

# 6. Test basic functionality
echo "🔍 Testing basic WiFi functionality..."
if iw dev $WLAN_DEVICE scan trigger >/dev/null 2>&1; then
    echo -e "${GREEN}✅ $WLAN_DEVICE can scan for networks${NC}"
else
    echo -e "${YELLOW}⚠️  $WLAN_DEVICE scan test failed (may be normal if busy)${NC}"
fi
echo ""

# 7. Final recommendation
echo "🎯 COMPATIBILITY SUMMARY"
echo "======================="

if [ -n "$AP_SUPPORT" ] && echo "$WLAN_INTERFACES" | grep -q "wlan1"; then
    echo -e "${GREEN}✅ EXCELLENT: Your WiFi setup should work perfectly!${NC}"
    echo ""
    echo "✅ USB WiFi adapter detected"
    echo "✅ wlan1 interface available"  
    echo "✅ AP mode supported"
    echo ""
    echo "You can proceed with the installation:"
    echo "  ./01_main.sh"
elif [ -n "$AP_SUPPORT" ]; then
    echo -e "${YELLOW}⚠️  GOOD: WiFi should work with minor adjustments${NC}"
    echo ""
    echo "✅ AP mode supported"
    echo "⚠️  May need to modify scripts to use $WLAN_DEVICE instead of wlan1"
    echo ""
    echo "Proceed with caution or connect a second adapter"
else
    echo -e "${RED}❌ INCOMPATIBLE: WiFi adapter does not support AP mode${NC}"
    echo ""
    echo "❌ Cannot create WiFi access point"
    echo ""
    echo "Options:"
    echo "1. Use a different WiFi adapter that supports AP mode"
    echo "2. Skip WiFi AP and use wired network only"
    echo "3. Purchase recommended adapter (see above)"
fi

echo ""
echo "Need help? Run: ./wifi_troubleshoot.sh"