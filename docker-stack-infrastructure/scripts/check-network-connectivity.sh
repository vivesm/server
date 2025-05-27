#!/bin/bash
# Script to check network connectivity between containers

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}====== Docker Network Connectivity Check ======${NC}"

# List all networks
echo -e "\n${YELLOW}Docker Networks:${NC}"
docker network ls

# List containers on each network
echo -e "\n${YELLOW}Containers on each network:${NC}"
for network in $(docker network ls --format '{{.Name}}'); do
  echo -e "${GREEN}Network: ${network}${NC}"
  containers=$(docker network inspect $network --format '{{range .Containers}}{{.Name}}{{printf ", "}}{{end}}' | sed 's/, $//')
  if [ -z "$containers" ]; then
    echo "  No containers"
  else
    echo "  $containers"
  fi
done

# Check Caddy connectivity to other services
echo -e "\n${YELLOW}Testing Caddy connectivity to services:${NC}"
services=("portainer" "n8n" "wordpress" "rustdesk-hbbs" "mysql")

for service in "${services[@]}"; do
  echo -e "${GREEN}Testing Caddy → $service:${NC}"
  if docker exec caddy ping -c 1 -W 1 $service > /dev/null 2>&1; then
    echo -e "  ✅ Caddy can ping $service"
  else
    echo -e "  ${RED}❌ Caddy cannot ping $service${NC}"
  fi
done

# Check Portainer connectivity to other services
echo -e "\n${YELLOW}Testing Portainer connectivity to services:${NC}"
for service in "${services[@]}"; do
  if [ "$service" != "portainer" ]; then
    echo -e "${GREEN}Testing Portainer → $service:${NC}"
    if docker exec portainer ping -c 1 -W 1 $service > /dev/null 2>&1; then
      echo -e "  ✅ Portainer can ping $service"
    else
      echo -e "  ${RED}❌ Portainer cannot ping $service${NC}"
    fi
  fi
done

# Check web service accessibility
echo -e "\n${YELLOW}Testing web service accessibility:${NC}"

# Function to check HTTP service
check_service() {
  local container=$1
  local port=$2
  local protocol=$3
  local name=$4
  
  echo -e "${GREEN}Testing $name service ($container:$port):${NC}"
  
  # Test from the host
  if curl -s -o /dev/null -w "%{http_code}" $protocol://localhost:$port > /dev/null 2>&1; then
    echo -e "  ✅ $name is accessible from host"
  else
    echo -e "  ${RED}❌ $name is not accessible from host${NC}"
  fi
}

# Test services
check_service "portainer" "9443" "https" "Portainer"
check_service "n8n" "5678" "http" "n8n"
check_service "wordpress" "8080" "http" "WordPress"
check_service "caddy" "80" "http" "Caddy HTTP"
check_service "caddy" "443" "https" "Caddy HTTPS"

echo -e "\n${YELLOW}====== Connectivity Check Complete ======${NC}"