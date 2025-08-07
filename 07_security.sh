#!/bin/bash

# MODULE 6: Security Setup - System Hardening

set -e

echo "[Module 7] Security Setup - System Hardening"

# Protect critical files (supervisor config protected later in services module)
sudo chattr +i /home/pi/honeypot_ctf/ctf_scorer.py 2>/dev/null || true
sudo chattr +i /home/pi/.opencanary.conf 2>/dev/null || true

# Set restrictive permissions
sudo chmod 755 /home/pi/honeypot_ctf
sudo chmod 644 /home/pi/honeypot_ctf/ctf_scorer.py
sudo chmod 644 /home/pi/.opencanary.conf

# Create backup of critical configs
sudo mkdir -p /var/lib/honeypot_ctf/backups
sudo cp /home/pi/.opencanary.conf /var/lib/honeypot_ctf/backups/opencanary.conf 2>/dev/null || true
sudo cp /etc/supervisor/conf.d/honeypot.conf /var/lib/honeypot_ctf/backups/ 2>/dev/null || true
sudo cp /home/pi/honeypot_ctf/ctf_scorer.py /var/lib/honeypot_ctf/backups/ 2>/dev/null || true

# Set up basic firewall
sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.1.0/24
sudo ufw allow from 192.168.4.0/24 to any port 21,22,23,80,3306,6379,8080,161

echo "[Module 7] System hardened"