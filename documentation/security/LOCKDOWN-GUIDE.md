# Security Lockdown Guide
**Priority**: CRITICAL
**Created**: 2025-01-26

## Overview

This guide provides step-by-step instructions to lock down the Docker infrastructure to Tailscale-only access, addressing critical security vulnerabilities.

## Pre-Lockdown Checklist

⚠️ **WARNING**: These changes will restrict access. Ensure you have:
- [ ] Active Tailscale connection
- [ ] Console/VNC access as backup
- [ ] Current Tailscale IP noted: 100.112.235.46
- [ ] Backup of important data

## Automated Lockdown

### Quick Method
```bash
# Run the automated lockdown script
cd /home/melvin/projects/server
sudo ./lockdown.sh
```

This script will:
1. Configure UFW firewall with Tailscale rules
2. Generate secure passwords
3. Create SSH configuration for Tailscale-only access
4. Provide verification tools

## Manual Lockdown Steps

### Step 1: Enable UFW Firewall

```bash
# Reset firewall to clean state
sudo ufw --force reset

# Set default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH only from Tailscale
sudo ufw allow from 100.64.0.0/10 to any port 22 comment 'SSH Tailscale only'
sudo ufw allow from fd7a:115c:a1e0::/48 to any port 22 comment 'SSH Tailscale IPv6'

# Allow HTTP/HTTPS for public services
sudo ufw allow 80/tcp comment 'HTTP Caddy'
sudo ufw allow 443/tcp comment 'HTTPS Caddy'

# Allow Portainer only from Tailscale
sudo ufw allow from 100.64.0.0/10 to any port 9443 comment 'Portainer Tailscale only'

# Enable firewall
sudo ufw --force enable

# Verify rules
sudo ufw status verbose
```

### Step 2: Secure SSH Access

```bash
# Backup current SSH config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Edit SSH configuration
sudo nano /etc/ssh/sshd_config
```

Add/modify these settings:
```
# Bind to Tailscale IP only
ListenAddress 100.112.235.46

# Security settings
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no

# Only allow specific users
AllowUsers melvin
```

Apply changes:
```bash
# Test configuration
sudo sshd -t

# Restart SSH
sudo systemctl restart ssh
```

### Step 3: Secure n8n Service

```bash
# Generate secure password
openssl rand -base64 32 > n8n_password.txt
chmod 600 n8n_password.txt

# Update docker-compose
cd docker-stack-infrastructure
cp docker-compose/.env.example docker-compose/.env

# Edit .env file
nano docker-compose/.env
# Add: N8N_PASSWORD=<generated_password>

# Use secure compose file
docker compose -f docker-compose/core-infrastructure-secure.yml down
docker compose -f docker-compose/core-infrastructure-secure.yml up -d
```

### Step 4: Remove Public Exposures

Update `docker-compose/core-infrastructure.yml`:
```yaml
# Remove or comment out n8n public port
# ports:
#   - "5678:443"
```

### Step 5: Verify Lockdown

Run verification script:
```bash
cd /home/melvin/projects/server
./verify-lockdown.sh
```

Manual verification:
```bash
# Check exposed ports (should only show 80, 443 on 0.0.0.0)
sudo ss -tlnp | grep "0.0.0.0"

# Check firewall
sudo ufw status numbered

# Test from outside Tailscale
# SSH should timeout
# Portainer should be inaccessible
```

## Post-Lockdown Tasks

### 1. Update Credentials
- [ ] Change n8n password in UI
- [ ] Update WordPress admin password
- [ ] Rotate any API keys

### 2. Enable Monitoring
```bash
# Install fail2ban
sudo apt-get update && sudo apt-get install -y fail2ban

# Configure for SSH protection
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo systemctl enable --now fail2ban
```

### 3. Set Up Alerts
Configure monitoring to alert on:
- Failed login attempts
- Firewall violations
- Service failures

### 4. Document Changes
- Update team documentation
- Record new passwords in password manager
- Update access procedures

## Emergency Rollback

If locked out:

### Via Console/VNC:
```bash
# Disable firewall
sudo ufw disable

# Reset SSH to listen on all interfaces
sudo sed -i 's/ListenAddress.*/# ListenAddress 0.0.0.0/' /etc/ssh/sshd_config
sudo systemctl restart ssh
```

### Restore Original Configuration:
```bash
# Restore SSH
sudo cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
sudo systemctl restart ssh

# Restore docker-compose
cd docker-stack-infrastructure
git checkout docker-compose/core-infrastructure.yml
docker compose -f docker-compose/core-infrastructure.yml up -d
```

## Security Verification Checklist

After lockdown, verify:
- [ ] UFW enabled and configured correctly
- [ ] SSH accessible only via Tailscale
- [ ] No services on 0.0.0.0 except Caddy (80/443)
- [ ] All default passwords changed
- [ ] Monitoring active
- [ ] Backups configured
- [ ] Documentation updated

## Maintenance

Weekly:
- Review firewall logs
- Check for security updates
- Verify all services running

Monthly:
- Rotate passwords
- Review access logs
- Update documentation

## Support

If issues arise:
1. Check Tailscale connection first
2. Review `/var/log/ufw.log` for blocks
3. Check service logs via Portainer
4. Use console access if network locked out

---
*Remember: Security is an ongoing process, not a one-time task*