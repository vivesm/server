# Server Infrastructure

A production-ready Docker infrastructure with automated monitoring, security hardening, and disaster recovery capabilities.

## 🚀 Quick Start

```bash
# Clone repository
git clone https://github.com/vivesm/server.git
cd server

# Install prerequisites
sudo scripts/setup/install-docker.sh
sudo scripts/setup/install-tailscale.sh

# Start infrastructure
cd docker-stack-infrastructure
docker compose -f docker-compose/core-infrastructure.yml up -d
docker compose -f docker-compose/applications.yml up -d
```

## 📁 Repository Structure

```
server/
├── scripts/                     # Executable scripts
│   ├── backup/                 # Backup and restore tools
│   ├── setup/                  # Installation scripts
│   ├── security/               # Security hardening
│   ├── tmux/                   # Terminal persistence
│   └── utilities/              # Helper scripts
├── documentation/              # All documentation
│   ├── guides/                # How-to guides
│   ├── security/              # Security documentation
│   └── architecture/          # System design
├── docker-stack-infrastructure/ # Docker configurations
│   ├── docker-compose/        # Service definitions
│   ├── scripts/               # Infrastructure scripts
│   └── monitoring/            # Health check tools
├── n8n-backups/               # Workflow backups
└── archives/                  # Deprecated files

```

## 🔧 Core Services

| Service | Purpose | Access |
|---------|---------|--------|
| Portainer | Container Management | https://100.112.235.46:9443 |
| Caddy | Reverse Proxy & SSL | Ports 80/443 |
| n8n | Workflow Automation | https://n8n.stringbits.com |
| Watchtower | Auto Updates | Background service |
| Gollum | Documentation Wiki | http://100.112.235.46:4567 |

## 🔒 Security Features

- **Tailscale VPN**: All management interfaces restricted to VPN
- **Automatic HTTPS**: Caddy provides SSL for all services
- **UFW Firewall**: Configured for minimal exposure
- **Docker Security**: All containers run with `no-new-privileges`
- **Automated Backups**: Regular encrypted backups

## 📚 Documentation

- [Project Overview](documentation/architecture/PROJECT-OVERVIEW.md)
- [Quick Reference](documentation/QUICK-REFERENCE.md)
- [Security Review](documentation/security/SECURITY-REVIEW.md)
- [Backup Strategy](documentation/guides/BACKUP-STRATEGY.md)

### Access Documentation Wiki

```bash
# Gollum is already running if you started the infrastructure
# Access at: http://100.112.235.46:4567
```

## 🛠️ Common Tasks

### Backup Everything
```bash
./scripts/backup/backup-all.sh
```

### Check Security Status
```bash
./scripts/security/lockdown.sh --verify
```

### Monitor Services
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Access tmux Session
```bash
./scripts/tmux/tmux-setup.sh  # First time setup
tmux attach -t vibe           # Attach to session
```

## 🚨 Important Security Notes

1. **Change default passwords** immediately after deployment
2. **Enable UFW firewall** - Currently disabled!
3. **Restrict SSH** to Tailscale network only
4. Review [Security TODO](documentation/security/SECURITY-TODO.md)

## 🤝 Contributing

1. Create feature branch
2. Make changes
3. Update documentation
4. Submit pull request

## 📄 License

MIT License - See LICENSE file

---

**Maintained by**: Infrastructure Team  
**Repository**: https://github.com/vivesm/server