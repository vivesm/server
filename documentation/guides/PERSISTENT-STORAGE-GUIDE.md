# Persistent Storage Guide
**Created**: 2025-05-27

## Overview

This guide explains how persistent storage is configured for our Docker infrastructure and how to ensure data survives container updates, restarts, and migrations.

## Current Storage Configuration

### Storage Type: Docker Managed Volumes

We use Docker's native volume management system for all services:

```yaml
volumes:
  n8n_data:        # n8n workflows and settings
  wordpress_data:  # WordPress files
  db_data:        # MySQL database
  portainer_data: # Portainer configuration
  caddy_data:     # Caddy certificates and data
  caddy_config:   # Caddy configuration
```

### Why Docker Volumes?

1. **Automatic Management**: Docker handles permissions and mounting
2. **Better Performance**: Native Docker volumes are faster than bind mounts
3. **Portability**: Easy to backup and migrate
4. **Security**: Isolated from host filesystem

## Volume Locations

All Docker volumes are stored in:
```
/var/lib/docker/volumes/
```

Specific volumes:
- **n8n**: `/var/lib/docker/volumes/docker-compose_n8n_data/_data`
- **WordPress**: `/var/lib/docker/volumes/docker-compose_wordpress_data/_data`
- **MySQL**: `/var/lib/docker/volumes/docker-compose_db_data/_data`
- **Portainer**: `/var/lib/docker/volumes/docker-compose_portainer_data/_data`

## Backup and Restore

### Manual Backup

Use the provided backup script:
```bash
cd /home/melvin/projects/server/docker-stack-infrastructure
./scripts/backup-volumes.sh
```

This creates timestamped backups in:
```
/home/melvin/projects/server/docker-stack-infrastructure/backups/
```

### Automated Backups

Add to crontab for daily backups:
```bash
# Daily backup at 2 AM
0 2 * * * /home/melvin/projects/server/docker-stack-infrastructure/scripts/backup-volumes.sh
```

### Restore from Backup

Use the restore script:
```bash
cd /home/melvin/projects/server/docker-stack-infrastructure
./scripts/restore-volumes.sh
```

This will:
1. List available backups
2. Let you select which to restore
3. Stop the affected container
4. Restore the data
5. Restart the container

## Verifying Persistence

### Check Volume Status
```bash
# List all volumes
docker volume ls | grep docker-compose

# Inspect a specific volume
docker volume inspect docker-compose_n8n_data

# Check volume size
docker system df -v | grep -A5 "VOLUME NAME"
```

### Test Persistence
```bash
# 1. Create test data (e.g., new n8n workflow)
# 2. Restart container
docker restart n8n
# 3. Verify data still exists
```

## Important Data Locations

### n8n
- **Workflows**: Stored in the volume
- **Credentials**: Encrypted in the volume
- **Configuration**: In the volume

### WordPress
- **Posts/Pages**: In MySQL database
- **Media Uploads**: `/var/www/html/wp-content/uploads`
- **Themes/Plugins**: `/var/www/html/wp-content`
- **Configuration**: `wp-config.php`

### MySQL
- **All databases**: In the volume
- **User accounts**: In mysql system tables
- **Settings**: In the volume

## Migration Guide

### Moving to Another Server

1. **Backup all volumes**:
   ```bash
   ./scripts/backup-volumes.sh
   ```

2. **Copy backups to new server**:
   ```bash
   scp -r backups/ user@newserver:/path/
   ```

3. **On new server, restore volumes**:
   ```bash
   ./scripts/restore-volumes.sh
   ```

### Upgrading Containers

Volumes persist automatically during upgrades:
```bash
# Pull new image
docker pull n8nio/n8n:latest

# Recreate container (volume persists)
docker-compose up -d n8n
```

## Troubleshooting

### Permission Issues

If you encounter permission errors:
```bash
# n8n (runs as user 1000)
docker exec n8n chown -R node:node /home/node/.n8n

# WordPress (runs as www-data)
docker exec wordpress chown -R www-data:www-data /var/www/html

# MySQL (runs as mysql user)
docker exec mysql chown -R mysql:mysql /var/lib/mysql
```

### Volume Not Mounting

Check if volume exists:
```bash
docker volume ls | grep volume_name
```

Inspect container mounts:
```bash
docker inspect container_name | grep -A10 "Mounts"
```

### Data Loss Prevention

1. **Regular Backups**: Run daily via cron
2. **Test Restores**: Periodically test restore process
3. **Monitor Disk Space**: Ensure adequate space for volumes
4. **Version Control**: Keep docker-compose.yml in git

## Best Practices

1. **Never delete volumes** without backing up first
2. **Test updates** on a staging environment
3. **Document changes** to volume structure
4. **Monitor volume sizes** to prevent disk full issues
5. **Use consistent naming** for volumes

## Volume Maintenance

### Check Volume Sizes
```bash
# Show all volume sizes
docker system df -v

# Check specific volume
docker run --rm -v docker-compose_n8n_data:/data alpine du -sh /data
```

### Clean Unused Volumes
```bash
# List unused volumes
docker volume ls -f dangling=true

# Remove unused volumes (CAREFUL!)
docker volume prune
```

## Emergency Recovery

If a container won't start due to corrupted data:

1. **Stop the container**
2. **Backup the current volume** (even if corrupted)
3. **Try to repair**:
   - MySQL: Use mysqlcheck
   - WordPress: Check file permissions
   - n8n: Check logs for specific errors
4. **Restore from last good backup** if repair fails

## Summary

✅ **Current Status**:
- All services use Docker managed volumes
- Automatic persistence across restarts
- Backup scripts ready and tested
- ~32MB of critical data backed up

🔒 **Data Safety**:
- Volumes persist through container updates
- Daily backup recommendation
- Easy restore process
- Migration-ready setup