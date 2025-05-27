#!/bin/bash
# Docker Stack Infrastructure Installation Script
# Installs and configures the full Docker stack infrastructure

# Exit on error
set -e

# Print colorful messages
function print_message() {
  local color="\033[0;32m"  # Green
  local nc="\033[0m"  # No color
  echo -e "${color}$1${nc}"
}

function print_error() {
  local color="\033[0;31m"  # Red
  local nc="\033[0m"  # No color
  echo -e "${color}ERROR: $1${nc}"
}

function print_section() {
  local color="\033[0;34m"  # Blue
  local nc="\033[0m"  # No color
  echo -e "\n${color}=== $1 ===${nc}"
}

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
  print_error "This script must be run as root"
  exit 1
fi

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

print_section "Starting Docker Stack Infrastructure Installation"
print_message "Installation directory: $REPO_DIR"

# Check prerequisites
print_section "Checking Prerequisites"
print_message "Checking Docker..."

if ! command -v docker &> /dev/null; then
  print_message "Docker not found. Installing Docker..."
  
  # Install Docker
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  sh /tmp/get-docker.sh
  
  # Add current user to docker group
  usermod -aG docker "$SUDO_USER"
  
  print_message "Docker installed successfully."
else
  print_message "Docker is already installed."
fi

# Check Docker Compose
print_message "Checking Docker Compose..."
if ! docker compose version &> /dev/null; then
  print_message "Docker Compose not found. It should be included with Docker."
  print_message "If using an older Docker version, please install Docker Compose separately."
else
  print_message "Docker Compose is available."
fi

# Create required directories
print_section "Creating Directory Structure"
mkdir -p /home/shared/docker/{caddy/{config,data},n8n,mysql,wordpress/{wp-content},rustdesk,portainer/stacks,logs}

# Configure networks
print_section "Setting Up Docker Networks"
if ! docker network ls | grep -q "stringbits_net"; then
  print_message "Creating stringbits_net network..."
  docker network create stringbits_net
else
  print_message "stringbits_net network already exists."
fi

if ! docker network ls | grep -q "docker_stringbits_net"; then
  print_message "Creating docker_stringbits_net network..."
  docker network create docker_stringbits_net
else
  print_message "docker_stringbits_net network already exists."
fi

# Copy configuration files
print_section "Copying Configuration Files"
cp -R "$REPO_DIR/caddy/config"/* /home/shared/docker/caddy/config/
print_message "Caddy configuration copied."

# Set up Portainer
print_section "Setting Up Portainer"
cp "$REPO_DIR/docker-compose/core-infrastructure.yml" /home/shared/docker-compose.core.yml
print_message "Starting Portainer..."
docker compose -f /home/shared/docker-compose.core.yml up -d portainer
print_message "Portainer started."

# Configure security
print_section "Configuring Security"
cp "$REPO_DIR/scripts/security/update-firewall.sh" /home/shared/docker/update-firewall.sh
chmod +x /home/shared/docker/update-firewall.sh
print_message "Running firewall configuration script..."
/home/shared/docker/update-firewall.sh
print_message "Firewall configured."

# Set up monitoring
print_section "Setting Up Monitoring"
cp "$REPO_DIR/monitoring/scripts/enhanced-monitor.sh" /home/shared/docker/enhanced-monitor.sh
chmod +x /home/shared/docker/enhanced-monitor.sh
ln -sf /home/shared/docker/enhanced-monitor.sh /home/shared/docker/monitor.sh
print_message "Monitoring script installed."

# Set up validation
print_section "Setting Up Validation"
cp "$REPO_DIR/scripts/validate-all.sh" /home/shared/docker/validate-all.sh
chmod +x /home/shared/docker/validate-all.sh
ln -sf /home/shared/docker/validate-all.sh /home/shared/docker/validate.sh
print_message "Validation script installed."

# Copy networking scripts
cp "$REPO_DIR/scripts/check-network-connectivity.sh" /home/shared/docker/check-network-connectivity.sh
chmod +x /home/shared/docker/check-network-connectivity.sh
print_message "Network connectivity script installed."

# Start services
print_section "Starting Core Services"
docker compose -f /home/shared/docker-compose.core.yml up -d
print_message "Core services started."

# Configure cron jobs
print_section "Setting Up Cron Jobs"
cp "$REPO_DIR/scripts/setup/setup-cron.sh" /home/shared/docker/setup-cron.sh
chmod +x /home/shared/docker/setup-cron.sh
/home/shared/docker/setup-cron.sh
print_message "Cron jobs configured."

# Final validation
print_section "Performing Final Validation"
/home/shared/docker/validate-all.sh
print_message "Validation completed."

print_section "Installation Complete!"
print_message "Docker Stack Infrastructure has been successfully installed."
print_message "You can access the services at your configured domains."
print_message "For more information, refer to the documentation in $REPO_DIR/docs/"

exit 0