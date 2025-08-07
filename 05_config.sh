#!/bin/bash

# MODULE 5: Create OpenCanary Configuration

echo "[Module 5] Creating OpenCanary configuration..."

# First check if real SSH is running on port 22 and adjust if needed
SSH_PORT=22
if sudo netstat -tlnp | grep -q ":22.*sshd"; then
    echo "  Real SSH detected on port 22, using port 2222 for honeypot SSH"
    SSH_PORT=2222
fi

# Check if Apache/nginx is running on port 80
HTTP_PORT=80
if sudo netstat -tlnp | grep -q ":80.*"; then
    echo "  Real web server detected on port 80, using port 8000 for honeypot HTTP"
    HTTP_PORT=8000
fi

cat > ~/.opencanary.conf << CONFIG_EOF
{
    "device.node_id": "honeypot-ctf-01",
    "ip.ignorelist": ["127.0.0.1"],
    "git.enabled": false,
    "git.port": 9418,
    "ftp.enabled": true,
    "ftp.port": 21,
    "ftp.banner": "FTP Server Ready",
    "http.enabled": true,
    "http.port": ${HTTP_PORT},
    "http.banner": "Apache/2.4.41 (Ubuntu)",
    "http.skin": "basicLogin",
    "ssh.enabled": true,
    "ssh.port": ${SSH_PORT},
    "ssh.version": "SSH-2.0-OpenSSH_7.6p1 Ubuntu-4ubuntu0.3",
    "telnet.enabled": true,
    "telnet.port": 23,
    "telnet.banner": "Ubuntu 20.04 LTS",
    "mysql.enabled": true,
    "mysql.port": 3306,
    "mysql.banner": "5.7.28",
    "redis.enabled": true,
    "redis.port": 6379,
    "logger": {
        "class": "PyLogger",
        "kwargs": {
            "formatters": {
                "plain": {
                    "format": "%(message)s"
                }
            },
            "handlers": {
                "file": {
                    "class": "logging.FileHandler",
                    "filename": "/var/tmp/opencanary.log"
                }
            }
        }
    },
    "portscan.enabled": false,
    "portscan.synrate": 5,
    "portscan.nmaposrate": 5,
    "portscan.lorate": 3,
    "smb.enabled": false,
    "rdp.enabled": false,
    "sip.enabled": false,
    "snmp.enabled": false,
    "ntp.enabled": false,
    "tftp.enabled": false,
    "tcpbanner.enabled": false,
    "vnc.enabled": false,
    "mssql.enabled": false
}
CONFIG_EOF

echo "[Module 5] OpenCanary configured"
echo "  SSH honeypot port: ${SSH_PORT}"
echo "  HTTP honeypot port: ${HTTP_PORT}"