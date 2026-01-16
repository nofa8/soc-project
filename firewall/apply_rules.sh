#!/bin/sh

# SOC Firewall Rules - Docker Compatible
# Uses interface-based filtering to avoid conflicts with Docker networking

# 1. Create/Flush Custom Chain
iptables -N SOC_ALLOW 2>/dev/null
iptables -F SOC_ALLOW

# 2. Insert Jump from DOCKER-USER (if exists)
iptables -C DOCKER-USER -j SOC_ALLOW 2>/dev/null || \
iptables -I DOCKER-USER 1 -j SOC_ALLOW

echo "Applying Hardened SOC Firewall Rules..."

# ==========================================
# 1. ALLOW DOCKER INTERNAL TRAFFIC (SAFE)
# ==========================================
# 'docker0' is the default bridge
iptables -A SOC_ALLOW -i docker0 -j ACCEPT
iptables -A SOC_ALLOW -o docker0 -j ACCEPT

# 'br+' acts as a wildcard for all Docker custom bridge interfaces
# This guarantees that API <-> DB <-> Kibana traffic is never blocked
iptables -A SOC_ALLOW -i br+ -j ACCEPT
iptables -A SOC_ALLOW -o br+ -j ACCEPT

# ==========================================
# 2. STANDARD ALLOW RULES
# ==========================================
# Loopback
iptables -A SOC_ALLOW -i lo -j ACCEPT
# Established connections (replies)
iptables -A SOC_ALLOW -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# Public Services (Ingress)
iptables -A SOC_ALLOW -p tcp --dport 80 -j ACCEPT    # Nginx HTTP
iptables -A SOC_ALLOW -p tcp --dport 443 -j ACCEPT   # Nginx HTTPS
iptables -A SOC_ALLOW -p udp --dport 51820 -j ACCEPT # WireGuard VPN

# ==========================================
# 3. LOGGING & DROP
# ==========================================
# Log blocked packets with a specific prefix for Wazuh to catch
iptables -A SOC_ALLOW -j LOG --log-prefix "FIREWALL-DROP: " --log-level 4

# Drop everything else
iptables -A SOC_ALLOW -j DROP

echo "Rules applied. Monitoring..."
tail -f /dev/null
