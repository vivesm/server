#!/bin/bash
# Comprehensive backup script for all critical server data
# Run manually or via cron for disaster recovery preparedness

set -e

# Configuration
BACKUP_BASE="/home/melvin/projects/server/critical-backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_BASE/$DATE"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Starting comprehensive server backup...${NC}"
echo "Backup directory: $BACKUP_DIR"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Function to backup a Docker volume
backup_volume() {
    local volume=$1
    local name=${2:-$volume}
    echo -e "${YELLOW}Backing up volume: $volume${NC}"
    
    if docker volume inspect "$volume" >/dev/null 2>&1; then
        docker run --rm \
            -v "$volume":/data \
            -v "$BACKUP_DIR":/backup \
            alpine tar czf "/backup/${name}.tar.gz" -C /data .
        echo -e "${GREEN}✓ Backed up $volume${NC}"
    else
        echo -e "${RED}✗ Volume $volume not found${NC}"
    fi
}

# Function to backup a directory
backup_directory() {
    local source=$1
    local name=$2
    echo -e "${YELLOW}Backing up directory: $source${NC}"
    
    if [ -d "$source" ]; then
        sudo tar czf "$BACKUP_DIR/${name}.tar.gz" "$source" 2>/dev/null
        echo -e "${GREEN}✓ Backed up $source${NC}"
    else
        echo -e "${RED}✗ Directory $source not found${NC}"
    fi
}

# 1. Backup all Docker volumes
echo -e "\n${YELLOW}=== Backing up Docker volumes ===${NC}"
backup_volume "docker-compose_portainer_data" "portainer_data"
backup_volume "docker-compose_caddy_data" "caddy_data"
backup_volume "docker-compose_caddy_config" "caddy_config"
backup_volume "docker-compose_n8n_data" "n8n_data"
# WordPress removed - skip these
# backup_volume "docker-compose_wordpress_data" "wordpress_data"
# backup_volume "docker-compose_db_data" "mysql_data"

# 2. Backup shared Docker directories
echo -e "\n${YELLOW}=== Backing up shared directories ===${NC}"
backup_directory "/home/shared/docker" "shared_docker_complete"

# 3. WordPress removed - skip database export

# 4. Export n8n workflows
echo -e "\n${YELLOW}=== Exporting n8n workflows ===${NC}"
if docker ps | grep -q n8n; then
    docker exec n8n cp /home/node/.n8n/database.sqlite /tmp/n8n_backup.sqlite 2>/dev/null || true
    docker cp n8n:/tmp/n8n_backup.sqlite "$BACKUP_DIR/n8n_database.sqlite" 2>/dev/null || true
    echo -e "${GREEN}✓ Exported n8n database${NC}"
fi

# 5. Backup Docker Compose configurations
echo -e "\n${YELLOW}=== Backing up Docker Compose configs ===${NC}"
cp -r /home/melvin/projects/server/docker-stack-infrastructure/docker-compose "$BACKUP_DIR/"
echo -e "${GREEN}✓ Copied Docker Compose files${NC}"

# 6. Backup critical scripts
echo -e "\n${YELLOW}=== Backing up critical scripts ===${NC}"
mkdir -p "$BACKUP_DIR/scripts"
cp /home/melvin/projects/server/*.sh "$BACKUP_DIR/scripts/" 2>/dev/null || true
echo -e "${GREEN}✓ Copied shell scripts${NC}"

# 7. Create system information file
echo -e "\n${YELLOW}=== Saving system information ===${NC}"
cat > "$BACKUP_DIR/system-info.txt" << EOF
Backup Date: $(date)
Hostname: $(hostname)
Tailscale IP: $(tailscale ip -4 2>/dev/null || echo "Not available")
Docker Version: $(docker --version)
Docker Compose Version: $(docker compose version)

Running Containers:
$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}")

Docker Networks:
$(docker network ls)

Disk Usage:
$(df -h)
EOF
echo -e "${GREEN}✓ Saved system information${NC}"

# 8. Create restore instructions
echo -e "\n${YELLOW}=== Creating restore instructions ===${NC}"
cat > "$BACKUP_DIR/RESTORE-INSTRUCTIONS.md" << 'EOF'
# Disaster Recovery Restore Instructions

## Prerequisites
1. Fresh Ubuntu server with Docker installed
2. Tailscale configured with same IP (100.112.235.46)
3. This backup directory accessible

## Restore Steps

### 1. Restore Docker Networks
```bash
docker network create docker-compose_stringbits_net
```

### 2. Restore Docker Compose Files
```bash
sudo mkdir -p /home/melvin/projects/server/docker-stack-infrastructure/
cp -r docker-compose /home/melvin/projects/server/docker-stack-infrastructure/
```

### 3. Restore Shared Docker Directory
```bash
sudo tar xzf shared_docker_complete.tar.gz -C /
```

### 4. Restore Docker Volumes
```bash
# Restore each volume
for volume in portainer_data caddy_data caddy_config n8n_data wordpress_data mysql_data; do
    docker volume create docker-compose_$volume
    docker run --rm -v docker-compose_$volume:/data -v $(pwd):/backup alpine tar xzf /backup/${volume}.tar.gz -C /data
done
```

### 5. Start Core Services
```bash
cd /home/melvin/projects/server/docker-stack-infrastructure
docker compose -f docker-compose/core-infrastructure.yml up -d
```

### 6. Restore WordPress Database
```bash
docker exec -i mysql mysql -u root -p$MYSQL_ROOT_PASSWORD wordpress < wordpress_database.sql
```

### 7. Start Application Services
```bash
docker compose -f docker-compose/applications.yml up -d
```

### 8. Verify Services
- Portainer: https://100.112.235.46:9443
- WordPress: https://wp.stringbits.com
- n8n: https://n8n.stringbits.com

## Important Notes
- Update passwords after restore
- Check Caddy certificates
- Verify Tailscale connectivity
- Test all service endpoints
EOF

# 9. Create backup summary
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
FILE_COUNT=$(find "$BACKUP_DIR" -type f | wc -l)

cat > "$BACKUP_DIR/backup-summary.txt" << EOF
Backup Summary
==============
Date: $(date)
Total Size: $BACKUP_SIZE
File Count: $FILE_COUNT
Backup Location: $BACKUP_DIR

Contents:
$(ls -la "$BACKUP_DIR")
EOF

echo -e "\n${GREEN}=== Backup completed successfully! ===${NC}"
echo -e "Location: ${YELLOW}$BACKUP_DIR${NC}"
echo -e "Size: ${YELLOW}$BACKUP_SIZE${NC}"
echo -e "Files: ${YELLOW}$FILE_COUNT${NC}"

# 10. Optional: Compress entire backup
echo -e "\n${YELLOW}Creating compressed archive...${NC}"
cd "$BACKUP_BASE"
tar czf "server-backup-$DATE.tar.gz" "$DATE/"
echo -e "${GREEN}✓ Created: $BACKUP_BASE/server-backup-$DATE.tar.gz${NC}"

# Cleanup old backups (keep last 5)
echo -e "\n${YELLOW}Cleaning up old backups...${NC}"
ls -t "$BACKUP_BASE"/server-backup-*.tar.gz 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true
ls -t "$BACKUP_BASE"/ | grep -E '^[0-9]{8}_[0-9]{6}$' | tail -n +6 | xargs -I {} rm -rf "$BACKUP_BASE/{}" 2>/dev/null || true

echo -e "\n${GREEN}Backup process complete!${NC}"