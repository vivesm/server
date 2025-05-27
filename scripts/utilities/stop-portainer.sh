#!/bin/bash

# Stop Portainer and clean up firewall rules

echo "Stopping Portainer..."

# Stop containers
docker compose down

# Remove firewall rules
echo "Removing firewall rules..."
sudo iptables -D DOCKER-USER -p tcp --dport 9443 ! -s 100.64.0.0/10 -j DROP 2>/dev/null || true
sudo iptables -D DOCKER-USER -p tcp --dport 8000 ! -s 100.64.0.0/10 -j DROP 2>/dev/null || true

echo "Portainer stopped."