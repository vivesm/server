#!/bin/bash

# Infrastructure Firewall Configuration Script
# Configures the firewall to allow necessary traffic and restrict Portainer access to Tailscale

echo "Configuring firewall rules for the infrastructure..."

# Check if ufw is installed
if command -v ufw &> /dev/null; then
    # Using UFW (Uncomplicated Firewall)
    echo "Using UFW firewall..."
    
    # Reset to default
    echo "Resetting UFW to default configuration..."
    sudo ufw --force reset
    
    # Set default policies
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Allow SSH (always important to keep SSH access)
    sudo ufw allow ssh comment 'SSH access'
    
    # Allow RustDesk ports
    sudo ufw allow 21115/tcp comment 'RustDesk NAT type test'
    sudo ufw allow 21116/tcp comment 'RustDesk ID registration and TCP hole punching'
    sudo ufw allow 21116/udp comment 'RustDesk heartbeat service'
    sudo ufw allow 21117/tcp comment 'RustDesk relay service'
    sudo ufw allow 21118/tcp comment 'RustDesk web client support'
    sudo ufw allow 21119/tcp comment 'RustDesk web client support'
    
    # Allow HTTP/HTTPS for the domain
    sudo ufw allow 80/tcp comment 'HTTP'
    sudo ufw allow 443/tcp comment 'HTTPS'
    
    # Allow n8n port (if needed directly)
    sudo ufw allow 5678/tcp comment 'n8n service'
    
    # Block direct access to Portainer except from Tailscale network
    echo "Restricting Portainer access to Tailscale only..."
    sudo ufw deny 9443/tcp comment 'Block public Portainer access'
    sudo ufw deny 8000/tcp comment 'Block public Portainer agent access'
    sudo ufw deny 9000/tcp comment 'Block public Portainer API access'
    
    # Allow Portainer access only from Tailscale network
    sudo ufw allow from 100.64.0.0/10 to any port 9443 proto tcp comment 'Allow Portainer from Tailscale'
    sudo ufw allow from fd7a:115c:a1e0::/48 to any port 9443 proto tcp comment 'Allow Portainer from Tailscale IPv6'
    sudo ufw allow from 127.0.0.1 to any port 9443 proto tcp comment 'Allow Portainer from localhost'
    
    # Allow all traffic on Tailscale interface
    echo "Allowing all traffic on Tailscale interface..."
    sudo ufw allow in on tailscale0 comment 'Allow all Tailscale traffic'
    
    # Enable UFW if not already enabled
    if ! sudo ufw status | grep -q "Status: active"; then
        echo "Enabling UFW..."
        sudo ufw --force enable
    fi
    
    # Show status
    sudo ufw status verbose
    
elif command -v firewall-cmd &> /dev/null; then
    # Using FirewallD (CentOS/RHEL/Fedora)
    echo "Using FirewallD..."
    
    # Allow SSH
    sudo firewall-cmd --permanent --add-service=ssh
    
    # Allow RustDesk ports
    sudo firewall-cmd --permanent --add-port=21115/tcp --add-port=21116/tcp --add-port=21116/udp --add-port=21117/tcp --add-port=21118/tcp --add-port=21119/tcp
    
    # Allow HTTP/HTTPS
    sudo firewall-cmd --permanent --add-service=http --add-service=https
    
    # Allow n8n port
    sudo firewall-cmd --permanent --add-port=5678/tcp
    
    # Block Portainer ports from public access
    echo "Configuring Portainer access restrictions..."
    
    # Create a tailscale zone if it doesn't exist
    if ! sudo firewall-cmd --permanent --get-zones | grep -q 'tailscale'; then
        sudo firewall-cmd --permanent --new-zone=tailscale
    fi
    
    # Add tailscale interface to tailscale zone
    sudo firewall-cmd --permanent --zone=tailscale --add-interface=tailscale0
    
    # Allow Portainer access only from tailscale zone
    sudo firewall-cmd --permanent --zone=tailscale --add-port=9443/tcp
    
    # Allow localhost access
    sudo firewall-cmd --permanent --zone=trusted --add-source=127.0.0.1/8
    sudo firewall-cmd --permanent --zone=trusted --add-port=9443/tcp
    
    # Reload firewall
    sudo firewall-cmd --reload
    
    # Show status
    sudo firewall-cmd --list-all
    sudo firewall-cmd --zone=tailscale --list-all
    
elif command -v iptables &> /dev/null; then
    # Using iptables directly
    echo "Using iptables..."
    
    # Clear existing rules
    sudo iptables -F
    
    # Set default policies
    sudo iptables -P INPUT DROP
    sudo iptables -P FORWARD DROP
    sudo iptables -P OUTPUT ACCEPT
    
    # Allow established connections
    sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    sudo iptables -A INPUT -i lo -j ACCEPT
    
    # Allow SSH
    sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    
    # Allow RustDesk ports
    sudo iptables -A INPUT -p tcp --dport 21115 -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 21116 -j ACCEPT
    sudo iptables -A INPUT -p udp --dport 21116 -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 21117 -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 21118 -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 21119 -j ACCEPT
    
    # Allow HTTP/HTTPS
    sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    
    # Allow n8n port
    sudo iptables -A INPUT -p tcp --dport 5678 -j ACCEPT
    
    # Allow Portainer access only from Tailscale network and localhost
    echo "Restricting Portainer access to Tailscale only..."
    sudo iptables -A INPUT -i tailscale0 -p tcp --dport 9443 -j ACCEPT
    sudo iptables -A INPUT -s 127.0.0.1/8 -p tcp --dport 9443 -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 9443 -j DROP
    sudo iptables -A INPUT -p tcp --dport 8000 -j DROP
    sudo iptables -A INPUT -p tcp --dport 9000 -j DROP
    
    # Save rules
    if command -v iptables-save &> /dev/null; then
        sudo sh -c "iptables-save > /etc/iptables/rules.v4 || sudo iptables-save > /etc/iptables.rules"
        echo "Iptables rules saved"
    else
        echo "WARNING: iptables-save not found, rules may not persist after reboot"
        echo "Consider installing iptables-persistent package"
    fi
    
    # Show status
    sudo iptables -L -v
else
    echo "No supported firewall system detected (ufw, firewall-cmd, or iptables)."
    echo "Please configure your firewall manually to:"
    echo "1. Allow the following ports for general access:"
    echo "   - TCP: 21115, 21116, 21117, 21118, 21119, 80, 443, 5678, 22"
    echo "   - UDP: 21116"
    echo "2. Restrict Portainer ports to Tailscale network only:"
    echo "   - Block public access to TCP ports: 9443, 8000, 9000"
    echo "   - Only allow access to these ports from Tailscale IPs (100.64.0.0/10, fd7a:115c:a1e0::/48)"
    echo "   - Allow localhost (127.0.0.1) access to these ports"
fi

echo "Firewall configuration completed."
echo "Portainer access is now restricted to Tailscale network only."