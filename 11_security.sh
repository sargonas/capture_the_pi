#!/bin/bash

# MODULE 11: Security Hardening

echo "[Module 11] Hardening system against tampering..."

# Protect critical files and directories
sudo chattr +i /home/pi/honeypot_ctf/ctf_scorer.py
sudo chattr +i /etc/opencanaryd/opencanary.conf
sudo chattr +i /etc/supervisor/conf.d/honeypot.conf

# Set restrictive permissions on honeypot directory
sudo chmod 755 /home/pi/honeypot_ctf
sudo chmod 644 /home/pi/honeypot_ctf/ctf_scorer.py
sudo chmod 644 /etc/opencanaryd/opencanary.conf

# Protect database and logs
sudo chown root:root /var/lib/honeypot_ctf
sudo chmod 755 /var/lib/honeypot_ctf
sudo touch /var/lib/honeypot_ctf/scores.db
sudo chown pi:pi /var/lib/honeypot_ctf/scores.db
sudo chmod 644 /var/lib/honeypot_ctf/scores.db

# Protect log files
sudo touch /var/tmp/opencanary.log
sudo chown pi:pi /var/tmp/opencanary.log
sudo chmod 664 /var/tmp/opencanary.log

# Create backup of critical configs
sudo mkdir -p /var/lib/honeypot_ctf/backups
sudo cp /etc/opencanaryd/opencanary.conf /var/lib/honeypot_ctf/backups/
sudo cp /etc/supervisor/conf.d/honeypot.conf /var/lib/honeypot_ctf/backups/
sudo cp /home/pi/honeypot_ctf/ctf_scorer.py /var/lib/honeypot_ctf/backups/

# Remove dangerous tools that could be used for tampering
sudo apt-get remove -y \
    gcc \
    make \
    build-essential \
    python3-dev \
    git 2>/dev/null || true

# Disable unused services
sudo systemctl disable bluetooth 2>/dev/null || true
sudo systemctl disable avahi-daemon 2>/dev/null || true

# Set up file integrity monitoring for critical files
cat > /home/pi/honeypot_ctf/scripts/integrity_check.sh << 'INTEGRITY_EOF'
#!/bin/bash
echo "Checking file integrity..."

BACKUP_DIR="/var/lib/honeypot_ctf/backups"
ERRORS=0

# Check critical files
if ! cmp -s /etc/opencanaryd/opencanary.conf $BACKUP_DIR/opencanary.conf; then
    echo "WARNING: OpenCanary config has been modified!"
    ERRORS=$((ERRORS + 1))
fi

if ! cmp -s /home/pi/honeypot_ctf/ctf_scorer.py $BACKUP_DIR/ctf_scorer.py; then
    echo "WARNING: CTF scorer has been modified!"
    ERRORS=$((ERRORS + 1))
fi

if ! cmp -s /etc/supervisor/conf.d/honeypot.conf $BACKUP_DIR/honeypot.conf; then
    echo "WARNING: Supervisor config has been modified!"
    ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -eq 0 ]; then
    echo "All files intact"
else
    echo "$ERRORS files have been modified!"
    # Optionally restore from backup
    read -p "Restore from backup? (y/n): " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo cp $BACKUP_DIR/opencanary.conf /etc/opencanaryd/
        sudo cp $BACKUP_DIR/ctf_scorer.py /home/pi/honeypot_ctf/
        sudo cp $BACKUP_DIR/honeypot.conf /etc/supervisor/conf.d/
        sudo supervisorctl restart honeypot:*
        echo "Files restored and services restarted"
    fi
fi
INTEGRITY_EOF

chmod +x /home/pi/honeypot_ctf/scripts/integrity_check.sh

# Create tamper detection cron job
(crontab -l 2>/dev/null; echo "*/5 * * * * /home/pi/honeypot_ctf/scripts/integrity_check.sh >> /var/log/honeypot/integrity.log 2>&1") | crontab -

# Restrict sudo access (remove pi from sudo group for production)
# Uncomment next line for maximum security (you'll lose sudo access!)
# sudo deluser pi sudo

# Hide process information from other users
echo "proc /proc proc defaults,hidepid=2 0 0" | sudo tee -a /etc/fstab

# Set up basic firewall (in addition to iptables from module 10)
sudo ufw --force enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.1.0/24  # Management network
sudo ufw allow from 192.168.4.0/24 to any port 21,22,23,80,3306,6379,8080,161  # Honeypot services

echo "[Module 11] System hardened"
echo "WARNING: Some development tools have been removed"
echo "File integrity monitoring enabled (check every 5 minutes)"
echo "Run integrity_check.sh manually to verify system integrity"