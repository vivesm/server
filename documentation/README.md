# Docker Infrastructure Documentation
**Last Updated**: 2025-01-26

## 📚 Documentation Structure

```
documentation/
├── README.md                    # This index file
├── TOOLS-AND-SCRIPTS.md        # Complete script/tool index
├── setup/                       # Installation and setup guides
│   ├── INITIAL-SETUP.md        # Initial server setup
│   ├── DOCKER-SETUP.md         # Docker installation
│   ├── UNIFIED-STACK.md        # Stack unification process
│   └── 2025-01-26-WORK-LOG.md # Consolidation work log
├── security/                    # Security documentation
│   ├── SECURITY-REVIEW.md      # Security audit report
│   ├── SECURITY-TODO.md        # Security hardening tasks
│   └── LOCKDOWN-GUIDE.md       # Lockdown procedures
├── guides/                      # How-to guides
│   ├── TMUX-SETUP.md          # Terminal persistence
│   ├── TMUX-SCROLLING-FIX.md  # Fix tmux scrolling issues
│   ├── TMUX-MOUSE-SELECTION-FIX.md # Fix mouse selection in iTerm2
│   └── WORDPRESS-PUBLISH.md    # Publishing documentation
└── architecture/               # System architecture
    ├── PROJECT-OVERVIEW.md     # Overall project structure
    ├── service-access.md       # Service endpoints
    └── NETWORK-TOPOLOGY.md     # Network configuration
```

## 🚀 Quick Start Guides

### For New Team Members
1. Read [PROJECT-OVERVIEW.md](architecture/PROJECT-OVERVIEW.md) - Understand the system
2. Review [service-access.md](architecture/service-access.md) - Learn service endpoints
3. Setup [TMUX-SETUP.md](guides/TMUX-SETUP.md) - Configure persistent sessions
4. Fix scrolling with [TMUX-SCROLLING-FIX.md](guides/TMUX-SCROLLING-FIX.md) - Enable proper scrollback

### For Security Team
1. Review [SECURITY-REVIEW.md](security/SECURITY-REVIEW.md) - Current security status
2. Execute [SECURITY-TODO.md](security/SECURITY-TODO.md) - Hardening tasks
3. Follow [LOCKDOWN-GUIDE.md](security/LOCKDOWN-GUIDE.md) - Lockdown procedures

### For Operations
1. Check [UNIFIED-STACK.md](setup/UNIFIED-STACK.md) - Infrastructure setup
2. Monitor via Portainer at https://100.112.235.46:9443
3. Access logs at `/home/shared/docker/logs/`

## 📊 Current System Status

### Infrastructure Components
- **Docker Stack**: Unified architecture with compose files
- **Tailscale VPN**: Primary access control (IP: 100.112.235.46)
- **Monitoring**: 15-minute health checks via cron
- **Updates**: Automatic via Watchtower

### Running Services
| Service | Access | Status | Security |
|---------|--------|--------|----------|
| Portainer | https://100.112.235.46:9443 | ✅ Running | Tailscale-only |
| Caddy | Ports 80/443 | ✅ Running | Public |
| n8n | https://n8n.stringbits.com | ⚠️ Default password | Public |
| WordPress | https://wp.stringbits.com | ✅ Running | Public |
| Watchtower | Background service | ✅ Running | Internal |

### Security Status
- **UFW Firewall**: ❌ DISABLED (Critical)
- **SSH**: ⚠️ Open to all interfaces
- **Docker Security**: ✅ Good (no-new-privileges)
- **HTTPS**: ✅ Enabled via Caddy
- **Authentication**: ⚠️ Default passwords on n8n

## 📝 Recent Changes (2025-01-26)

### System Unification
- Consolidated dual Portainer instances into single stack
- Moved from root-level services to docker-stack-infrastructure
- Updated all configurations to use current Tailscale IP (100.112.235.46)
- Created unified documentation structure
- Fixed Docker networking issues

### Security Improvements
- Conducted comprehensive security audit
- Created automated lockdown scripts and procedures
- Identified critical vulnerabilities (UFW disabled, default passwords)
- Prepared secure Docker configurations
- Created step-by-step hardening guides

### Documentation & Tools
- Created organized documentation structure
- Developed WordPress publishing tools (Python & Bash)
- Established maintenance procedures
- Added mobile-friendly terminal setup with tmux
- Fixed tmux scrolling for long outputs
- Created work logs and guides

### Scripts Created
- `lockdown.sh` - Automated security hardening
- `tmux-setup.sh` - Terminal persistence setup
- `fix-tmux-scrolling.sh` - Scrollback configuration
- `wordpress-publisher.py` - Documentation to WordPress
- `verify-lockdown.sh` - Security verification

## 🔧 Common Tasks

### View All Services
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Check Security Status
```bash
./verify-lockdown.sh
```

### Access Documentation Wiki
```bash
# Start Gollum wiki
cd docker-stack-infrastructure
docker compose -f docker-compose/gollum.yml up -d

# Access at: http://100.112.235.46:4567
# Or: https://docs.stringbits.com (if configured)
```

### Publish Documentation
```bash
cd /home/melvin/projects/server
# New Python publisher with full formatting support
./wp-publisher.py documentation/guides/TMUX-SETUP.md

# Or use the old bash script (limited formatting)
./post-to-wordpress.sh
```

### Start Development Session
```bash
vibe  # or tmux attach -t vibe
```

### Fix tmux Scrolling
```bash
./fix-tmux-scrolling.sh
```

## 🚨 Critical Actions Needed

1. **Enable UFW Firewall** - System is exposed!
2. **Change n8n password** - Default credentials active
3. **Restrict SSH** - Currently open to all
4. **Complete security tasks** - See [SECURITY-TODO.md](security/SECURITY-TODO.md)

## 📞 Support

- **Documentation Issues**: Update via PR to this repository
- **Security Concerns**: Follow incident response in security/
- **Service Problems**: Check Portainer first, then logs
- **Access Issues**: Verify Tailscale connection

---
*This documentation is maintained as part of the Docker Infrastructure project*