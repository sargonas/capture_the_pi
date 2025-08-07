#!/bin/bash
# MODULE 10: Dual Network Setup
echo "[Module 10] Setting up dual network configuration..."
# Install hostapd and dnsmasq for AP
sudo apt-get install -y hostapd dnsmasq iptables-persistent
# Stop services while configuring
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq
# Create isolated network interface config
sudo tee -a /etc/dhcpcd.conf << 'DHCP_EOF'
# Honeypot AP Interface
interface wlan1
static ip_address=192.168.4.1/24
nohook wpa_supplicant
DHCP_EOF
# Configure hostapd for open AP
sudo tee /etc/hostapd/hostapd.conf << 'HOSTAPD_EOF'
interface=wlan1
driver=nl80211
ssid=PLAYGROUND
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=0
HOSTAPD_EOF
# Configure dnsmasq for DHCP on AP
sudo tee -a /etc/dnsmasq.conf << 'DNSMASQ_EOF'
# Honeypot AP DHCP
interface=wlan1
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
DNSMASQ_EOF
# Enable IP forwarding and NAT (but isolate the networks)
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
# Create iptables rules for network isolation
sudo tee /etc/iptables.rules << 'IPTABLES_EOF'
*filter
:INPUT ACCEPT [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
# Allow loopback
-A INPUT -i lo -j ACCEPT
# Allow established connections
-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# Allow management network (adjust range as needed)
-A INPUT -s 192.168.1.0/24 -j ACCEPT
-A INPUT -s 10.0.0.0/8 -j ACCEPT
# Allow honeypot network to honeypot services only
-A INPUT -s 192.168.4.0/24 -p tcp --dport 21 -j ACCEPT
-A INPUT -s 192.168.4.0/24 -p tcp --dport 22 -j ACCEPT
-A INPUT -s 192.168.4.0/24 -p tcp --dport 23 -j ACCEPT
-A INPUT -s 192.168.4.0/24 -p tcp --dport 80 -j ACCEPT
-A INPUT -s 192.168.4.0/24 -p tcp --dport 3306 -j ACCEPT
-A INPUT -s 192.168.4.0/24 -p tcp --dport 6379 -j ACCEPT
-A INPUT -s 192.168.4.0/24 -p tcp --dport 8080 -j ACCEPT
-A INPUT -s 192.168.4.0/24 -p udp --dport 161 -j ACCEPT
# Block everything else from honeypot network
-A INPUT -s 192.168.4.0/24 -j DROP
COMMIT
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
# No internet access for honeypot network
# (Remove these lines if you want to allow internet)
COMMIT
IPTABLES_EOF
# Apply iptables rules
sudo iptables-restore < /etc/iptables.rules
# Save iptables rules to persist
sudo sh -c "iptables-save > /etc/iptables/rules.v4"
# Enable services
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl enable dnsmasq

# Create network status script
cat > /home/pi/honeypot_ctf/scripts/network_status.sh << 'NETWORK_EOF'
#!/bin/bash
echo "Network Status:"
echo "=============="
echo "Management Interface:"
ip addr show eth0 2>/dev/null || ip addr show wlan0
echo ""
echo "Honeypot AP Interface:"
ip addr show wlan1 2>/dev/null || echo "wlan1 not found"
echo ""
echo "AP Status:"
sudo systemctl is-active hostapd
sudo systemctl is-active dnsmasq
echo ""
echo "Connected Devices:"
sudo grep DHCPACK /var/log/syslog | tail -5
NETWORK_EOF

chmod +x /home/pi/honeypot_ctf/scripts/network_status.sh

echo "[Module 10] Network configuration complete"
echo "[Module 10] Network status script created"
echo "  Management: eth0 or wlan0 (your existing connection)"
echo "  Honeypot AP: wlan1 (USB adapter) - SSID: FREE_WIFI_DEFCON"
echo "  Honeypot network: 192.168.4.0/24"