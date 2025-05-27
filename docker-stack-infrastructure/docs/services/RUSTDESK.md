# RustDesk Self-Hosted Server Guide

This document provides information about the RustDesk self-hosted server setup and how to connect clients to it.

## Overview

RustDesk is an open-source remote desktop solution that serves as an alternative to proprietary solutions like TeamViewer and AnyDesk. Our setup uses Docker containers to run the RustDesk server components locally.

## Server Domain

The RustDesk server is accessible through the following domain:

- **rd.stringbits.com**: Main domain for RustDesk services
  - This domain provides access to the RustDesk web interface and API
  - Secured with HTTPS via Caddy's automatic certificate management

## Server Components

The RustDesk server consists of two main components:

1. **HBBS (ID/Rendezvous Server)**:
   - Handles client discovery and NAT traversal
   - Helps clients find each other on the network
   - Container name: `rustdesk-hbbs`
   - Ports: 21115 (TCP), 21116 (TCP/UDP), 21118 (TCP)

2. **HBBR (Relay Server)**:
   - Relays traffic when direct connections between clients aren't possible
   - Used as a fallback when NAT traversal fails
   - Container name: `rustdesk-hbbr`
   - Ports: 21117 (TCP), 21119 (TCP)

## Required Ports

The following ports need to be accessible for proper RustDesk server functionality:

- **21115 (TCP)**: Used for NAT type test
- **21116 (TCP/UDP)**: Used for ID registration, heartbeat service, and TCP hole punching
- **21117 (TCP)**: Used for relay services
- **21118 (TCP)**: Used to support web clients
- **21119 (TCP)**: Used to support web clients

These ports are configured in the firewall using the `/home/shared/docker/update-firewall.sh` script. Run this script if you need to update the firewall rules.

## Data Persistence

The RustDesk server stores its data in `/home/shared/docker/rustdesk`. This directory contains important files including:

- `id_ed25519`: Private key for the server
- `id_ed25519.pub`: Public key used to configure clients

## Connecting Clients to the Self-Hosted Server

To connect RustDesk clients to your self-hosted server:

1. **Get the server's public key**:
   ```bash
   cat /home/shared/docker/rustdesk/id_ed25519.pub
   ```

2. **Configure the RustDesk client**:
   - Open RustDesk client
   - Go to Settings
   - Navigate to "Network" or "Connection"
   - Enter the server domain: `rd.stringbits.com`
   - Paste the public key from `id_ed25519.pub`
   - Save and restart the client

3. **Verify Connection**:
   - After restarting, the client should connect to your self-hosted server
   - Your IDs will be issued by your server rather than the public RustDesk server

## Web Client Access

RustDesk provides a web client interface that can be accessed through:

- **https://rd.stringbits.com**

This allows users to connect to remote machines without installing the RustDesk client, provided the remote machine is already running a RustDesk host configured to connect to your server.

## Troubleshooting

If you encounter issues with the RustDesk server:

1. **Check container status**:
   ```bash
   docker ps | grep rustdesk
   ```

2. **View logs**:
   ```bash
   docker logs rustdesk-hbbs
   docker logs rustdesk-hbbr
   ```

3. **Verify port accessibility**:
   ```bash
   nc -zv localhost 21115
   nc -zv localhost 21116
   nc -zv localhost 21117
   ```

4. **Check key files**:
   ```bash
   ls -la /home/shared/docker/rustdesk/
   ```

5. **Check Caddy configuration**:
   ```bash
   docker logs caddy
   ```

6. **Test domain connectivity**:
   ```bash
   curl -I https://rd.stringbits.com
   ```

## Security Considerations

- The RustDesk server components handle potentially sensitive remote access operations
- Access to the server's private key should be restricted
- Firewall rules are configured to restrict access to only necessary ports
- HTTPS is enforced for all web connections to rd.stringbits.com
- Security headers are implemented through Caddy
- Regular updates through Watchtower ensure security patches are applied