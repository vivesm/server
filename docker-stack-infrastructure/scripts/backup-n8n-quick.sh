#\!/bin/bash
# Quick n8n backup script
BACKUP_DIR="/home/melvin/projects/server/docker-stack-infrastructure/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Backup n8n only
docker run --rm \
    -v docker-compose_n8n_data:/source:ro \
    -v ${BACKUP_DIR}:/backup \
    alpine tar -czf /backup/n8n_${DATE}.tar.gz -C /source .

echo "n8n backed up to: ${BACKUP_DIR}/n8n_${DATE}.tar.gz"
