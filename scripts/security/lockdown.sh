#!/bin/bash
# Security Lockdown Script for Docker Infrastructure
# This script implements critical security measures to lock down the system to Tailscale-only access

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔒 Starting Security Lockdown for Tailscale-Only Access...${NC}"
echo "=================================================="

# Get current Tailscale IP
TAILSCALE_IP=$(./get-tailscale-ip.sh)
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error: Could not get Tailscale IP. Is Tailscale running?${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Tailscale IP: $TAILSCALE_IP${NC}"

# 1. Configure UFW Firewall
echo -e "\n${YELLOW}📌 Step 1: Configuring UFW Firewall...${NC}"
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH only from Tailscale network
sudo ufw allow from 100.64.0.0/10 to any port 22 comment 'SSH Tailscale only'
sudo ufw allow from fd7a:115c:a1e0::/48 to any port 22 comment 'SSH Tailscale IPv6'

# Allow HTTP/HTTPS for Caddy (public access for web services)
sudo ufw allow 80/tcp comment 'HTTP Caddy'
sudo ufw allow 443/tcp comment 'HTTPS Caddy'

# Allow Portainer only from Tailscale
sudo ufw allow from 100.64.0.0/10 to any port 9443 comment 'Portainer Tailscale only'
sudo ufw allow from fd7a:115c:a1e0::/48 to any port 9443 comment 'Portainer Tailscale IPv6'

# Enable firewall
sudo ufw --force enable
echo -e "${GREEN}✓ UFW Firewall configured and enabled${NC}"

# 2. Generate secure passwords
echo -e "\n${YELLOW}🔑 Step 2: Generating secure passwords...${NC}"
if [ ! -f n8n_password.txt ]; then
    openssl rand -base64 32 > n8n_password.txt
    chmod 600 n8n_password.txt
    echo -e "${GREEN}✓ Generated n8n password${NC}"
else
    echo -e "${YELLOW}⚠ n8n password already exists, skipping${NC}"
fi

# 3. Create SSH config backup and update
echo -e "\n${YELLOW}🔐 Step 3: Updating SSH configuration...${NC}"
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)

# Create new SSH config that binds to Tailscale only
cat > /tmp/sshd_config_tailscale << EOF
# Tailscale-only SSH configuration
ListenAddress $TAILSCALE_IP
Port 22
Protocol 2

# Authentication
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes

# Security
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server

# Logging
SyslogFacility AUTH
LogLevel INFO

# Connection settings
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
MaxSessions 10

# Only allow specific users (add your username)
AllowUsers melvin
EOF

echo -e "${YELLOW}Review SSH configuration changes:${NC}"
echo "Current SSH will be bound to: $TAILSCALE_IP"
echo -e "${RED}WARNING: This will restrict SSH to Tailscale network only!${NC}"
read -p "Apply SSH configuration? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo mv /tmp/sshd_config_tailscale /etc/ssh/sshd_config
    sudo systemctl restart ssh
    echo -e "${GREEN}✓ SSH configuration updated and service restarted${NC}"
else
    echo -e "${YELLOW}⚠ SSH configuration not applied${NC}"
    rm /tmp/sshd_config_tailscale
fi

# 4. Create updated Docker Compose for n8n
echo -e "\n${YELLOW}📝 Step 4: Creating secure Docker Compose configurations...${NC}"

# Read the n8n password
if [ -f n8n_password.txt ]; then
    N8N_PASSWORD=$(cat n8n_password.txt)
else
    echo -e "${RED}❌ n8n password file not found!${NC}"
    exit 1
fi

# Create a secure version of core-infrastructure.yml
cp docker-stack-infrastructure/docker-compose/core-infrastructure.yml docker-stack-infrastructure/docker-compose/core-infrastructure.yml.backup

# Update n8n configuration to remove public port exposure
cat > /tmp/n8n_update.yml << EOF
# Update n8n service to remove public port exposure
# n8n will only be accessible through Caddy reverse proxy
# Remove the line: - "5678:443"
# Update N8N_BASIC_AUTH_PASSWORD environment variable
EOF

echo -e "${GREEN}✓ Configuration templates created${NC}"

# 5. Display iptables rules for Docker
echo -e "\n${YELLOW}🛡️ Step 5: Verifying Docker iptables rules...${NC}"
sudo iptables -L DOCKER-USER -n -v | head -10

# 6. Show current exposed ports
echo -e "\n${YELLOW}🔍 Step 6: Current exposed ports:${NC}"
sudo ss -tlnp | grep -E "(LISTEN|State)" | head -20

# 7. Create verification script
cat > verify-lockdown.sh << 'EOF'
#!/bin/bash
# Verify security lockdown

echo "🔍 Security Lockdown Verification"
echo "================================="

# Check UFW status
echo -e "\n📌 UFW Status:"
sudo ufw status numbered

# Check exposed ports
echo -e "\n🔌 Exposed Ports:"
sudo ss -tlnp | grep "0.0.0.0" | grep -v -E "(80|443)"

# Check SSH configuration
echo -e "\n🔐 SSH Configuration:"
grep -E "(ListenAddress|PermitRootLogin|PasswordAuthentication)" /etc/ssh/sshd_config | grep -v "^#"

# Check Docker containers
echo -e "\n🐳 Docker Exposed Ports:"
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep "0.0.0.0"

echo -e "\n✅ Verification complete!"
EOF

chmod +x verify-lockdown.sh

# Final summary
echo -e "\n${GREEN}=================================================="
echo "🎯 Security Lockdown Initial Phase Complete!"
echo "=================================================="
echo -e "${NC}"
echo "✅ Completed:"
echo "  - UFW firewall enabled with Tailscale rules"
echo "  - Generated secure passwords"
echo "  - Created SSH configuration for Tailscale-only access"
echo ""
echo -e "${YELLOW}⚠️  Manual steps required:${NC}"
echo "  1. Update docker-compose/core-infrastructure.yml:"
echo "     - Remove n8n port exposure (5678:443)"
echo "     - Update N8N_BASIC_AUTH_PASSWORD with contents of n8n_password.txt"
echo "  2. Restart Docker services:"
echo "     cd docker-stack-infrastructure"
echo "     docker compose -f docker-compose/core-infrastructure.yml down"
echo "     docker compose -f docker-compose/core-infrastructure.yml up -d"
echo ""
echo "  3. Run ./verify-lockdown.sh to verify security settings"
echo ""
echo -e "${RED}⚠️  CRITICAL: Make sure you have Tailscale access before applying all changes!${NC}"