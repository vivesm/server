# SSH Setup for Alpine Terminal on Phone

## Server Information
- **Tailscale IP**: 100.112.235.46
- **Username**: melvin
- **SSH Port**: 22 (standard)

## Option 1: SSH Key Authentication (Recommended)

### On your phone's Alpine terminal:

1. **Generate SSH key pair** (if you don't have one):
```bash
ssh-keygen -t ed25519 -C "phone@alpine"
# Press Enter to accept default location
# Optionally set a passphrase
```

2. **Display your public key**:
```bash
cat ~/.ssh/id_ed25519.pub
```

3. **Copy the public key** and send it to me to add to the server

### Alternative: Add the key yourself via existing access:
```bash
# From a machine that already has SSH access:
echo "YOUR_PHONE_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
```

## Option 2: Use Existing Key

If you already have the private key that matches the authorized key on the server:

1. **Create .ssh directory** on your phone:
```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

2. **Create the private key file**:
```bash
vi ~/.ssh/id_ed25519
# Paste your private key
chmod 600 ~/.ssh/id_ed25519
```

## Connect via SSH

Once your key is set up:

```bash
ssh melvin@100.112.235.46
```

Or add an alias to your phone's `~/.ssh/config`:
```bash
Host vps
    HostName 100.112.235.46
    User melvin
    IdentityFile ~/.ssh/id_ed25519
```

Then connect with:
```bash
ssh vps
```

## Troubleshooting

1. **Permission denied**: Ensure your private key has correct permissions (600)
2. **Connection refused**: Verify Tailscale is connected on your phone
3. **Host key verification**: Accept the host key on first connection

## Security Notes
- SSH is configured to only accept key authentication (no passwords)
- Root login is disabled
- The server is only accessible via Tailscale network