# Safe Security Lockdown - Step by Step
**DO NOT RUSH - Test each step**

## Pre-Flight Checklist

- [ ] Keep THIS SSH session open at all times
- [ ] Open a SECOND SSH session for testing
- [ ] Note your Tailscale IP: 100.112.235.46
- [ ] Note your public IP: 147.93.3.63
- [ ] Have console/VNC access ready

## Step 1: Test Tailscale SSH Access FIRST

**In a NEW terminal**, test:
```bash
ssh melvin@100.112.235.46
```

If this works, you're safe to proceed. If not, STOP and fix Tailscale first.

## Step 2: Configure UFW (WITHOUT enabling yet)

```bash
# Reset UFW to clean state
sudo ufw --force reset

# Set defaults
sudo ufw default deny incoming
sudo ufw default allow outgoing

# CRITICAL: Allow SSH from both your current IP and Tailscale
sudo ufw allow from 147.93.3.63 to any port 22 comment 'Current IP SSH'
sudo ufw allow from 100.64.0.0/10 to any port 22 comment 'Tailscale SSH'

# Allow web services
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# Show what WILL happen (dry run)
sudo ufw show added
```

## Step 3: Test UFW Rules (WITHOUT enabling)

Check the rules look correct:
```bash
sudo ufw status numbered
```

You should see:
- SSH allowed from your current IP (147.93.3.63)
- SSH allowed from Tailscale network (100.64.0.0/10)
- HTTP and HTTPS allowed

## Step 4: Enable UFW with Escape Plan

**CRITICAL**: Have your second SSH session ready!

```bash
# Enable UFW
sudo ufw --force enable

# IMMEDIATELY test in your SECOND terminal:
# ssh melvin@147.93.3.63
# ssh melvin@100.112.235.46
```

If you can't connect in the second terminal:
```bash
# QUICKLY disable UFW in your first session
sudo ufw disable
```

## Step 5: Remove n8n Public Exposure (SAFE)

This is safe to do anytime:
```bash
cd /home/melvin/projects/server/docker-stack-infrastructure

# Backup current config
cp docker-compose/core-infrastructure.yml docker-compose/core-infrastructure.yml.backup

# Edit the file
nano docker-compose/core-infrastructure.yml
```

Find the n8n section and remove/comment the ports:
```yaml
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: always
    # REMOVE OR COMMENT THIS:
    # ports:
    #   - "5678:443"
```

Apply changes:
```bash
docker compose -f docker-compose/core-infrastructure.yml up -d
```

## Step 6: SSH Hardening (MOST DANGEROUS - DO LAST)

**ONLY do this after confirming UFW works!**

```bash
# Backup SSH config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.safe

# Test SSH config changes
sudo sshd -t
```

For now, let's SKIP binding SSH to Tailscale only until everything else is secure.

## Safe Order of Operations

1. ✅ Test Tailscale SSH works
2. ✅ Configure UFW with current IP allowed
3. ✅ Enable UFW and test immediately
4. ✅ Fix n8n exposure (safe anytime)
5. ⏸️ WAIT on SSH restrictions until confident

## Emergency Rollback Commands

```bash
# Disable firewall
sudo ufw disable

# Restore SSH config
sudo cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
sudo systemctl restart ssh

# Restore docker-compose
cd docker-stack-infrastructure
git checkout docker-compose/core-infrastructure.yml
```

---
**Remember**: It's better to be partially secure and have access than fully secure and locked out!