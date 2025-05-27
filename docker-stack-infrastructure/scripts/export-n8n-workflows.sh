#!/bin/bash
# Export n8n workflows to JSON files for extra backup

EXPORT_DIR="/home/melvin/projects/server/docker-stack-infrastructure/backups/n8n-workflows"
DATE=$(date +%Y%m%d_%H%M%S)

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}n8n Workflow Export${NC}"
echo "==================="

# Create export directory
mkdir -p "$EXPORT_DIR"

# Export using n8n CLI
echo -e "\n${YELLOW}Exporting workflows from n8n...${NC}"

# Method 1: Direct database query
echo "Method 1: Extracting from database..."
docker exec n8n sqlite3 /home/node/.n8n/database.sqlite \
    "SELECT name, nodes, connections, settings FROM workflow_entity WHERE active = 1;" \
    > "${EXPORT_DIR}/workflows_${DATE}.sql" 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Exported active workflows to SQL${NC}"
fi

# Method 2: Copy the entire database for safekeeping
echo -e "\nMethod 2: Copying entire database..."
docker cp n8n:/home/node/.n8n/database.sqlite "${EXPORT_DIR}/database_${DATE}.sqlite" 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Copied complete database${NC}"
fi

# Show export summary
echo -e "\n${GREEN}Export Summary:${NC}"
ls -lah "${EXPORT_DIR}"/*${DATE}* 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'

echo -e "\n${YELLOW}TIP: For best results, also export workflows from n8n UI:${NC}"
echo "1. Login to https://n8n.stringbits.com"
echo "2. Go to Workflows"
echo "3. Select workflows and click 'Download'"
echo ""
echo "Exports saved to: ${EXPORT_DIR}"