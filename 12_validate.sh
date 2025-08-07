#!/bin/bash

# MODULE 12: System Validation and Health Check

echo "[Module 12] Validating system deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

print_check() { echo -e "${BLUE}[CHECK]${NC} $1"; }
print_pass() { echo -e "${GREEN}[✓ PASS]${NC} $1"; }
print_fail() { echo -e "${RED}[✗ FAIL]${NC} $1"; ERRORS=$((ERRORS + 1)); }
print_warn() { echo -e "${YELLOW}[! WARN]${NC} $1"; WARNINGS=$((WARNINGS + 1)); }

echo ""
echo "======================================================"
echo "           HONEYPOT CTF VALIDATION REPORT"
echo "======================================================"
echo ""

# 1. Check directory structure
print_check "Checking directory structure..."
if [ -d "/home/pi/honeypot_ctf" ]; then
    print_pass "Main directory exists"
else
    print_fail "Main directory missing"
fi

if [ -d "/home/pi/honeypot_ctf/venv" ]; then
    print_pass "Python virtual environment exists"
else
    print_fail "Python virtual environment missing"
fi

if [ -d "/home/pi/honeypot_ctf/scripts" ]; then
    print_pass "Scripts directory exists"
else
    print_fail "Scripts directory missing"
fi

# 2. Check key files
print_check "Checking configuration files..."
if [ -f "/home/pi/.opencanary.conf" ]; then
    print_pass "OpenCanary config exists"
    if python3 -m json.tool /home/pi/.opencanary.conf > /dev/null 2>&1; then
        print_pass "OpenCanary config is valid JSON"
    else
        print_fail "OpenCanary config has invalid JSON"
    fi
else
    print_fail "OpenCanary config missing"
fi

if [ -f "/etc/supervisor/conf.d/honeypot.conf" ]; then
    print_pass "Supervisor config exists"
else
    print_fail "Supervisor config missing"
fi

# 3. Check Python environment
print_check "Validating Python environment..."
if [ -f "/home/pi/honeypot_ctf/venv/bin/python" ]; then
    print_pass "Python virtual environment active"
    
    # Check required packages
    cd /home/pi/honeypot_ctf
    source venv/bin/activate
    
    if python -c "import opencanary" 2>/dev/null; then
        print_pass "OpenCanary package installed"
    else
        print_fail "OpenCanary package missing"
    fi
    
    if python -c "import flask" 2>/dev/null; then
        print_pass "Flask package installed"
    else
        print_fail "Flask package missing"
    fi
    
    if python -c "import sqlite3" 2>/dev/null; then
        print_pass "SQLite3 package available"
    else
        print_fail "SQLite3 package missing"
    fi
    
    # Check OpenCanary executable
    if [ -f "venv/bin/opencanaryd" ]; then
        print_pass "OpenCanary daemon executable found"
    else
        print_fail "OpenCanary daemon executable missing"
    fi
    
    deactivate
else
    print_fail "Python virtual environment not found"
fi

# 4. Check services
print_check "Checking service status..."
if sudo supervisorctl status | grep -q "honeypot:opencanary.*RUNNING"; then
    print_pass "OpenCanary service running"
elif sudo supervisorctl status | grep -q "honeypot:opencanary.*FATAL"; then
    print_fail "OpenCanary service failed to start"
else
    print_warn "OpenCanary service status unknown"
fi

if sudo supervisorctl status | grep -q "honeypot:ctf_scorer.*RUNNING"; then
    print_pass "CTF Scorer service running"
elif sudo supervisorctl status | grep -q "honeypot:ctf_scorer.*FATAL"; then
    print_fail "CTF Scorer service failed to start"
else
    print_warn "CTF Scorer service status unknown"
fi

# 5. Check network ports
print_check "Checking network ports..."
if sudo netstat -tlnp | grep -q ":80.*LISTEN"; then
    print_pass "Port 80 (HTTP) is listening"
else
    print_fail "Port 80 (HTTP) not listening"
fi

if sudo netstat -tlnp | grep -q ":8080.*LISTEN"; then
    print_pass "Port 8080 (Scoreboard) is listening"
else
    print_fail "Port 8080 (Scoreboard) not listening"
fi

if sudo netstat -tlnp | grep -q ":22.*LISTEN"; then
    print_pass "Port 22 (SSH honeypot) is listening"
else
    print_warn "Port 22 (SSH) not listening (may conflict with real SSH)"
fi

if sudo netstat -tlnp | grep -q ":21.*LISTEN"; then
    print_pass "Port 21 (FTP honeypot) is listening"
