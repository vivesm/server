# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docker-based infrastructure management project for hosting multiple services with Tailscale VPN security, automated monitoring, and Portainer management. The infrastructure includes:

- **Core Services**: Portainer (container management), Caddy (reverse proxy), Watchtower (automatic updates)
- **Applications**: n8n (workflow automation), WordPress, RustDesk (remote desktop)
- **Security**: Tailscale-only access, UFW firewall rules, HTTPS everywhere
- **Monitoring**: Enhanced monitoring with 15-minute health checks and alerting
- **MCP Services**: Claude AI integration (claude-mcp.service, admin-mcp.service)

## Common Commands

### Service Management
```bash
# Start all services (unified stack)
cd docker-stack-infrastructure
docker compose -f docker-compose/core-infrastructure.yml up -d
docker compose -f docker-compose/applications.yml up -d
docker compose -f docker-compose/mcp-services.yml up -d

# Install/upgrade Docker
sudo ./install-docker.sh
sudo ./upgrade-docker.sh

# Install Tailscale
sudo ./install-tailscale.sh

# Get Tailscale IP
./get-tailscale-ip.sh
```

### Infrastructure Setup and Validation
```bash
# Full infrastructure installation
cd docker-stack-infrastructure
sudo ./scripts/setup/install.sh

# Validate all services
./scripts/validate-all.sh

# Check network connectivity
./scripts/check-network-connectivity.sh

# Setup cron jobs for monitoring
sudo ./scripts/setup/setup-cron.sh

# Update firewall rules
sudo ./scripts/security/update-firewall.sh

# Backup to GitHub
./scripts/backup/backup-to-github.sh
```

### Monitoring
```bash
# Run enhanced monitoring (generates HTML report)
./docker-stack-infrastructure/monitoring/scripts/enhanced-monitor.sh

# View validation logs
tail -f /home/shared/docker/logs/validation.log

# View monitoring report
open /home/shared/docker/logs/validation-report.html
```

### Docker Compose Operations
```bash
# Core infrastructure (Caddy, Portainer, Watchtower)
docker compose -f docker-stack-infrastructure/docker-compose/core-infrastructure.yml up -d

# Applications (n8n, WordPress, MySQL)
docker compose -f docker-stack-infrastructure/docker-compose/applications.yml up -d

# RustDesk remote desktop
docker compose -f docker-stack-infrastructure/docker-compose/rustdesk.yml up -d
```

## Architecture

### Service Access Points
- **n8n**: n8n.stringbits.com (workflow automation)
- **WordPress**: wp.stringbits.com 
- **Portainer**: ptn.stringbits.com:9443 (Tailscale-only)
- **RustDesk**: rd.stringbits.com

### Network Architecture
- **stringbits_net**: Primary Docker network for inter-service communication
- **docker_stringbits_net**: Secondary network for specific service isolation
- **Tailscale Network**: 100.64.0.0/10 (VPN access only)
- **Portainer Ports**: 9443 (HTTPS UI), 8000 (Edge agent)

### Data Persistence
All service data is stored in `/home/shared/docker/`:
- `caddy/`: Caddy configuration and certificates
- `n8n/`: Workflow data
- `mysql/`: WordPress database
- `wordpress/`: WordPress files
- `rustdesk/`: Remote desktop configuration
- `portainer/`: Container management data
- `logs/`: Monitoring and validation logs

### Security Model
1. **Tailscale VPN**: Primary access control - services bound to Tailscale IP (100.112.235.46)
2. **UFW Firewall**: Blocks non-Tailscale access to sensitive ports
3. **Docker Security**: All containers run with `no-new-privileges:true`
4. **HTTPS**: Caddy provides automatic SSL/TLS for all public services
5. **Access Restrictions**: Portainer restricted to Tailscale network only

### MCP Services Architecture
- **claude-mcp**: AI tools channel on port 6101 (Tailscale-only) - Dockerized
- **admin-mcp**: Shell-exec channel on port 6201 (Tailscale-only) - Dockerized
- Accessible via:
  - Direct: tcp://100.112.235.46:6101 and tcp://100.112.235.46:6201
  - Caddy: https://mcp-ai.stringbits.com and https://mcp-admin.stringbits.com
- Part of unified Docker stack with automatic updates via Watchtower

## Key Implementation Details

### Unified Stack Architecture
All services run in Docker containers managed through docker-compose:
1. Core infrastructure (Portainer, Caddy, Watchtower)
2. Applications (n8n, WordPress, RustDesk)
3. MCP services (Claude AI integrations)
4. All bound to Tailscale IP (100.112.235.46) where needed
5. Caddy handles HTTPS termination and access control

### Validation System
The `validate-all.sh` script performs comprehensive checks:
- Container health status
- Docker Compose file syntax
- Caddy configuration and proxy functionality
- Network connectivity
- Portainer persistence across restarts
- RustDesk configuration
- Git repository status
- Endpoint accessibility
- System resources (disk/memory)
- Generates HTML report with results

### Monitoring System
Enhanced monitoring runs every 15 minutes via cron:
- Checks all service health
- Validates configurations
- Monitors system resources
- Sends alerts on failures
- Generates detailed HTML reports in `/home/shared/docker/logs/`