#!/bin/bash

# MODULE 0: Cleanup Previous Installation

echo "[Module 0] Cleaning up previous installation..."

# Remove immutable flags
echo "Removing file protection..."
sudo chattr -i /home/pi/honeypot_ctf/ctf_scorer.py 2>/dev/null || true
sudo chattr -i /home/pi/.opencanary.conf 2>/dev/null || true
sudo chattr -i /etc/supervisor/conf.d/honeypot.conf 2>/dev/null || true

# Stop services
echo "Stopping services..."
sudo supervisorctl stop honeypot:* 2>/dev/null || true
sudo systemctl stop hostapd 2>/dev/null || true
sudo systemctl stop dnsmasq 2>/dev/null || true

# Remove old installations
echo "Removing old files..."
sudo rm -rf /home/pi/honeypot_ctf 2>/dev/null || true
sudo rm -f /home/pi/.opencanary.conf 2>/dev/null || true
sudo rm -f /etc/supervisor/conf.d/honeypot.conf 2>/dev/null || true

# Clean web directory
sudo rm -rf /var/www/html/* 2>/dev/null || true

# Reset iptables (if set)
sudo iptables -F 2>/dev/null || true
sudo iptables -X 2>/dev/null || true

# Remove cron jobs (integrity checking)
crontab -l 2>/dev/null | grep -v "integrity_check" | crontab - 2>/dev/null || true

echo "[Module 0] Cleanup complete"