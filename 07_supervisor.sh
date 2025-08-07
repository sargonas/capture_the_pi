#!/bin/bash

# MODULE 7: Configure Supervisor

echo "[Module 7] Configuring supervisor..."

# Create supervisor configuration
sudo tee /etc/supervisor/conf.d/honeypot.conf > /dev/null << 'SUPER_EOF'
[group:honeypot]
programs=opencanary,ctf_scorer

[program:opencanary]
command=/home/pi/honeypot_ctf/venv/bin/opencanaryd --dev
directory=/home/pi/honeypot_ctf
user=pi
autostart=true
autorestart=true
stderr_logfile=/var/log/honeypot/opencanary.err.log
stdout_logfile=/var/log/honeypot/opencanary.out.log

[program:ctf_scorer]
command=/home/pi/honeypot_ctf/venv/bin/python /home/pi/honeypot_ctf/ctf_scorer.py
directory=/home/pi/honeypot_ctf
user=pi
autostart=true
autorestart=true
stderr_logfile=/var/log/honeypot/scorer.err.log
stdout_logfile=/var/log/honeypot/scorer.out.log
SUPER_EOF

# Update supervisor
sudo supervisorctl reread
sudo supervisorctl update

echo "[Module 7] Supervisor configured"