# Emergency Access Information
**Created**: 2025-01-26
**KEEP THIS INFORMATION SAFE**

## Current Access Methods

### 1. Direct SSH (Currently Working)
- Public IP: 147.93.3.63
- SSH Port: 22
- User: melvin

### 2. Tailscale Access
- Tailscale IP: 100.112.235.46
- Device name: vmi2605051
- Status: Connected

### 3. Console Access
- Provider: Contabo (based on hostname vmi2605051)
- Use VNC/Console from hosting control panel

## Before Making Changes

1. **Keep multiple SSH sessions open**
   - Current session: DO NOT CLOSE
   - Open a second SSH session as backup
   - Keep console/VNC ready

2. **Test commands before applying**
   ```bash
   # Test SSH connection via Tailscale
   ssh melvin@100.112.235.46
   
   # Test SSH connection via public IP
   ssh melvin@147.93.3.63
   ```

3. **Backup current configs**
   ```bash
   sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)
   ```

## If Locked Out

### Option 1: Console/VNC Access
1. Login to Contabo control panel
2. Access VNC console
3. Login directly as melvin
4. Reverse changes:
   ```bash
   sudo ufw disable
   sudo cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
   sudo systemctl restart ssh
   ```

### Option 2: Recovery Mode
1. Reboot server from control panel
2. Access recovery/rescue mode
3. Mount filesystem and reverse changes

## Safe Testing Procedure

1. Make change
2. Test in NEW terminal (don't close current)
3. If it works, continue
4. If it fails, reverse immediately in current session