# Automation and Backup Guide
**Last Updated**: 2025-01-26

## Overview

This guide covers the automation scripts for scheduled tasks, firewall management, and backup procedures used in the Docker infrastructure.

## Cron Job Setup

### setup-cron.sh

**Location**: `/home/melvin/projects/server/docker-stack-infrastructure/scripts/setup/setup-cron.sh`

**Purpose**: Configure automated monitoring and maintenance tasks

**Usage**:
```bash
sudo ./docker-stack-infrastructure/scripts/setup/setup-cron.sh
```

**What it configures**:

1. **Monitoring Job** (Every 15 minutes)
   - Runs enhanced-monitor.sh
   - Checks service health
   - Sends alerts if needed

2. **Daily Validation** (3:00 AM)
   - Runs validate-all.sh
   - Comprehensive system check
   - Logs results

3. **Weekly Tests** (Sunday 4:00 AM)
   - Runs comprehensive test suite
   - Deep system validation

4. **Cleanup Job** (Saturday 2:00 AM)
   - Removes old logs
   - Cleans up unused resources

### Managing Cron Jobs

```bash
# View current cron jobs
crontab -l

# Edit cron jobs manually
crontab -e

# Remove all cron jobs
crontab -r

# Backup cron jobs
crontab -l > cron-backup.txt

# Restore cron jobs
crontab cron-backup.txt
```

### Cron Job Monitoring

```bash
# Check cron service status
systemctl status cron

# View cron logs
grep CRON /var/log/syslog

# Test cron job manually
/home/shared/docker/enhanced-monitor.sh
```

## Firewall Management

### update-firewall.sh

**Location**: `/home/melvin/projects/server/docker-stack-infrastructure/scripts/security/update-firewall.sh`

**Purpose**: Configure firewall rules for Docker infrastructure

**Usage**:
```bash
sudo ./docker-stack-infrastructure/scripts/security/update-firewall.sh
```

**What it configures**:

1. **Default Policies**
   - Deny incoming traffic
   - Allow outgoing traffic
   - Allow established connections

2. **Service Ports**
   - SSH (22)
   - HTTP (80)
   - HTTPS (443)
   - n8n (5678)
   - RustDesk (21115-21119)

3. **Tailscale Restrictions**
   - Portainer (9443) - Tailscale only
   - Allow all traffic on tailscale0 interface

4. **Security Features**
   - Blocks public access to Portainer
   - Allows Tailscale network (100.64.0.0/10)
   - Allows localhost access

### Firewall Commands

**UFW (Ubuntu)**:
```bash
# Check status
sudo ufw status verbose

# List rules with numbers
sudo ufw status numbered

# Delete a rule
sudo ufw delete <rule-number>

# Disable firewall (emergency)
sudo ufw disable

# Reset to defaults
sudo ufw --force reset
```

**Custom Rules**:
```bash
# Allow specific IP
sudo ufw allow from 192.168.1.100 to any port 9443

# Allow port range
sudo ufw allow 8000:8100/tcp

# Block specific IP
sudo ufw deny from 10.0.0.5
```

## Backup System

### backup-to-github.sh

**Location**: `/home/melvin/projects/server/docker-stack-infrastructure/scripts/backup/backup-to-github.sh`

**Purpose**: Automated Git backup of configuration files

**Usage**:
```bash
./docker-stack-infrastructure/scripts/backup/backup-to-github.sh
```

**What it does**:

1. **Change Detection**
   - Checks for uncommitted changes
   - Skips if nothing to commit

2. **Validation**
   - Tests Docker Compose files before commit
   - Rolls back on validation errors

3. **Git Operations**
   - Commits with timestamp
   - Pushes to GitHub origin/main
   - Logs all operations

4. **Error Handling**
   - Validates configurations
   - Resets commits on errors
   - Detailed logging

### Manual Backup Procedures

**Configuration Backup**:
```bash
# Backup all configurations
tar -czf docker-config-backup-$(date +%Y%m%d).tar.gz \
  /home/melvin/projects/server/docker-stack-infrastructure \
  /home/shared/docker/*.yml \
  /etc/docker/daemon.json

# Backup specific service data
docker run --rm \
  -v portainer_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/portainer-backup.tar.gz /data
```

**Database Backup**:
```bash
# Backup WordPress database
docker exec mysql mysqldump -u root -p wordpress > wordpress-backup.sql

# Backup with compression
docker exec mysql mysqldump -u root -p wordpress | gzip > wordpress-backup-$(date +%Y%m%d).sql.gz
```

