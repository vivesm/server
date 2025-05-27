# Tools and Scripts Index
**Last Updated**: 2025-01-26

## Overview

This document provides a comprehensive index of all scripts and tools created for the Docker infrastructure project.

## 🔧 Scripts by Category

### Security Scripts

#### `lockdown.sh`
**Purpose**: Automated security hardening for Tailscale-only access  
**Location**: `/home/melvin/projects/server/lockdown.sh`  
**Usage**: `sudo ./lockdown.sh`  
**Features**:
- Configures UFW firewall with Tailscale rules
- Generates secure passwords
- Updates SSH configuration for Tailscale-only access
- Creates verification tools

#### `verify-lockdown.sh`
**Purpose**: Verify security lockdown effectiveness  
**Location**: Created by lockdown.sh  
**Usage**: `./verify-lockdown.sh`  
**Features**:
- Checks UFW status
- Verifies exposed ports
- Validates SSH configuration
- Lists Docker exposed ports

### Terminal & Development

#### `tmux-setup.sh`
**Purpose**: Automated tmux installation and configuration for mobile SSH  
**Location**: `/home/melvin/projects/server/tmux-setup.sh`  
**Usage**: `./tmux-setup.sh`  
**Features**:
- Installs tmux with mobile-optimized config
- Creates helpful aliases
- Sets up session persistence plugins
- Configures touch-friendly keybindings

#### `fix-tmux-scrolling.sh`
**Purpose**: Fix tmux scrollback issues for long outputs  
**Location**: `/home/melvin/projects/server/fix-tmux-scrolling.sh`  
**Usage**: `./fix-tmux-scrolling.sh`  
**Features**:
- Enables mouse scrolling
- Increases history buffer to 50,000 lines
- Configures proper scroll behavior
- Adds copy mode improvements

#### `fix-tmux-mouse-selection.sh`
**Purpose**: Fix mouse selection immediately unhighlighting in iTerm2  
**Location**: `/home/melvin/projects/server/fix-tmux-mouse-selection.sh`  
**Usage**: `./fix-tmux-mouse-selection.sh`  
**Features**:
- Completely disables tmux mouse handling
- Unbinds ALL mouse events that interfere
- Allows terminal to handle selection natively
- Includes diagnostic checks

#### Helper Scripts (created by tmux-setup.sh)
- `~/tmux-quick.sh` - Quick session manager
- `~/tmux-dev-env.sh` - Development environment creator
- `~/iphone-tmux.sh` - iPhone-specific helper

### Documentation Publishing

#### `wordpress-publisher.py`
**Purpose**: Publish markdown documentation to WordPress  
**Location**: `/home/melvin/projects/server/wordpress-publisher.py`  
**Usage**: `python3 wordpress-publisher.py <username> <app-password>`  
**Features**:
- Converts markdown to HTML
- Creates categories and tags
- Handles authentication
- Batch publishes documents

#### `post-to-wordpress.sh`
**Purpose**: Bash alternative for WordPress publishing  
**Location**: `/home/melvin/projects/server/post-to-wordpress.sh`  
**Usage**: `./post-to-wordpress.sh <username> <app-password>`  
**Features**:
- Basic markdown conversion
- REST API integration
- Category creation

### Infrastructure Management

#### `start-portainer.sh`
**Purpose**: Start Portainer with Tailscale-only access  
**Location**: `/home/melvin/projects/server/start-portainer.sh`  
**Status**: Deprecated (use docker-compose instead)

#### `stop-portainer.sh`
**Purpose**: Stop Portainer and cleanup  
**Location**: `/home/melvin/projects/server/stop-portainer.sh`  
**Status**: Used during unification

#### `get-tailscale-ip.sh`
**Purpose**: Retrieve current Tailscale IP  
**Location**: `/home/melvin/projects/server/get-tailscale-ip.sh`  
**Usage**: `./get-tailscale-ip.sh`  
**Output**: Current Tailscale IP address

### Validation & Monitoring

#### `validate-all.sh`
**Purpose**: Comprehensive Docker stack validation  
**Location**: `/home/melvin/projects/server/docker-stack-infrastructure/scripts/validate-all.sh`  
**Usage**: `./scripts/validate-all.sh`  
**Features**:
- Container health checks
- Configuration validation
- Network connectivity tests
- HTML report generation

#### `enhanced-monitor.sh`
**Purpose**: Advanced health monitoring with alerts  
**Location**: `/home/melvin/projects/server/docker-stack-infrastructure/monitoring/scripts/enhanced-monitor.sh`  
**Usage**: `./monitoring/scripts/enhanced-monitor.sh`  
**Features**:
- Real-time monitoring
- Multi-channel alerting
- Metric collection
- HTML email reports

#### `check-network-connectivity.sh`
**Purpose**: Verify network connectivity  
**Location**: `/home/melvin/projects/server/docker-stack-infrastructure/scripts/check-network-connectivity.sh`  
**Usage**: `./scripts/check-network-connectivity.sh`

### Installation Scripts

#### `install-docker.sh`
**Purpose**: Install Docker on Ubuntu  
**Location**: `/home/melvin/projects/server/install-docker.sh`  
**Usage**: `sudo ./install-docker.sh`

#### `upgrade-docker.sh`
**Purpose**: Upgrade Docker to latest version  
**Location**: `/home/melvin/projects/server/upgrade-docker.sh`  
**Usage**: `sudo ./upgrade-docker.sh`

