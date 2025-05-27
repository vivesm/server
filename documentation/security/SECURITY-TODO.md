# Security Lockdown TODO List
**Goal**: Lock down entire infrastructure to Tailscale-only access

## 🔴 CRITICAL - Do Immediately

### 1. Enable UFW Firewall with Tailscale-Only Rules
```bash
# [ ] Enable UFW with Tailscale-only SSH access
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 100.64.0.0/10 to any port 22 comment 'SSH Tailscale only'
sudo ufw allow 80/tcp comment 'HTTP for Caddy'
sudo ufw allow 443/tcp comment 'HTTPS for Caddy'
sudo ufw allow from 100.64.0.0/10 to any port 9443 comment 'Portainer Tailscale only'
sudo ufw --force enable
```

### 2. Lock Down SSH to Tailscale Only
```bash
# [ ] Edit SSH configuration
sudo nano /etc/ssh/sshd_config

# Add/modify these lines:
ListenAddress 100.112.235.46
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes

# [ ] Restart SSH
sudo systemctl restart ssh
```

### 3. Secure n8n Service
```bash
# [ ] Generate secure n8n password
openssl rand -base64 32 > n8n_password.txt
chmod 600 n8n_password.txt

# [ ] Update docker-compose/core-infrastructure.yml
# Change N8N_BASIC_AUTH_PASSWORD to the generated password
# Remove public port exposure (0.0.0.0:5678)
# Only expose through Caddy reverse proxy
```

### 4. Remove All Public Port Exposures
```bash
# [ ] Update docker-compose files to bind services to Tailscale IP only
# [ ] Ensure all services go through Caddy for access control
```

## 🟡 HIGH PRIORITY - Complete within 24 hours

### 5. Update All Service Configurations

#### [ ] Core Infrastructure (docker-compose/core-infrastructure.yml)
- [ ] n8n: Remove `- "5678:443"` port mapping
- [ ] Portainer: Verify bound to Tailscale IP only ✓
- [ ] Add resource limits to all containers

#### [ ] Update Caddy Configuration
- [ ] Ensure all services have Tailscale IP restrictions
- [ ] Add rate limiting to all endpoints
- [ ] Verify security headers are applied

### 6. Implement Docker Secrets
```bash
# [ ] Create Docker secrets for all passwords
docker secret create n8n_password n8n_password.txt
docker secret create portainer_password portainer_password.txt

# [ ] Update docker-compose to use secrets instead of env vars
```

### 7. Fix Documentation
- [ ] Update SECURITY.md with correct Tailscale IP (100.112.235.46)
- [ ] Update all references to old IP (100.84.182.31)
- [ ] Document all security measures implemented

## 🟢 MEDIUM PRIORITY - Complete within 1 week

### 8. Enhanced Monitoring & Security
```bash
# [ ] Install and configure fail2ban
sudo apt-get update && sudo apt-get install fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
# Configure for SSH and Caddy logs

# [ ] Set up log aggregation
# [ ] Configure alerts for suspicious activities
```

### 9. Network Segmentation
- [ ] Create separate Docker networks:
  - `public_services` - For Caddy only
  - `internal_services` - For all other containers
  - `database_network` - For database connections only

### 10. Automated Security Updates
```bash
# [ ] Configure unattended-upgrades for security patches
sudo apt-get install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades
```

### 11. Backup Security
- [ ] Implement encrypted backups
- [ ] Set up automated offsite backup to GitHub
- [ ] Test restore procedures

## 📋 Verification Checklist

After completing above tasks, verify:

### Port Security
```bash
# [ ] Check no services listening on 0.0.0.0 except Caddy
sudo ss -tlnp | grep "0.0.0.0"
# Should only show ports 80, 443 for Caddy

# [ ] Verify Tailscale-only services
sudo ss -tlnp | grep "100.112.235.46"
# Should show SSH, Portainer, and any other admin services
```

### Firewall Verification
```bash
# [ ] Check UFW status
sudo ufw status verbose

# [ ] Test from outside Tailscale
# SSH should timeout
# Portainer should be inaccessible
# Only Caddy services should respond
```

### Authentication Check
- [ ] Verify no default passwords remain
- [ ] Confirm all services require strong authentication
- [ ] Test access with and without Tailscale connection

### Docker Security
```bash
# [ ] Verify all containers use security options
docker ps -q | xargs docker inspect | grep -E "(SecurityOpt|Privileged)"

# [ ] Check no containers run as root
docker ps -q | xargs docker inspect | grep '"User"'
```

## 🚀 Quick Implementation Script

Create `lockdown.sh`:
```bash
#!/bin/bash
# Security Lockdown Script

echo "🔒 Starting Security Lockdown..."

# Enable UFW
echo "📌 Configuring UFW..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 100.64.0.0/10 to any port 22 comment 'SSH Tailscale only'
sudo ufw allow 80/tcp comment 'HTTP Caddy'
sudo ufw allow 443/tcp comment 'HTTPS Caddy'
sudo ufw --force enable

# Generate passwords
echo "🔑 Generating secure passwords..."
openssl rand -base64 32 > n8n_password.txt
chmod 600 n8n_password.txt

echo "⚡ Next steps:"
echo "1. Update SSH config to bind to Tailscale IP"
echo "2. Update docker-compose with new passwords"
echo "3. Remove public port exposures"
echo "4. Restart all services"

echo "✅ Basic lockdown complete!"
```

## 📊 Progress Tracking

- [ ] Critical Tasks (0/4)
- [ ] High Priority Tasks (0/3)
- [ ] Medium Priority Tasks (0/4)
- [ ] Verification Complete
- [ ] Documentation Updated

## 🎯 Success Criteria

System is considered locked down when:
1. **NO services** accessible without Tailscale (except HTTP/HTTPS via Caddy)
2. **ALL authentication** uses strong, unique passwords
3. **UFW firewall** actively blocking non-Tailscale access
4. **Monitoring** alerts on any security events
5. **Documentation** reflects all security measures

---
Last Updated: 2025-01-26
Priority: CRITICAL - System currently has major security vulnerabilities