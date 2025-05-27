# Portainer Security Configuration

This document outlines the security measures implemented to restrict Portainer access to the Tailscale network only.

## Overview

Portainer is a powerful container management UI that provides full control over your Docker environment. To enhance security, we've restricted access to Portainer in multiple layers:

1. **Network Binding**: Portainer only listens on localhost and Tailscale IP addresses
2. **Caddy Reverse Proxy**: Access filtering at the HTTP level
3. **Firewall Rules**: Additional protection at the network level

## Configuration Details

### 1. Docker Port Binding Restrictions

Portainer's ports are now only bound to:
- `127.0.0.1` (localhost): For local access on the server
- `100.84.182.31` (Tailscale IP): For secure access through Tailscale VPN

Configuration in `docker-compose.yml`:
```yaml
ports:
  - "127.0.0.1:9443:9443"
  - "100.84.182.31:9443:9443"
```

### 2. Caddy Access Control

Caddy is configured to:
- Only allow connections from Tailscale IP ranges (100.64.0.0/10, fd7a:115c:a1e0::/48)
- Return a 403 Forbidden response for all other IP addresses

Configuration in `Caddyfile`:
```
ptn.stringbits.com {
    import security_headers
    
    # Only allow access from Tailscale network
    @tailscale {
        remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48
    }
    
    # Deny access from non-Tailscale IPs
    @non_tailscale {
        not remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48
    }
    
    respond @non_tailscale 403 {
        body "Access to Portainer is restricted to Tailscale network only"
    }
    
    reverse_proxy @tailscale portainer:9443 {
        transport http {
            tls_insecure_skip_verify
        }
    }
}
```

### 3. Firewall Rules

The firewall is configured to:
- Deny direct access to Portainer ports (9443, 8000, 9000) from the internet
- Allow access only from Tailscale IP ranges
- Allow access from localhost for local administration

The `/home/shared/docker/update-firewall.sh` script handles these configurations for UFW, FirewallD, and iptables.

## Testing Access

### From Tailscale Network

When connected to Tailscale, you should be able to access Portainer at:
- https://ptn.stringbits.com
- https://100.84.182.31:9443 (direct access)

### From Outside Tailscale Network

When not connected to Tailscale, you should see:
- A 403 Forbidden response when accessing https://ptn.stringbits.com
- Connection timeout when attempting to connect to port 9443 directly

## Troubleshooting

If you encounter issues accessing Portainer through Tailscale:

1. Verify Tailscale connection status:
   ```
   tailscale status
   ```

2. Check that your device is properly connected to the Tailscale network

3. Verify that the Tailscale interface is up:
   ```
   ip -br addr show tailscale0
   ```

4. Check the Caddy logs for access attempts:
   ```
   docker logs caddy
   ```

5. Test direct connection to the Portainer port on the Tailscale IP:
   ```
   curl -k https://100.84.182.31:9443
   ```

## Security Benefits

This configuration provides several security benefits:

1. **Zero Public Exposure**: Portainer is completely inaccessible from the public internet
2. **Encrypted VPN Access**: All Tailscale traffic is end-to-end encrypted
3. **Identity-Based Access**: Tailscale requires user authentication before network access
4. **Defense in Depth**: Multiple layers of protection (binding, proxy, firewall)
5. **Access Logging**: Both Tailscale and Caddy provide logs of access attempts