# Securing n8n with SSL/TLS Certificate
**Created**: 2025-05-27

## Overview

This guide explains how to properly configure SSL/TLS for n8n workflow automation through Caddy reverse proxy.

## Current Issue

n8n is currently misconfigured:
- Container exposes port 5678 publicly (security risk)
- Caddy tries to proxy to n8n:443 but n8n serves on port 5678
- Default credentials are still active
- No proper SSL termination

## Solution: Proper SSL Configuration

### Step 1: Update n8n Docker Configuration

Edit `/home/melvin/projects/server/docker-stack-infrastructure/docker-compose/applications.yml`:

```yaml
services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: always
    # Remove public port exposure - access only through Caddy
    # ports:
    #   - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_USER:-admin}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD:-changeme}
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY:-your_super_secret_key}
      - N8N_HOST=n8n.stringbits.com
      - N8N_PROTOCOL=https
      - N8N_PORT=443
      - N8N_SECURE_COOKIE=true
      - WEBHOOK_URL=https://n8n.stringbits.com/
      - NODE_ENV=production
    volumes:
      - n8n_data:/home/node/.n8n
    networks:
      - stringbits_net
    security_opt:
      - no-new-privileges:true
    labels:
      - com.centurylinklabs.watchtower.enable=true
```

### Step 2: Fix Caddy Configuration

Update `/home/melvin/projects/server/docker-stack-infrastructure/caddy/config/Caddyfile`:

```
n8n.stringbits.com {
    import security_headers
    reverse_proxy n8n:5678
}
```

### Step 3: Create Environment File

Create `/home/melvin/projects/server/docker-stack-infrastructure/.env`:

```bash
# n8n Configuration
N8N_USER=admin
N8N_PASSWORD=your_secure_password_here
N8N_ENCRYPTION_KEY=$(openssl rand -base64 32)

# MySQL Configuration (for WordPress)
MYSQL_ROOT_PASSWORD=your_root_password
MYSQL_PASSWORD=your_wp_password
```

### Step 4: Apply Changes

```bash
cd /home/melvin/projects/server/docker-stack-infrastructure

# Stop services
docker-compose -f docker-compose/applications.yml down

# Restart with new configuration
docker-compose -f docker-compose/applications.yml up -d

# Restart Caddy to apply proxy changes
docker restart caddy
```

### Step 5: Verify SSL Certificate

```bash
# Check certificate
curl -I https://n8n.stringbits.com

# Should see:
# HTTP/2 200
# strict-transport-security: max-age=31536000; includeSubDomains; preload
```

## How It Works

1. **Caddy handles SSL/TLS**:
   - Automatically obtains Let's Encrypt certificates
   - Terminates SSL/TLS connections
   - Forwards plain HTTP to n8n container

2. **n8n runs HTTP internally**:
   - Listens on port 5678 (default)
   - No need for n8n to handle certificates
   - Secure cookies enabled for HTTPS

3. **Security improvements**:
   - No public port exposure
   - Environment variables for secrets
   - Network isolation
   - Proper authentication

## Important Security Notes

### Change Default Credentials

**Critical**: Update these immediately:
1. n8n username and password
2. n8n encryption key (use `openssl rand -base64 32`)
3. MySQL passwords

### Network Security

- n8n should only be accessible through Caddy
- Remove the `ports: - "5678:5678"` line
- Ensure n8n is on the same Docker network as Caddy

### Additional Hardening

1. **Enable 2FA in n8n**:
   - Login to n8n
   - Go to Settings > Security
   - Enable two-factor authentication

2. **Restrict Access by IP** (optional):
   ```
   n8n.stringbits.com {
       @allowed {
           remote_ip 100.64.0.0/10
       }
       handle @allowed {
           import security_headers
           reverse_proxy n8n:5678
       }
       respond 403
   }
   ```

3. **Monitor Access**:
   ```bash
   # Check access logs
   docker logs caddy | grep n8n.stringbits.com
   ```

## Troubleshooting

### 502 Bad Gateway

If you get a 502 error:
1. Check n8n is running: `docker ps | grep n8n`
2. Verify network: `docker inspect n8n | grep NetworkMode`
3. Check logs: `docker logs n8n`

### Certificate Issues

Caddy automatically handles certificates, but if issues arise:
```bash
# Check Caddy logs
docker logs caddy | grep -i cert

# Force certificate renewal
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

### Can't Access n8n

1. Verify DNS: `nslookup n8n.stringbits.com`
2. Check firewall: `sudo ufw status`
3. Test locally: `docker exec caddy wget -O- http://n8n:5678`

## Next Steps

1. Change all default passwords
2. Remove public port exposure from docker-compose
3. Enable 2FA in n8n
4. Set up monitoring for the service
5. Configure backup for n8n workflows

## References

- [n8n Security Best Practices](https://docs.n8n.io/hosting/security/)
- [Caddy Reverse Proxy](https://caddyserver.com/docs/quick-starts/reverse-proxy)
- [Docker Network Security](https://docs.docker.com/network/security/)