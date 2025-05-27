# MCP Services Configuration Guide
**Last Updated**: 2025-01-26

## Overview

MCP (Model Control Protocol) services provide AI integration capabilities through Docker containers. This guide covers the setup, configuration, and management of the MCP services in the Docker infrastructure.

## Service Architecture

### Components

1. **claude-mcp** - AI tools channel on port 6101
   - Provides Claude AI integration
   - Accessible via TCP protocol
   - Bound to Tailscale IP for security

2. **admin-mcp** - Shell execution channel on port 6201
   - Administrative command execution
   - Enhanced security with isolated container
   - Also bound to Tailscale IP

### Access Points

- **Direct TCP Access**:
  - Claude MCP: `tcp://100.112.235.46:6101`
  - Admin MCP: `tcp://100.112.235.46:6201`

- **HTTPS via Caddy**:
  - Claude MCP: `https://mcp-ai.stringbits.com`
  - Admin MCP: `https://mcp-admin.stringbits.com`

## Configuration

### Docker Compose Configuration

Location: `/home/melvin/projects/server/docker-stack-infrastructure/docker-compose/mcp-services.yml`

```yaml
version: '3.8'

services:
  claude-mcp:
    image: node:20-alpine
    container_name: claude-mcp
    restart: always
    working_dir: /app
    volumes:
      - /opt/claude:/app
      - /home/melvin/.claude:/home/node/.claude
    environment:
      - NODE_ENV=production
      - MCP_LISTEN=tcp://0.0.0.0:6101
    ports:
      - "100.112.235.46:6101:6101"
    command: ["sh", "-c", "npm install -g @anthropic-ai/claude-code && claude mcp serve"]
    user: "1000:1000"
    security_opt:
      - no-new-privileges:true
    labels:
      - com.centurylinklabs.watchtower.enable=true
    networks:
      - stringbits_net
      - docker_stringbits_net

  admin-mcp:
    image: node:20-alpine
    container_name: admin-mcp
    restart: always
    working_dir: /app
    volumes:
      - /opt/admin-mcp:/app
      - /home/melvin/.claude:/home/node/.claude
    environment:
      - NODE_ENV=production
      - MCP_LISTEN=tcp://0.0.0.0:6201
    ports:
      - "100.112.235.46:6201:6201"
    command: ["sh", "-c", "npm install -g @anthropic-ai/claude-code && claude mcp serve --agent ./exec-agent.js"]
    user: "1000:1000"
    security_opt:
      - no-new-privileges:true
    labels:
      - com.centurylinklabs.watchtower.enable=true
    networks:
      - stringbits_net
      - docker_stringbits_net
```

### Security Features

1. **Tailscale-only Access**: Services bound to Tailscale IP (100.112.235.46)
2. **No New Privileges**: Containers run with restricted privileges
3. **User Isolation**: Runs as non-root user (UID 1000)
4. **Network Isolation**: Uses dedicated Docker networks
5. **Automatic Updates**: Enabled via Watchtower labels

## Management

### Starting Services

```bash
# Start MCP services only
cd /home/melvin/projects/server/docker-stack-infrastructure
docker compose -f docker-compose/mcp-services.yml up -d

# Start as part of unified stack
docker compose -f docker-compose/core-infrastructure.yml up -d
docker compose -f docker-compose/applications.yml up -d
docker compose -f docker-compose/mcp-services.yml up -d
```

### Stopping Services

```bash
# Stop MCP services
docker compose -f docker-compose/mcp-services.yml down

# Stop specific service
docker stop claude-mcp
docker stop admin-mcp
```

### Viewing Logs

```bash
# View claude-mcp logs
docker logs -f claude-mcp

# View admin-mcp logs
docker logs -f admin-mcp

# View last 100 lines
docker logs --tail 100 claude-mcp
```

### Restarting Services

```bash
# Restart individual service
docker restart claude-mcp
docker restart admin-mcp

# Recreate services (pulls latest config)
docker compose -f docker-compose/mcp-services.yml up -d --force-recreate
```

## Troubleshooting

### Service Not Starting

1. Check container status:
   ```bash
   docker ps -a | grep mcp
   ```

2. Check logs for errors:
   ```bash
   docker logs claude-mcp
   docker logs admin-mcp
   ```

3. Verify Tailscale IP:
   ```bash
   ./get-tailscale-ip.sh
   ```

4. Check port availability:
   ```bash
   sudo netstat -tlnp | grep -E "6101|6201"
   ```

### Connection Issues

1. Verify service is running:
   ```bash
   docker ps | grep mcp
   ```

2. Test TCP connectivity:
   ```bash
   nc -zv 100.112.235.46 6101
   nc -zv 100.112.235.46 6201
   ```

3. Check Caddy proxy:
   ```bash
   curl -I https://mcp-ai.stringbits.com
   curl -I https://mcp-admin.stringbits.com
   ```

### Container Crashes

1. Check resource limits:
   ```bash
   docker stats claude-mcp admin-mcp
   ```

2. Review system logs:
   ```bash
   journalctl -u docker -n 100
   ```

3. Inspect container:
   ```bash
   docker inspect claude-mcp
   docker inspect admin-mcp
   ```

## Maintenance

### Updating Services

Services are automatically updated by Watchtower. To manually update:

```bash
# Pull latest images
docker compose -f docker-compose/mcp-services.yml pull

# Recreate containers
docker compose -f docker-compose/mcp-services.yml up -d
```

### Backup Configuration

Important files to backup:
- `/home/melvin/projects/server/docker-stack-infrastructure/docker-compose/mcp-services.yml`
- `/opt/claude/` (claude-mcp data)
- `/opt/admin-mcp/` (admin-mcp data)
- `/home/melvin/.claude/` (user configuration)

### Health Monitoring

MCP services are monitored by the enhanced monitoring system:

```bash
# Run manual health check
./docker-stack-infrastructure/monitoring/scripts/enhanced-monitor.sh

# Check validation
./docker-stack-infrastructure/scripts/validate-all.sh
```

## Security Considerations

1. **Access Control**: Services only accessible via Tailscale VPN
2. **Port Binding**: Bound to specific Tailscale IP, not 0.0.0.0
3. **Container Isolation**: Running with restricted privileges
4. **Network Segmentation**: Using dedicated Docker networks
5. **Regular Updates**: Automatic updates via Watchtower

## Integration with Other Services

### Caddy Reverse Proxy

MCP services are proxied through Caddy for HTTPS access. Configuration in Caddyfile:

```
mcp-ai.stringbits.com {
    reverse_proxy claude-mcp:6101
}

mcp-admin.stringbits.com {
    reverse_proxy admin-mcp:6201
}
```

### Network Architecture

- Connected to both `stringbits_net` and `docker_stringbits_net`
- Can communicate with other services on the same networks
- Isolated from host network except for exposed ports

## Best Practices

1. **Regular Monitoring**: Check service health daily
2. **Log Review**: Review logs for errors weekly
3. **Resource Monitoring**: Monitor CPU/memory usage
4. **Security Updates**: Keep base images updated
5. **Backup Strategy**: Regular backups of configuration and data

## Related Documentation

- [Docker Infrastructure Overview](../architecture/PROJECT-OVERVIEW.md)
- [Security Lockdown Guide](../security/LOCKDOWN-GUIDE.md)
- [Service Access Guide](../architecture/service-access.md)
- [Unified Stack Setup](../setup/UNIFIED-STACK.md)