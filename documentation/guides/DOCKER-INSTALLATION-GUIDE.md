# Docker Installation and Management Guide
**Last Updated**: 2025-01-26

## Overview

This guide covers the Docker installation scripts and management tools used in the infrastructure setup. These scripts automate Docker installation, upgrades, and provide utilities for Docker management.

## Installation Scripts

### install-docker.sh

**Location**: `/home/melvin/projects/server/install-docker.sh`

**Purpose**: Automated Docker installation on Ubuntu systems

**Usage**:
```bash
sudo ./install-docker.sh
```

**What it does**:
1. Updates system packages
2. Installs Docker prerequisites
3. Adds Docker's official GPG key
4. Sets up Docker repository
5. Installs Docker Engine, CLI, and plugins
6. Configures Docker to start on boot
7. Adds current user to docker group
8. Installs Docker Compose

**Post-Installation**:
- Log out and back in for group changes to take effect
- Or run: `newgrp docker`

### upgrade-docker.sh

**Location**: `/home/melvin/projects/server/upgrade-docker.sh`

**Purpose**: Upgrade Docker to the latest version

**Usage**:
```bash
sudo ./upgrade-docker.sh
```

**What it does**:
1. Updates package repository
2. Upgrades Docker packages to latest versions
3. Restarts Docker service
4. Verifies the upgrade

**Safety Features**:
- Creates backup of docker daemon.json
- Checks service status after upgrade
- Preserves existing configurations

## Tailscale Installation

### install-tailscale.sh

**Location**: `/home/melvin/projects/server/install-tailscale.sh`

**Purpose**: Install Tailscale VPN for secure access

**Usage**:
```bash
sudo ./install-tailscale.sh
```

**What it does**:
1. Adds Tailscale package repository
2. Installs Tailscale
3. Starts Tailscale service
4. Prompts for authentication

**Post-Installation**:
```bash
# Authenticate Tailscale
sudo tailscale up

# Get Tailscale IP
tailscale ip -4
```

### get-tailscale-ip.sh

**Location**: `/home/melvin/projects/server/get-tailscale-ip.sh`

**Purpose**: Retrieve current Tailscale IP address

**Usage**:
```bash
./get-tailscale-ip.sh
```

**Output**: Current Tailscale IPv4 address (e.g., 100.112.235.46)

**Use Cases**:
- Configuring services to bind to Tailscale IP
- Updating firewall rules
- Verifying Tailscale connectivity

## System Security Setup

### setup-passwordless-sudo.sh

**Location**: `/home/melvin/projects/server/setup-passwordless-sudo.sh`

**Purpose**: Configure passwordless sudo for automation

**Usage**:
```bash
sudo ./setup-passwordless-sudo.sh
```

**What it does**:
1. Creates sudoers.d file for user
2. Validates syntax before applying
3. Sets proper permissions (0440)
4. Verifies configuration

**Safety Features**:
- Hardcoded username for safety
- Syntax validation with visudo
- Rollback on error
- Clear testing instructions

**Important**: Test sudo in a new terminal before closing current session!

## Docker Compose Management

### Docker Compose Files Structure

```
docker-stack-infrastructure/docker-compose/
├── core-infrastructure.yml     # Portainer, Caddy, Watchtower
├── applications.yml           # n8n, WordPress, MySQL
├── mcp-services.yml          # MCP AI services
└── core-infrastructure-secure.yml  # Hardened version
```

### Common Docker Commands

**Start Services**:
```bash
# Start all services
cd docker-stack-infrastructure
docker compose -f docker-compose/core-infrastructure.yml up -d
docker compose -f docker-compose/applications.yml up -d
docker compose -f docker-compose/mcp-services.yml up -d

# Start specific service
docker compose -f docker-compose/core-infrastructure.yml up -d portainer
```

**Stop Services**:
```bash
# Stop all services
docker compose -f docker-compose/core-infrastructure.yml down

# Stop and remove volumes (CAUTION: data loss)
docker compose -f docker-compose/core-infrastructure.yml down -v
```

**View Logs**:
```bash
# View all logs
docker compose -f docker-compose/core-infrastructure.yml logs

# Follow specific service logs
docker compose -f docker-compose/core-infrastructure.yml logs -f caddy
```

**Update Services**:
```bash
# Pull latest images
docker compose -f docker-compose/core-infrastructure.yml pull

# Recreate containers with new images
docker compose -f docker-compose/core-infrastructure.yml up -d
```

## Docker Maintenance

### Cleanup Commands

```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove unused volumes (CAUTION: data loss)
docker volume prune

# Remove all unused objects
docker system prune

# See disk usage
docker system df
```

### Health Checks

```bash
# Check Docker service status
systemctl status docker

# Check Docker version
docker --version
docker compose version

# List running containers
docker ps

# Check container health
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
```

### Resource Monitoring

```bash
# Real-time container stats
docker stats

# Container resource limits
docker inspect <container> | grep -A 10 "HostConfig"

# Check logs size
du -sh /var/lib/docker/containers/*/
```

## Troubleshooting

### Docker Service Issues

**Service won't start**:
```bash
# Check service status
sudo systemctl status docker

# Check logs
sudo journalctl -u docker -n 50

# Restart service
sudo systemctl restart docker
```

**Permission denied errors**:
```bash
# Verify user in docker group
groups

# Add user to docker group
sudo usermod -aG docker $USER

# Apply changes
newgrp docker
```

### Container Issues

**Container won't start**:
```bash
# Check logs
docker logs <container-name>

# Inspect container
docker inspect <container-name>

# Check for port conflicts
sudo netstat -tlnp | grep <port>
```

**Out of disk space**:
```bash
# Check disk usage
df -h

# Clean up Docker
docker system prune -a

# Check Docker root directory
du -sh /var/lib/docker/
```

### Network Issues

**Container can't connect**:
```bash
# List networks
docker network ls

# Inspect network
docker network inspect <network-name>

# Test connectivity
docker exec <container> ping <target>
```

## Best Practices

### Installation

1. **Always use official Docker repositories**
2. **Keep Docker updated for security patches**
3. **Configure Docker daemon for production**:
   ```json
   {
     "log-driver": "json-file",
     "log-opts": {
       "max-size": "10m",
       "max-file": "3"
     },
     "storage-driver": "overlay2"
   }
   ```

### Security

1. **Run containers as non-root users**
2. **Use Docker secrets for sensitive data**
3. **Enable Docker Content Trust**:
   ```bash
   export DOCKER_CONTENT_TRUST=1
   ```
4. **Limit container resources**
5. **Use read-only filesystems where possible**

### Monitoring

1. **Set up log rotation**
2. **Monitor disk usage regularly**
3. **Use health checks in compose files**
4. **Set restart policies appropriately**

## Advanced Configuration

### Docker Daemon Configuration

**Location**: `/etc/docker/daemon.json`

Example production configuration:
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3",
    "labels": "production"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "metrics-addr": "127.0.0.1:9323",
  "experimental": false,
  "features": {
    "buildkit": true
  },
  "insecure-registries": [],
  "registry-mirrors": [],
  "debug": false
}
```

### Systemd Overrides

Create custom systemd settings:
```bash
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo cat > /etc/systemd/system/docker.service.d/override.conf << EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker
```

## Related Documentation

- [Project Overview](../architecture/PROJECT-OVERVIEW.md)
- [Security Lockdown Guide](../security/LOCKDOWN-GUIDE.md)
- [Unified Stack Setup](../setup/UNIFIED-STACK.md)
- [Tools and Scripts Index](../TOOLS-AND-SCRIPTS.md)