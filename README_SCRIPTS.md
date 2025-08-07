# Honeypot CTF Scripts - Quick Reference

## Script Overview

### Main Installation
- `01_main.sh` - **Main installer** - Run this to install everything

### Individual Modules (run automatically by main)
- `02_prerequisites.sh` - Cleanup + SSH setup (move to port 2022)
- `03_environment.sh` - System packages + Python virtual environment  
- `04_application.sh` - CTF scorer + OpenCanary configuration
- `05_content.sh` - Deploy all 25 CTF flags to web server
- `06_network.sh` - WiFi Access Point setup ("Open_Playground")
- `07_security.sh` - System hardening and file protection
- `08_services.sh` - Supervisor, management scripts, start services
- `09_finalize.sh` - Validation and final checks

### Reset Options
- `00_nuke_reset.sh` - **NUCLEAR OPTION** - Complete removal of everything

### WiFi Troubleshooting Tools
- `check_wifi_compatibility.sh` - **Check WiFi adapter compatibility BEFORE installing**
- `wifi_troubleshoot.sh` - **Diagnose WiFi AP issues after installation**

## Usage

### Fresh Installation
```bash
# RECOMMENDED: Check WiFi compatibility first
./check_wifi_compatibility.sh

# Standard install
./01_main.sh

# Or step by step for troubleshooting
bash 02_prerequisites.sh
bash 03_environment.sh
# ... etc
```

### Re-installation on Dirty System
```bash
# Option 1: Let regular cleanup handle it (usually works)
./01_main.sh

# Option 2: Nuclear reset first (if regular cleanup fails)
./00_nuke_reset.sh
# Then after reboot:
./01_main.sh
```

### Management After Install
```bash
# Management console
/home/pi/honeypot_ctf/scripts/manage.sh

# Quick reset scores
/home/pi/honeypot_ctf/scripts/reset.sh

# Check status
sudo supervisorctl status
```

## Key Features

- **SSH Admin**: Port 2022 (real SSH)
- **Honeypot Services**: Ports 21,22,23,80,3306,6379 (OpenCanary)
- **Scoreboard**: Port 8080 (CTF dashboard)
- **WiFi AP**: "Open_Playground" on wlan1 (192.168.4.0/24)
- **CTF Flags**: 25 flags worth 100-1500 points each
- **Logging**: /tmp/opencanary.log (fixed permissions)

## Resilience Features

### Regular Installation (`01_main.sh`):
✅ Stops running services first
✅ Removes file protections  
✅ Cleans old files and directories
✅ Updates supervisor configs
✅ Should work on systems with previous installs

### Nuclear Reset (`00_nuke_reset.sh`):
🚨 **USE WITH CAUTION** - Requires typing "NUKE" to confirm
✅ Force kills all processes
✅ Removes ALL honeypot traces
✅ Resets network configurations
✅ Offers to restore SSH from backup
✅ Resets firewall rules completely
✅ Comprehensive cleanup verification

## Common Issues

1. **Permission Denied**: Make sure scripts are executable (`chmod +x *.sh`)
2. **SSH Locked Out**: Scripts move real SSH to port 2022 - connect with `ssh -p 2022 pi@<ip>`
3. **Services Won't Start**: Check logs with `/home/pi/honeypot_ctf/scripts/manage.sh`
4. **WiFi AP Not Working**: 
   - Run `./wifi_troubleshoot.sh` to diagnose
   - Check USB WiFi adapter supports AP mode
   - Try `./check_wifi_compatibility.sh` before installing
5. **Scores Not Working**: Check `/tmp/opencanary.log` exists and is writable
6. **hostapd Failed**: 
   - Common with cheap WiFi adapters that don't support AP mode
   - Installation will continue without WiFi (wired network still works)
   - Use `./wifi_troubleshoot.sh` for detailed diagnosis

## File Structure Created
```
/home/pi/honeypot_ctf/
├── venv/                    # Python virtual environment
├── ctf_scorer.py           # Main scoring application
└── scripts/
    ├── manage.sh           # Management console
    └── reset.sh           # Reset scores

/var/lib/honeypot_ctf/
├── scores.db              # SQLite scoring database
└── backups/               # Config backups

/var/www/html/             # CTF flags and web content
├── robots.txt             # FLAG{welcome_to_honeypot}
├── index.html            # FLAG{web_explorer}
├── admin/                # FLAG{admin_access}
├── config/               # Multiple flags
├── .hidden/              # FLAG{hidden_discovery}
└── ... (25 total flags)
```

## Testing Commands
```bash
# Test honeypot services
nmap <pi_ip>

# Test web flags  
curl http://<pi_ip>/robots.txt

# Check scoreboard
curl http://<pi_ip>:8080

# SSH admin access
ssh -p 2022 pi@<pi_ip>
```