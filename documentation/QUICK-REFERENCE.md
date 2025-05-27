# Quick Reference Card
**Infrastructure Management Cheat Sheet**

## 🚀 Essential Commands

### Service Management
```bash
# View all services
docker ps -a

# Start infrastructure
cd docker-stack-infrastructure
docker compose -f docker-compose/core-infrastructure.yml up -d

# View logs
docker logs -f <container-name>

# Restart service
docker restart <container-name>
```

### tmux Session Management
```bash
# Start/attach main session
vibe

# List sessions
tl

# Detach from session
Ctrl+a d

# Scroll in tmux
Ctrl+a [  (then arrows/PgUp/PgDn, 'q' to exit)
```

### Security Commands
```bash
# Run security lockdown
sudo ./lockdown.sh

# Verify security
./verify-lockdown.sh

# Check firewall
sudo ufw status verbose

# Generate secure password
openssl rand -base64 32
```

## 📍 Service URLs

| Service | URL | Access |
|---------|-----|--------|
| Portainer | https://100.112.235.46:9443 | Tailscale only |
| n8n | https://n8n.stringbits.com | Public (auth required) |
| WordPress | https://wp.stringbits.com | Public |
| Documentation | http://100.112.235.46:8080 | Local network |

## 🔑 Key Paths

```bash
# Documentation
/home/melvin/projects/server/documentation/

# Docker configurations
/home/melvin/projects/server/docker-stack-infrastructure/docker-compose/

# Service data
/home/shared/docker/

# Logs
/home/shared/docker/logs/
```

## 🛠️ Common Fixes

### Can't scroll in tmux
```bash
./fix-tmux-scrolling.sh
```

### Service not accessible
```bash
# Check if running
docker ps | grep <service>

# Check logs
docker logs <service>

# Restart
docker restart <service>
```

### Locked out (SSH)
```bash
# Use console/VNC access
sudo ufw disable
sudo systemctl restart ssh
```

## 📝 Documentation Tasks

### Publish to WordPress
```bash
cd /home/melvin/projects/server
python3 wordpress-publisher.py <user> <app-pass>
```

### Update documentation
```bash
cd documentation/
# Edit relevant .md files
git add .
git commit -m "Update documentation"
```

## 🚨 Emergency Contacts

- **Tailscale IP**: 100.112.235.46
- **Backup access**: Console/VNC via hosting provider
- **Documentation**: See `/documentation/README.md`

## 💡 Pro Tips

1. **Always in tmux**: Run `vibe` immediately after SSH
2. **Check before lockdown**: Ensure Tailscale is connected
3. **Document changes**: Update relevant .md files
4. **Test first**: Use development environment
5. **Keep backups**: Before major changes

---
*Keep this card handy for quick reference*