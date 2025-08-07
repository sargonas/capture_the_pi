#!/bin/bash

# MODULE 7: Services Setup - Supervisor & Management Scripts

set -e

echo "[Module 8] Services Setup"

# Configure supervisor
cat << 'EOF' | sudo tee /etc/supervisor/conf.d/honeypot.conf > /dev/null
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
EOF

# Update supervisor
sudo supervisorctl reread
sudo supervisorctl update

# Create management script
cat << 'EOF' > /home/pi/honeypot_ctf/scripts/manage.sh
#!/bin/bash
clear
echo "=============================="
echo "  HONEYPOT CTF MANAGEMENT"
echo "=============================="
echo ""
echo "1) View service status"
echo "2) View top scores"
echo "3) Reset scores"
echo "4) Restart services"
echo "5) View logs"
echo "6) Exit"
echo ""
read -p "Choice: " choice

case $choice in
    1) sudo supervisorctl status;;
    2) sqlite3 -column -header /var/lib/honeypot_ctf/scores.db "SELECT username, total_score FROM players ORDER BY total_score DESC LIMIT 10" 2>/dev/null || echo "No scores yet";;
    3) sudo supervisorctl stop honeypot:ctf_scorer; rm -f /var/lib/honeypot_ctf/scores.db; > /tmp/opencanary.log; sudo supervisorctl start honeypot:ctf_scorer; echo "Reset complete!";;
    4) sudo supervisorctl restart honeypot:*;;
    5) tail -20 /tmp/opencanary.log;;
    6) exit 0;;
esac
EOF

chmod +x /home/pi/honeypot_ctf/scripts/manage.sh

# Create reset script
cat << 'EOF' > /home/pi/honeypot_ctf/scripts/reset.sh
#!/bin/bash
echo "Resetting scores..."
sudo supervisorctl stop honeypot:ctf_scorer
rm -f /var/lib/honeypot_ctf/scores.db
> /tmp/opencanary.log
sudo supervisorctl start honeypot:ctf_scorer
echo "Reset complete!"
EOF

chmod +x /home/pi/honeypot_ctf/scripts/reset.sh

# Protect supervisor config now that it exists
sudo chattr +i /etc/supervisor/conf.d/honeypot.conf 2>/dev/null || true

# Start services
touch /tmp/opencanary.log
chmod 666 /tmp/opencanary.log
sudo supervisorctl start honeypot:*

echo "[Module 8] Services configured and started"