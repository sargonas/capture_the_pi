#!/bin/bash

# NUCLEAR RESET - Complete CTF Honeypot Cleanup
# WARNING: This will aggressively remove ALL traces of the honeypot installation
# Use this if you need to completely start over on a system that had previous installs

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
echo -e "${RED}           NUCLEAR HONEYPOT CTF RESET${NC}"
echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}WARNING: This will completely remove all honeypot installations!${NC}"
echo -e "${YELLOW}This includes stopping services, removing files, and resetting configs.${NC}"
echo ""
read -p "Are you SURE you want to nuke everything? (type 'NUKE' to confirm): " confirmation

if [ "$confirmation" != "NUKE" ]; then
    print_error "Reset cancelled - confirmation not provided"
    exit 1
fi

echo ""
print_warning "Beginning nuclear reset..."

# 1. STOP ALL SERVICES AGGRESSIVELY
print_status "Force stopping all services..."
sudo pkill -f opencanary 2>/dev/null || true
sudo pkill -f ctf_scorer 2>/dev/null || true
sudo supervisorctl stop all 2>/dev/null || true
sudo systemctl stop supervisor 2>/dev/null || true
sudo systemctl stop hostapd 2>/dev/null || true
sudo systemctl stop dnsmasq 2>/dev/null || true

# Wait for services to die
sleep 3

# Kill any remaining processes
sudo pkill -9 -f opencanary 2>/dev/null || true
sudo pkill -9 -f ctf_scorer 2>/dev/null || true