**Volume Backup**:
```bash
# List all volumes
docker volume ls

# Backup specific volume
docker run --rm \
  -v <volume-name>:/source \
  -v $(pwd):/backup \
  alpine tar czf /backup/<volume-name>-backup.tar.gz /source
```

### Automated Backup Strategy

1. **Daily Backups**
   - Configuration files to Git
   - Database dumps
   - Critical volumes

2. **Weekly Backups**
   - Full volume backups
   - System configurations
   - Docker images

3. **Monthly Archives**
   - Compressed archives
   - Off-site storage
   - Retention policy

### Setting Up Automated Backups

```bash
# Add to crontab
crontab -e

# Daily configuration backup (2 AM)
0 2 * * * /home/melvin/projects/server/docker-stack-infrastructure/scripts/backup/backup-to-github.sh

# Daily database backup (3 AM)
0 3 * * * docker exec mysql mysqldump -u root -p wordpress | gzip > /backup/wordpress-$(date +\%Y\%m\%d).sql.gz

# Weekly full backup (Sunday 4 AM)
0 4 * * 0 /home/melvin/projects/server/scripts/full-backup.sh
```

## Restoration Procedures

### Restore from Git Backup

```bash
# Clone repository
git clone https://github.com/yourusername/portainer-stacks.git

# Restore specific file from history
git checkout <commit-hash> -- <file-path>

# View file history
git log --oneline -- <file-path>
```

### Restore Docker Volumes

```bash
# Restore volume from backup
docker run --rm \
  -v <volume-name>:/target \
  -v $(pwd):/backup \
  alpine sh -c "cd /target && tar xzf /backup/<volume-name>-backup.tar.gz --strip 1"
```

### Restore Database

```bash
# Restore MySQL database
docker exec -i mysql mysql -u root -p wordpress < wordpress-backup.sql

# Restore from compressed backup
gunzip < wordpress-backup.sql.gz | docker exec -i mysql mysql -u root -p wordpress
```

## Monitoring Automation

### Log Rotation

Configure log rotation for Docker and monitoring logs:

```bash
# Create logrotate config
sudo cat > /etc/logrotate.d/docker-monitoring << EOF
/home/shared/docker/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 melvin melvin
}
EOF
```

### Automated Cleanup

```bash
# Docker cleanup script
cat > /home/shared/docker/cleanup.sh << 'EOF'
#!/bin/bash
# Docker cleanup script

# Remove stopped containers
docker container prune -f

# Remove unused images
docker image prune -a -f

# Remove unused volumes (careful!)
# docker volume prune -f

# Remove unused networks
docker network prune -f

# Clean build cache
docker builder prune -f

# Log cleanup action
echo "$(date): Cleanup completed" >> /home/shared/docker/logs/cleanup.log
EOF

chmod +x /home/shared/docker/cleanup.sh
```

## Best Practices

### Automation Guidelines

1. **Test Before Automating**
   - Run scripts manually first
   - Verify expected behavior
   - Check error handling

2. **Logging**
   - Log all automated actions
   - Include timestamps
   - Rotate logs regularly

3. **Error Handling**
   - Check exit codes
   - Send alerts on failures
   - Implement retry logic

4. **Security**
   - Use absolute paths in cron
   - Restrict script permissions
   - Avoid hardcoded credentials

### Backup Best Practices

1. **3-2-1 Rule**
   - 3 copies of data
   - 2 different storage types
   - 1 off-site backup

2. **Testing**
   - Regular restore tests
   - Document procedures
   - Verify backup integrity

3. **Retention**
   - Daily backups: 7 days
   - Weekly backups: 4 weeks
   - Monthly backups: 12 months

## Troubleshooting

### Cron Job Issues

```bash
# Check if cron is running
systemctl status cron

# View cron logs
grep CRON /var/log/syslog | tail -50

# Test script permissions
ls -la /path/to/script.sh

# Run script as cron would
env -i /bin/bash -c '/path/to/script.sh'
```

### Firewall Problems

```bash
# Temporarily disable firewall
sudo ufw disable

# Check specific port
sudo ufw status | grep 9443

# View detailed rules
sudo iptables -L -n -v
```

### Backup Failures

```bash
# Check Git status
cd /home/shared/git-repos/portainer-stacks
git status
git remote -v

# Test GitHub connection
ssh -T git@github.com

# Check disk space
df -h
```

## Related Documentation

- [Security Lockdown Guide](../security/LOCKDOWN-GUIDE.md)
- [Validation and Monitoring Guide](VALIDATION-AND-MONITORING.md)
- [Docker Installation Guide](DOCKER-INSTALLATION-GUIDE.md)
- [Tools and Scripts Index](../TOOLS-AND-SCRIPTS.md)