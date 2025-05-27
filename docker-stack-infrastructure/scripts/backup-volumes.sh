#!/bin/bash
# Backup Docker volumes to ensure data persistence

BACKUP_DIR="/home/melvin/projects/server/docker-stack-infrastructure/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Docker Volume Backup Script${NC}"
echo "============================"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Function to backup a volume
backup_volume() {
    local volume_name=$1
    local backup_name=$2
    
    echo -e "\n${YELLOW}Backing up ${volume_name}...${NC}"
    
    # Create backup using a temporary container
    docker run --rm \
        -v ${volume_name}:/source:ro \
        -v ${BACKUP_DIR}:/backup \
        alpine tar -czf /backup/${backup_name}_${DATE}.tar.gz -C /source .
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Backed up to: ${BACKUP_DIR}/${backup_name}_${DATE}.tar.gz${NC}"
    else
        echo -e "${RED}✗ Failed to backup ${volume_name}${NC}"
    fi
}

# Backup all important volumes
backup_volume "docker-compose_n8n_data" "n8n"
backup_volume "docker-compose_wordpress_data" "wordpress"
backup_volume "docker-compose_db_data" "mysql"
backup_volume "docker-compose_portainer_data" "portainer"
backup_volume "docker-compose_caddy_data" "caddy_data"
backup_volume "docker-compose_caddy_config" "caddy_config"

# Also backup the Caddyfile
echo -e "\n${YELLOW}Backing up Caddyfile...${NC}"
cp /home/melvin/projects/server/docker-stack-infrastructure/caddy/config/Caddyfile \
   ${BACKUP_DIR}/Caddyfile_${DATE}.bak

# List backups
echo -e "\n${GREEN}Backup Summary:${NC}"
ls -lh ${BACKUP_DIR}/*${DATE}* 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'

# Cleanup old backups (keep last 7 days)
echo -e "\n${YELLOW}Cleaning up old backups...${NC}"
find ${BACKUP_DIR} -name "*.tar.gz" -mtime +7 -delete
find ${BACKUP_DIR} -name "*.bak" -mtime +7 -delete

echo -e "\n${GREEN}✓ Backup completed!${NC}"
echo -e "Backups stored in: ${BACKUP_DIR}"