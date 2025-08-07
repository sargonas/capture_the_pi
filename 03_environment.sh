#!/bin/bash

# MODULE 2: Environment Setup - System Packages & Python
# Combines old modules: 02_system.sh + 03_python.sh

set -e

echo "[Module 3] Environment Setup - System Packages & Python"

# ==========================================
# SYSTEM PACKAGE INSTALLATION
# ==========================================

echo "[Module 3] Installing system packages..."

# Update package lists
sudo apt-get update

# Install required packages
sudo apt-get install -y \
    python3-dev \
    python3-pip \
    python3-venv \
    supervisor \
    sqlite3 \
    net-tools \
    curl \
    hostapd \
    dnsmasq \
    iptables-persistent

# Create all necessary directories at once
echo "Creating directory structure..."
sudo mkdir -p /var/lib/honeypot_ctf/backups
sudo mkdir -p /var/log/honeypot  
sudo mkdir -p /var/www/html
mkdir -p /home/pi/honeypot_ctf/scripts

# Set permissions
sudo chown $USER:$USER /var/lib/honeypot_ctf
sudo chown $USER:$USER /var/lib/honeypot_ctf/backups
sudo chown $USER:$USER /var/log/honeypot

# Create and set permissions for log file (using /tmp for write permissions)
sudo touch /tmp/opencanary.log
sudo chown $USER:$USER /tmp/opencanary.log
sudo chmod 666 /tmp/opencanary.log

echo "System packages installed"

# ==========================================
# PYTHON VIRTUAL ENVIRONMENT SETUP
# ==========================================

echo "[Module 3] Setting up Python environment..."

mkdir -p /home/pi/honeypot_ctf
cd /home/pi/honeypot_ctf

# Remove old venv if exists
if [ -d "venv" ]; then
    echo "Removing old virtual environment..."
    rm -rf venv
fi

# Create virtual environment
python3 -m venv venv

# Activate and install packages
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install required packages
echo "Installing Python packages..."
pip install opencanary
pip install flask
pip install requests
pip install scapy

# Try to install optional packages
pip install tailer 2>/dev/null || echo "Tailer not available (optional)"

deactivate

echo "[Module 3] Environment setup complete"
echo "  System packages: installed"
echo "  Python environment: ready"
echo "  Directories: created"
echo "  Permissions: configured"