#!/bin/bash

# MODULE 9: Start Services

echo "[Module 9] Starting services..."

# Create initial log file
touch /var/tmp/opencanary.log

# Start services
sudo supervisorctl start honeypot:*

# Wait a moment
sleep 3

# Check status
echo ""
echo "Service status:"
sudo supervisorctl status | grep honeypot

echo ""
echo "[Module 9] Services started"