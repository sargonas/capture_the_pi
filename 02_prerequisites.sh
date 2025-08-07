#!/bin/bash

# MODULE 1: Prerequisites - Cleanup & SSH Setup
# Combines old modules: 00_cleanup.sh + 00_setup_sh.sh

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

echo "[Module 2] Prerequisites - Cleanup and SSH Setup"

# ==========================================
# CLEANUP PREVIOUS INSTALLATION
# ==========================================

echo "[Module 2] Cleaning up previous installation..."

# Remove immutable flags
echo "Removing file protection..."
sudo chattr -i /home/pi/honeypot_ctf/ctf_scorer.py 2>/dev/null || true
sudo chattr -i /home/pi/.opencanary.conf 2>/dev/null || true
sudo chattr -i /etc/supervisor/conf.d/honeypot.conf 2>/dev/null || true
find /home/pi/honeypot_ctf -type f -exec sudo chattr -i {} \; 2>/dev/null || true

# Stop services more aggressively
echo "Stopping services..."
sudo supervisorctl stop honeypot:* 2>/dev/null || true
sudo pkill -f opencanary 2>/dev/null || true
sudo pkill -f ctf_scorer 2>/dev/null || true
sudo systemctl stop hostapd 2>/dev/null || true
sudo systemctl stop dnsmasq 2>/dev/null || true

# Wait for processes to stop
sleep 2

# Remove old installations
echo "Removing old files..."
sudo rm -rf /home/pi/honeypot_ctf 2>/dev/null || true
sudo rm -rf /var/lib/honeypot_ctf 2>/dev/null || true
sudo rm -rf /var/log/honeypot 2>/dev/null || true
sudo rm -f /home/pi/.opencanary.conf 2>/dev/null || true
sudo rm -f /etc/supervisor/conf.d/honeypot.conf 2>/dev/null || true
sudo rm -f /tmp/opencanary.log 2>/dev/null || true
sudo rm -f /var/tmp/opencanary.log 2>/dev/null || true

# Clean web directory
sudo rm -rf /var/www/html/* 2>/dev/null || true

# Reset iptables (if set)
sudo iptables -F 2>/dev/null || true
sudo iptables -X 2>/dev/null || true
sudo iptables -t nat -F 2>/dev/null || true

# Remove cron jobs (integrity checking)
crontab -l 2>/dev/null | grep -v "integrity_check" | crontab - 2>/dev/null || true

# Update supervisor to remove stale configs
sudo supervisorctl reread 2>/dev/null || true
sudo supervisorctl update 2>/dev/null || true

echo "Cleanup complete"

# ==========================================
# SSH SETUP - MOVE TO PORT 2022
# ==========================================

echo "[Module 2] Moving real SSH to port 2022..."

# Check if SSH is currently on port 22
if sudo netstat -tlnp | grep -q ":22.*sshd"; then
    echo -e "${YELLOW}Real SSH detected on port 22${NC}"
    echo "Moving it to port 2022 for administration..."
    
    # Backup original SSH config
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Check if Port 2022 is already configured
    if grep -q "^Port 2022" /etc/ssh/sshd_config; then
        echo "Port 2022 already configured"
    else
        # Add Port 2022 (keeping Port 22 temporarily for safety)
        echo -e "${YELLOW}Adding Port 2022 to SSH configuration...${NC}"
        sudo sed -i '/^#Port 22/a Port 22\nPort 2022' /etc/ssh/sshd_config
        
        # If no Port line exists, add it
        if ! grep -q "^Port" /etc/ssh/sshd_config; then
            sudo sed -i '1i Port 22\nPort 2022' /etc/ssh/sshd_config
        fi
    fi
    
    # Restart SSH to listen on both ports temporarily
    echo "Restarting SSH to listen on both ports temporarily..."
    sudo systemctl restart ssh
    
    sleep 2
    
    # Verify SSH is listening on port 2022
    if sudo netstat -tlnp | grep -q ":2022.*sshd"; then
        echo -e "${GREEN}✓ SSH is now listening on port 2022${NC}"
        
        echo ""
        echo -e "${YELLOW}IMPORTANT: Before proceeding, test the new SSH port!${NC}"
        echo "Open a NEW terminal and connect with:"
        echo -e "${GREEN}  ssh -p 2022 pi@$(hostname -I | awk '{print $1}')${NC}"
        echo ""
        read -p "Have you verified you can connect on port 2022? (y/n): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Now remove port 22 from SSH config
            echo "Removing port 22 from SSH configuration..."
            sudo sed -i '/^Port 22$/d' /etc/ssh/sshd_config
            
            # Restart SSH to only listen on 2022
            echo "Restarting SSH to only listen on port 2022..."
            sudo systemctl restart ssh
            
            sleep 2
            
            # Verify port 22 is free
            if ! sudo netstat -tlnp | grep -q ":22.*sshd"; then
                echo -e "${GREEN}✓ Port 22 is now free for the honeypot${NC}"
                echo -e "${GREEN}✓ Real SSH is running on port 2022${NC}"
            else
                echo -e "${RED}Warning: SSH still appears to be on port 22${NC}"
            fi
        else
            echo -e "${RED}Aborting! Keeping SSH on both ports for safety.${NC}"
            echo "Please verify you can connect on port 2022 before continuing."
            exit 1
        fi
    else
        echo -e "${RED}Failed to start SSH on port 2022!${NC}"
        echo "Reverting configuration..."
        sudo cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
        sudo systemctl restart ssh
        exit 1
    fi
else
    echo -e "${GREEN}Port 22 is already free (SSH not detected)${NC}"
    
    # Still configure SSH for port 2022 if it exists
    if [ -f /etc/ssh/sshd_config ]; then
        if ! grep -q "^Port 2022" /etc/ssh/sshd_config; then
            echo "Configuring SSH to use port 2022..."
            sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
            sudo sed -i 's/^#*Port 22/Port 2022/' /etc/ssh/sshd_config
            
            if ! grep -q "^Port" /etc/ssh/sshd_config; then
                sudo sed -i '1i Port 2022' /etc/ssh/sshd_config
            fi
            
            sudo systemctl restart ssh 2>/dev/null || true
        fi
    fi
fi

# Update firewall rules if ufw is active
if sudo ufw status | grep -q "Status: active"; then
    echo "Updating firewall rules..."
    sudo ufw allow 2022/tcp comment 'SSH Admin'
    # Don't delete port 22 rule yet - honeypot will use it
fi

echo ""
echo -e "${GREEN}[Module 2] Prerequisites complete!${NC}"
echo "  Administration SSH: Port 2022"
echo "  CTF Honeypot SSH: Port 22 (available for OpenCanary)"
echo ""
echo -e "${YELLOW}Remember to always connect with: ssh -p 2022 pi@<ip>${NC}"