else
    print_warn "Port 21 (FTP) not listening"
fi

# 6. Check log files
print_check "Checking log files..."
if [ -f "/var/tmp/opencanary.log" ]; then
    print_pass "OpenCanary log file exists"
    if [ -w "/var/tmp/opencanary.log" ]; then
        print_pass "OpenCanary log file is writable"
    else
        print_warn "OpenCanary log file not writable"
    fi
else
    print_fail "OpenCanary log file missing"
fi

if [ -f "/var/lib/honeypot_ctf/scores.db" ]; then
    print_pass "Scores database exists"
else
    print_warn "Scores database not yet created (will be created on first activity)"
fi

# 7. Check CTF flags
print_check "Checking CTF flags deployment..."
if [ -f "/var/www/html/robots.txt" ]; then
    print_pass "robots.txt flag file exists"
    if grep -q "FLAG{welcome_to_honeypot}" /var/www/html/robots.txt; then
        print_pass "Welcome flag found in robots.txt"
    else
        print_warn "Welcome flag missing from robots.txt"
    fi
else
    print_fail "robots.txt flag file missing"
fi

if [ -f "/var/www/html/index.html" ]; then
    print_pass "index.html flag file exists"
    if grep -q "FLAG{web_explorer}" /var/www/html/index.html; then
        print_pass "Web explorer flag found"
    else
        print_warn "Web explorer flag missing"
    fi
else
    print_fail "index.html flag file missing"
fi

# 8. Test HTTP responses
print_check "Testing HTTP responses..."
if curl -s http://localhost/robots.txt | grep -q "User-agent"; then
    print_pass "HTTP service responding correctly"
else
    print_fail "HTTP service not responding or returning wrong content"
fi

if curl -s http://localhost:8080 | grep -q "HONEYPOT CTF"; then
    print_pass "Scoreboard responding correctly"
else
    print_fail "Scoreboard not responding or returning wrong content"
fi

# 9. Check network configuration (if module 10 was run)
print_check "Checking network configuration..."
if ip addr show wlan1 > /dev/null 2>&1; then
    print_pass "WiFi AP interface (wlan1) exists"
    if ip addr show wlan1 | grep -q "192.168.4.1"; then
        print_pass "WiFi AP has correct IP address"
    else
        print_warn "WiFi AP IP address not configured"
    fi
    
    if sudo systemctl is-active hostapd > /dev/null 2>&1; then
        print_pass "hostapd service is active"
    else
        print_warn "hostapd service not active"
    fi
    
    if sudo systemctl is-active dnsmasq > /dev/null 2>&1; then
        print_pass "dnsmasq service is active"
    else
        print_warn "dnsmasq service not active"
    fi
else
    print_warn "WiFi AP interface not found (USB adapter may not be connected)"
fi

# 10. Check management scripts
print_check "Checking management scripts..."
if [ -f "/home/pi/honeypot_ctf/scripts/manage.sh" ]; then
    print_pass "Management script exists"
else
    print_warn "Management script missing"
fi

if [ -f "/home/pi/honeypot_ctf/scripts/reset.sh" ]; then
    print_pass "Reset script exists"
else
    print_warn "Reset script missing"
fi

# 11. Security hardening check (if module 11 was run)
print_check "Checking security hardening..."
if lsattr /home/pi/honeypot_ctf/ctf_scorer.py 2>/dev/null | grep -q "i"; then
    print_pass "Critical files are immutable"
else
    print_warn "Critical files not protected (module 11 may not have run)"
fi

# Summary
echo ""
echo "======================================================"
echo "                VALIDATION SUMMARY"
echo "======================================================"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}🎉 PERFECT! All checks passed!${NC}"
    echo "Your honeypot CTF is ready for deployment!"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}✅ GOOD! All critical checks passed with $WARNINGS warnings${NC}"
    echo "Your honeypot CTF should work, but check the warnings above."
else
    echo -e "${RED}❌ ISSUES FOUND! $ERRORS errors and $WARNINGS warnings${NC}"
    echo "Please fix the errors above before deploying."
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    IP_ADDR=$(hostname -I | awk '{print $1}')
    echo "Target IP:      $IP_ADDR"
    echo "Scoreboard:     http://$IP_ADDR:8080"
    echo "Management:     /home/pi/honeypot_ctf/scripts/manage.sh"
    echo ""
    echo "Test commands:"
    echo "  nmap $IP_ADDR"
    echo "  curl http://$IP_ADDR/robots.txt"
    echo ""
fi

echo "[Module 12] Validation complete - $ERRORS errors, $WARNINGS warnings"
exit $ERRORS