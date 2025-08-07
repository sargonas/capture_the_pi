#!/bin/bash

# HONEYPOT CTF - MAIN INSTALLER CONTROLLER
# This runs all the other modules in order

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

# Check not root
if [[ $EUID -eq 0 ]]; then
    print_error "Don't run as root! Use pi user"
    exit 1
fi

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}         HONEYPOT CTF MODULAR INSTALLER${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Check all modules exist
MODULES=(
    "02_prerequisites.sh"
    "03_environment.sh"
    "04_application.sh"
    "05_content.sh"
    "06_network.sh"
    "07_security.sh"
    "08_services.sh"
    "09_finalize.sh"
)

print_status "Checking modules..."
for module in "${MODULES[@]}"; do
    if [ ! -f "$module" ]; then
        print_error "Missing module: $module"
        print_warning "Make sure all module files are in the same directory!"
        exit 1
    fi
done

print_status "All modules found!"
echo ""
read -p "Start installation? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Installation cancelled"
    exit 1
fi

# Run each module
for module in "${MODULES[@]}"; do
    echo ""
    print_status "Running $module..."
    bash "$module"
    if [ $? -ne 0 ]; then
        print_error "Module $module failed!"
        exit 1
    fi
done

# Final message
IP_ADDR=$(hostname -I | awk '{print $1}')

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}           INSTALLATION COMPLETE!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Target IP:  ${IP_ADDR}"
echo "Scoreboard: http://${IP_ADDR}:8080"
echo ""
echo "Test with:"
echo "  nmap ${IP_ADDR}"
echo "  curl http://${IP_ADDR}/robots.txt"
echo ""
echo "Management:"
echo "  /home/pi/honeypot_ctf/scripts/manage.sh"
echo "  /home/pi/honeypot_ctf/scripts/reset.sh"
echo ""