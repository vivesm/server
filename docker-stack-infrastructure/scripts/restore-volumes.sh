#!/bin/bash
# Restore Docker volumes from backups

BACKUP_DIR="/home/melvin/projects/server/docker-stack-infrastructure/backups"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Docker Volume Restore Script${NC}"
echo "============================="

# List available backups
echo -e "\n${YELLOW}Available backups:${NC}"
ls -lh ${BACKUP_DIR}/*.tar.gz 2>/dev/null | nl -v 0 | while read num file; do
    echo "  $num) $(basename $(echo $file | awk '{print $NF}'))"
done

echo -e "\n${YELLOW}Enter backup number to restore (or 'q' to quit):${NC}"
read -p "> " choice

if [ "$choice" = "q" ]; then
    exit 0
fi

# Get the selected backup file
BACKUP_FILE=$(ls ${BACKUP_DIR}/*.tar.gz 2>/dev/null | sed -n "$((choice+1))p")

if [ -z "$BACKUP_FILE" ]; then
    echo -e "${RED}Invalid selection${NC}"
    exit 1
fi

# Extract volume name from backup filename
BASENAME=$(basename "$BACKUP_FILE")
VOLUME_TYPE=$(echo $BASENAME | cut -d'_' -f1)

# Map backup types to volume names
case $VOLUME_TYPE in
    "n8n") VOLUME_NAME="docker-compose_n8n_data" ;;
    "wordpress") VOLUME_NAME="docker-compose_wordpress_data" ;;
    "mysql") VOLUME_NAME="docker-compose_db_data" ;;
    "portainer") VOLUME_NAME="docker-compose_portainer_data" ;;
    "caddy") 
        if [[ $BASENAME == *"data"* ]]; then
            VOLUME_NAME="docker-compose_caddy_data"
        else
            VOLUME_NAME="docker-compose_caddy_config"
        fi
        ;;
    *) 
        echo -e "${RED}Unknown backup type: $VOLUME_TYPE${NC}"
        exit 1
        ;;
esac

echo -e "\n${YELLOW}Restoring $BASENAME to volume $VOLUME_NAME${NC}"
echo -e "${RED}WARNING: This will overwrite all current data in the volume!${NC}"
read -p "Continue? (y/N): " confirm

if [ "$confirm" != "y" ]; then
    echo "Cancelled"
    exit 0
fi

# Stop the container using this volume
echo -e "\n${YELLOW}Stopping related container...${NC}"
case $VOLUME_TYPE in
    "n8n") docker stop n8n ;;
    "wordpress") docker stop wordpress ;;
    "mysql") docker stop mysql ;;
    "portainer") docker stop portainer ;;
    "caddy") docker stop caddy ;;
esac

# Clear the volume
echo -e "${YELLOW}Clearing volume...${NC}"
docker run --rm -v ${VOLUME_NAME}:/volume alpine sh -c "rm -rf /volume/*"

# Restore from backup
echo -e "${YELLOW}Restoring from backup...${NC}"
docker run --rm \
    -v ${VOLUME_NAME}:/volume \
    -v ${BACKUP_DIR}:/backup:ro \
    alpine tar -xzf /backup/$(basename $BACKUP_FILE) -C /volume

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Successfully restored from backup${NC}"
    
    # Restart the container
    echo -e "${YELLOW}Restarting container...${NC}"
    case $VOLUME_TYPE in
        "n8n") docker start n8n ;;
        "wordpress") docker start wordpress ;;
        "mysql") docker start mysql ;;
        "portainer") docker start portainer ;;
        "caddy") docker start caddy ;;
    esac
    
    echo -e "${GREEN}✓ Restore completed!${NC}"
else
    echo -e "${RED}✗ Restore failed${NC}"
    exit 1
fi