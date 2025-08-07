#!/bin/bash

# MODULE 8: Create Management Scripts

echo "[Module 8] Creating management scripts..."

# Create reset script
cat > /home/pi/honeypot_ctf/scripts/reset.sh << 'RESET_EOF'
#!/bin/bash
echo "Resetting scores..."
sudo supervisorctl stop honeypot:ctf_scorer
rm -f /var/lib/honeypot_ctf/scores.db
> /var/tmp/opencanary.log
sudo supervisorctl start honeypot:ctf_scorer
echo "Reset complete!"
RESET_EOF

# Create management console
cat > /home/pi/honeypot_ctf/scripts/manage.sh << 'MANAGE_EOF'
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
    1)
        sudo supervisorctl status
        ;;
    2)
        sqlite3 -column -header /var/lib/honeypot_ctf/scores.db \
            "SELECT username, total_score FROM players ORDER BY total_score DESC LIMIT 10" 2>/dev/null \
            || echo "No scores yet"
        ;;
    3)
        bash /home/pi/honeypot_ctf/scripts/reset.sh
        ;;
    4)
        sudo supervisorctl restart honeypot:*
        ;;
    5)
        tail -20 /var/tmp/opencanary.log
        ;;
    6)
        exit 0
        ;;
esac
MANAGE_EOF

# Create status script
cat > /home/pi/honeypot_ctf/scripts/status.sh << 'STATUS_EOF'
#!/bin/bash
IP=$(hostname -I | awk '{print $1}')
echo "Honeypot CTF Status"
echo "=================="
echo "IP: $IP"
echo "Scoreboard: http://$IP:8080"
echo ""
sudo supervisorctl status | grep honeypot
STATUS_EOF

# Make all scripts executable
chmod +x /home/pi/honeypot_ctf/scripts/*.sh

echo "[Module 8] Management scripts created"