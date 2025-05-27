#!/bin/bash

# Secure Portainer startup script with Tailscale-only access

set -e

echo "Starting Portainer with Tailscale-only access..."

# Check if Tailscale is running
if ! command -v tailscale &> /dev/null; then
    echo "Error: Tailscale is not installed"
    echo "Please run: sudo ./install-tailscale.sh"
    exit 1
fi

# Get Tailscale IP
TAILSCALE_IP=$(./get-tailscale-ip.sh)
if [ $? -ne 0 ]; then
    exit 1
fi

echo "Tailscale IP: $TAILSCALE_IP"

# Generate secure password if not exists
if [ ! -f portainer_password.txt ]; then
    echo "Generating secure password for Portainer..."
    openssl rand -base64 32 > portainer_password.txt
    chmod 600 portainer_password.txt
    echo "Password saved to portainer_password.txt"
fi

# Update docker-compose.yml with actual Tailscale IP
sed -i "s/TAILSCALE_IP:/$TAILSCALE_IP:/g" docker-compose.yml

# Pull latest image
docker compose pull

# Start Portainer
docker compose up -d

# Wait for Portainer to start
echo "Waiting for Portainer to start..."
sleep 10

# Configure iptables to block non-Tailscale access
echo "Configuring firewall rules..."

# Allow only Tailscale network (100.64.0.0/10) to access Portainer ports
sudo iptables -I DOCKER-USER -p tcp --dport 9443 ! -s 100.64.0.0/10 -j DROP
sudo iptables -I DOCKER-USER -p tcp --dport 8000 ! -s 100.64.0.0/10 -j DROP

echo "================================"
echo "Portainer is now running!"
echo "Access URL: https://$TAILSCALE_IP:9443"
echo "Username: admin"
echo "Password: $(cat portainer_password.txt)"
echo "================================"
echo ""
echo "Security features enabled:"
echo "✓ Bound to Tailscale IP only ($TAILSCALE_IP)"
echo "✓ Firewall rules blocking non-Tailscale access"
echo "✓ HTTPS enabled on port 9443"
echo "✓ Random secure password generated"