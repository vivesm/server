# n8n Workflow Backups

This directory contains backups of n8n workflows and database exports.

## Backup Contents

- `database_*.sqlite` - Complete n8n SQLite database backups
- `workflows_*.sql` - SQL exports of workflow data

## Restore Instructions

### Method 1: Restore Complete Database
```bash
# Stop n8n
docker stop n8n

# Backup current database
docker exec n8n cp /home/node/.n8n/database.sqlite /home/node/.n8n/database.sqlite.backup

# Copy new database
docker cp database_20250526_235200.sqlite n8n:/home/node/.n8n/database.sqlite

# Fix permissions
docker exec n8n chown node:node /home/node/.n8n/database.sqlite

# Start n8n
docker start n8n
```

### Method 2: Import via UI
1. Login to n8n at https://n8n.stringbits.com
2. Create new workflows
3. Switch to "Code" view
4. Paste workflow JSON from exports

## Backup Schedule

Run regular backups with:
```bash
cd /home/melvin/projects/server
./docker-stack-infrastructure/scripts/export-n8n-workflows.sh
```

## Security Note

These backups may contain sensitive credentials. Handle with care.