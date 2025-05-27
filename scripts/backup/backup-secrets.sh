#!/bin/bash
# Backup sensitive data separately with encryption
# Store this backup in a secure location

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Starting encrypted secrets backup...${NC}"

# Check for required tools
if ! command -v gpg &> /dev/null; then
    echo -e "${RED}Error: gpg is required for encryption${NC}"
    echo "Install with: sudo apt-get install gnupg"
    exit 1
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d)
DATE=$(date +%Y%m%d_%H%M%S)

echo -e "${YELLOW}Collecting sensitive data...${NC}"

# 1. Collect environment files
find /home/melvin/projects/server -name ".env*" -type f 2>/dev/null | while read -r file; do
    cp "$file" "$TEMP_DIR/$(basename "$file").$(echo "$file" | md5sum | cut -d' ' -f1)" 2>/dev/null || true
done

# 2. n8n credentials and config
if docker ps | grep -q n8n; then
    docker exec n8n cat /home/node/.n8n/config 2>/dev/null > "$TEMP_DIR/n8n-config.json" || true
    echo -e "${GREEN}✓ Collected n8n configuration${NC}"
fi

# 3. Portainer sensitive data
if [ -d "/home/shared/docker/portainer" ]; then
    # Portainer stores encrypted data, but we'll backup the key files
    sudo cp /home/shared/docker/portainer/portainer.key "$TEMP_DIR/" 2>/dev/null || true
    sudo cp /home/shared/docker/portainer/public.pem "$TEMP_DIR/" 2>/dev/null || true
    echo -e "${GREEN}✓ Collected Portainer keys${NC}"
fi

# 4. Caddy certificates (already encrypted, but sensitive)
if [ -d "/home/shared/docker/caddy" ]; then
    sudo tar czf "$TEMP_DIR/caddy-certs.tar.gz" /home/shared/docker/caddy/data/caddy/certificates 2>/dev/null || true
    echo -e "${GREEN}✓ Collected Caddy certificates${NC}"
fi

# 5. System information that might be sensitive
cat > "$TEMP_DIR/system-secrets.txt" << EOF
Generated: $(date)
Hostname: $(hostname)
Tailscale Status: $(tailscale status 2>/dev/null | head -5 || echo "Not available")

Docker Login Status:
$(docker info 2>/dev/null | grep -E "(Username|Registry)" || echo "No Docker Hub login")

Critical Service Passwords:
- n8n: Check container environment
- Portainer: Admin password set during first login
- Caddy: No default passwords

Network Information:
$(ip addr show | grep -E "(inet |link/ether)" | grep -v "127.0.0.1")
EOF

# 6. Create inventory of what's backed up
cat > "$TEMP_DIR/INVENTORY.txt" << EOF
Secrets Backup Inventory
========================
Date: $(date)
Host: $(hostname)

Contents:
$(ls -la "$TEMP_DIR" | tail -n +2)

File Count: $(find "$TEMP_DIR" -type f | wc -l)
Total Size: $(du -sh "$TEMP_DIR" | cut -f1)

IMPORTANT: This backup contains sensitive data including:
- API keys and passwords
- SSL certificates and private keys
- Authentication tokens
- System configuration secrets

Handle with extreme care!
EOF

# 7. Create tarball and encrypt
echo -e "\n${YELLOW}Encrypting backup...${NC}"
OUTPUT_FILE="/home/melvin/projects/server/secrets-backup-${DATE}.tar.gz.gpg"

tar czf - -C "$TEMP_DIR" . | gpg --symmetric --cipher-algo AES256 --compress-algo none --output "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Encrypted backup created successfully${NC}"
    echo -e "Location: ${YELLOW}$OUTPUT_FILE${NC}"
    echo -e "\n${YELLOW}IMPORTANT:${NC}"
    echo "1. Store this file in a secure location"
    echo "2. Remember the passphrase you just entered"
    echo "3. To decrypt: gpg --decrypt $OUTPUT_FILE | tar xzf -"
else
    echo -e "${RED}✗ Encryption failed${NC}"
fi

# Cleanup
rm -rf "$TEMP_DIR"

# Optional: Show recent secret backups
echo -e "\n${YELLOW}Recent secret backups:${NC}"
ls -lh /home/melvin/projects/server/secrets-backup-*.tar.gz.gpg 2>/dev/null | tail -5 || echo "No previous backups found"