#!/bin/bash

# MODULE 8: Finalization - System Validation

set -e

echo "[Module 9] Finalization - System Validation"

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

# Check directory structure
print_check "Checking directory structure..."
[ -d "/home/pi/honeypot_ctf" ] && print_pass "Main directory exists" || print_fail "Main directory missing"
[ -d "/home/pi/honeypot_ctf/venv" ] && print_pass "Python virtual environment exists" || print_fail "Python virtual environment missing"
[ -d "/home/pi/honeypot_ctf/scripts" ] && print_pass "Scripts directory exists" || print_fail "Scripts directory missing"

# Check configuration files
print_check "Checking configuration files..."
if [ -f "/home/pi/.opencanary.conf" ]; then
    print_pass "OpenCanary config exists"
    python3 -m json.tool /home/pi/.opencanary.conf > /dev/null 2>&1 && print_pass "OpenCanary config is valid JSON" || print_fail "OpenCanary config has invalid JSON"
else
    print_fail "OpenCanary config missing"
fi
[ -f "/etc/supervisor/conf.d/honeypot.conf" ] && print_pass "Supervisor config exists" || print_fail "Supervisor config missing"

# Check services
print_check "Checking service status..."
sudo supervisorctl status | grep -q "honeypot:opencanary.*RUNNING" && print_pass "OpenCanary service running" || print_warn "OpenCanary service not running"
sudo supervisorctl status | grep -q "honeypot:ctf_scorer.*RUNNING" && print_pass "CTF Scorer service running" || print_warn "CTF Scorer service not running"

# Check network ports
print_check "Checking network ports..."
sudo netstat -tlnp | grep -q ":80.*LISTEN" && print_pass "Port 80 (HTTP) is listening" || print_fail "Port 80 (HTTP) not listening"
sudo netstat -tlnp | grep -q ":8080.*LISTEN" && print_pass "Port 8080 (Scoreboard) is listening" || print_fail "Port 8080 (Scoreboard) not listening"

# Check log files
print_check "Checking log files..."
if [ -f "/tmp/opencanary.log" ]; then
    print_pass "OpenCanary log file exists"
    [ -w "/tmp/opencanary.log" ] && print_pass "OpenCanary log file is writable" || print_warn "OpenCanary log file not writable"
else
    print_fail "OpenCanary log file missing"
fi

# Check CTF flags
print_check "Checking CTF flags deployment..."
if [ -f "/var/www/html/robots.txt" ]; then
    print_pass "robots.txt flag file exists"
    grep -q "FLAG{welcome_to_honeypot}" /var/www/html/robots.txt && print_pass "Welcome flag found in robots.txt" || print_warn "Welcome flag missing from robots.txt"
else
    print_fail "robots.txt flag file missing"
fi

# Test HTTP responses
print_check "Testing HTTP responses..."
curl -s http://localhost/robots.txt | grep -q "User-agent" && print_pass "HTTP service responding correctly" || print_fail "HTTP service not responding correctly"
curl -s http://localhost:8080 | grep -q "HONEYPOT CTF" && print_pass "Scoreboard responding correctly" || print_fail "Scoreboard not responding correctly"

# Summary
echo ""
echo "======================================================"
echo "                VALIDATION SUMMARY"
echo "======================================================"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}🎉 PERFECT! All checks passed!${NC}"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}✅ GOOD! All critical checks passed with $WARNINGS warnings${NC}"
else
    echo -e "${RED}❌ ISSUES FOUND! $ERRORS errors and $WARNINGS warnings${NC}"
fi

if [ $ERRORS -eq 0 ]; then
    IP_ADDR=$(hostname -I | awk '{print $1}')
    echo ""
    echo "Target IP:      $IP_ADDR"
    echo "Scoreboard:     http://$IP_ADDR:8080"
    echo "Management:     /home/pi/honeypot_ctf/scripts/manage.sh"
    echo "Admin SSH:      ssh -p 2022 pi@$IP_ADDR"
    echo "WiFi AP:        Open_Playground (192.168.4.0/24)"
fi

echo ""
echo "[Module 9] Validation complete - $ERRORS errors, $WARNINGS warnings"
exit $ERRORS