#!/bin/bash

# MODULE 2: System Package Installation

echo "[Module 2] Installing system packages..."

# Update package lists
sudo apt-get update

# Install required packages
sudo apt-get install -y \
    python3-dev \
    python3-pip \
    python3-venv \
    supervisor \
    sqlite3 \
    net-tools

# Create directories
sudo mkdir -p /var/lib/honeypot_ctf
sudo mkdir -p /var/lib/honeypot_ctf/backups
sudo mkdir -p /var/log/honeypot
sudo mkdir -p /var/www/html

# Set permissions
sudo chown $USER:$USER /var/lib/honeypot_ctf
sudo chown $USER:$USER /var/lib/honeypot_ctf/backups
sudo chown $USER:$USER /var/log/honeypot

# Create and set permissions for log file
sudo touch /var/tmp/opencanary.log
sudo chown $USER:$USER /var/tmp/opencanary.log
sudo chmod 664 /var/tmp/opencanary.log

# Create base directory
mkdir -p /home/pi/honeypot_ctf
mkdir -p /home/pi/honeypot_ctf/scripts

echo "[Module 2] System setup complete"