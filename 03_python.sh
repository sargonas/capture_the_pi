#!/bin/bash

# MODULE 3: Python Virtual Environment Setup

echo "[Module 3] Setting up Python environment..."

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
pip install opencanary
pip install flask
pip install requests
pip install scapy

# Try to install optional packages
pip install tailer 2>/dev/null || echo "Tailer not available (optional)"

deactivate

echo "[Module 3] Python environment ready"