# 2. REMOVE FILE PROTECTIONS
print_status "Removing all file protections..."
sudo chattr -i /home/pi/honeypot_ctf/ctf_scorer.py 2>/dev/null || true
sudo chattr -i /home/pi/.opencanary.conf 2>/dev/null || true
sudo chattr -i /etc/supervisor/conf.d/honeypot.conf 2>/dev/null || true
sudo chattr -i /var/lib/honeypot_ctf/backups/* 2>/dev/null || true

# Remove any immutable flags on entire directories recursively
find /home/pi/honeypot_ctf -type f -exec sudo chattr -i {} \; 2>/dev/null || true
find /var/lib/honeypot_ctf -type f -exec sudo chattr -i {} \; 2>/dev/null || true

# 3. REMOVE ALL HONEYPOT FILES AND DIRECTORIES
print_status "Removing all honeypot files..."
sudo rm -rf /home/pi/honeypot_ctf
sudo rm -rf /var/lib/honeypot_ctf
sudo rm -rf /var/log/honeypot
sudo rm -f /home/pi/.opencanary.conf
sudo rm -f /tmp/opencanary.log
sudo rm -f /var/tmp/opencanary.log

# 4. REMOVE SUPERVISOR CONFIGURATIONS
print_status "Removing supervisor configurations..."
sudo rm -f /etc/supervisor/conf.d/honeypot.conf
sudo supervisorctl reread 2>/dev/null || true
sudo supervisorctl update 2>/dev/null || true

# 5. CLEAN WEB DIRECTORIES
print_status "Cleaning web directories..."
sudo rm -rf /var/www/html/* 2>/dev/null || true

# Restore default web files if they exist
if [ -f /var/www/html.backup/index.html ]; then
    sudo cp -r /var/www/html.backup/* /var/www/html/ 2>/dev/null || true
fi

# 6. RESET NETWORK CONFIGURATIONS
print_status "Resetting network configurations..."

# Remove hostapd configuration
sudo rm -f /etc/hostapd/hostapd.conf 2>/dev/null || true

# Reset hostapd daemon config
sudo sed -i 's|DAEMON_CONF="/etc/hostapd/hostapd.conf"|#DAEMON_CONF=""|' /etc/default/hostapd 2>/dev/null || true

# Remove dnsmasq honeypot configurations
if [ -f /etc/dnsmasq.conf ]; then
    # Remove our added configurations but preserve original
    sudo cp /etc/dnsmasq.conf /etc/dnsmasq.conf.backup 2>/dev/null || true
    sudo sed -i '/# Honeypot AP DHCP/,+2d' /etc/dnsmasq.conf 2>/dev/null || true
fi

# Remove dhcpcd honeypot configurations  
if [ -f /etc/dhcpcd.conf ]; then
    sudo cp /etc/dhcpcd.conf /etc/dhcpcd.conf.backup 2>/dev/null || true
    sudo sed -i '/# Honeypot AP Interface/,+3d' /etc/dhcpcd.conf 2>/dev/null || true
fi

# Reset wlan1 interface
if ip link show wlan1 >/dev/null 2>&1; then
    sudo ip link set wlan1 down 2>/dev/null || true
    sudo ip addr flush dev wlan1 2>/dev/null || true
fi

# Kill any wpa_supplicant processes that might interfere
sudo pkill wpa_supplicant 2>/dev/null || true

# Reset IP forwarding (comment out our line)
if [ -f /etc/sysctl.conf ]; then
    sudo sed -i 's/^net.ipv4.ip_forward=1/#net.ipv4.ip_forward=1/' /etc/sysctl.conf 2>/dev/null || true
fi

# Disable network services
sudo systemctl disable hostapd 2>/dev/null || true
sudo systemctl disable dnsmasq 2>/dev/null || true

# 7. RESET SSH CONFIGURATION
print_status "Checking SSH configuration..."
if [ -f /etc/ssh/sshd_config.backup ]; then
    print_warning "SSH backup found - do you want to restore original SSH config? (y/n)"
    read -p "This will restore SSH to its original configuration: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
        sudo systemctl restart ssh
        print_status "SSH configuration restored from backup"
    else
        print_warning "SSH configuration left as-is"
    fi
else
    print_warning "No SSH backup found - leaving SSH configuration unchanged"
fi

# 8. RESET FIREWALL RULES
print_status "Resetting firewall rules..."
sudo ufw --force reset 2>/dev/null || true
sudo iptables -F 2>/dev/null || true
sudo iptables -X 2>/dev/null || true
sudo iptables -t nat -F 2>/dev/null || true
sudo iptables -t nat -X 2>/dev/null || true

# Remove persistent iptables rules
sudo rm -f /etc/iptables.rules 2>/dev/null || true
sudo rm -f /etc/iptables/rules.v4 2>/dev/null || true
sudo rm -f /etc/iptables/rules.v6 2>/dev/null || true

# 9. CLEAN CRON JOBS
print_status "Removing cron jobs..."
crontab -l 2>/dev/null | grep -v "integrity_check" | crontab - 2>/dev/null || true
crontab -l 2>/dev/null | grep -v "honeypot" | crontab - 2>/dev/null || true

# 10. CLEAN PYTHON VIRTUAL ENVIRONMENTS
print_status "Cleaning Python environments..."
# This was already handled in step 3, but being thorough
sudo rm -rf /home/pi/honeypot_ctf/venv 2>/dev/null || true

# 11. RESTART AFFECTED SERVICES
print_status "Restarting affected services..."
sudo systemctl restart supervisor 2>/dev/null || true
sudo systemctl restart networking 2>/dev/null || true

# Optional: restart network manager if it exists
sudo systemctl restart NetworkManager 2>/dev/null || true

# 12. CLEAN UP PROCESSES AND SOCKETS
print_status "Final cleanup..."
# Clean any leftover sockets
sudo rm -f /tmp/*.sock 2>/dev/null || true
sudo rm -f /var/run/*.sock 2>/dev/null || true

# Clean temporary files
sudo rm -f /tmp/opencanary* 2>/dev/null || true
sudo rm -f /tmp/honeypot* 2>/dev/null || true

# 13. FINAL VERIFICATION
print_status "Verifying cleanup..."
REMAINING_FILES=0

if [ -d "/home/pi/honeypot_ctf" ]; then
    print_warning "Main honeypot directory still exists"
    REMAINING_FILES=$((REMAINING_FILES + 1))
fi

if [ -f "/home/pi/.opencanary.conf" ]; then
    print_warning "OpenCanary config still exists"
    REMAINING_FILES=$((REMAINING_FILES + 1))
fi

if [ -f "/etc/supervisor/conf.d/honeypot.conf" ]; then
    print_warning "Supervisor config still exists"
    REMAINING_FILES=$((REMAINING_FILES + 1))
fi

if pgrep -f "opencanary\|ctf_scorer" > /dev/null; then
    print_warning "Honeypot processes still running"
    REMAINING_FILES=$((REMAINING_FILES + 1))
fi

# Final status
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
if [ $REMAINING_FILES -eq 0 ]; then
    echo -e "${GREEN}           NUCLEAR RESET COMPLETE!${NC}"
    echo -e "${GREEN}All honeypot components have been removed.${NC}"
    echo ""
    echo -e "${GREEN}System should now be clean for fresh installation.${NC}"
    echo "You can now run ./01_main.sh to reinstall from scratch."
else
    echo -e "${YELLOW}           RESET COMPLETE WITH WARNINGS${NC}"
    echo -e "${YELLOW}$REMAINING_FILES components may still remain.${NC}"
    echo ""
    echo "Check the warnings above and manually remove if needed."
    echo "You may still be able to run ./01_main.sh for fresh installation."
fi
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Reboot suggestion
print_warning "RECOMMENDATION: Reboot the system to ensure all changes take effect:"
echo "  sudo reboot"
echo ""