# Docker Stack Infrastructure - Service Access

## Unified Architecture Overview

All services are now managed through a single Docker stack infrastructure with Tailscale VPN security.

## Service Access Points

### Core Infrastructure Services

#### 1. Portainer (Container Management)
- **URL**: https://ptn.stringbits.com or https://100.112.235.46:9443
- **Access**: Tailscale network only
- **Features**: Full Docker container management UI

#### 2. Caddy (Reverse Proxy)
- **Ports**: 80 (HTTP), 443 (HTTPS)
- **Function**: Automatic HTTPS, security headers, Tailscale IP filtering
- **Management**: Through Portainer

#### 3. Watchtower (Automatic Updates)
- **Status**: Running in background
- **Function**: Automatically updates containers every 5 minutes
- **No web interface**

### Application Services

#### 4. n8n (Workflow Automation)
- **URL**: https://n8n.stringbits.com
- **Direct Access**: http://100.112.235.46:5678
- **Default Credentials**: admin/changeme (change after first login!)
- **Access**: Public (protected by authentication)

#### 5. WordPress
- **URL**: https://wp.stringbits.com
- **Database**: MySQL (internal)
- **Access**: Public

#### 6. RustDesk (Remote Desktop)
- **URL**: https://rd.stringbits.com
- **Ports**: 21115-21119 (various protocols)
- **Key Location**: /home/shared/docker/rustdesk/id_ed25519.pub

### MCP Services (Claude AI Integration)

#### 7. Claude MCP (AI Tools)
- **URL**: https://mcp-ai.stringbits.com or tcp://100.112.235.46:6101
- **Access**: Tailscale network only
- **Function**: AI tools channel for Claude

#### 8. Admin MCP (Shell Execution)
- **URL**: https://mcp-admin.stringbits.com or tcp://100.112.235.46:6201
- **Access**: Tailscale network only
- **Function**: Administrative shell execution

## Network Architecture

- **Primary Network**: stringbits_net (all services)
- **Secondary Network**: docker_stringbits_net (service isolation)
- **Tailscale Range**: 100.64.0.0/10
- **Current Tailscale IP**: 100.112.235.46

## Data Persistence

All service data stored in `/home/shared/docker/`:
- `portainer/`: Container management data
- `caddy/`: SSL certificates and configuration
- `n8n/`: Workflow data
- `mysql/`: WordPress database
- `wordpress/`: WordPress files
- `rustdesk/`: Remote desktop configuration
- `logs/`: Monitoring and validation logs

## Security Features

1. **Tailscale VPN Protection**: Critical services restricted to VPN access
2. **Automatic HTTPS**: Caddy provides SSL/TLS for all domains
3. **Security Headers**: HSTS, CSP, X-Frame-Options, etc.
4. **Container Security**: All containers run with `no-new-privileges:true`
5. **Automatic Updates**: Watchtower keeps containers updated

## Management Commands

```bash
# Start all services
cd docker-stack-infrastructure
docker compose -f docker-compose/core-infrastructure.yml up -d
docker compose -f docker-compose/applications.yml up -d
docker compose -f docker-compose/mcp-services.yml up -d

# View logs
docker compose -f docker-compose/core-infrastructure.yml logs -f

# Restart a service
docker restart <container-name>

# Run validation
./scripts/validate-all.sh

# Monitor services
./monitoring/scripts/enhanced-monitor.sh
```

## Monitoring & Validation

- **Validation Script**: `/scripts/validate-all.sh`
- **Monitoring**: 15-minute automated health checks via cron
- **Reports**: HTML reports in `/home/shared/docker/logs/`
- **Logs**: Centralized in `/home/shared/docker/logs/`

## Quick Troubleshooting

1. **Service not accessible**: Check Tailscale connection and firewall rules
2. **Container issues**: View logs via Portainer or `docker logs <container>`
3. **Certificate problems**: Check Caddy logs and configuration
4. **MCP connection failed**: Ensure services are running and check network connectivity

Last Updated: 2025-01-26