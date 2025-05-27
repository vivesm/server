# Docker Stack Infrastructure Setup

A comprehensive Docker-based infrastructure for hosting multiple services with robust monitoring, security, and management capabilities.

## Overview

This repository contains the complete configuration and tooling for a Docker-based infrastructure that includes:

* **n8n**: Workflow automation tool
* **WordPress**: Content management system
* **Portainer**: Docker container management UI
* **RustDesk**: Self-hosted remote desktop solution
* **Watchtower**: Automatic container updates
* **Caddy**: Reverse proxy handling HTTPS for all services
* **Git Server**: Hosting stack definitions and configuration

The infrastructure is designed with security, monitoring, and ease of maintenance in mind.

## Repository Structure

```
/
├── caddy/                   # Caddy reverse proxy configuration
│   └── config/              # Configuration files including Caddyfile
├── docker-compose/          # Docker Compose configuration files
│   ├── core-infrastructure.yml  # Core services (Caddy, Portainer, etc.)
│   ├── applications.yml     # Application services (WordPress, n8n, etc.)
│   └── rustdesk.yml         # RustDesk self-hosted remote desktop
├── monitoring/              # Monitoring and alerting configurations
│   └── scripts/             # Monitoring scripts
├── portainer/               # Portainer configurations and stacks
├── scripts/                 # Utility scripts
│   ├── setup/               # Setup and installation scripts
│   ├── backup/              # Backup and recovery scripts
│   └── security/            # Security configuration scripts
└── docs/                    # Documentation files
    └── services/            # Service-specific documentation
```

## Key Features

- **Container Orchestration**: Using Docker Compose for service coordination
- **Automatic HTTPS**: SSL/TLS certificates managed by Caddy
- **Centralized Management**: Portainer UI for container management
- **Comprehensive Monitoring**: Regular health checks and alerting
- **Automatic Updates**: Container updates via Watchtower
- **Secure Configuration**: Hardened security settings and firewall rules
- **Persistent Storage**: Data persistence configurations for all services
- **Self-hosted Remote Access**: Through RustDesk remote desktop solution
- **Documentation**: Extensive documentation for maintenance and troubleshooting

## Getting Started

### Prerequisites

- A Linux server (Ubuntu 22.04 LTS or later recommended)
- Docker and Docker Compose installed
- Basic familiarity with Docker concepts

### Quick Start

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/docker-stack-infrastructure.git
   cd docker-stack-infrastructure
   ```

2. Run the setup script:
   ```bash
   ./scripts/setup/install.sh
   ```

3. Verify the installation:
   ```bash
   ./scripts/validate-all.sh
   ```

## Service Access

After installation, services are available at:

- **n8n**: n8n.yourdomain.com
- **WordPress**: wp.yourdomain.com
- **Portainer**: ptn.yourdomain.com (restricted to Tailscale network)
- **RustDesk**: rd.yourdomain.com

## Documentation

Detailed documentation is available in the `docs/` directory:

- [Infrastructure Overview](./docs/INFRASTRUCTURE-OVERVIEW.md)
- [Monitoring Setup](./docs/MONITORING.md)
- [Persistence Configuration](./docs/PERSISTENCE.md)
- [Portainer Stack Management](./docs/PORTAINER-STACKS.md)
- [Security Considerations](./docs/SECURITY.md)
- [Troubleshooting Guide](./docs/TROUBLESHOOTING.md)

## Maintenance

Regular maintenance tasks are automated using cron jobs and scripts:

```bash
# View active monitoring and maintenance jobs
crontab -l

# Run manual validation
./scripts/validate-all.sh

# Check system status
./scripts/enhanced-monitor.sh
```

## Security

This infrastructure implements several security best practices:

- **HTTPS Everywhere**: All services are accessed via HTTPS
- **Security Headers**: Proper security headers via Caddy
- **Network Isolation**: Services run on isolated Docker networks
- **Privilege Restrictions**: All containers use `no-new-privileges:true`
- **Regular Updates**: Automatic security updates via Watchtower
- **Access Controls**: Limited access to sensitive services (e.g., Portainer)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.