#### `install-tailscale.sh`
**Purpose**: Install Tailscale VPN  
**Location**: `/home/melvin/projects/server/install-tailscale.sh`  
**Usage**: `sudo ./install-tailscale.sh`

#### `setup-passwordless-sudo.sh`
**Purpose**: Configure passwordless sudo  
**Location**: `/home/melvin/projects/server/setup-passwordless-sudo.sh`  
**Usage**: `sudo ./setup-passwordless-sudo.sh`

### Setup & Automation

#### `setup-cron.sh`
**Purpose**: Configure automated monitoring and maintenance  
**Location**: `/home/melvin/projects/server/docker-stack-infrastructure/scripts/setup/setup-cron.sh`  
**Usage**: `sudo ./scripts/setup/setup-cron.sh`  
**Features**:
- Sets up 15-minute monitoring
- Daily validation checks
- Weekly comprehensive tests
- Automated cleanup

#### `update-firewall.sh`
**Purpose**: Configure firewall for Docker infrastructure  
**Location**: `/home/melvin/projects/server/docker-stack-infrastructure/scripts/security/update-firewall.sh`  
**Usage**: `sudo ./scripts/security/update-firewall.sh`  
**Features**:
- UFW/iptables configuration
- Tailscale-only Portainer access
- Service port management
- Security hardening

#### `backup-to-github.sh`
**Purpose**: Automated Git backup of configurations  
**Location**: `/home/melvin/projects/server/docker-stack-infrastructure/scripts/backup/backup-to-github.sh`  
**Usage**: `./scripts/backup/backup-to-github.sh`  
**Features**:
- Validates configurations before commit
- Automatic Git push
- Error handling and rollback
- Detailed logging

## 📁 Configuration Files

### Docker Compose Files
```
docker-stack-infrastructure/docker-compose/
├── core-infrastructure.yml      # Main services
├── core-infrastructure-secure.yml  # Hardened version
├── applications.yml            # WordPress, n8n
├── mcp-services.yml           # MCP configuration
└── .env.example               # Environment template
```

### Service Configurations
```
docker-stack-infrastructure/
├── caddy/config/Caddyfile     # Reverse proxy config
└── monitoring/scripts/
    └── enhanced-monitor.sh     # Monitoring script
```

## 🔨 Quick Reference

### Daily Operations
```bash
# Check service status
docker ps --format "table {{.Names}}\t{{.Status}}"

# Start development session
vibe  # or tmux attach -t vibe

# View logs
docker logs -f <container-name>

# Run security check
./verify-lockdown.sh
```

### Security Tasks
```bash
# Full lockdown
sudo ./lockdown.sh

# Generate secure password
openssl rand -base64 32

# Check firewall
sudo ufw status verbose
```

### Documentation
```bash
# Publish to WordPress
python3 wordpress-publisher.py admin "app-password"

# View documentation
ls -la documentation/
```

## 🎯 Script Usage Matrix

| Task | Script | Sudo Required | Frequency |
|------|--------|---------------|-----------|
| Security hardening | `lockdown.sh` | Yes | Once |
| Verify security | `verify-lockdown.sh` | No | Weekly |
| Setup terminal | `tmux-setup.sh` | No | Once |
| Fix scrolling | `fix-tmux-scrolling.sh` | No | As needed |
| Publish docs | `wordpress-publisher.py` | No | Regular |
| Get Tailscale IP | `get-tailscale-ip.sh` | No | As needed |
| Install Docker | `install-docker.sh` | Yes | Once |
| Upgrade Docker | `upgrade-docker.sh` | Yes | As needed |
| Install Tailscale | `install-tailscale.sh` | Yes | Once |
| Full validation | `validate-all.sh` | No | Daily/Weekly |
| Health monitoring | `enhanced-monitor.sh` | No | Every 15 min |
| Check network | `check-network-connectivity.sh` | No | As needed |
| Setup passwordless sudo | `setup-passwordless-sudo.sh` | Yes | Once |
| Setup cron jobs | `setup-cron.sh` | Yes | Once |
| Update firewall | `update-firewall.sh` | Yes | As needed |
| Backup to GitHub | `backup-to-github.sh` | No | Daily/Manual |

## 📚 Related Documentation

- [Security Lockdown Guide](security/LOCKDOWN-GUIDE.md)
- [TMUX Setup Guide](guides/TMUX-SETUP.md)
- [WordPress Publishing Guide](guides/WORDPRESS-PUBLISH.md)
- [Project Overview](architecture/PROJECT-OVERVIEW.md)
- [MCP Services Guide](guides/MCP-SERVICES-GUIDE.md)
- [Validation and Monitoring Guide](guides/VALIDATION-AND-MONITORING.md)
- [Docker Installation Guide](guides/DOCKER-INSTALLATION-GUIDE.md)
- [Automation and Backup Guide](guides/AUTOMATION-AND-BACKUP-GUIDE.md)

## 🚀 Getting Started

For new team members:
1. Run `./tmux-setup.sh` for terminal persistence
2. Run `./fix-tmux-scrolling.sh` if needed
3. Review security status with `./verify-lockdown.sh`
4. Read documentation in `documentation/`

## ⚠️ Important Notes

1. **Always backup** before running security scripts
2. **Test scripts** in development first
3. **Keep Tailscale active** before lockdown
4. **Document changes** when creating new scripts

---
*Keep this index updated when adding new scripts or tools*