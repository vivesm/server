# Comprehensive Server Backup Strategy

## Critical Data Inventory

### 🔴 ESSENTIAL (Must backup - Server won't function without these)

#### 1. **Portainer Data**
- **Location**: `/home/shared/docker/portainer/` and Docker volume `portainer_data`
- **Contains**: Container configurations, stacks, settings
- **Sensitive**: Yes (contains credentials)
- **Backup Method**: Volume backup + configuration export

#### 2. **Caddy Configuration & Certificates**
- **Location**: `/home/shared/docker/caddy/` and volumes `caddy_data`, `caddy_config`
- **Contains**: SSL certificates, reverse proxy configs
- **Sensitive**: Yes (private keys)
- **Backup Method**: Full directory backup

#### 3. ~~**WordPress Database**~~ (REMOVED)
- Service has been decommissioned

#### 4. **n8n Workflows & Database**
- **Location**: `/home/shared/docker/n8n/` and volume `n8n_data`
- **Contains**: Automation workflows, credentials
- **Sensitive**: Yes (API keys, credentials)
- **Status**: ✅ Already backed up in repo

### 🟡 IMPORTANT (Service will be degraded without these)

#### 5. ~~**WordPress Files**~~ (REMOVED)
- Service has been decommissioned

#### 6. **Docker Compose Files**
- **Location**: `/home/melvin/projects/server/docker-stack-infrastructure/docker-compose/`
- **Contains**: Service definitions
- **Status**: ✅ Already in Git

#### 7. **Configuration Files**
- **Location**: Various `.env` files, service configs
- **Contains**: Service settings
- **Sensitive**: Yes (may contain passwords)
- **Backup Method**: Selective backup (exclude secrets)

### 🟢 NICE-TO-HAVE (Can be recreated but saves time)

#### 8. **Monitoring Logs**
- **Location**: `/home/shared/docker/logs/`
- **Contains**: Service health reports
- **Backup Method**: Periodic archival

#### 9. **WikiJS Data** 
- **Location**: `/home/shared/docker/wikijs/`
- **Contains**: Wiki content (if using WikiJS)
- **Backup Method**: Database export

## Backup Implementation

### 1. Create Master Backup Script

```bash
#!/bin/bash
# /home/melvin/projects/server/backup-all.sh

BACKUP_DIR="/home/melvin/projects/server/critical-backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR/$DATE"

# 1. Backup Portainer
docker run --rm -v portainer_data:/data -v "$BACKUP_DIR/$DATE":/backup alpine tar czf /backup/portainer_data.tar.gz -C /data .

# 2. Backup Caddy (certificates!)
sudo tar czf "$BACKUP_DIR/$DATE/caddy_complete.tar.gz" /home/shared/docker/caddy/

# 3-4. WordPress removed - skip these backups

# 5. Backup all Docker volumes
for volume in $(docker volume ls -q); do
    docker run --rm -v "$volume":/data -v "$BACKUP_DIR/$DATE":/backup alpine tar czf "/backup/volume_${volume}.tar.gz" -C /data .
done

# 6. Export Docker compose configs
cp -r /home/melvin/projects/server/docker-stack-infrastructure/docker-compose "$BACKUP_DIR/$DATE/"

# 7. Create restore instructions
cat > "$BACKUP_DIR/$DATE/RESTORE.md" << EOF
# Restore Instructions
Generated: $DATE

## Quick Restore Commands

### Portainer
docker run --rm -v portainer_data:/data -v \$(pwd):/backup alpine tar xzf /backup/portainer_data.tar.gz -C /data

### WordPress - REMOVED
# Service decommissioned

### Caddy Certificates
sudo tar xzf caddy_complete.tar.gz -C /

### All Volumes
for file in volume_*.tar.gz; do
    volume=\${file#volume_}
    volume=\${volume%.tar.gz}
    docker run --rm -v "\$volume":/data -v \$(pwd):/backup alpine tar xzf "/backup/\$file" -C /data
done
EOF

echo "Backup completed: $BACKUP_DIR/$DATE"
```

### 2. Secrets Backup (Separate, Encrypted)

```bash
#!/bin/bash
# /home/melvin/projects/server/backup-secrets.sh

# Collect all sensitive data
mkdir -p /tmp/secrets-backup
cp /home/melvin/projects/server/.wordpress-api-key /tmp/secrets-backup/ 2>/dev/null || true
docker exec n8n cat /home/node/.n8n/config > /tmp/secrets-backup/n8n-config.json 2>/dev/null || true

# Encrypt with GPG
tar czf - -C /tmp/secrets-backup . | gpg --symmetric --cipher-algo AES256 > secrets-backup-$(date +%Y%m%d).tar.gz.gpg

# Clean up
rm -rf /tmp/secrets-backup
```

### 3. Automated Backup Cron

```bash
# Add to crontab
0 3 * * * /home/melvin/projects/server/backup-all.sh
0 3 * * 0 /home/melvin/projects/server/backup-secrets.sh
```

## Critical Files Checklist

- [ ] Portainer database and configurations
- [ ] Caddy SSL certificates and configs
- [x] ~~WordPress database dump~~ (REMOVED)
- [x] ~~WordPress uploads and themes~~ (REMOVED)
- [ ] n8n workflows and database
- [ ] All Docker volume data
- [ ] Docker compose configurations
- [ ] Environment variables and secrets
- [ ] Tailscale configuration
- [ ] System firewall rules

## Restore Priority Order

1. **Network & Security**
   - Tailscale VPN
   - Firewall rules
   
2. **Core Infrastructure**
   - Docker & Docker Compose
   - Portainer
   - Caddy (with certificates)
   
3. **Applications**
   - ~~WordPress~~ (REMOVED)
   - n8n workflows
   - Other services

## Off-site Backup Locations

1. **GitHub Repository** (non-sensitive)
   - ✅ Docker configurations
   - ✅ Scripts and documentation
   - ✅ n8n workflow exports

2. **Cloud Storage** (encrypted)
   - Full volume backups
   - Database dumps
   - SSL certificates

3. **Local Machine**
   - Recent full backup
   - Secrets backup (encrypted)

## Recovery Time Objectives

- **Minimal Service**: 30 minutes (Portainer + Caddy)
- **Core Services**: 1 hour (+ WordPress, n8n)
- **Full Recovery**: 2-4 hours (all services + data)

## Testing Schedule

- Monthly: Restore single service to test environment
- Quarterly: Full disaster recovery drill
- After major changes: Backup verification

---

**Remember**: A backup is only as good as its last successful restore test!